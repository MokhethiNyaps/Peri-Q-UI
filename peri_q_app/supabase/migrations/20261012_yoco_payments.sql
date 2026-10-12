-- Yoco Online Payments extension — additive, idempotent, safe to rerun.
-- Adds separate payment_status (independent of fulfilment status), Yoco checkout linkage,
-- payments audit table, and webhook idempotency table. Preserves existing cash/eft.
-- Backup production before applying. Run in Supabase SQL editor.

-- 1) Extend orders with Yoco/payment tracking (all nullable/defaults for backward compatibility)
alter table public.orders
  add column if not exists yoco_checkout_id text,
  add column if not exists payment_status text not null default 'unpaid'
    check (payment_status in ('unpaid','pending','paid','failed','cancelled','expired','refunded')),
  add column if not exists paid_at timestamptz,
  add column if not exists payment_amount_cents integer check (payment_amount_cents is null or payment_amount_cents >= 0),
  add column if not exists yoco_payment_id text,
  add column if not exists yoco_mode text check (yoco_mode is null or yoco_mode in ('test','live'));

-- Relax payment_method check to include yoco (online card via Yoco Checkout)
alter table public.orders drop constraint if exists orders_payment_method_check;
alter table public.orders
  add constraint orders_payment_method_check
  check (payment_method in ('cash_collection','cash_delivery','eft','card','yoco'));

-- Unique constraint for Yoco checkout (one active checkout per order)
do $$ begin
  if not exists (select 1 from pg_indexes where indexname = 'orders_yoco_checkout_id_idx') then
    create unique index orders_yoco_checkout_id_idx on public.orders (yoco_checkout_id) where yoco_checkout_id is not null;
  end if;
end $$;

create index if not exists orders_payment_status_idx on public.orders (payment_status);
create index if not exists orders_paid_at_idx on public.orders (paid_at) where paid_at is not null;

-- 2) Payments audit table — one row per order (or per checkout attempt), stores latest verified state
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders (id) on delete cascade,
  yoco_checkout_id text unique,
  amount_cents integer not null check (amount_cents > 0),
  currency text not null default 'ZAR' check (currency = 'ZAR'),
  status text not null check (status in ('pending','succeeded','failed','cancelled','expired')),
  yoco_payment_id text,
  webhook_event_id text unique,
  raw_payload jsonb,
  mode text check (mode in ('test','live')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- Indexes for admin reconciliation
create index if not exists payments_order_id_idx on public.payments (order_id);
create index if not exists payments_yoco_checkout_id_idx on public.payments (yoco_checkout_id) where yoco_checkout_id is not null;
create index if not exists payments_status_idx on public.payments (status);
create index if not exists payments_created_at_idx on public.payments (created_at desc);

drop trigger if exists payments_touch_updated_at on public.payments;
create trigger payments_touch_updated_at
before update on public.payments
for each row execute procedure public.touch_updated_at();

-- 3) Webhook idempotency table — prevents duplicate processing (Yoco retries 8x over ~25h)
create table if not exists public.yoco_webhook_events (
  id text primary key, -- Yoco event id (e.g., evt_xxxx)
  type text not null check (type in ('payment.succeeded','payment.failed','refund.succeeded','checkout.expired','checkout.cancelled')),
  payload jsonb not null,
  order_id uuid references public.orders (id) on delete set null,
  yoco_checkout_id text,
  processed boolean not null default false,
  processed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists yoco_webhook_events_type_idx on public.yoco_webhook_events (type);
create index if not exists yoco_webhook_events_order_id_idx on public.yoco_webhook_events (order_id) where order_id is not null;
create index if not exists yoco_webhook_events_created_at_idx on public.yoco_webhook_events (created_at desc);

-- 4) RLS — payments and webhook events are service-role / admin only for writes; owners can read own payments
alter table public.payments enable row level security;
alter table public.yoco_webhook_events enable row level security;

revoke all on table public.payments from anon, authenticated;
revoke all on table public.yoco_webhook_events from anon, authenticated;

drop policy if exists "payments_admin_all" on public.payments;
create policy "payments_admin_all"
on public.payments
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "payments_owner_read" on public.payments;
create policy "payments_owner_read"
on public.payments
for select
to authenticated
using (
  exists (
    select 1 from public.orders
    where orders.id = payments.order_id
      and orders.user_id = (select auth.uid())
  )
);

-- webhook events: no direct client access; only service_role (bypasses RLS) and admin via dashboard
drop policy if exists "yoco_webhook_admin_read" on public.yoco_webhook_events;
create policy "yoco_webhook_admin_read"
on public.yoco_webhook_events
for select
to authenticated
using (public.is_admin());

-- 5) Update place_order to accept yoco/card as valid online payment method
create or replace function public.place_order(
  p_customer_name text,
  p_customer_phone text,
  p_order_type text,
  p_payment_method text,
  p_delivery_address text,
  p_expected_total numeric,
  p_client_request_id text,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  settings public.app_settings%rowtype;
  existing_order_id uuid;
  created_order_id uuid;
  item_json jsonb;
  menu_row public.menu_items%rowtype;
  requested_add_on jsonb;
  trusted_add_on jsonb;
  trusted_add_ons jsonb;
  add_on_total numeric;
  trusted_total numeric := 0;
  item_quantity integer;
  calculated_estimate integer := 0;
  local_time time;
  opening_value time;
  closing_value time;
  is_within_hours boolean;
begin
  if auth.uid() is null then
    raise exception 'A signed-in session is required.' using errcode = '42501';
  end if;
  if length(trim(p_customer_name)) not between 2 and 100 then
    raise exception 'Invalid customer name.' using errcode = '22023';
  end if;
  if length(trim(p_customer_phone)) not between 7 and 30 then
    raise exception 'Invalid customer phone.' using errcode = '22023';
  end if;
  if length(coalesce(p_client_request_id, '')) not between 8 and 200 then
    raise exception 'Invalid order request identifier.' using errcode = '22023';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) not between 1 and 50 then
    raise exception 'An order must contain between 1 and 50 items.' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtext(auth.uid()::text || p_client_request_id));
  select id into existing_order_id
  from public.orders
  where user_id = auth.uid() and client_request_id = p_client_request_id;
  if existing_order_id is not null then
    return jsonb_build_object('id', existing_order_id);
  end if;

  select * into settings from public.app_settings where id = 'default';
  if settings.id is null or not settings.store_open then
    raise exception 'Ordering is paused.' using errcode = 'P0001';
  end if;
  local_time := timezone('Africa/Johannesburg', now())::time;
  opening_value := settings.opening_time::time;
  closing_value := settings.closing_time::time;
  is_within_hours := case
    when opening_value = closing_value then true
    when opening_value < closing_value then local_time >= opening_value and local_time < closing_value
    else local_time >= opening_value or local_time < closing_value
  end;
  if not is_within_hours then
    raise exception 'Store is closed.' using errcode = 'P0001';
  end if;
  if p_order_type = 'pickup' and not settings.pickup_available then
    raise exception 'Pickup is unavailable.' using errcode = 'P0001';
  elsif p_order_type = 'delivery' and not settings.delivery_available then
    raise exception 'Delivery is unavailable.' using errcode = 'P0001';
  elsif p_order_type not in ('pickup', 'delivery') then
    raise exception 'Invalid order type.' using errcode = '22023';
  end if;
  if p_order_type = 'delivery' and length(trim(coalesce(p_delivery_address, ''))) < 8 then
    raise exception 'A delivery address is required.' using errcode = '22023';
  end if;
  -- Allow cash/eft plus yoco/card for online card payments; validate pickup vs delivery compatibility
  if p_payment_method not in ('cash_collection', 'cash_delivery', 'eft', 'yoco', 'card')
     or (p_order_type = 'pickup' and p_payment_method = 'cash_delivery') then
    raise exception 'Invalid payment method.' using errcode = '22023';
  end if;

  insert into public.orders (
    user_id, customer_name, customer_phone, order_type, payment_method,
    total_price, status, estimated_minutes, delivery_address, client_request_id,
    payment_status
  ) values (
    auth.uid(), trim(p_customer_name), trim(p_customer_phone), p_order_type,
    p_payment_method, 0, 'pending', 0,
    case when p_order_type = 'delivery' then trim(p_delivery_address) else null end,
    p_client_request_id,
    case when p_payment_method in ('yoco','card') then 'pending' else 'unpaid' end
  ) returning id into created_order_id;

  for item_json in select value from jsonb_array_elements(p_items)
  loop
    item_quantity := (item_json ->> 'quantity')::integer;
    if item_quantity not between 1 and 50 then
      raise exception 'Invalid item quantity.' using errcode = '22023';
    end if;
    select * into menu_row
    from public.menu_items
    where id = item_json ->> 'menu_item_id'
    for share;
    if menu_row.id is null then
      raise exception 'Menu item not found.' using errcode = 'P0001';
    end if;
    if not menu_row.is_available then
      raise exception 'Menu item is unavailable.' using errcode = 'P0001';
    end if;
    if item_json ->> 'spice_level' is not null
       and not ((item_json ->> 'spice_level') = any(menu_row.spice_levels)) then
      raise exception 'Invalid spice selection.' using errcode = '22023';
    end if;
    if length(coalesce(item_json ->> 'notes', '')) > 500 then
      raise exception 'Item notes are too long.' using errcode = '22023';
    end if;

    trusted_add_ons := '[]'::jsonb;
    add_on_total := 0;
    for requested_add_on in
      select value from jsonb_array_elements(coalesce(item_json -> 'selected_add_ons', '[]'::jsonb))
    loop
      trusted_add_on := null;
      select value into trusted_add_on
      from jsonb_array_elements(menu_row.add_ons)
      where value ->> 'name' = requested_add_on ->> 'name'
      limit 1;
      if trusted_add_on is null then
        raise exception 'Invalid add-on selection.' using errcode = '22023';
      end if;
      trusted_add_ons := trusted_add_ons || jsonb_build_array(trusted_add_on);
      add_on_total := add_on_total + coalesce((trusted_add_on ->> 'price')::numeric, 0);
    end loop;

    trusted_total := trusted_total + ((menu_row.price + add_on_total) * item_quantity);
    calculated_estimate := greatest(calculated_estimate, menu_row.prep_minutes);
    insert into public.order_items (
      order_id, menu_item_id, item_name, item_description, item_image_path,
      item_category, unit_price, quantity, spice_level, notes, selected_add_ons
    ) values (
      created_order_id, menu_row.id, menu_row.name, menu_row.description,
      menu_row.image_path, menu_row.category, menu_row.price, item_quantity,
      item_json ->> 'spice_level', left(coalesce(item_json ->> 'notes', ''), 500),
      trusted_add_ons
    );
  end loop;

  if p_order_type = 'delivery' then
    trusted_total := trusted_total + settings.delivery_fee;
    calculated_estimate := calculated_estimate + 20;
  end if;
  if abs(trusted_total - p_expected_total) > 0.009 then
    raise exception 'Price changed before checkout.' using errcode = 'P0001';
  end if;

  update public.orders
  set total_price = trusted_total,
      estimated_minutes = greatest(calculated_estimate, 5),
      payment_amount_cents = (trusted_total * 100)::integer
  where id = created_order_id;
  return jsonb_build_object('id', created_order_id);
end;
$$;

revoke all on function public.place_order(text, text, text, text, text, numeric, text, jsonb) from public, anon;
grant execute on function public.place_order(text, text, text, text, text, numeric, text, jsonb) to authenticated;

-- 6) Enable realtime for new tables if not already
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='payments') then
    alter publication supabase_realtime add table public.payments;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='yoco_webhook_events') then
    alter publication supabase_realtime add table public.yoco_webhook_events;
  end if;
end $$;

-- 7) Backfill: existing cash/eft orders keep payment_status 'unpaid'; yoco/card legacy set to pending/paid logic left to webhook
