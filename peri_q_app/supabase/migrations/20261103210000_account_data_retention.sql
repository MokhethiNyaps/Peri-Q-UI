-- Stage 3: account data and retention (compliance audit D-H2, D-M2).
-- 1) Deleting an account keeps the customer's orders and payment records,
--    with name, phone, address and notes removed, instead of deleting them.
-- 2) Retention periods live in a settings table. Clean-up runs only for
--    periods that are confirmed (attorney/accountant decision), daily.
-- No existing rows are deleted by this migration. Safe to re-run.

begin;

-- 1) Orders outlive the account that placed them ------------------------

alter table public.orders alter column user_id drop not null;
alter table public.orders drop constraint if exists orders_user_id_fkey;
alter table public.orders
  add constraint orders_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete set null;

-- Removes what identifies a customer from their orders. Items, totals,
-- payment references and dates stay, as financial records.
create or replace function public.anonymise_customer_orders(p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  changed integer;
begin
  update public.order_items
  set notes = ''
  where order_id in (select id from public.orders where user_id = p_user_id)
    and notes <> '';
  update public.orders
  set customer_name = 'Deleted customer',
      customer_phone = 'deleted',
      delivery_address = null
  where user_id = p_user_id;
  get diagnostics changed = row_count;
  return changed;
end;
$$;

revoke all on function public.anonymise_customer_orders(uuid) from public, anon, authenticated;
grant execute on function public.anonymise_customer_orders(uuid) to service_role;

-- Account deletion: anonymise the orders, then delete the account. The
-- profile, push tokens, unfinished checkouts, consent records and privacy
-- requests are deleted with it; the orders are kept without an owner.
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  caller_id uuid := auth.uid();
begin
  if caller_id is null then
    raise exception 'No signed-in account.' using errcode = '42501';
  end if;
  perform public.anonymise_customer_orders(caller_id);
  delete from auth.users where id = caller_id;
end;
$$;

revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;

-- 2) Retention settings --------------------------------------------------

-- keep_days = null means "keep until decided". Clean-up only acts on rows
-- with confirmed = true. Proposed defaults are not confirmed.
create table if not exists public.retention_settings (
  data_type text primary key,
  description text not null,
  keep_days integer check (keep_days is null or keep_days > 0),
  confirmed boolean not null default false,
  confirmed_by text check (confirmed_by is null or length(confirmed_by) between 1 and 200),
  updated_at timestamptz not null default timezone('utc', now())
);

insert into public.retention_settings (data_type, description, keep_days) values
  ('checkout_drafts', 'Unfinished checkouts: unpaid drafts holding name, phone and address. Proposed: 30 days.', 30),
  ('guest_accounts', 'Guest (anonymous) sign-ins that never placed an order. Proposed: 90 days.', 90),
  ('deleted_customer_orders', 'Orders kept after the customer deleted their account, anonymised. Period set by tax and record-keeping law: to be confirmed.', null),
  ('webhook_events', 'Verified payment notifications from Yoco (no personal details). To be confirmed.', null),
  ('admin_audit_log', 'Record of admin changes. To be confirmed.', null)
on conflict (data_type) do nothing;

drop trigger if exists retention_settings_touch_updated_at on public.retention_settings;
create trigger retention_settings_touch_updated_at
before update on public.retention_settings
for each row execute procedure public.touch_updated_at();

-- Admins can read the periods. Changing them can delete financial records,
-- so it is done deliberately by the owner in the Supabase SQL editor, e.g.:
--   update public.retention_settings
--   set keep_days = 30, confirmed = true, confirmed_by = 'Owner, 2026-11-10'
--   where data_type = 'checkout_drafts';
alter table public.retention_settings enable row level security;
revoke all on table public.retention_settings from anon, authenticated;
grant select on table public.retention_settings to authenticated;
grant select, update on table public.retention_settings to service_role;

drop policy if exists "retention_settings_admin_read" on public.retention_settings;
create policy "retention_settings_admin_read" on public.retention_settings
  for select to authenticated using (public.is_admin());

-- 3) Clean-up job --------------------------------------------------------

-- Deletes data older than each confirmed period and returns how many rows
-- each rule removed. Unconfirmed or open-ended periods are skipped.
create or replace function public.run_retention()
returns jsonb
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  rule record;
  cutoff timestamptz;
  removed integer;
  summary jsonb := '{}'::jsonb;
begin
  for rule in
    select data_type, keep_days from public.retention_settings
    where confirmed and keep_days is not null
  loop
    cutoff := timezone('utc', now()) - make_interval(days => rule.keep_days);
    removed := 0;
    if rule.data_type = 'checkout_drafts' then
      delete from public.checkout_intents where created_at < cutoff;
      get diagnostics removed = row_count;
    elsif rule.data_type = 'guest_accounts' then
      delete from auth.users u
      where u.is_anonymous
        and u.created_at < cutoff
        and coalesce(u.last_sign_in_at, u.created_at) < cutoff
        and not exists (select 1 from public.orders o where o.user_id = u.id);
      get diagnostics removed = row_count;
    elsif rule.data_type = 'deleted_customer_orders' then
      delete from public.orders where user_id is null and created_at < cutoff;
      get diagnostics removed = row_count;
    elsif rule.data_type = 'webhook_events' then
      delete from public.yoco_webhook_events where created_at < cutoff;
      get diagnostics removed = row_count;
    elsif rule.data_type = 'admin_audit_log' then
      delete from public.admin_audit_log where created_at < cutoff;
      get diagnostics removed = row_count;
    end if;
    summary := summary || jsonb_build_object(rule.data_type, removed);
  end loop;
  return summary;
end;
$$;

revoke all on function public.run_retention() from public, anon, authenticated;
grant execute on function public.run_retention() to service_role;

commit;

-- Daily at 02:15 (UTC) where pg_cron is available. Scheduling under the same
-- name replaces the existing job, so re-running does not duplicate it.
do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    perform cron.schedule('retention-daily', '15 2 * * *', 'select public.run_retention()');
  end if;
end;
$$;
