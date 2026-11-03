create extension if not exists pgcrypto;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text,
  phone text,
  role text not null default 'customer' check (role in ('customer', 'admin')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute procedure public.touch_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
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

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and role = 'admin'
  );
$$;

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

create table if not exists public.app_settings (
  id text primary key,
  store_open boolean not null default true,
  pickup_available boolean not null default true,
  delivery_available boolean not null default true,
  delivery_fee numeric(10, 2) not null default 30 check (delivery_fee >= 0),
  opening_time text not null default '10:00',
  closing_time text not null default '21:00',
  todays_special_enabled boolean not null default true,
  todays_special_label text not null default 'TODAY''S SPECIAL',
  todays_special_title text not null default 'Chicken, Pork & Wors Plate',
  todays_special_subtitle text not null default 'R70 - Flame-grilled meats served with pap',
  todays_special_image_path text not null default 'assets/images/white-app-icon.png',
  todays_special_menu_item_id text default 'combo-chicken-pork-wors',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.app_settings
  add column if not exists opening_time text not null default '10:00',
  add column if not exists pickup_available boolean not null default true,
  add column if not exists delivery_available boolean not null default true,
  add column if not exists delivery_fee numeric(10, 2) not null default 30,
  add column if not exists closing_time text not null default '21:00',
  add column if not exists todays_special_enabled boolean not null default true,
  add column if not exists todays_special_label text not null default 'TODAY''S SPECIAL',
  add column if not exists todays_special_title text not null default 'Chicken, Pork & Wors Plate',
  add column if not exists todays_special_subtitle text not null default 'R70 - Flame-grilled meats served with pap',
  add column if not exists todays_special_image_path text not null default 'assets/images/white-app-icon.png',
  add column if not exists todays_special_menu_item_id text default 'combo-chicken-pork-wors';

drop trigger if exists app_settings_touch_updated_at on public.app_settings;
create trigger app_settings_touch_updated_at
before update on public.app_settings
for each row execute procedure public.touch_updated_at();

insert into public.app_settings (id, store_open)
values ('default', true)
on conflict (id) do nothing;

update public.app_settings
set
  todays_special_title = 'Chicken, Pork & Wors Plate',
  todays_special_subtitle = 'R70 - Flame-grilled meats served with pap',
  todays_special_image_path = 'assets/images/white-app-icon.png',
  todays_special_menu_item_id = 'combo-chicken-pork-wors'
where id = 'default'
  and (
    todays_special_menu_item_id is null
    or todays_special_menu_item_id = 'kota-1'
    or todays_special_image_path = 'assets/images/chicken_kota.png'
  );

create table if not exists public.menu_categories (
  id text primary key,
  name text not null unique,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

drop trigger if exists menu_categories_touch_updated_at on public.menu_categories;
create trigger menu_categories_touch_updated_at
before update on public.menu_categories
for each row execute procedure public.touch_updated_at();

insert into public.menu_categories (id, name, sort_order)
values
  ('cat-combo-plates', 'Combo Plates', 10),
  ('cat-wors-meals', 'Wors Meals', 20),
  ('cat-pork-meals', 'Pork Meals', 30),
  ('cat-chicken-meals', 'Chicken Meals', 40),
  ('cat-liver-meals', 'Liver Meals', 50),
  ('cat-family-meals', 'Family Meals', 60),
  ('cat-build-your-own-meal', 'Build Your Own Meal', 70),
  ('cat-sides', 'Sides', 80),
  ('cat-sauces', 'Sauces', 90),
  ('cat-cold-drinks', 'Cold Drinks', 100)
on conflict (id) do update
  set
    name = excluded.name,
    sort_order = excluded.sort_order,
    is_active = true;

update public.menu_categories
set is_active = false
where id in ('cat-kotas', 'cat-chicken', 'cat-grills', 'cat-drinks');

create table if not exists public.menu_items (
  id text primary key,
  name text not null,
  description text not null,
  price numeric(10, 2) not null,
  category text not null,
  image_path text not null,
  is_available boolean not null default true,
  prep_minutes integer not null default 25,
  spice_levels text[] not null default array['Mild', 'Medium', 'Hot', 'Extra Hot'],
  add_ons jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

drop trigger if exists menu_items_touch_updated_at on public.menu_items;
create trigger menu_items_touch_updated_at
before update on public.menu_items
for each row execute procedure public.touch_updated_at();

insert into public.menu_items (
  id,
  name,
  description,
  price,
  category,
  image_path,
  is_available,
  prep_minutes,
  spice_levels
)
values
  (
    'combo-chicken-pork-wors',
    'Chicken, Pork & Wors Plate',
    'Flame-grilled chicken, juicy pork and traditional wors served with pap.',
    70,
    'Combo Plates',
    'assets/images/white-app-icon.png',
    true,
    25,
    array['Mild', 'Medium', 'Hot', 'Extra Hot']
  ),
  (
    'combo-chicken-wors-liver',
    'Chicken, Wors & Liver Plate',
    'Grilled chicken, wors and tender liver served with pap.',
    70,
    'Combo Plates',
    'assets/images/white-app-icon.png',
    true,
    25,
    array['Mild', 'Medium', 'Hot', 'Extra Hot']
  ),
  (
    'combo-beef-wors',
    'Beef & Wors Plate',
    'Tender beef and traditional wors served with pap.',
    60,
    'Combo Plates',
    'assets/images/white-app-icon.png',
    true,
    25,
    array['Mild', 'Medium', 'Hot', 'Extra Hot']
  ),
  (
    'combo-pork-beef-wors',
    'Pork, Beef & Wors Plate',
    'A hearty combination of pork, beef and wors served with pap.',
    60,
    'Combo Plates',
    'assets/images/white-app-icon.png',
    true,
    25,
    array['Mild', 'Medium', 'Hot', 'Extra Hot']
  ),
  (
    'combo-choice-meat-liver-wors',
    'Pork, Beef or Chicken, Liver & Wors Plate',
    'Choice of pork, beef or chicken served with liver and wors, accompanied by pap.',
    80,
    'Combo Plates',
    'assets/images/white-app-icon.png',
    true,
    25,
    array['Mild', 'Medium', 'Hot', 'Extra Hot']
  ),
  (
    'pork-plate',
    'Pork Plate',
    'Grilled pork served with pap.',
    40,
    'Pork Meals',
    'assets/images/white-app-icon.png',
    true,
    20,
    array['Mild', 'Medium', 'Hot', 'Extra Hot']
  ),
  (
    'pork-wors-plate',
    'Pork & Wors Plate',
    'Tender pork and traditional wors served with pap.',
    50,
    'Pork Meals',
    'assets/images/white-app-icon.png',
    true,
    20,
    array['Mild', 'Medium', 'Hot', 'Extra Hot']
  ),
  (
    'chicken-wors-pap-salad',
    'Chicken, Wors, Pap & Salad',
    'Grilled chicken and wors served with pap and fresh salad.',
    50,
    'Chicken Meals',
    'assets/images/white-app-icon.png',
    true,
    20,
    array['Mild', 'Medium', 'Hot', 'Extra Hot']
  ),
  (
    'liver-pap-salad',
    'Liver with Pap & Salad',
    'Tender liver served with pap and fresh salad.',
    50,
    'Liver Meals',
    'assets/images/white-app-icon.png',
    true,
    20,
    array['Mild', 'Medium', 'Hot', 'Extra Hot']
  ),
  (
    'liver-plate',
    'Liver Plate',
    'Traditional liver meal served with pap.',
    40,
    'Liver Meals',
    'assets/images/white-app-icon.png',
    true,
    20,
    array['Mild', 'Medium', 'Hot', 'Extra Hot']
  ),
  (
    'wors-plate',
    'Wors Plate',
    'Traditional South African wors served with pap.',
    50,
    'Wors Meals',
    'assets/images/white-app-icon.png',
    true,
    20,
    array['Mild', 'Medium', 'Hot', 'Extra Hot']
  ),
  (
    'family-meal-for-5',
    'Meal for 5',
    'Assorted grilled meats served with generous portions of pap. Perfect for sharing with family and friends.',
    350,
    'Family Meals',
    'assets/images/white-app-icon.png',
    true,
    35,
    array['Mild', 'Medium', 'Hot', 'Extra Hot']
  ),
  (
    'build-any-meat-choice',
    'Any Meat of Your Choice',
    'From R60. Choose your preferred meat served with pap.',
    60,
    'Build Your Own Meal',
    'assets/images/white-app-icon.png',
    true,
    25,
    array['Mild', 'Medium', 'Hot', 'Extra Hot']
  ),
  (
    'side-extra-pap',
    'Extra Pap',
    'Additional serving of freshly prepared pap.',
    10,
    'Sides',
    'assets/images/white-app-icon.png',
    true,
    10,
    array['Regular']
  ),
  (
    'side-extra-salad',
    'Extra Salad',
    'Fresh mixed salad.',
    10,
    'Sides',
    'assets/images/white-app-icon.png',
    true,
    10,
    array['Regular']
  ),
  (
    'sauce-bbq',
    'BBQ Sauce',
    'Sweet and smoky barbecue sauce.',
    0,
    'Sauces',
    'assets/images/white-app-icon.png',
    true,
    2,
    array['Regular']
  ),
  (
    'sauce-mix',
    'Mix Sauce',
    'Signature mixed sauce packed with flavour.',
    0,
    'Sauces',
    'assets/images/white-app-icon.png',
    true,
    2,
    array['Regular']
  ),
  (
    'sauce-lemon-herb',
    'Lemon & Herb Sauce',
    'Light and zesty lemon herb sauce.',
    0,
    'Sauces',
    'assets/images/white-app-icon.png',
    true,
    2,
    array['Regular']
  ),
  (
    'sauce-peri-peri',
    'Peri-Peri Sauce',
    'Hot and spicy peri-peri sauce.',
    0,
    'Sauces',
    'assets/images/white-app-icon.png',
    true,
    2,
    array['Regular']
  ),
  (
    'drink-coca-cola-330ml',
    'Coca-Cola 330ml',
    'Chilled 330ml can of Coca-Cola.',
    15,
    'Cold Drinks',
    'assets/images/white-app-icon.png',
    true,
    5,
    array['Regular']
  ),
  (
    'drink-coca-cola-no-sugar-330ml',
    'Coca-Cola No Sugar 330ml',
    'Chilled 330ml can of Coca-Cola No Sugar.',
    15,
    'Cold Drinks',
    'assets/images/white-app-icon.png',
    true,
    5,
    array['Regular']
  ),
  (
    'drink-fanta-orange-330ml',
    'Fanta Orange 330ml',
    'Chilled 330ml can of Fanta Orange.',
    15,
    'Cold Drinks',
    'assets/images/white-app-icon.png',
    true,
    5,
    array['Regular']
  ),
  (
    'drink-sprite-330ml',
    'Sprite 330ml',
    'Chilled 330ml can of Sprite.',
    15,
    'Cold Drinks',
    'assets/images/white-app-icon.png',
    true,
    5,
    array['Regular']
  ),
  (
    'drink-stoney-ginger-beer-330ml',
    'Stoney Ginger Beer 330ml',
    'Chilled 330ml can of Stoney Ginger Beer.',
    15,
    'Cold Drinks',
    'assets/images/white-app-icon.png',
    true,
    5,
    array['Regular']
  ),
  (
    'drink-creme-soda-330ml',
    'Creme Soda 330ml',
    'Chilled 330ml can of Creme Soda.',
    15,
    'Cold Drinks',
    'assets/images/white-app-icon.png',
    true,
    5,
    array['Regular']
  ),
  (
    'drink-sparletta-pine-nut-330ml',
    'Sparletta Pine Nut 330ml',
    'Chilled 330ml can of Sparletta Pine Nut.',
    15,
    'Cold Drinks',
    'assets/images/white-app-icon.png',
    true,
    5,
    array['Regular']
  ),
  (
    'drink-sparletta-cream-soda-330ml',
    'Sparletta Cream Soda 330ml',
    'Chilled 330ml can of Sparletta Cream Soda.',
    15,
    'Cold Drinks',
    'assets/images/white-app-icon.png',
    true,
    5,
    array['Regular']
  ),
  (
    'drink-bonaqua-still-water-500ml',
    'Bonaqua Still Water 500ml',
    'Chilled 500ml bottle of Bonaqua still water.',
    12,
    'Cold Drinks',
    'assets/images/white-app-icon.png',
    true,
    5,
    array['Regular']
  ),
  (
    'drink-bonaqua-sparkling-water-500ml',
    'Bonaqua Sparkling Water 500ml',
    'Chilled 500ml bottle of Bonaqua sparkling water.',
    12,
    'Cold Drinks',
    'assets/images/white-app-icon.png',
    true,
    5,
    array['Regular']
  ),
  (
    'drink-appletiser-330ml',
    'Appletiser 330ml',
    'Chilled 330ml can of Appletiser.',
    20,
    'Cold Drinks',
    'assets/images/white-app-icon.png',
    true,
    5,
    array['Regular']
  ),
  (
    'drink-grapetiser-red-330ml',
    'Grapetiser Red 330ml',
    'Chilled 330ml can of Grapetiser Red.',
    20,
    'Cold Drinks',
    'assets/images/white-app-icon.png',
    true,
    5,
    array['Regular']
  )
on conflict (id) do update
  set
    name = excluded.name,
    description = excluded.description,
    price = excluded.price,
    category = excluded.category,
    image_path = excluded.image_path,
    is_available = excluded.is_available,
    prep_minutes = excluded.prep_minutes,
    spice_levels = excluded.spice_levels;

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number bigint generated by default as identity unique,
  user_id uuid not null references auth.users (id) on delete cascade,
  customer_name text not null,
  customer_phone text not null,
  order_type text not null check (order_type in ('pickup', 'delivery')),
  payment_method text not null check (
    payment_method in ('cash_collection', 'cash_delivery', 'eft', 'card', 'yoco')
  ),
  total_price numeric(10, 2) not null,
  status text not null default 'pending' check (
    status in ('pending', 'preparing', 'ready', 'completed', 'cancelled')
  ),
  estimated_minutes integer not null,
  delivery_address text,
  client_request_id text not null,
  payment_proof_path text,
  yoco_checkout_id text,
  payment_status text not null default 'unpaid' check (payment_status in ('unpaid','pending','paid','failed','cancelled','expired','refunded')),
  paid_at timestamptz,
  payment_amount_cents integer check (payment_amount_cents is null or payment_amount_cents >= 0),
  yoco_payment_id text,
  yoco_mode text check (yoco_mode is null or yoco_mode in ('test','live')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.orders
  add column if not exists client_request_id text,
  add column if not exists payment_proof_path text,
  add column if not exists yoco_checkout_id text,
  add column if not exists payment_status text,
  add column if not exists paid_at timestamptz,
  add column if not exists payment_amount_cents integer,
  add column if not exists yoco_payment_id text,
  add column if not exists yoco_mode text;

update public.orders
set client_request_id = 'legacy-' || id::text
where client_request_id is null;

alter table public.orders alter column client_request_id set not null;

create unique index if not exists orders_user_client_request_idx
on public.orders (user_id, client_request_id);

drop trigger if exists orders_touch_updated_at on public.orders;
create trigger orders_touch_updated_at
before update on public.orders
for each row execute procedure public.touch_updated_at();

create index if not exists orders_user_id_created_at_idx
on public.orders (user_id, created_at desc);

-- Yoco extension indexes (idempotent)
do $$ begin
  if not exists (select 1 from pg_indexes where indexname = 'orders_yoco_checkout_id_idx') then
    create unique index orders_yoco_checkout_id_idx on public.orders (yoco_checkout_id) where yoco_checkout_id is not null;
  end if;
end $$;
create index if not exists orders_payment_status_idx on public.orders (payment_status);
create index if not exists orders_paid_at_idx on public.orders (paid_at) where paid_at is not null;
alter table public.orders drop constraint if exists orders_payment_method_check;
alter table public.orders
  add constraint orders_payment_method_check
  check (payment_method in ('cash_collection','cash_delivery','eft','card','yoco'));

-- Payments audit + webhook idempotency (shared by website + mobile)
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
create index if not exists payments_order_id_idx on public.payments (order_id);
create index if not exists payments_yoco_checkout_id_idx on public.payments (yoco_checkout_id) where yoco_checkout_id is not null;
create index if not exists payments_status_idx on public.payments (status);
create index if not exists payments_created_at_idx on public.payments (created_at desc);
drop trigger if exists payments_touch_updated_at on public.payments;
create trigger payments_touch_updated_at
before update on public.payments
for each row execute procedure public.touch_updated_at();

create table if not exists public.yoco_webhook_events (
  id text primary key,
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

alter table public.payments enable row level security;
alter table public.yoco_webhook_events enable row level security;
revoke all on table public.payments from anon, authenticated;
revoke all on table public.yoco_webhook_events from anon, authenticated;
grant select on table public.payments, public.yoco_webhook_events to authenticated;
grant select, insert, update on table public.payments, public.yoco_webhook_events to service_role;
drop policy if exists "payments_admin_all" on public.payments;
create policy "payments_admin_all" on public.payments for all to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "payments_owner_read" on public.payments;
create policy "payments_owner_read" on public.payments for select to authenticated using (
  exists (select 1 from public.orders where orders.id = payments.order_id and orders.user_id = (select auth.uid()))
);
drop policy if exists "yoco_webhook_admin_read" on public.yoco_webhook_events;
create policy "yoco_webhook_admin_read" on public.yoco_webhook_events for select to authenticated using (public.is_admin());

do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='payments') then
    alter publication supabase_realtime add table public.payments;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='yoco_webhook_events') then
    alter publication supabase_realtime add table public.yoco_webhook_events;
  end if;
end $$;

-- ensure legacy orders have correct payment_status
update public.orders set payment_status='unpaid' where payment_status is null;
alter table public.orders alter column payment_status set not null;
alter table public.orders alter column payment_status set default 'unpaid';

create table if not exists public.push_notification_dispatches (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  event_key text not null check (length(event_key) between 3 and 100),
  sent_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  unique (order_id, event_key)
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  menu_item_id text not null,
  item_name text not null,
  item_description text not null,
  item_image_path text not null,
  item_category text not null,
  unit_price numeric(10, 2) not null,
  quantity integer not null,
  spice_level text,
  notes text not null default '',
  selected_add_ons jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists order_items_order_id_idx
on public.order_items (order_id);

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

create or replace function public.attach_payment_proof(
  p_order_id uuid,
  p_storage_path text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null
     or not exists (
       select 1 from public.orders
       where id = p_order_id and user_id = auth.uid() and payment_method = 'eft'
     ) then
    raise exception 'Payment proof is not allowed for this order.' using errcode = '42501';
  end if;
  if p_storage_path not like auth.uid()::text || '/' || p_order_id::text || '/%' then
    raise exception 'Invalid proof path.' using errcode = '22023';
  end if;
  update public.orders set payment_proof_path = p_storage_path where id = p_order_id;
end;
$$;

revoke all on function public.attach_payment_proof(uuid, text) from public, anon;
grant execute on function public.attach_payment_proof(uuid, text) to authenticated;

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
  delete from auth.users where id = caller_id;
end;
$$;

revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;

create or replace function public.protect_profile_role()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if new.role is distinct from old.role and not public.is_admin() then
    raise exception 'Only an administrator can change account roles.' using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protect_role on public.profiles;
create trigger profiles_protect_role
before update on public.profiles
for each row execute procedure public.protect_profile_role();

create or replace function public.validate_order_status_transition()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if new.status is not distinct from old.status then
    return new;
  end if;
  if not public.is_admin() then
    raise exception 'Only an administrator can update order status.' using errcode = '42501';
  end if;
  if not (
    (old.status = 'pending' and new.status in ('preparing', 'cancelled')) or
    (old.status = 'preparing' and new.status = 'ready') or
    (old.status = 'ready' and new.status = 'completed')
  ) then
    raise exception 'Invalid order status transition.' using errcode = '22023';
  end if;
  return new;
end;
$$;

drop trigger if exists orders_validate_status on public.orders;
create trigger orders_validate_status
before update on public.orders
for each row execute procedure public.validate_order_status_transition();

alter table public.profiles enable row level security;
alter table public.push_tokens enable row level security;
alter table public.push_notification_dispatches enable row level security;
alter table public.app_settings enable row level security;
alter table public.menu_categories enable row level security;
alter table public.menu_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

revoke all on table public.push_tokens from anon, authenticated;
revoke all on table public.push_notification_dispatches from anon, authenticated;

drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin"
on public.profiles
for select
to authenticated
using ((select auth.uid()) = id or public.is_admin());

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles
for insert
to authenticated
with check ((select auth.uid()) = id and role = 'customer');

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id or public.is_admin())
with check ((select auth.uid()) = id or public.is_admin());

drop policy if exists "app_settings_read_all" on public.app_settings;
create policy "app_settings_read_all"
on public.app_settings
for select
to anon, authenticated
using (true);

drop policy if exists "app_settings_admin_write" on public.app_settings;
create policy "app_settings_admin_write"
on public.app_settings
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "app_settings_admin_insert" on public.app_settings;
create policy "app_settings_admin_insert"
on public.app_settings
for insert
to authenticated
with check (public.is_admin());

drop policy if exists "menu_categories_read_all" on public.menu_categories;
create policy "menu_categories_read_all"
on public.menu_categories
for select
to anon, authenticated
using (true);

drop policy if exists "menu_categories_admin_insert" on public.menu_categories;
create policy "menu_categories_admin_insert"
on public.menu_categories
for insert
to authenticated
with check (public.is_admin());

drop policy if exists "menu_categories_admin_update" on public.menu_categories;
create policy "menu_categories_admin_update"
on public.menu_categories
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "menu_categories_admin_delete" on public.menu_categories;
create policy "menu_categories_admin_delete"
on public.menu_categories
for delete
to authenticated
using (public.is_admin());

drop policy if exists "menu_items_read_all" on public.menu_items;
create policy "menu_items_read_all"
on public.menu_items
for select
to anon, authenticated
using (true);

drop policy if exists "menu_items_admin_insert" on public.menu_items;
create policy "menu_items_admin_insert"
on public.menu_items
for insert
to authenticated
with check (public.is_admin());

drop policy if exists "menu_items_admin_update" on public.menu_items;
create policy "menu_items_admin_update"
on public.menu_items
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "menu_items_admin_delete" on public.menu_items;
create policy "menu_items_admin_delete"
on public.menu_items
for delete
to authenticated
using (public.is_admin());

drop policy if exists "orders_select_owner_or_admin" on public.orders;
create policy "orders_select_owner_or_admin"
on public.orders
for select
to authenticated
using (public.is_admin() or (select auth.uid()) = user_id);

drop policy if exists "orders_insert_own" on public.orders;

drop policy if exists "orders_admin_update" on public.orders;
create policy "orders_admin_update"
on public.orders
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "order_items_select_owner_or_admin" on public.order_items;
create policy "order_items_select_owner_or_admin"
on public.order_items
for select
to authenticated
using (
  public.is_admin()
  or exists (
    select 1
    from public.orders
    where orders.id = order_items.order_id
      and orders.user_id = (select auth.uid())
  )
);

drop policy if exists "order_items_insert_owner" on public.order_items;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'menu_categories'
  ) then
    alter publication supabase_realtime add table public.menu_categories;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'menu_items'
  ) then
    alter publication supabase_realtime add table public.menu_items;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'orders'
  ) then
    alter publication supabase_realtime add table public.orders;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'order_items'
  ) then
    alter publication supabase_realtime add table public.order_items;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'app_settings'
  ) then
    alter publication supabase_realtime add table public.app_settings;
  end if;
end;
$$;

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'menu-images',
  'menu-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "menu_images_public_read" on storage.objects;
create policy "menu_images_public_read"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'menu-images');

drop policy if exists "menu_images_admin_insert" on storage.objects;
create policy "menu_images_admin_insert"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'menu-images' and public.is_admin());

drop policy if exists "menu_images_admin_update" on storage.objects;
create policy "menu_images_admin_update"
on storage.objects
for update
to authenticated
using (bucket_id = 'menu-images' and public.is_admin())
with check (bucket_id = 'menu-images' and public.is_admin());

drop policy if exists "menu_images_admin_delete" on storage.objects;
create policy "menu_images_admin_delete"
on storage.objects
for delete
to authenticated
using (bucket_id = 'menu-images' and public.is_admin());

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'payment-proofs',
  'payment-proofs',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
on conflict (id) do update
set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "payment_proofs_owner_insert" on storage.objects;
create policy "payment_proofs_owner_insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'payment-proofs'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "payment_proofs_owner_or_admin_read" on storage.objects;
create policy "payment_proofs_owner_or_admin_read"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'payment-proofs'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.is_admin()
  )
);

drop policy if exists "payment_proofs_owner_delete" on storage.objects;
create policy "payment_proofs_owner_delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'payment-proofs'
  and (storage.foldername(name))[1] = auth.uid()::text
);


-- Checkout drafts never appear in orders or trigger kitchen notifications.
begin;
create table if not exists public.checkout_intents (like public.orders including defaults);
alter table public.checkout_intents alter column order_number drop not null;
alter table public.checkout_intents add primary key (id);
alter table public.checkout_intents add foreign key(user_id) references auth.users(id) on delete cascade;
alter table public.checkout_intents add column redirect_url text;
create unique index if not exists checkout_intents_request on public.checkout_intents(user_id,client_request_id);
create unique index if not exists checkout_intents_yoco on public.checkout_intents(yoco_checkout_id);
create table if not exists public.checkout_intent_items (like public.order_items including defaults);
alter table public.checkout_intent_items add primary key(id);
alter table public.checkout_intent_items add foreign key(order_id) references public.checkout_intents(id) on delete cascade;
alter table public.checkout_intents enable row level security;
alter table public.checkout_intent_items enable row level security;
revoke all on public.checkout_intents, public.checkout_intent_items from anon, authenticated;
grant select on public.checkout_intents to authenticated;
create policy checkout_owner on public.checkout_intents for select to authenticated using(user_id=auth.uid());
grant all on public.checkout_intents,public.checkout_intent_items to service_role;
create or replace function public.prepare_card_checkout(
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
  existing_draft public.checkout_intents%rowtype;
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
  if p_payment_method is distinct from 'yoco' then raise exception 'Only Yoco card payments are accepted.'; end if;
  if p_customer_name is null or p_customer_phone is null or p_expected_total is null or p_items is null or p_order_type is null then raise exception 'Missing checkout details.'; end if;
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
  select * into existing_draft
  from public.checkout_intents
  where user_id = auth.uid() and client_request_id = p_client_request_id;

  -- A retried request may only reuse its draft while the request is unchanged.
  -- Reusing an identifier after the cart, fulfilment or total changed would
  -- return the earlier draft and charge its amount instead of the current one.
  if existing_draft.id is not null then
    if existing_draft.order_type is distinct from p_order_type
       or existing_draft.total_price is distinct from p_expected_total
       or coalesce(existing_draft.delivery_address, '') is distinct from
          coalesce(
            case when p_order_type = 'delivery' then trim(p_delivery_address) else null end,
            ''
          )
    then
      raise exception 'Checkout details changed. Please restart checkout.' using errcode = 'P0001';
    end if;
    return jsonb_build_object('id', existing_draft.id);
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
  if p_payment_method is distinct from 'yoco' then
    raise exception 'Invalid payment method.' using errcode = '22023';
  end if;

  insert into public.checkout_intents (
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
    insert into public.checkout_intent_items (
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

  update public.checkout_intents
  set total_price = trusted_total,
      estimated_minutes = greatest(calculated_estimate, 5),
      payment_amount_cents = (trusted_total * 100)::integer
  where id = created_order_id;
  return jsonb_build_object('id', created_order_id);
end;
$$;

revoke all on function public.prepare_card_checkout(text, text, text, text, text, numeric, text, jsonb) from public, anon;
grant execute on function public.prepare_card_checkout(text, text, text, text, text, numeric, text, jsonb) to authenticated;


-- Disable the old unpaid-order RPC, including stale versions of both clients.
create or replace function public.place_order(p_customer_name text,p_customer_phone text,p_order_type text,p_payment_method text,p_delivery_address text,p_expected_total numeric,p_client_request_id text,p_items jsonb)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
begin raise exception 'Pay by card through Yoco checkout before placing an order.'; end $$;

create or replace function public.require_verified_card_order() returns trigger
language plpgsql set search_path=public,pg_temp as $$
begin
 if TG_OP='INSERT' then
   if auth.role() is distinct from 'service_role' or new.payment_method is distinct from 'yoco' or new.payment_status is distinct from 'paid' or new.paid_at is null or new.yoco_payment_id is null then
     raise exception 'A verified Yoco card payment is required.';
   end if;
 elsif new.status is distinct from old.status and new.status in ('confirmed','preparing','ready','out_for_delivery','completed') and old.payment_method in ('card','yoco') and new.payment_status <> 'paid' then
   raise exception 'An unpaid card order cannot enter fulfilment.';
 end if;
 return new;
end $$;
create trigger require_verified_card_order before insert or update on public.orders for each row execute function public.require_verified_card_order();

create or replace function public.finalize_card_checkout(p_checkout_id text,p_payment_id text,p_amount integer,p_mode text)
returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare draft public.checkout_intents%rowtype; result uuid; cols text;
begin
 select * into draft from public.checkout_intents where yoco_checkout_id=p_checkout_id for update;
 if draft.id is null then raise exception 'Checkout is not linked yet'; end if;
 if draft.payment_amount_cents is distinct from p_amount or draft.yoco_mode is distinct from p_mode or draft.payment_method <> 'yoco' or nullif(p_payment_id,'') is null then raise exception 'Payment mismatch'; end if;
 select id into result from public.orders where id=draft.id;
 if result is not null then return result; end if;
 update public.checkout_intents set payment_status='paid',paid_at=now(),yoco_payment_id=p_payment_id where id=draft.id;
 select string_agg(quote_ident(column_name),',' order by ordinal_position) into cols from information_schema.columns where table_schema='public' and table_name='orders' and column_name <> 'order_number';
 execute format('insert into public.orders (%s) select %s from public.checkout_intents where id=$1',cols,cols) using draft.id;
 insert into public.order_items select * from public.checkout_intent_items where order_id=draft.id;
 return draft.id;
end $$;
revoke all on function public.finalize_card_checkout(text,text,integer,text) from public,anon,authenticated;
grant execute on function public.finalize_card_checkout(text,text,integer,text) to service_role;
commit;


-- Stage 5 (migrations/20261103120000_yoco_refunds_and_rate_limits.sql):
-- refunds, atomic webhook event processing and route rate limits.
begin;

-- 1) Refund tracking -----------------------------------------------------

-- Refunded total per payment. The payment itself stays 'succeeded'; the
-- order becomes 'refunded' only once the full amount has been returned.
alter table public.payments
  add column if not exists refunded_amount_cents integer not null default 0
    check (refunded_amount_cents >= 0);

-- One row per Yoco refund. Kept if the order is later deleted, so the
-- financial record survives (see compliance audit D-H2).
create table if not exists public.payment_refunds (
  id text primary key check (length(id) between 1 and 200),
  order_id uuid references public.orders (id) on delete set null,
  yoco_checkout_id text not null,
  amount_cents integer not null check (amount_cents > 0),
  currency text not null default 'ZAR' check (currency = 'ZAR'),
  mode text not null check (mode in ('test', 'live')),
  webhook_event_id text not null unique,
  created_at timestamptz not null default timezone('utc', now())
);
create index if not exists payment_refunds_order_id_idx
  on public.payment_refunds (order_id) where order_id is not null;

alter table public.payment_refunds enable row level security;
revoke all on table public.payment_refunds from anon, authenticated;
grant select on table public.payment_refunds to authenticated;
grant select, insert on table public.payment_refunds to service_role;

drop policy if exists "payment_refunds_admin_read" on public.payment_refunds;
create policy "payment_refunds_admin_read" on public.payment_refunds
  for select to authenticated using (public.is_admin());
drop policy if exists "payment_refunds_owner_read" on public.payment_refunds;
create policy "payment_refunds_owner_read" on public.payment_refunds
  for select to authenticated using (
    exists (
      select 1 from public.orders
      where orders.id = payment_refunds.order_id
        and orders.user_id = (select auth.uid())
    )
  );

-- What happened to each verified event, for reconciliation by an admin.
alter table public.yoco_webhook_events
  add column if not exists outcome text
    check (outcome is null or outcome in ('processed', 'duplicate', 'unmatched', 'rejected'));

-- 2) Atomic webhook processing ------------------------------------------

-- Records a verified payment.succeeded event in one transaction: the event
-- row, the paid order, the payment record and processed = true either all
-- commit or none do. A retried or concurrent delivery of the same event
-- waits on the event row and then returns 'duplicate'.
create or replace function public.record_card_payment_event(
  p_event_id text,
  p_checkout_id text,
  p_payment_id text,
  p_amount integer,
  p_mode text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  event_row public.yoco_webhook_events%rowtype;
  paid_order public.orders%rowtype;
begin
  if nullif(p_event_id, '') is null or nullif(p_checkout_id, '') is null then
    raise exception 'Missing payment event details.' using errcode = '22023';
  end if;

  insert into public.yoco_webhook_events (id, type, payload, yoco_checkout_id, processed)
  values (
    p_event_id, 'payment.succeeded',
    jsonb_build_object('id', p_event_id, 'type', 'payment.succeeded', 'payload', jsonb_build_object(
      'id', p_payment_id, 'amount', p_amount, 'currency', 'ZAR', 'mode', p_mode,
      'metadata', jsonb_build_object('checkoutId', p_checkout_id))),
    p_checkout_id, false
  )
  on conflict (id) do nothing;

  select * into event_row from public.yoco_webhook_events where id = p_event_id for update;
  if event_row.processed then
    return jsonb_build_object('status', 'duplicate', 'order_id', event_row.order_id);
  end if;

  perform public.finalize_card_checkout(p_checkout_id, p_payment_id, p_amount, p_mode);

  select * into paid_order from public.orders where yoco_checkout_id = p_checkout_id;
  if paid_order.id is null or paid_order.payment_status not in ('paid', 'refunded') then
    raise exception 'Order finalization did not persist a confirmed payment.';
  end if;
  if paid_order.payment_amount_cents is distinct from p_amount
     or paid_order.yoco_mode is distinct from p_mode then
    raise exception 'Payment does not match this order.';
  end if;

  if paid_order.payment_status = 'paid' then
    insert into public.payments (
      order_id, yoco_checkout_id, amount_cents, currency, status,
      yoco_payment_id, webhook_event_id, mode
    ) values (
      paid_order.id, p_checkout_id, p_amount, 'ZAR', 'succeeded',
      p_payment_id, p_event_id, p_mode
    )
    on conflict (order_id) do update
      set yoco_checkout_id = excluded.yoco_checkout_id,
          amount_cents = excluded.amount_cents,
          status = 'succeeded',
          yoco_payment_id = excluded.yoco_payment_id,
          webhook_event_id = excluded.webhook_event_id,
          mode = excluded.mode;
  end if;

  update public.yoco_webhook_events
  set processed = true, processed_at = timezone('utc', now()),
      order_id = paid_order.id, outcome = 'processed'
  where id = p_event_id;

  return jsonb_build_object('status', 'processed', 'order_id', paid_order.id);
end;
$$;

revoke all on function public.record_card_payment_event(text, text, text, integer, text)
  from public, anon, authenticated;
grant execute on function public.record_card_payment_event(text, text, text, integer, text)
  to service_role;

-- Records a verified refund.succeeded event in one transaction. Refunds that
-- cannot be matched to a paid order, or that do not fit it, are kept as
-- 'unmatched' or 'rejected' for manual review instead of being retried.
create or replace function public.record_card_refund(
  p_event_id text,
  p_checkout_id text,
  p_refund_id text,
  p_amount integer,
  p_currency text,
  p_mode text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  event_row public.yoco_webhook_events%rowtype;
  target public.orders%rowtype;
  already_refunded integer;
  refunded_total integer;
  v_outcome text;
begin
  if nullif(p_event_id, '') is null or nullif(p_refund_id, '') is null
     or p_amount is null or p_amount <= 0 then
    raise exception 'Missing refund event details.' using errcode = '22023';
  end if;

  insert into public.yoco_webhook_events (id, type, payload, yoco_checkout_id, processed)
  values (
    p_event_id, 'refund.succeeded',
    jsonb_build_object('id', p_event_id, 'type', 'refund.succeeded', 'payload', jsonb_build_object(
      'id', p_refund_id, 'amount', p_amount, 'currency', p_currency, 'mode', p_mode,
      'metadata', jsonb_build_object('checkoutId', p_checkout_id))),
    nullif(p_checkout_id, ''), false
  )
  on conflict (id) do nothing;

  select * into event_row from public.yoco_webhook_events where id = p_event_id for update;
  if event_row.processed then
    return jsonb_build_object('status', 'duplicate', 'order_id', event_row.order_id);
  end if;

  if nullif(p_checkout_id, '') is not null then
    -- The order lock serialises refunds for the same payment.
    select * into target from public.orders where yoco_checkout_id = p_checkout_id for update;
  end if;

  if target.id is null then
    v_outcome := 'unmatched';
  elsif p_currency is distinct from 'ZAR' or target.yoco_mode is distinct from p_mode
        or target.payment_status not in ('paid', 'refunded') then
    v_outcome := 'rejected';
  elsif exists (select 1 from public.payment_refunds where id = p_refund_id) then
    v_outcome := 'duplicate';
  else
    select coalesce(sum(amount_cents), 0)::integer into already_refunded
    from public.payment_refunds where order_id = target.id;
    refunded_total := already_refunded + p_amount;
    if target.payment_amount_cents is null or refunded_total > target.payment_amount_cents then
      v_outcome := 'rejected';
    else
      insert into public.payment_refunds (
        id, order_id, yoco_checkout_id, amount_cents, currency, mode, webhook_event_id
      ) values (
        p_refund_id, target.id, p_checkout_id, p_amount, 'ZAR', p_mode, p_event_id
      );
      update public.payments
      set refunded_amount_cents = refunded_total
      where order_id = target.id;
      if refunded_total = target.payment_amount_cents then
        update public.orders set payment_status = 'refunded' where id = target.id;
      end if;
      v_outcome := 'processed';
    end if;
  end if;

  update public.yoco_webhook_events
  set processed = true, processed_at = timezone('utc', now()),
      order_id = target.id, outcome = v_outcome
  where id = p_event_id;

  return jsonb_build_object(
    'status', v_outcome,
    'order_id', target.id,
    'refunded_amount_cents', refunded_total
  );
end;
$$;

revoke all on function public.record_card_refund(text, text, text, integer, text, text)
  from public, anon, authenticated;
grant execute on function public.record_card_refund(text, text, text, integer, text, text)
  to service_role;

-- 3) Rate limiting for server routes ------------------------------------

-- Fixed-window counters. Buckets hold a user ID or a keyed hash of the
-- client IP, never a raw IP. Rows older than a day are removed.
create table if not exists public.api_rate_limits (
  bucket text not null check (length(bucket) between 1 and 200),
  window_start timestamptz not null,
  hits integer not null default 0,
  primary key (bucket, window_start)
);
alter table public.api_rate_limits enable row level security;
revoke all on table public.api_rate_limits from anon, authenticated;
grant select, insert, update, delete on table public.api_rate_limits to service_role;

create or replace function public.consume_rate_limit(
  p_bucket text,
  p_limit integer,
  p_window_seconds integer
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  current_window timestamptz;
  current_hits integer;
begin
  if p_limit < 1 or p_window_seconds < 1 then
    raise exception 'Invalid rate limit.' using errcode = '22023';
  end if;
  current_window := to_timestamp(
    floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds
  );
  insert into public.api_rate_limits as l (bucket, window_start, hits)
  values (p_bucket, current_window, 1)
  on conflict (bucket, window_start) do update set hits = l.hits + 1
  returning hits into current_hits;
  -- Occasional cleanup keeps the table small without a scheduled job.
  if random() < 0.01 then
    delete from public.api_rate_limits
    where window_start < timezone('utc', now()) - interval '1 day';
  end if;
  return current_hits <= p_limit;
end;
$$;

revoke all on function public.consume_rate_limit(text, integer, integer)
  from public, anon, authenticated;
grant execute on function public.consume_rate_limit(text, integer, integer)
  to service_role;

commit;


-- Stage 2 (migrations/20261103160000_consent_and_privacy_requests.sql):
-- policy acceptances and privacy-rights requests.
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


-- Stage 6 (migrations/20261103180000_database_security.sql):
-- least-privilege grants, admin column limits and the admin audit log.
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


-- Stage 3 (migrations/20261103210000_account_data_retention.sql):
-- account deletion keeps anonymised orders; retention settings and clean-up.
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
