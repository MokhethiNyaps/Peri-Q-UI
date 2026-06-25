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

create table if not exists public.app_settings (
  id text primary key,
  store_open boolean not null default true,
  opening_time text not null default '10:00',
  closing_time text not null default '21:00',
  todays_special_enabled boolean not null default true,
  todays_special_label text not null default 'TODAY''S SPECIAL',
  todays_special_title text not null default 'Chicken, Pork & Wors Plate',
  todays_special_subtitle text not null default 'R70 - Flame-grilled meats served with pap',
  todays_special_image_path text not null default 'assets/images/brand_mark.png',
  todays_special_menu_item_id text default 'combo-chicken-pork-wors',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.app_settings
  add column if not exists opening_time text not null default '10:00',
  add column if not exists closing_time text not null default '21:00',
  add column if not exists todays_special_enabled boolean not null default true,
  add column if not exists todays_special_label text not null default 'TODAY''S SPECIAL',
  add column if not exists todays_special_title text not null default 'Chicken, Pork & Wors Plate',
  add column if not exists todays_special_subtitle text not null default 'R70 - Flame-grilled meats served with pap',
  add column if not exists todays_special_image_path text not null default 'assets/images/brand_mark.png',
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
  todays_special_image_path = 'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    'assets/images/brand_mark.png',
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
    payment_method in ('cash_collection', 'cash_delivery', 'eft', 'card')
  ),
  total_price numeric(10, 2) not null,
  status text not null default 'pending' check (
    status in ('pending', 'preparing', 'ready', 'completed', 'cancelled')
  ),
  estimated_minutes integer not null,
  delivery_address text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

drop trigger if exists orders_touch_updated_at on public.orders;
create trigger orders_touch_updated_at
before update on public.orders
for each row execute procedure public.touch_updated_at();

create index if not exists orders_user_id_created_at_idx
on public.orders (user_id, created_at desc);

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

alter table public.profiles enable row level security;
alter table public.app_settings enable row level security;
alter table public.menu_categories enable row level security;
alter table public.menu_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

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
with check ((select auth.uid()) = id);

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
create policy "orders_insert_own"
on public.orders
for insert
to authenticated
with check ((select auth.uid()) = user_id);

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
create policy "order_items_insert_owner"
on public.order_items
for insert
to authenticated
with check (
  exists (
    select 1
    from public.orders
    where orders.id = order_items.order_id
      and orders.user_id = (select auth.uid())
  )
);

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

insert into storage.buckets (id, name, public)
values ('menu-images', 'menu-images', true)
on conflict (id) do update
  set public = excluded.public;

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
