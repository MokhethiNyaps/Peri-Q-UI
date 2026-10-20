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
