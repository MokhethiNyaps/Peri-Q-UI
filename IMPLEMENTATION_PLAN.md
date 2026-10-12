# PeriQ Chesanyama — Inspection Report & Implementation Plan

**Date:** 2026-10-12  
**Domain:** rastasperiq.co.za  
**Branch:** arena/aa6bfb2c-peri-q-ui

---

## 1. Phase 1 — Inspection Results (actual codebase, no assumptions)

### Mobile app (`peri_q_app/`)
- **Framework:** Flutter 3.12+ (Dart), Material, `pubspec.yaml` version 1.0.5+6, `android` applicationId `za.co.rastasperiq.ordering`, API 36, R8/shrinking configured.
- **State/Architecture:** `lib/src/core/app_controller.dart` (ChangeNotifier) owns bootstrapping, auth, menu, cart, orders, preferences, notifications. Repositories abstract Supabase.
- **Dependencies:** `supabase_flutter ^2.16.0`, `shared_preferences`, `flutter_secure_storage`, `firebase_core` + `firebase_messaging`, `flutter_local_notifications`, `app_links`, `file_picker`, `url_launcher`.
- **Auth:** Supabase Auth via `supabase_auth_repository.dart`. Supports `Email+password` and `Anonymous` (guest checkout). Session stored via `SecureAuthLocalStorage` (platform-secure, backup excluded). `SUPABASE_URL` + `SUPABASE_PUBLISHABLE_KEY` supplied via `--dart-define`, never via bundled `.env`. Profile promotion `profiles.role = 'admin'` via SQL.
- **Menu/Catalog:** `menu_items` + `menu_categories` tables, Realtime subscribed, local cache (`cached_menu_items_v1`). Images via `menu-images` bucket (public, 5 MB, jpg/png/webp, RLS admin-only writes).
- **Orders:** Created via **single atomic RPC** `public.place_order(...)` which validates: auth, store_open, within operating hours (Africa/Johannesburg), pickup/delivery availability, delivery address length, payment method, item availability, spice levels, add-ons, quantity 1–50, array 1–50, and **server-calculates trusted total** (`price + add_on_total` per item × qty + delivery_fee) and compares `abs(trusted - expected) < 0.01` else throws "Price changed". Uses `pg_advisory_xact_lock(hashtext(uid||requestId))` + `unique(user_id, client_request_id)` for idempotency. Estimated minutes = max prep_minutes (+20 if delivery). Writes `orders` + `order_items` transactionally.
- **Order tables:** `orders(id uuid pk, order_number bigint identity, user_id uuid→auth.users, customer_name/phone, order_type pickup/delivery, payment_method cash_collection/cash_delivery/eft/card, total_price numeric, status pending/preparing/ready/completed/cancelled, estimated_minutes, delivery_address, client_request_id text, payment_proof_path, created_at, updated_at)` with RLS (owner or admin select, admin-only update, inserts only via RPC). `order_items` snapshots name/description/image/category/unit_price etc + `selected_add_ons jsonb`. Policies `orders_select_owner_or_admin`, `orders_admin_update`, `order_items_select_owner_or_admin`. Trigger `validate_order_status_transition` enforces pending→preparing/cancelled→ready→completed and admin-only.
- **Payments (existing):** `cash_collection`, `cash_delivery`, `eft` (proof upload via `attach_payment_proof` RPC + `payment-proofs` private bucket 5 MB jpg/png/webp/pdf). Schema lists `card` as allowed but RPC currently **rejects** `card`/`yoco` (`if p_payment_method not in ('cash_collection','cash_delivery','eft')`). No online gateway, no `yoco_checkout_id` columns, no `payments` table.
- **Admin:** `profiles.role`, `is_admin()` definer function, RLS for `app_settings`, `menu_*`, `orders`. Admin screens for menu editor, category manager, Today's Special, dashboard, fulfilment panel. Status updates via `orders.update(status)` (admin-only trigger).
- **Store settings:** `app_settings(id='default', store_open, pickup_available, delivery_available, delivery_fee 30, opening_time 10:00, closing_time 21:00, todays_special_* )` with Realtime.
- **Push:** `push_tokens`, `push_notification_dispatches`, `register_push_token`/`unregister_push_token` + Firebase.

### Website (`website/`)
- **Framework:** Next.js 16.2.12 + React 19.2.8, Tailwind 4.3.3, TypeScript 6.0.3, pnpm 11.9.0. `next.config.ts`: `output:"export"`, `trailingSlash:true`, `images.unoptimized:true` → **fully static export** (`out/`). Cannot run `app/api` or server code in current config. Detected framework Vercel Next.js, `Root Directory = website`.
- **Pages present:** `/` (landing with hero, features, how-it-works, TodaysSpecialLive, visit, contact), `/get-app/` (device detection, market:// → Play Store), `/privacy-policy/`, `/terms-and-conditions/`, `/delete-account/`, `not-found.tsx` 404, `layout.tsx` with SiteHeader/SiteFooter.
- **Ordering capability:** **None**. No menu browser, cart, checkout, order confirmation. Only reading `app_settings.todays_special_*` via `@supabase/supabase-js ^2.110.9` client-side in `TodaysSpecialLive` (direct anon read with `NEXT_PUBLIC_SUPABASE_URL/_PUBLISHABLE_KEY`). No authentication, no `place_order`.
- **Config:** `.env.example` only `NEXT_PUBLIC_INSTAGRAM_URL/FACEBOOK/TIKTOK_URL` + `NEXT_PUBLIC_SUPABASE_URL/_PUBLISHABLE_KEY`. No `SUPABASE_SERVICE_ROLE`, no Yoco secrets, no webhook URLs.
- **Styling:** `globals.css` with brand palette (`peri-red #C8240B`, `orange #F07820`, `charcoal #1A1A1A`, `cream #FFF8F5`). Components `Brand`, `SiteHeader`, `SiteFooter`, `SocialLinks`, `GetAppPanel`.
- **Deployment:** Docs state `pnpm build` → `out/` → Vercel import, set Root Dir `website`, add domains `rastasperiq.co.za` + `www`. No `vercel.json`, no redirects, no API route config. Build is `next build` static.

### Backend / Database (authoritative)
- **Provider:** Supabase Postgres only. No separate Node/Express/Django backend folder exists. `supabase/config.toml` placeholder only `[functions.order-push] verify_jwt=true`.
- **Schema source:** `peri_q_app/supabase/schema.sql` (1259 lines) + migrations `20260727_harden_menu_image_uploads.sql` + `20260731_add_push_notifications.sql`. Must be applied manually via Supabase SQL editor (no CLI CI). No ORM, no `prisma`.
- **Where data lives:** All menu, prices, availability, `app_settings`, customers (`profiles` + `auth.users`), orders, order_items, `payment_proofs` storage in single Supabase project. Website currently shares **nothing except** `app_settings` row read. No duplicate customer accounts between platforms yet (website has none), but **no shared cart/checkout**.
- **Shared DB?** Partially. Both can point at same project URL, but website does NOT yet create orders/carts. Mobile app and website would share data **after** we point website at same Supabase auth + `place_order` RPC. No separate system to migrate; consolidation = reuse mobile's tables.
- **Order flow (mobile):** Cart in memory (`AppController.cart`), checkout form validates name/phone/address/type/payment, calls `placeOrder` → `SupabaseOrderRepository.createOrder` → `rpc place_order` → returns `id` → fetches full order row with `order_items` → shows `ConfirmationScreen`. Admin watches `orders` Realtime stream (bounded 100) and updates status.
- **Auth & permissions:** RLS enabled on all tables. `is_admin()` checks `profiles.role='admin'` via `auth.jwt()->>email` lookup definer. Anonymous users can read `menu_*` + `app_settings`, can call `place_order` as authenticated (anon is still `authenticated` role in Supabase), cannot change roles or order status. Profiles policy `insert with check role='customer'` + trigger `protect_profile_role` prevents escalation.
- **Deploy setup rastasperiq.co.za:** Static Vercel deployment (`website` root). Domain DNS to Vercel. HTTPS via Vercel. Env vars set in Vercel Project Settings → Environment Variables (public Supabase only). No server env needed yet. No webhook domain allowlist.

### Payment integration (existing)
- **Cash-based:** `cash_collection`/`cash_delivery` immediate; `eft` requires proof upload to `payment-proofs` then manual verification. No gateway keys, no `YOCO_*` env, no checkout session table, no webhook handler, no verification code. `order.status` is fulfilment only, separate from payment proof (`payment_proof_path` nullable).

### Migrations / Backups / Tests
- **Migrations:** No automated runner; `supabase/schema.sql` idempotent with `create table if not exists`, `on conflict do update`, `add column if not exists`. Two delta migrations present. Must be applied manually; no `supabase db push` CI.
- **Backups:** No documented schedule; relies on Supabase project daily backups (not verified). No explicit dump/restore scripts.
- **Automated tests:** Flutter `flutter test` suite: `admin_order_fulfilment_panel_test.dart`, `app_theme_test.dart`, `auth_and_menu_test.dart` (large AppController harness), `shared_preferences_repository_test.dart`, `supabase_config_test.dart`, `widget_test.dart`. `dart format --output=none --set-exit-if-changed` + `flutter analyze`. **Website has zero tests** (no vitest/jest). No `supabase` integration tests.

---

## 2. Risks & Constraints
- **Static export blocks server secrets:** `output:"export"` disables `app/api/*`. Yoco secret (`sk_test_.../sk_live_...`) must never ship to browser; must switch to Vercel serverless (`output` omitted, `trailingSlash` kept, `images.unoptimized:true` retained for simplicity).
- **Yoco live gating:** Live `sk_live_` + live webhook require verified domain in Yoco App (Sales → Payment Gateway → Verified Domains → Add `https://rastasperiq.co.za` → wait). Test keys work immediately.
- **Price trust:** Must not accept client-submitted totals; rely on `place_order` trusted calculation + webhook amount-vs-order cross-check.
- **Idempotency:** Advisory lock + `(user_id, client_request_id)` already prevents double orders on mobile; same must apply to website. Yoco `Idempotency-Key` header and checkout `yoco_checkout_id` uniqueness prevents double charges on refresh.
- **Webhook security:** Must verify `whsec_...` HMAC-SHA256 signature with raw body, `webhook-id` + `webhook-timestamp` + body, check timestamp within 5 min, constant-time compare, store processed event ids idempotently, and ignore browser `successUrl` visits.

## 3. Implementation Plan (safe, minimal-rebuild)

### A. Database — one shared authoritative Postgres (no duplicate system)
1. **Additive migration** `supabase/migrations/20261012_yoco_payments.sql` (also patch `schema.sql`):
   - Extend `orders`: `yoco_checkout_id text unique`, `payment_status text not null default 'unpaid' check in ('unpaid','pending','paid','failed','cancelled','expired')`, `paid_at timestamptz`, `payment_amount_cents integer check >=0`, `yoco_payment_id text`, `yoco_mode text check in ('test','live')`.
   - Update `place_order` allowed methods: add `'yoco','card'` to check and branching.
   - New tables:
     ```sql
     create table payments (
       id uuid pk default gen_random_uuid(),
       order_id uuid not null unique references orders(id) on delete cascade,
       yoco_checkout_id text unique,
       amount_cents integer not null check >0,
       currency text not null default 'ZAR',
       status text not null check in ('pending','succeeded','failed','cancelled','expired'),
       yoco_payment_id text,
       webhook_event_id text unique,
       raw_payload jsonb,
       created_at timestamptz default now(),
       updated_at timestamptz default now()
     );
     create table yoco_webhook_events (
       id text primary key, -- Yoco event id
       type text not null,
       payload jsonb not null,
       processed_at timestamptz,
       created_at timestamptz default now()
     );
     ```
   - RLS: `payments` owner-or-admin select, service_role full; webhook table service_role only.
   - Trigger `touch_updated_at` for new tables, realtime additions.
   - Backwards compatibility: existing orders `payment_status` defaults correctly; `card` kept for legacy OTP app.
2. **Manual step:** Apply migration in Supabase SQL editor after verified backup (Dashboard → Database → Backups → Create backup). Test on staging project first.

### B. Website framework change (reuse existing design)
- Remove `output:"export"` from `next.config.ts`, keep `images.unoptimized` + `trailingSlash`. Vercel will then serve both static assets + server functions; no DNS change needed.
- Add `lib/supabase.ts` with `createClient()` (anon client for browser) and `createServiceClient()` (service_role only in `app/api/*`).
- Add `lib/yoco.ts` helpers: `createYocoCheckout({amountCents, currency, orderId, metadata, IdempotencyKey, success/cancel/failureUrls})` + `verifyYocoWebhook(headers, rawBody, secret)`.
- Add `lib/cart.tsx` React context persisted to `localStorage` (`peri_q_cart_v1`), with `CartItem` shape mirroring `MenuItem` + qty/spice/notes/addOns, helpers `add, inc, dec, remove, clear, subtotal`.
- Update `.env.example` with placeholders: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `YOCO_SECRET_KEY`, `YOCO_WEBHOOK_SECRET`, `NEXT_PUBLIC_SITE_URL`.
- Keep `NEXT_PUBLIC_SUPABASE_*` for client, never expose service_role or Yoco secret to client.

### C. Website ordering UI (preserve cash, add Yoco)
Routes:
- `/menu` — fetches `menu_items` + `menu_categories` via Supabase publishable key (RLS public read), filters by availability/category, search, shows price, image (fallback `white-app-icon.png`), Add to Cart.
- `/cart` — quantity ±, remove, subtotal, delivery fee note.
- `/checkout` — form: customer_name (2–100 chars), customer_phone (7–30), fulfillment toggle (pickup/delivery, disabled per `app_settings`), delivery_address (>=8 chars if delivery), payment method: `cash_collection`/`cash_delivery`/`eft`/`yoco` (yoco labelled "Pay with Card / Yoco"). Validates store_open + hours client + server. Calls `place_order` via Supabase (anonymous session ensured). After order created:
   - if cash/eft → show confirmation + (eft) proof upload link (reuse future pattern).
   - if yoco → `POST /api/yoco/checkout {orderId}` → receive `redirectUrl` → `window.location = redirectUrl`.
- `/order/[id]` — fetches order + items (owner-or-admin RLS via service-role or user token), shows timeline, payment_status vs fulfilment status separate, polling + Realtime. Success/cancel/failure query params.
- Header adds "Menu | Cart (badge) | Order" navigation, mobile-friendly.

Server trust:
- Client never sends price; `place_order` computes trusted total.
- `/api/yoco/checkout` re-fetches order via service_role, checks `total_price*100 == yoco amount`, checks `payment_status not in ('paid')`, attaches idempotency, creates Yoco checkout with `authorization Bearer YOCO_SECRET_KEY`.
- Amount in cents, currency ZAR, `metadata:{order_id, order_number, source:"website"}`, line items display-only.

### D. Yoco integration (official Checkout API)
- **Create checkout:** `POST https://payments.yoco.com/api/checkouts` with `Idempotency-Key: order.client_request_id`.
- **Checkout URLs:** `successUrl = ${NEXT_PUBLIC_SITE_URL}/order/${orderId}?checkout=success` (do NOT mark paid here), `cancelUrl` `?checkout=cancel`, `failureUrl` `?checkout=failure`.
- **Webhook endpoint:** `POST https://rastasperiq.co.za/api/yoco/webhook` — reads raw body (`await req.text()`), verifies signature:
   1) split `webhook-signature` on spaces, strip `v1,` prefixes, base64 decode comparison;
   2) recover secret via `whsec_` prefix trimmed → base64 decode;
   3) signedContent = `${webhook-id}.${webhook-timestamp}.${rawBody}`;
   4) HMAC-SHA256 → base64;
   5) timestamp diff < 5 min (3 min recommended, we allow 5 for retries);
   6) `timingSafeEqual`.
- **Payload handling:** `{id, type: payment.succeeded|payment.failed, payload:{id, amount, currency, status, metadata:{order_id}, paymentMethodDetails}}`. Validate currency ZAR, verify `payload.metadata.order_id` exists, verify amount matches `order.total_price*100` (reject silently if mismatch, log). On `payment.succeeded`: update `orders.payment_status='paid', paid_at=now(), yoco_payment_id, yoco_mode`, `payments.status='succeeded'`. On `payment.failed`: `payment_status='failed'`. Upsert `yoco_webhook_events` idempotently (unique id) to drop duplicates. Acknowledge with `204`/`200` quickly.
- **Anti-double-pay:** `orders.yoco_checkout_id` unique prevents re-creation; if checkout already pending return same redirectUrl; if `paid_at` not null reject new checkout. Frontend disables button + shows pending state.

### E. Mobile app preservation
- No breaking change to Flutter RPC caller; expand allowed `paymentMethod.code` handling to include `yoco` (mapped to `card` fallback for UI) but keep cash/eft primary. Test regression: ensure anonymous + email flows still pass `auth_and_menu_test`.
- If mobile later wants Yoco, it can reuse same `orders.yoco_checkout_id` + webhook without schema change.

### F. Tests
- **Website:** add `vitest` + `@testing-library/react` minimal tests: menu loading, cart maths, server price validation (mock RPC error "Price changed"), order creation success, delivery validation, shared data (menu from same Supabase project), Yoco checkout initiation (mock fetch to Yoco with test key), webhook success/failed/cancelled/pending, duplicate webhook idempotency, duplicate checkout idempotency, auth isolation (own vs other's order 403).
- **Flutter:** run `flutter analyze` + `flutter test` (existing suite) after migration; ensure `place_order` still rejects invalid price.
- **Manual Yoco:** Use `sk_test_...` + test cards from Yoco App to drive Hosted Checkout → verify webhook reaches Vercel logs → check `orders.payment_status` flips only after webhook, not on redirect.

### G. Deployment
- Keep Vercel project, `Root Directory: website`. Change build from static export to server (remove `out/` expectation). Env vars per environment (Preview/Production). Add domains if needed; HTTPS auto.
- Commands: `pnpm install; pnpm build; pnpm start` locally (requires `.env.local`). Tests `pnpm test` / `flutter test`.

### H. Remaining blockers needing owner action
- Supply Supabase project URL/publishable key + service_role (never in chat/repo) → paste into Vercel env.
- In Yoco App → Sales → Payment Gateway → obtain `YOCO_SECRET_KEY` (test + later live) + `YOCO_WEBHOOK_SECRET` + verified domain `rastasperiq.co.za`.
- Approve additive migration after backup, run it on production Supabase.
- Configure webhook URL in Yoco dashboard (`https://rastasperiq.co.za/api/yoco/webhook`, events `payment.succeeded`, `payment.failed`).

### Deliverables
- Single shared ordering backend (Supabase), mobile untouched.
- Website full ordering flow (browse → cart → checkout → confirmation) + cash/eft preserved + Yoco card.
- Secure server checkout + webhook verification, amount validation, idempotency, separated payment vs fulfilment status.
- Example env files, docs, automated tests, MANUAL_SETUP_AND_LAUNCH_CHECKLIST.md sections A–F.

