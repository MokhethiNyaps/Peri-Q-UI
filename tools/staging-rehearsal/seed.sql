-- Deterministic fixtures for the rehearsal. Test data only: no customer records.
update public.app_settings
set store_open = true, pickup_available = true, delivery_available = true,
    delivery_fee = 30, opening_time = '00:00', closing_time = '23:59'
where id = 'default';

insert into public.menu_categories (id, name, sort_order) values ('mains', 'Mains', 1)
on conflict (id) do nothing;

insert into public.menu_items (id, name, description, price, category, image_path, is_available, prep_minutes, spice_levels, add_ons)
values
  ('kota-1', 'Chicken Kota', 'Quarter loaf', 45.00, 'mains', 'assets/images/kota.png', true, 20,
   array['Mild','Medium','Hot'], '[{"name":"Cheese","price":5},{"name":"Extra Wors","price":15}]'::jsonb),
  ('off-1', 'Sold Out Plate', 'Unavailable', 60.00, 'mains', 'assets/images/off.png', false, 25,
   array['Mild'], '[]'::jsonb)
on conflict (id) do nothing;

insert into auth.users (id, email, raw_user_meta_data) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.test', '{"full_name":"Alice"}'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.test', '{"full_name":"Bob"}')
on conflict (id) do nothing;
