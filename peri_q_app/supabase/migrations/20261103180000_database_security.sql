-- Stage 6: database security hardening (compliance audit D-M3, D-M6, D-L2,
-- D-L3 and live-check L-1, L-2). No data is changed or deleted. It removes
-- permissions nothing legitimately uses, narrows what admins can edit, and
-- adds an audit log of admin changes. Safe to re-run.

begin;

-- 1) Least-privilege table grants (L-1) ----------------------------------

-- Signed-out visitors (anon) only ever read the menu and store settings.
-- Guests who check out sign in anonymously and act as `authenticated`.
revoke insert, update, delete on all tables in schema public from anon;
-- Nobody outside the database owner needs these.
revoke truncate, trigger, references on all tables in schema public from anon, authenticated;

alter default privileges in schema public revoke insert, update, delete on tables from anon;
alter default privileges in schema public revoke truncate, trigger, references on tables from anon, authenticated;

-- 2) Admins may change only an order's status (D-M3) --------------------

-- Payment fields, totals and customer details on orders are written only by
-- the server (service_role) and its functions. RLS still limits status
-- changes to admins, and the status trigger limits which changes are valid.
revoke update on table public.orders from authenticated;
grant update (status) on table public.orders to authenticated;

-- 3) Customers cannot change the email on their profile (D-L3) ------------

-- profiles.email mirrors the sign-in email. Customers may still edit their
-- name and phone; the email always follows auth.users unless an admin or
-- the server makes the change.
create or replace function public.protect_profile_email()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
begin
  if new.email is distinct from old.email
     and auth.uid() is not null
     and not public.is_admin() then
    new.email := (select email from auth.users where id = new.id);
  end if;
  return new;
end;
$$;

revoke all on function public.protect_profile_email() from public, anon, authenticated;

drop trigger if exists profiles_protect_email on public.profiles;
create trigger profiles_protect_email
before update on public.profiles
for each row execute procedure public.protect_profile_email();

-- 4) Retired EFT uploads and storage listing (D-M6, D-L2) -----------------

-- EFT payment proofs are no longer accepted. Customers keep read and delete
-- access to their own historical files (account deletion uses both).
drop policy if exists "payment_proofs_owner_insert" on storage.objects;
revoke execute on function public.attach_payment_proof(uuid, text) from authenticated;

-- Menu photos are served from the public bucket URL, which needs no policy.
-- Listing the bucket is limited to admins, whose uploads overwrite files.
drop policy if exists "menu_images_public_read" on storage.objects;
drop policy if exists "menu_images_admin_read" on storage.objects;
create policy "menu_images_admin_read" on storage.objects
  for select to authenticated
  using (bucket_id = 'menu-images' and public.is_admin());

-- 5) Function hardening (L-2 and advisor findings) ------------------------

alter function public.touch_updated_at() set search_path = public, pg_temp;

-- handle_new_user runs only as a trigger; nobody needs to call it directly.
revoke execute on function public.handle_new_user() from public, anon, authenticated;
-- is_admin is used by policies for signed-in users only.
revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated, service_role;

-- 6) Admin audit log (D-M3) ----------------------------------------------

-- One row for each change an admin makes to orders, the menu, store
-- settings, profiles and privacy requests: who, when, and the changed
-- values. Server and customer changes are not admin actions and are not
-- logged here. Retention: [To be confirmed with the Stage 3 retention
-- decision].
create table if not exists public.admin_audit_log (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users (id) on delete set null,
  table_name text not null,
  row_id text not null,
  action text not null check (action in ('insert', 'update', 'delete')),
  changes jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);
create index if not exists admin_audit_log_created_idx
  on public.admin_audit_log (created_at desc);
create index if not exists admin_audit_log_row_idx
  on public.admin_audit_log (table_name, row_id);

alter table public.admin_audit_log enable row level security;
revoke all on table public.admin_audit_log from anon, authenticated;
grant select on table public.admin_audit_log to authenticated;
grant select on table public.admin_audit_log to service_role;

drop policy if exists "admin_audit_log_admin_read" on public.admin_audit_log;
create policy "admin_audit_log_admin_read" on public.admin_audit_log
  for select to authenticated using (public.is_admin());

create or replace function public.log_admin_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  old_row jsonb := case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end;
  new_row jsonb := case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end;
  changed jsonb;
begin
  if auth.uid() is null or not public.is_admin() then
    return null;
  end if;
  if tg_op = 'UPDATE' then
    select jsonb_object_agg(key, jsonb_build_object('from', old_row -> key, 'to', value))
    into changed
    from jsonb_each(new_row)
    where key <> 'updated_at' and (old_row -> key) is distinct from value;
    if changed is null then
      return null;
    end if;
  else
    changed := coalesce(new_row, old_row);
  end if;
  insert into public.admin_audit_log (actor_id, table_name, row_id, action, changes)
  values (
    auth.uid(), tg_table_name, coalesce(new_row ->> 'id', old_row ->> 'id'),
    lower(tg_op), changed
  );
  return null;
end;
$$;

revoke all on function public.log_admin_change() from public, anon, authenticated;

drop trigger if exists orders_admin_audit on public.orders;
create trigger orders_admin_audit after update on public.orders
for each row execute procedure public.log_admin_change();
drop trigger if exists menu_items_admin_audit on public.menu_items;
create trigger menu_items_admin_audit after insert or update or delete on public.menu_items
for each row execute procedure public.log_admin_change();
drop trigger if exists menu_categories_admin_audit on public.menu_categories;
create trigger menu_categories_admin_audit after insert or update or delete on public.menu_categories
for each row execute procedure public.log_admin_change();
drop trigger if exists app_settings_admin_audit on public.app_settings;
create trigger app_settings_admin_audit after insert or update on public.app_settings
for each row execute procedure public.log_admin_change();
drop trigger if exists profiles_admin_audit on public.profiles;
create trigger profiles_admin_audit after update on public.profiles
for each row execute procedure public.log_admin_change();
drop trigger if exists privacy_requests_admin_audit on public.privacy_requests;
create trigger privacy_requests_admin_audit after update on public.privacy_requests
for each row execute procedure public.log_admin_change();

commit;
