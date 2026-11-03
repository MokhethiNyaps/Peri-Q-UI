-- Stage 5: Yoco payment hardening. Additive only: new tables, new columns
-- with defaults, and new functions. Nothing is dropped or narrowed.
-- Apply this before deploying the matching website code.

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
