-- Stage 2: POPIA consent records and privacy-rights requests. Additive only:
-- two new tables, new functions, and handle_new_user extended to record the
-- policy acceptance a customer gives when signing up. Safe to re-run.

begin;

-- 1) Policy acceptances --------------------------------------------------

-- Evidence that a customer accepted the terms and read the privacy policy,
-- at signup or at checkout. Customers can read their own records; only the
-- functions below write them.
create table if not exists public.policy_acceptances (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  documents text[] not null
    check (cardinality(documents) >= 1 and documents <@ array['terms', 'privacy']),
  version text not null check (length(version) between 1 and 60),
  context text not null check (context in ('signup', 'checkout')),
  client text not null check (client in ('website', 'android')),
  checkout_id uuid,
  accepted_at timestamptz not null default timezone('utc', now())
);
create index if not exists policy_acceptances_user_idx
  on public.policy_acceptances (user_id, accepted_at desc);
create unique index if not exists policy_acceptances_checkout_idx
  on public.policy_acceptances (user_id, checkout_id) where checkout_id is not null;

alter table public.policy_acceptances enable row level security;
revoke all on table public.policy_acceptances from anon, authenticated;
grant select on table public.policy_acceptances to authenticated;
grant select, insert on table public.policy_acceptances to service_role;

drop policy if exists "policy_acceptances_owner_read" on public.policy_acceptances;
create policy "policy_acceptances_owner_read" on public.policy_acceptances
  for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists "policy_acceptances_admin_read" on public.policy_acceptances;
create policy "policy_acceptances_admin_read" on public.policy_acceptances
  for select to authenticated using (public.is_admin());

-- Records a checkout acceptance for the caller. Linking the checkout draft
-- ties the acceptance to the order that payment creates (same ID). Repeated
-- calls for one checkout return the existing record.
create or replace function public.record_policy_acceptance(
  p_version text,
  p_context text,
  p_client text,
  p_checkout_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  caller_id uuid := auth.uid();
  existing_id uuid;
  created_id uuid;
begin
  if caller_id is null then
    raise exception 'A signed-in session is required.' using errcode = '42501';
  end if;
  if length(coalesce(p_version, '')) not between 1 and 60
     or p_context not in ('signup', 'checkout')
     or p_client not in ('website', 'android') then
    raise exception 'Invalid policy acceptance.' using errcode = '22023';
  end if;
  if p_checkout_id is not null then
    if not exists (
      select 1 from public.checkout_intents where id = p_checkout_id and user_id = caller_id
    ) then
      raise exception 'Checkout not found for this account.' using errcode = '42501';
    end if;
    select id into existing_id from public.policy_acceptances
    where user_id = caller_id and checkout_id = p_checkout_id;
    if existing_id is not null then
      return existing_id;
    end if;
  end if;

  insert into public.policy_acceptances (user_id, documents, version, context, client, checkout_id)
  values (caller_id, array['terms', 'privacy'], p_version, p_context, p_client, p_checkout_id)
  on conflict (user_id, checkout_id) where checkout_id is not null do nothing
  returning id into created_id;
  if created_id is null then
    select id into created_id from public.policy_acceptances
    where user_id = caller_id and checkout_id = p_checkout_id;
  end if;
  return created_id;
end;
$$;

revoke all on function public.record_policy_acceptance(text, text, text, uuid) from public, anon;
grant execute on function public.record_policy_acceptance(text, text, text, uuid) to authenticated;

-- Signup acceptance travels in the new user's metadata (policy_version and
-- policy_client), because email sign-ups have no session until confirmed.
-- Invalid or missing values record nothing, so signup can never fail here.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  accepted_version text := new.raw_user_meta_data ->> 'policy_version';
  accepted_client text := new.raw_user_meta_data ->> 'policy_client';
begin
  insert into public.profiles (id, email, full_name, phone)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'phone'
  )
  on conflict (id) do update
    set
      email = excluded.email,
      full_name = coalesce(excluded.full_name, public.profiles.full_name),
      phone = coalesce(excluded.phone, public.profiles.phone);

  if length(coalesce(accepted_version, '')) between 1 and 60
     and accepted_client in ('website', 'android') then
    insert into public.policy_acceptances (user_id, documents, version, context, client)
    values (new.id, array['terms', 'privacy'], accepted_version, 'signup', accepted_client);
  end if;

  return new;
end;
$$;

-- 2) Privacy-rights requests ---------------------------------------------

-- Requests to access, correct or delete personal information, or to object
-- to processing. Customers submit and read their own; admins read and update
-- the status.
create table if not exists public.privacy_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  request_type text not null
    check (request_type in ('access', 'correction', 'deletion', 'objection', 'other')),
  details text not null check (length(details) between 1 and 2000),
  status text not null default 'received'
    check (status in ('received', 'in_progress', 'completed', 'declined')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  resolved_at timestamptz
);
create index if not exists privacy_requests_user_idx
  on public.privacy_requests (user_id, created_at desc);
create index if not exists privacy_requests_open_idx
  on public.privacy_requests (created_at) where status in ('received', 'in_progress');

drop trigger if exists privacy_requests_touch_updated_at on public.privacy_requests;
create trigger privacy_requests_touch_updated_at
before update on public.privacy_requests
for each row execute procedure public.touch_updated_at();

alter table public.privacy_requests enable row level security;
revoke all on table public.privacy_requests from anon, authenticated;
grant select on table public.privacy_requests to authenticated;
grant update (status, resolved_at) on table public.privacy_requests to authenticated;
grant select, insert, update on table public.privacy_requests to service_role;

drop policy if exists "privacy_requests_owner_read" on public.privacy_requests;
create policy "privacy_requests_owner_read" on public.privacy_requests
  for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists "privacy_requests_admin_read" on public.privacy_requests;
create policy "privacy_requests_admin_read" on public.privacy_requests
  for select to authenticated using (public.is_admin());
drop policy if exists "privacy_requests_admin_update" on public.privacy_requests;
create policy "privacy_requests_admin_update" on public.privacy_requests
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- Signed-in (not guest) customers only, at most three open requests each.
create or replace function public.submit_privacy_request(
  p_request_type text,
  p_details text
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  caller_id uuid := auth.uid();
  created_id uuid;
begin
  if caller_id is null or coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) then
    raise exception 'Sign in to your account to make a privacy request.' using errcode = '42501';
  end if;
  if p_request_type not in ('access', 'correction', 'deletion', 'objection', 'other')
     or length(trim(coalesce(p_details, ''))) not between 1 and 2000 then
    raise exception 'Invalid privacy request.' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtext('privacy_request:' || caller_id::text));
  if (select count(*) from public.privacy_requests
      where user_id = caller_id and status in ('received', 'in_progress')) >= 3 then
    raise exception 'You already have three open privacy requests.' using errcode = 'P0001';
  end if;
  insert into public.privacy_requests (user_id, request_type, details)
  values (caller_id, p_request_type, trim(p_details))
  returning id into created_id;
  return created_id;
end;
$$;

revoke all on function public.submit_privacy_request(text, text) from public, anon;
grant execute on function public.submit_privacy_request(text, text) to authenticated;

commit;
