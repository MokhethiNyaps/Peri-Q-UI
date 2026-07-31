create table if not exists public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  installation_id text not null check (length(installation_id) between 16 and 200),
  fcm_token text not null check (length(fcm_token) between 20 and 4096),
  role text not null check (role in ('admin', 'client')),
  platform text not null check (platform in ('android', 'ios')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id, installation_id),
  unique (fcm_token)
);

create index if not exists push_tokens_role_idx
on public.push_tokens (role);

drop trigger if exists push_tokens_touch_updated_at on public.push_tokens;
create trigger push_tokens_touch_updated_at
before update on public.push_tokens
for each row execute procedure public.touch_updated_at();

create table if not exists public.push_notification_dispatches (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  event_key text not null check (length(event_key) between 3 and 100),
  sent_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  unique (order_id, event_key)
);

create or replace function public.register_push_token(
  p_installation_id text,
  p_fcm_token text,
  p_role text,
  p_platform text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  caller_id uuid := auth.uid();
begin
  if caller_id is null then
    raise exception 'A signed-in session is required.' using errcode = '42501';
  end if;
  if length(trim(coalesce(p_installation_id, ''))) not between 16 and 200
     or length(trim(coalesce(p_fcm_token, ''))) not between 20 and 4096 then
    raise exception 'Invalid push token registration.' using errcode = '22023';
  end if;
  if p_platform not in ('android', 'ios') then
    raise exception 'Invalid push platform.' using errcode = '22023';
  end if;
  if p_role not in ('admin', 'client')
     or (p_role = 'admin' and not public.is_admin()) then
    raise exception 'Invalid push notification role.' using errcode = '42501';
  end if;

  delete from public.push_tokens
  where fcm_token = trim(p_fcm_token)
     or (user_id = caller_id and installation_id = trim(p_installation_id));

  insert into public.push_tokens (
    user_id, installation_id, fcm_token, role, platform
  ) values (
    caller_id,
    trim(p_installation_id),
    trim(p_fcm_token),
    p_role,
    p_platform
  );
end;
$$;

revoke all on function public.register_push_token(text, text, text, text)
from public, anon;
grant execute on function public.register_push_token(text, text, text, text)
to authenticated;

create or replace function public.unregister_push_token(
  p_installation_id text
)
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  delete from public.push_tokens
  where user_id = (select auth.uid())
    and installation_id = trim(p_installation_id);
$$;

revoke all on function public.unregister_push_token(text) from public, anon;
grant execute on function public.unregister_push_token(text) to authenticated;

alter table public.push_tokens enable row level security;
alter table public.push_notification_dispatches enable row level security;

revoke all on table public.push_tokens from anon, authenticated;
revoke all on table public.push_notification_dispatches from anon, authenticated;
