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
  todays_special_title text not null default 'Flame-Grilled Chicken Kota',
  todays_special_subtitle text not null default 'R65 - Chips, Russian and Sauce included',
  todays_special_image_path text not null default 'assets/images/chicken_kota.png',
  todays_special_menu_item_id text default 'kota-1',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.app_settings
  add column if not exists opening_time text not null default '10:00',
  add column if not exists closing_time text not null default '21:00',
  add column if not exists todays_special_enabled boolean not null default true,
  add column if not exists todays_special_label text not null default 'TODAY''S SPECIAL',
  add column if not exists todays_special_title text not null default 'Flame-Grilled Chicken Kota',
  add column if not exists todays_special_subtitle text not null default 'R65 - Chips, Russian and Sauce included',
  add column if not exists todays_special_image_path text not null default 'assets/images/chicken_kota.png',
  add column if not exists todays_special_menu_item_id text default 'kota-1';

drop trigger if exists app_settings_touch_updated_at on public.app_settings;
create trigger app_settings_touch_updated_at
before update on public.app_settings
for each row execute procedure public.touch_updated_at();

insert into public.app_settings (id, store_open)
values ('default', true)
on conflict (id) do nothing;

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
  ('cat-kotas', 'Kotas', 10),
  ('cat-chicken', 'Chicken', 20),
  ('cat-grills', 'Grills', 30),
  ('cat-sides', 'Sides', 40),
  ('cat-drinks', 'Drinks', 50)
on conflict (id) do nothing;

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
