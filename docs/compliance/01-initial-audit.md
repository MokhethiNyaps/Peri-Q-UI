# 01 — Initial Compliance and Security Audit (Phase One)

| | |
|---|---|
| Platform | Rasta's Peri-Q online ordering (website `rastasperiq.co.za` + Android app `za.co.rastasperiq.ordering`) |
| Repository | `MokhethiNyaps/Peri-Q-UI`, branch `main` at `60c5fbd` |
| Audit date | 3 November 2026 |
| Audit type | Read-only review of the repository. No code, database, configuration or migration was changed. |
| Status of this document | Draft for the business owner and an attorney. **This is not a legal opinion and does not confirm compliance with any law.** |

Status labels used: IMPLEMENTED AND TESTED · IMPLEMENTED BUT NOT FULLY TESTED · NOT IMPLEMENTED · BLOCKED BY MISSING INFORMATION · REQUIRES BUSINESS OWNER APPROVAL · REQUIRES ATTORNEY REVIEW · REQUIRES EXTERNAL REGISTRATION OR APPROVAL.

Placeholders appear as `[[PLACEHOLDER: …]]`. They must be filled by the restaurant or an attorney. They must not be guessed.

---

## 0. Scope, method and limits

**What was inspected:** the root project docs (`DESIGN.md`, `IMPLEMENTATION_PLAN.md`, `IMPLEMENTATION_REPORT_20261020.md`, `CONTINUATION_HANDOFF_20261020.md`, `MANUAL_SETUP_AND_LAUNCH_CHECKLIST.md`), `peri_q_app/DESIGN.md` and `peri_q_app/docs/*`, all of `website/` (app routes, API routes, `lib/`, legal pages, config, tests), all of `peri_q_app/lib/`, `peri_q_app/supabase/` (`schema.sql`, four migrations, `functions/order-push`, `config.toml`), the Android manifest, and `tools/`.

**What was not verified (could not be verified from the repository):**

1. **Live Supabase state.** The Supabase MCP connection was not authorised in this session. Every database finding is based on `peri_q_app/supabase/schema.sql` and the migrations. Live RLS policies, grants, triggers, auth settings, storage policies and backups may differ. → Stage 6 starts with a live read-only check.
2. **Migration history is incomplete.** No migration creates the base tables (`profiles`, `orders`, `order_items`, `menu_*`, `app_settings`). Those exist only in `schema.sql`. It cannot be proven that production matches `schema.sql`.
3. **Supabase Auth settings:** email confirmation, password strength, leaked-password protection, anonymous sign-in rate limits, MFA, JWT expiry, redirect allow-list.
4. **Vercel settings:** environment variable scope, deployment protection, firewall/WAF, log retention, region.
5. **Yoco dashboard:** registered webhook URL, events subscribed to, live/test keys, refund process.
6. **Firebase project:** data region and retention of FCM data.
7. **Backups and restore:** the Supabase plan, point-in-time recovery and whether a restore has ever been tested.
8. **Tests were not run** in this phase. The test files exist (listed in §A.10), but their pass state was not confirmed.
9. **The `tests` and `tools/staging-rehearsal` scripts** were read but not executed.

**Dependency tooling that ran (read-only):** `pnpm audit --prod` (through corepack) in `website/`, and `flutter pub outdated --no-dev-dependencies` in `peri_q_app/`. `npm audit` could not run because the website uses a pnpm lockfile.

**No secrets, env values or customer records were read or recorded.** Environment variables are listed by name only.

---

## User-supplied business facts (from CIPC COR39, page 2 of 3)

The user supplied these facts from a CIPC COR39 certificate (Director Amendments, issued 23 July 2025). They were **not** independently verified.

| Item | Value |
|---|---|
| Registered name | PERI Q CHISANYAMA (PTY) LTD |
| Registration number | 2025/302145/07 |
| Type / status | Private company / In Business |
| Registration date | 08/04/2025 |
| Financial year end | December |
| Registered office, postal address, company records | 28 King Edward Willows, Bloemfontein, Free State, 9301 |
| Tax number | On the certificate. Left out of the repo on purpose. |

**Still unknown, marked BLOCKED BY MISSING INFORMATION:**

- `[[PLACEHOLDER: Directors]]`: page 3 of the COR39 was not supplied.
- `[[PLACEHOLDER: Relationship between trading name "Rasta's Peri-Q" / "RastasperiQ" and PERI Q CHISANYAMA (PTY) LTD]]`
- `[[PLACEHOLDER: Information Officer name and contact details]]` and any Deputy Information Officers
- `[[PLACEHOLDER: Official contact email/phone for legal notices, privacy requests and complaints]]`
- `[[PLACEHOLDER: Certificate of Acceptability (R638) number and issuing authority]]`
- `[[PLACEHOLDER: VAT registration status]]`
- `[[PLACEHOLDER: Physical trading address]]`. The website says "28 King Edward Rd, Bloemfontein" (`website/lib/site.ts:10`). The CIPC registered office is "28 King Edward Willows". The owner must confirm whether these are the same premises.

---

## A. Architecture

### A.1 Website
- Next.js 16.2.12, React 19.2.8, TypeScript, Tailwind. pnpm lockfile (`website/package.json`, `website/pnpm-lock.yaml`).
- Hosted on Vercel (per brief and `MANUAL_SETUP_AND_LAUNCH_CHECKLIST.md`). No `vercel.json` in the repo.
- Mostly client components that talk to Supabase directly with the publishable key (`website/lib/supabase.ts:4-37`).
- Two server routes, both `runtime = "nodejs"`:
  - `website/app/api/yoco/checkout/route.ts`: GET readiness probe; POST creates a Yoco hosted checkout.
  - `website/app/api/yoco/webhook/route.ts`: receives signed Yoco webhooks.
- Pages: `/`, `/menu`, `/cart`, `/checkout`, `/payment/[id]`, `/order/[id]`, `/account`, `/auth/callback`, `/get-app`, `/privacy-policy`, `/terms-and-conditions`, `/delete-account`.
- **No admin area on the website.** Admin tasks live only in the Android app.

### A.2 Mobile
- Flutter app `peri_q_app`, version `1.0.6+7`, Android only in practice. The manifest is Android; iOS is listed only as a push platform value.
- Main packages: `supabase_flutter`, `firebase_core`, `firebase_messaging`, `flutter_local_notifications`, `flutter_secure_storage`, `shared_preferences`, `url_launcher`, `app_links`, `file_picker`, `flutter_image_compress` (`peri_q_app/pubspec.yaml:29-41`).
- The customer screens and the admin screens (`admin_*_screen.dart`, `widgets/admin_order_fulfilment_panel.dart`) ship in the same APK. The admin UI appears when `profiles.role = 'admin'` (`supabase_auth_repository.dart:143-150`).

### A.3 Backend and database
- One Supabase project, shared by the website and the app. The privacy policy says it is hosted in `eu-west-1` (Ireland) (`website/app/privacy-policy/page.tsx:194`). Not verified live.
- Postgres tables: `profiles`, `app_settings`, `menu_categories`, `menu_items`, `orders`, `order_items`, `payments`, `yoco_webhook_events`, `push_tokens`, `push_notification_dispatches`, `checkout_intents`, `checkout_intent_items`.
- Security-definer RPCs: `is_admin`, `handle_new_user` (trigger), `register_push_token`, `unregister_push_token`, `place_order` (now disabled), `prepare_card_checkout`, `attach_payment_proof` (legacy EFT), `delete_own_account`, `finalize_card_checkout` (service_role only).
- Triggers: `touch_updated_at`, `protect_profile_role`, `validate_order_status_transition`, `require_verified_card_order`.
- Storage buckets: `menu-images` (public), `payment-proofs` (private, legacy EFT).
- Edge Function: `order-push` (`verify_jwt = true`, `peri_q_app/supabase/config.toml`).
- Realtime publication: `menu_categories`, `menu_items`, `orders`, `order_items`, `app_settings`, `payments`, `yoco_webhook_events`.

### A.4 Authentication
- Supabase Auth with email and password, plus **anonymous sign-in** for guest checkout (`website/lib/auth.ts:14`, `supabase_auth_repository.dart:26-27`).
- Password reset by email link. The website uses `/auth/callback`. The app uses the deep link `rastasperiq://reset-password`.
- Sessions: website in browser `localStorage` (supabase-js default, `persistSession: true`). App in `flutter_secure_storage` (`data/local/secure_auth_storage.dart`).
- Roles: `profiles.role in ('customer','admin')`. Role changes are blocked for non-admins by a trigger (`schema.sql:1014-1030`). There is no in-product way to make someone an admin; that is done in the database.

### A.5 Payment architecture (Yoco, card only)
1. The client calls the RPC `prepare_card_checkout`. It **recalculates every price on the server** from `menu_items`/`app_settings`, rejects a mismatched `p_expected_total`, and writes a draft to `checkout_intents` (`schema.sql:1375-1562`).
2. The client calls `POST /api/yoco/checkout` with its Supabase bearer token. The server checks the token, checks that the caller owns the draft, and creates a Yoco checkout for the **server-stored** `total_price` (`route.ts:60-147`).
3. The customer pays on Yoco's hosted page. The website redirects there. The app opens it in an in-app browser sheet (`supabase_order_repository.dart:173`).
4. Yoco sends a signed webhook. The server checks the HMAC, timestamp, amount, currency and mode, then calls `finalize_card_checkout`. That function copies the draft into `orders`/`order_items` as `payment_status = 'paid'` (`webhook/route.ts`, `schema.sql:1584-1600`).
5. The success/return pages and the app deep link are **hints only**. Both clients poll the database for `payment_status` (`payment-status.tsx:57-69`, `supabase_order_repository.dart:201-213`).
- Legacy cash/EFT paths are disabled: `place_order` now always raises (`schema.sql:1566-1568`), and a trigger refuses any `orders` insert that is not a service-role, Yoco-paid insert (`schema.sql:1570-1582`).

### A.6 Hosting
Vercel (website), Supabase (database/auth/storage/edge), Google Play (app distribution), Firebase Cloud Messaging (push).

### A.7 External integrations / operators
| Provider | Purpose | Evidence |
|---|---|---|
| Supabase | DB, auth, storage, realtime, edge functions | `website/lib/supabase.ts`, `peri_q_app/lib/main.dart:39` |
| Yoco | Hosted card checkout, webhooks | `website/app/api/yoco/*` |
| Vercel | Website hosting, server routes, logs | brief, setup checklist |
| Google Firebase (FCM) | Push notifications; receives device tokens and notification text | `peri_q_app/lib/main.dart:23`, `supabase/functions/order-push/index.ts` |
| Google OAuth token endpoint | Used by the Edge Function to get an FCM access token | `order-push/index.ts:307-329` |
| Google Play | App distribution | `website/lib/site.ts` |
| WhatsApp / email / phone | Customer support (outside the platform) | `peri_q_app/lib/src/core/external_links.dart`, `website/lib/site.ts` |
| Google Search Console | Site verification file | `website/public/google03cf5e6c24cb0330.html` |

No analytics, advertising, crash-reporting or tag-manager SDKs were found in either codebase (searched for gtag, GTM, Vercel Analytics, Speed Insights, Sentry, PostHog).

### A.8 Shared code
No shared package. The website and the app share **only the Supabase database and the RPC contract**. Validation rules are repeated in each client (for example name 2–100 characters, phone 7–30 characters) and enforced again in `prepare_card_checkout`.

### A.9 Existing security controls (positive findings)
- RLS is enabled on every public table in `schema.sql` (`schema.sql:738-739, 1060-1067, 1369-1370`).
- Prices are calculated by the server, and the total is cross-checked (`schema.sql:1490-1550`).
- The order status machine is enforced by a trigger, and only admins can change status (`schema.sql:1032-1058`).
- The role escalation guard trigger exists (`schema.sql:1014-1030`).
- Paid orders can only be created by `service_role` after a verified payment (`schema.sql:1570-1600`).
- Webhook HMAC (Standard Webhooks) check with constant-time compare and a ±5 min replay window (`website/lib/yoco.ts:39-96`).
- Webhook idempotency: event-ID table, a row lock in `finalize_card_checkout`, and an upsert on `payments.order_id`.
- Yoco `Idempotency-Key` is set to the client request ID (`route.ts:119, 143`).
- Card data never touches the platform (Yoco hosted page).
- The service-role key is used only on the server (`website/lib/supabase.ts:39-59`). `.env.example` warns against putting it in `NEXT_PUBLIC_*`.
- Android: `allowBackup="false"`, `usesCleartextTraffic="false"` (`AndroidManifest.xml:10,15`). The session is stored in secure storage.
- `next.config.ts` limits remote images to the project's `menu-images` bucket, so the optimiser is not an open proxy.
- The `menu-images` bucket limits size and MIME type (5 MB; jpeg/png/webp).

### A.10 Existing tests (not run in this phase)
- Website (Vitest): `website/tests/{auth-and-orders,cart,customer-account,menu,order-refresh,payment-status,presentation,yoco}.test.ts(x)`.
- App (flutter_test): `peri_q_app/test/*` (9 files, including `card_payment_session_test.dart` and `payment_config_test.dart`).
- DB: `tools/staging-rehearsal/rehearsal_test.py` with seed/legacy SQL.
- **No automated RLS tests against a live or local Supabase** were found, apart from the staging rehearsal scripts.

---

## B. Customer information inventory

This inventory records only what the code collects. "Kept" means what the code does. **No retention period is defined anywhere in code or the database**; the only stated periods are in policy text (see C).

| Category | Collected where | Stored where | Why / necessary? | Who can access | External recipients | How long kept (per code) |
|---|---|---|---|---|---|---|
| **Name** | Signup (`customer-account.ts:30-34`; app auth screen), checkout form (`checkout-client.tsx:21`), profile | `auth.users.raw_user_meta_data`, `profiles.full_name`, `orders.customer_name`, `checkout_intents.customer_name`; website `localStorage["peri_q_customer_v1"]`; app secure storage `peri_q_customer_name_v1` | To identify the order at collection/delivery. Necessary. | Owner (RLS), admins (all orders/profiles), service role | Supabase; **Google FCM** (admin "new order" text contains the customer name, `order-push/index.ts:199`); Vercel (in transit through the API route? No: the name is not sent to `/api/yoco/checkout`) | Until account deletion. Drafts in `checkout_intents` are never purged. |
| **Email** | Signup / sign-in / reset | `auth.users.email`, `profiles.email` | Account login and recovery. Necessary for registered accounts; not collected for guests. | Owner, admins (profiles) | Supabase (and its email sender for auth mails) | Until account deletion |
| **Phone** | Signup metadata, checkout, profile | `profiles.phone`, `orders.customer_phone`, `checkout_intents.customer_phone`, `localStorage`, app secure storage | To contact about the order/delivery. Necessary. | Owner, admins | Supabase | Until account deletion. Drafts are never purged. |
| **Delivery address** | Checkout (delivery only); app "saved addresses" | `orders.delivery_address`, `checkout_intents.delivery_address`; website `localStorage`; app secure storage `peri_q_saved_addresses_v1` | To deliver. Necessary only for delivery (enforced: `schema.sql:1471-1473, 1485`). | Owner, admins | Supabase | Until account deletion. Drafts are never purged. Local copies stay until the user clears them / signs out. |
| **Credentials** | Signup / sign-in | Password hash in Supabase Auth only. Website session tokens in browser `localStorage`. App tokens in `flutter_secure_storage`. | Authentication. Necessary. | Supabase Auth | Supabase | Session lifetime / until sign-out |
| **Anonymous identity** | Automatic guest sign-in (`website/lib/auth.ts:14`, app) | `auth.users` (anonymous) | Lets guests own orders under RLS. | Owner, Supabase | Supabase | **Never cleaned up** (no code removes stale anonymous users) |
| **Order history** | Checkout | `orders`, `order_items`, `checkout_intents`, `checkout_intent_items`, `payments`, `push_notification_dispatches` | Fulfilment, customer history, accounting. Necessary. | Owner, admins, service role | Supabase; Yoco receives order ID and order number in checkout metadata (`route.ts:122-126`) | Deleted **with the account** (`orders.user_id … on delete cascade`, `schema.sql:635`; `payments` cascade `schema.sql:703`). Not kept as the policy claims. |
| **Food preferences / notes** | Item customisation: spice level, add-ons, free-text notes up to 500 characters | `order_items.spice_level/notes/selected_add_ons`, `checkout_intent_items` | Prepare food as requested. Necessary. **Free-text notes may contain health/allergy or religious information (special personal information under POPIA s26)**. Not prompted, but possible. | Owner, admins | Supabase | As order history |
| **Payment references** | Yoco checkout and webhook | `checkout_intents/orders.yoco_checkout_id, yoco_payment_id, payment_amount_cents, yoco_mode, paid_at`, `redirect_url`; `payments`; `yoco_webhook_events.payload` (minimal subset stored by the webhook, `webhook/route.ts:73-76, 87-90`). No card data. | Reconciliation and proof of payment. Necessary. | Owner (own `payments` row), admins (`payments`, `yoco_webhook_events`), service role | Yoco (is the payment processor) | Cascade-deleted with the order/account. `yoco_webhook_events.order_id` is set null and the row is kept. |
| **Legacy EFT payment proofs** | Old app versions (`supabase_order_repository.dart:392-411`) | Private bucket `payment-proofs/<uid>/<order>/…`; `orders.payment_proof_path` | Historical only. Not needed for new orders. | Owner, admins | Supabase | **Not deleted by `delete_own_account`.** Storage objects are not removed when `auth.users` is deleted. |
| **Device information** | App push registration | `push_tokens(user_id, installation_id, fcm_token, role, platform)` | Order-status push messages. Optional (the user can deny the notification permission). | Service role only (all grants revoked, `schema.sql:1069`) | **Google FCM** | Until token rotation, unregister, or account deletion (cascade) |
| **IP addresses / request metadata** | Not collected by app code | Implicitly in Supabase, Vercel and Yoco logs | Operations/security | Provider dashboards | Supabase, Vercel, Yoco | Provider default; **not verified** |
| **Analytics** | None found | — | — | — | — | — |
| **Support communications** | WhatsApp, email, phone links (outside the platform) | Outside the platform (WhatsApp/email inboxes) | Support | Restaurant staff | Meta (WhatsApp), email provider | Unknown. `[[PLACEHOLDER: support retention]]` |
| **Local device data (website)** | Checkout and cart | `localStorage`: `peri_q_customer_v1` (name, phone, address, order type), `peri_q_checkout_request`, `peri_q_pending_payment`, cart, Supabase session | Convenience / reliability | That browser | — | Until cleared. `peri_q_customer_v1` is removed on sign-out (`customer-account.ts:48`). |

**Not collected by the code:** date of birth, ID numbers, precise location, contacts, card numbers, marketing consent, cookies set by first-party code (supabase-js uses `localStorage`, not cookies).

---

## C. Legal-document gap analysis

| Document / process | Current state | Gaps | Status |
|---|---|---|---|
| **Privacy policy** | `website/app/privacy-policy/page.tsx`, effective 20 July 2026 | (1) Scoped to "its Android ordering app" (meta description, line 18). It does not cover the website, its `localStorage` or website guest checkout. (2) **It says the app does not use Firebase Cloud Messaging (line 160). That is false**: `firebase_messaging` is a dependency, `main.dart:23` initialises Firebase, and customer names go to FCM. (3) It does not name Yoco, Vercel or Google/Firebase as operators. (4) It says order/financial records "may be anonymised and retained for at least five years" (line 218), but code cascade-deletes them (see D-H2). (5) It does not name the responsible party (PERI Q CHISANYAMA (PTY) LTD and registration number) or an Information Officer. (6) No reference to the Information Regulator or the right to complain (POPIA s18(1)(h)). (7) The cross-border transfer statement (line 261) has no s72 basis stated. (8) Special personal information in free-text notes is not addressed. | NOT IMPLEMENTED (accurate version) · REQUIRES ATTORNEY REVIEW · BLOCKED BY MISSING INFORMATION |
| **Terms and conditions** | `website/app/terms-and-conditions/page.tsx`, effective 27 July 2026, 12 sections | No supplier legal identity, registration number or physical address (ECTA s43(1)). Section 7 on cancellations and refunds is vague (lines 100-105). No dispute or complaints procedure. No allergen disclaimer. No governing law or jurisdiction clause. No statement of whether the ECTA s42 cooling-off period applies to perishable food. No acceptance mechanism at checkout. | REQUIRES ATTORNEY REVIEW · BLOCKED BY MISSING INFORMATION |
| **PAIA manual (s51)** | None | No manual. Whether an exemption applies to a small private body must be confirmed. | NOT IMPLEMENTED · REQUIRES ATTORNEY REVIEW |
| **Cookie / local-storage notice** | None | No first-party cookies or analytics were found. The site does use `localStorage` for PII (name, phone, address) and auth tokens. A short storage notice is advisable. Whether a consent banner is needed depends on the legal view. | NOT IMPLEMENTED · REQUIRES ATTORNEY REVIEW |
| **Refund policy** | One paragraph in T&C §7 | No process, timelines, method (back to card via Yoco), partial refunds or wrong-item handling. The code has **no refund handling**: the webhook ignores `refund.succeeded` (`webhook/route.ts:41-43`), and no admin refund tool exists. | NOT IMPLEMENTED · REQUIRES BUSINESS OWNER APPROVAL |
| **Cancellation policy** | T&C §7 ("may not be available once preparation has started") | No defined window. Admins can set `pending → cancelled` (`schema.sql:1045`), but a cancelled paid order does not trigger a refund or record one. | NOT IMPLEMENTED · REQUIRES BUSINESS OWNER APPROVAL |
| **Payment policy** | T&C §5 | It does not name Yoco, the currency, when the card is charged, what happens to failed payments or double-payment handling, or security measures (ECTA s43(5)/s43(1)(p)). | REQUIRES ATTORNEY REVIEW |
| **Complaints procedure** | None (contact details only) | No procedure, timelines or escalation route (Consumer Goods and Services Ombud / National Consumer Commission, Information Regulator for privacy). | NOT IMPLEMENTED |
| **Privacy notices at collection points** | None at signup or checkout | No "we collect X for Y" notice and no link to the policy at the point of collection (POPIA s18). The app opens policy links from its Privacy & Support screen only. | NOT IMPLEMENTED |
| **Consent records** | None | No table records policy or terms version acceptance, and no timestamp. There is no marketing processing today, so no marketing consent is needed yet. | NOT IMPLEMENTED |
| **Data deletion procedure** | App: `delete_own_account` RPC. Website: email request only (`delete-account/page.tsx`) | The website has no self-service deletion. Deletion hard-deletes orders and payments (contradicts the stated retention). Storage proofs are not removed. Drafts are removed by cascade (good). There is no admin workflow or log for emailed requests. | IMPLEMENTED BUT NOT FULLY TESTED (app) · NOT IMPLEMENTED (website) |
| **Retention procedure / schedule** | Policy text only (5 years, 30-day backups). Not in code. | No schedule. No purge job for `checkout_intents`, anonymous users or webhook events. Periods are unconfirmed. `[[PLACEHOLDER: retention periods, attorney/accountant to confirm]]` | NOT IMPLEMENTED · REQUIRES ATTORNEY REVIEW |
| **Operator agreements (POPIA s20-21)** | None in the repo | Supabase, Vercel, Yoco and Google (Firebase) DPAs/terms must be accepted and filed. Cross-border transfers (Ireland/EU, US) need a s72 basis. | REQUIRES EXTERNAL REGISTRATION OR APPROVAL · REQUIRES ATTORNEY REVIEW |
| **Information Officer registration** | None | Register with the Information Regulator. | REQUIRES EXTERNAL REGISTRATION OR APPROVAL · BLOCKED BY MISSING INFORMATION |
| **Food information / allergens** | None. A search for "allerg", "halaal" and "gluten" across both clients returned nothing. | No allergen or ingredient information. No "may contain" statement. No halaal statement (and none should be made without certification). | NOT IMPLEMENTED · BLOCKED BY MISSING INFORMATION · REQUIRES ATTORNEY REVIEW |
| **Business information page / ECTA s43 disclosures** | Partial (trading name, address, phone, email in `website/lib/site.ts`) | Legal name, registration number, directors, Certificate of Acceptability and VAT status are missing. | BLOCKED BY MISSING INFORMATION |

---

## D. Security audit

Severity: Critical / High / Medium / Low / Informational. "Law" names the related regime (POPIA, PAIA, CPA, ECTA, Cybercrimes Act, food information, IP, payment security). This is context, not a legal conclusion.

### D.0 The four key questions

| Question | Answer from code | Evidence |
|---|---|---|
| Can a customer read another customer's data? | **No (by schema).** Owner-or-admin RLS on `profiles`, `orders`, `order_items`, `payments`, `checkout_intents`. Push tables are revoked. Storage proofs are scoped to a per-user folder. The Edge Function checks ownership. *Live policies not verified.* | `schema.sql:1072-1077, 1174-1179, 1191-1204, 746-749, 1373, 1069-1070, 1333-1344`; `order-push/index.ts:103-105` |
| Can a customer change order prices? | **No.** The server prices every item, add-on and delivery fee. A client total that does not match is rejected. Yoco is charged the server-stored total. | `schema.sql:1490-1550`; `route.ts:91-96, 128-135` |
| Can a customer mark their own order paid? | **No (by schema).** No customer insert/update policy on `orders`. `checkout_intents` grants are select-only. The insert trigger requires `service_role` + `paid` + `yoco_payment_id`. `finalize_card_checkout` is executable only by service_role. | `schema.sql:1181-1189, 1371-1373, 1570-1582, 1599-1600` |
| Can a customer reach admin endpoints? | **No admin HTTP endpoints exist.** Admin writes go through RLS (`is_admin()`). The `order-push` status event requires admin. Admin screens ship in the public APK but have no power without the DB role. | `schema.sql:1101-1172, 1183-1189`; `order-push/index.ts:107` |
| Does the server alone decide a payment succeeded? | **Yes.** Only the verified webhook → `finalize_card_checkout` creates a paid order. Return URLs and deep links are hints only. | `webhook/route.ts:20-30, 63-65`; `payment_session.dart:21-26`; `payment-status.tsx:57-69` |
| Are webhooks verified and idempotent? | **Verified:** HMAC-SHA256, constant-time compare, ±300 s timestamp. **Idempotent:** event-ID check, row lock and "already exists" return in finalize, upsert on `payments.order_id`. See D-M5 for remaining gaps. | `yoco.ts:39-96`; `webhook/route.ts:58-59, 96-103`; `schema.sql:1588-1592` |

### D.1 Findings

#### Critical

**D-C1. The Next.js version has published critical RCE advisories.** `next@16.2.12` (`website/package.json`). `pnpm audit --prod` reports 5 critical advisories in `next` (Image Optimization RCE with AVIF [GHSA-2xp9-vwfh-vxw4] and SVG [GHSA-2464-fhr4-w9xw], `next/og` RCE [GHSA-vcvr-r3jv-pc5j], `use cache` RCE [GHSA-673q-mjm6-r5xr], Windows-hosted RCE [GHSA-p293-qw3h-jr36]). The site enables the AVIF image format (`next.config.ts:18`). Some advisories may not be exploitable on Vercel's managed image optimiser or with features this site does not use. **Exploitability on Vercel was not verified.** Upgrade to a patched release (≥ 16.4.1 covers all listed). *Law: POPIA s19 (security safeguards); Cybercrimes Act context.* → Code fix.

#### High

**D-H1. The privacy policy is factually wrong about Firebase Cloud Messaging and omits operators.** `website/app/privacy-policy/page.tsx:160` says the app does not use FCM. The app initialises Firebase (`peri_q_app/lib/main.dart:23, 58`), stores FCM tokens (`schema.sql:72-83`) and sends the customer's name in admin push text (`order-push/index.ts:199`). Yoco, Vercel and Google are not named. *Law: POPIA s18 (notification), s20-21 (operators), s72 (cross-border).* → Code fix (text) + attorney review.

**D-H2. Account deletion hard-deletes financial records, which contradicts the stated retention.** `delete_own_account` deletes `auth.users` (`schema.sql:995-1012`). This cascades to `orders` (`schema.sql:635`), `order_items`, `payments` (`schema.sql:703`) and push data. The privacy policy (line 218) and the delete-account page (line 124) say records may be anonymised and kept for at least five years. There is therefore no proof-of-sale record after deletion, which also hurts refund and chargeback handling. *Law: POPIA s14 (retention), tax record-keeping (Tax Administration Act; attorney/accountant to confirm), CPA (refund disputes).* → Code fix (anonymise instead of cascade; non-destructive migration) + attorney decision on periods.

**D-H3. Website customers cannot delete their account themselves.** Users who registered on the website can only email a request (`website/app/delete-account/page.tsx:20-23, 93-95`). There is no logging or tracking of those requests. *Law: POPIA s24 (correction/deletion); Google Play account-deletion policy also applies to the app.* → Code fix.

**D-H4. No allergen or food information is shown anywhere.** Not in menu data (`menu_items` has no allergen/ingredient columns, `schema.sql:248-261`) or UI. Customers can type allergy notes, but nothing tells them the kitchen cannot guarantee allergen-free food. *Law: CPA s24/s41 (product information, misleading by omission), Foodstuffs regulations (R146 applicability to non-prepacked food to be confirmed by attorney), duty of care.* → Restaurant supplies data + code + attorney review.

#### Medium

**D-M1. No rate limiting on the server routes or anonymous sign-up.** `POST /api/yoco/checkout` has none (`route.ts:29`). Any visitor can create anonymous users (`website/lib/auth.ts:14`) and then unlimited `checkout_intents` through `prepare_card_checkout`. Supabase Auth's built-in limits are not verified. Risk: DB growth, Yoco API abuse, a spike in notifications. → Code + Supabase/Vercel config.

**D-M2. Checkout drafts and anonymous users are never purged.** `checkout_intents` keeps name, phone and address for abandoned and failed payments indefinitely (`schema.sql:1359-1374`). Anonymous auth users are never removed. *Law: POPIA s14 (retention), s10 (minimality).* → Code (scheduled purge, non-destructive to orders) + retention decision.

**D-M3. No admin MFA and no admin audit trail.** Admins see every customer's name, phone and address and can update any `orders` column, including `payment_status`, `paid_at` and `total_price` (`orders_admin_update`, `schema.sql:1183-1189`; no column restriction). Admin actions are not logged. A stolen admin password exposes all customer PII. *Law: POPIA s19, s22 (breach notification readiness).* → Code + Supabase MFA config.

**D-M4. No security headers on the website.** `next.config.ts` sets no CSP, HSTS, `X-Frame-Options`/`frame-ancestors`, `Referrer-Policy` or `Permissions-Policy`. Supabase sessions live in `localStorage`, so any XSS could steal tokens. → Code.

**D-M5. Webhook gaps.** (a) `refund.succeeded` is ignored (`webhook/route.ts:41-43`), so refunds made in the Yoco dashboard never reach `payment_status`. (b) There is a race between `existing?.processed` (line 58) and the final `processed=true` update (line 103), and the `payment.failed` path upserts with `ignoreDuplicates`. This is safe today because finalize and the upserts are idempotent, but it means the "processed" flag is advisory. (c) The webhook trusts the signed payload and does not query Yoco to re-confirm payment status. Acceptable with a verified signature; optional hardening. *Law: payment security, CPA refunds.* → Code.

**D-M6. Payment-proof storage can be written by any signed-in user.** `payment_proofs_owner_insert` (`schema.sql:1323-1331`) lets any authenticated user, including anonymous ones, upload up to 5 MB files into their own folder, although EFT is retired. These objects survive account deletion. → Code (drop the insert policy; non-destructive cleanup plan).

**D-M7. Production schema is not reproducible from migrations.** Base tables exist only in `schema.sql`. The `create trigger require_verified_card_order` line has no `drop … if exists` guard (`schema.sql:1582`), so `schema.sql` is not safely re-runnable. This makes RLS review and disaster recovery depend on the live DB. → Code (baseline migration generated from live, read-only diff first).

**D-M8. Free-text order notes may capture special personal information.** Notes (≤ 500 characters, `schema.sql:1510-1512`) are shown to staff and kept with orders. Allergies, health or religious dietary needs are POPIA s26 special information. No notice or minimisation exists. → Code (helper text) + attorney review.

#### Low

**D-L1. Push notification text sends the customer's name to Google FCM.** `order-push/index.ts:199`. Prefer order number only. *POPIA s10/s72.*

**D-L2. The public `menu-images` bucket allows listing.** The select policy for anon/authenticated (`schema.sql:1278-1283`) lets anyone list all objects. Public buckets do not need a select policy to serve files. Low impact (menu photos only).

**D-L3. Customers can overwrite `profiles.email`.** `profiles_update_own` (`schema.sql:1086-1092`) does not restrict columns. `profiles.email` can drift from `auth.users.email`. Any admin view that trusts `profiles.email` could be misled.

**D-L4. The password policy is enforced only on the client (≥ 8 characters).** `customer-account.ts:31, 59`. The server-side Supabase password policy and leaked-password protection are not verified.

**D-L5. The FCM error body is logged in full.** `order-push/index.ts:290` may log token-related details in Supabase function logs.

**D-L6. `profiles` has no insert-time validation of `full_name`/`phone`** beyond client checks (`handle_new_user` copies metadata as-is, `schema.sql:35-41`).

**D-L7. The draft reuse check does not compare items.** `prepare_card_checkout` returns an existing draft when the type, total and address match (`schema.sql:1435-1447`). A reused `client_request_id` with different items but the same total would return the old draft. Clients currently derive the ID from a fingerprint that includes the items (`checkout-client.tsx:131-136`), so the risk is theoretical.

**D-L8. Dev dependencies and transitive packages have high advisories:** `postcss`, `sharp`, `nanoid`, `source-map-js` (see D-I3).

#### Informational

**D-I1.** `peri_q_app/android/app/google-services.json` is committed. Firebase client config is not secret, but the API key should be restricted in Google Cloud.
**D-I2.** `hs_err_pid23492.log` (JVM crash log, 939 lines) is committed at the repo root. It contains local environment variable names and paths. No secrets were found by keyword search. It should be removed from the repo.
**D-I3.** Full `pnpm audit --prod` result: **20 advisories: 5 critical, 9 high, 5 moderate, 1 low**. Packages: `next` (critical/high/moderate/low; patched ≥ 16.4.1), `sharp` (high; ≥ 0.35.5), `postcss` (high/moderate; ≥ 8.5.23), `nanoid` (high; ≥ 3.3.18), `source-map-js` (high; ≥ 1.2.2).
**D-I4.** `flutter pub outdated`: 43 upgradable dependencies are locked to older versions, and 12 are constrained by `pubspec.yaml`. Examples: `supabase` 2.14.0 → 2.16.5, `realtime_client` 2.11.0 → 2.13.2, `postgrest` 2.8.0 → 2.9.1, `storage_client` 2.6.0 → 2.8.1. `path_provider_android` is intentionally overridden. Dart has no built-in vulnerability audit; no known-vulnerability check was possible.
**D-I5.** `GET /api/yoco/checkout` reveals whether the site runs in `test` or `live` mode (`route.ts:24-25`). Low value to an attacker.
**D-I6.** `require_verified_card_order` refers to statuses (`confirmed`, `out_for_delivery`) that the `orders.status` check does not allow (`schema.sql:1577` vs `643-645`). Harmless, but out of date.
**D-I7.** The `is_admin()` RPC is callable by anon (default execute). It returns false for anon. Harmless.
**D-I8.** **Backup/recovery is not verified.** No restore runbook was found in the repo. `tools/staging-rehearsal` exists for migration rehearsal only.
**D-I9.** **Logging is minimal and avoids PII** in the website routes (`route.ts:158, 191, 197`; `webhook/route.ts:106`). That is good. Provider log retention (Vercel/Supabase) is unknown.
**D-I10.** **Input validation:** server-side length and enum checks in the RPCs. The name/phone format is validated only by the website client (`customer-account.ts:12-18`). React escapes output. No `dangerouslySetInnerHTML` was found in the pages reviewed.
**D-I11.** **Copyright/IP:** fonts are under the OFL (`assets/fonts/OFL.txt`, `website/app/fonts/OFL.txt`). Menu text names third-party drink brands (Coca-Cola, Fanta, Appletiser, etc.), which is nominative use. The owner should confirm ownership or licence of food photos, plate cut-outs (`tools/plate-cutouts`) and the logo. `[[PLACEHOLDER: image/logo ownership confirmation]]`
**D-I12.** **Cybercrimes Act:** no specific provider obligations were identified for a restaurant. A breach or incident response procedure (useful for POPIA s22 and any reporting decision) does not exist.

---

## E. Separation of work

### E.1 Fixable in code (once approved)
- Upgrade `next` and the transitive packages (D-C1, D-I3). Refresh Flutter dependencies (D-I4).
- Correct the privacy policy facts (FCM, operators, website scope, storage) (D-H1). Add terms/privacy links and a short collection notice at signup and checkout.
- Replace cascade-delete with anonymisation in `delete_own_account`, keeping order and payment rows (D-H2). Add a website self-service delete (D-H3).
- Allergen/ingredient fields and UI, with a general allergen warning (D-H4), once the restaurant supplies the data.
- Rate limiting on `/api/yoco/checkout`; Supabase anon sign-in limits (D-M1).
- Scheduled purge of stale `checkout_intents` and anonymous users (D-M2).
- Admin audit log; restrict admin-updatable order columns; MFA for admins (D-M3).
- Security headers (D-M4).
- Handle `refund.succeeded` and record refunds/cancellations (D-M5).
- Drop the legacy `payment_proofs_owner_insert` policy; plan proof cleanup (D-M6).
- Baseline migration from the live schema (D-M7).
- Low items D-L1 to D-L7; remove `hs_err_pid23492.log` (D-I2).
- Consent/acceptance records table (policy version + timestamp).
- Compliance docs `docs/compliance/02`–`10`.

### E.2 Information the restaurant must supply
- Directors (COR39 page 3); trading name ↔ company relationship; confirmed physical trading address (Rd vs Willows).
- Information Officer (and deputies): name, email, phone.
- Official contact details for privacy requests and complaints.
- Certificate of Acceptability details; VAT status.
- Allergen and ingredient data for every menu item; whether any halaal or similar claims are certified.
- Actual refund, cancellation and delivery practice (cut-off times, delivery area, who pays when an order fails).
- Who has admin access and from which devices.
- Ownership/licence of photos, logo and brand assets.
- Copies or confirmation of acceptance of Supabase, Vercel, Yoco and Firebase terms/DPAs.

### E.3 Decisions that need an attorney
- Retention periods for orders, payment records, drafts, anonymous accounts, support messages and logs (with the accountant for tax).
- Whether ECTA s42 cooling-off applies and how to word the refund, cancellation and payment terms.
- Cross-border transfer basis (s72) for Supabase EU, Vercel and Google.
- Whether a PAIA manual is required now or an exemption applies.
- Treatment of special personal information in order notes.
- Allergen and food-information obligations for a non-prepacked food business.
- Whether a cookie/storage consent banner is required.
- Wording of the privacy policy, T&Cs, complaints procedure and PAIA manual.

### E.4 External registrations or approvals
- Information Officer registration with the Information Regulator.
- Certificate of Acceptability (R638) from the municipal environmental health office, if not already held.
- Operator agreements / DPA acceptance with Supabase, Vercel, Yoco and Google.
- Yoco: confirm the live webhook subscription includes refund events (if D-M5 is implemented).
- Google Play: Data Safety form must match the corrected policy (FCM, account deletion).
- Supabase dashboard: enable admin MFA, leaked-password protection and anon sign-in rate limits.

---

## F. Proposed implementation plan (small, reviewable stages)

Each stage is one branch/PR. Each is additive and non-destructive (no `drop table`, no data deletion without an approved retention decision). None of them changes the database provider, auth, payment provider or architecture. Every DB change ships as a new migration, rehearsed with `tools/staging-rehearsal` first.

| # | Stage | Affected files | DB objects | Risks | Depends on |
|---|---|---|---|---|---|
| **0** | **Urgent dependency patch** (pulled forward because of D-C1) | `website/package.json`, `website/pnpm-lock.yaml` | — | Next 16.2 → 16.4 behaviour changes; must run website tests and a Vercel preview | Approval only |
| **1** | **Legal documents (drafts with placeholders)** | `website/app/privacy-policy/page.tsx`, `terms-and-conditions/page.tsx`; new `website/app/{paia-manual,cookie-policy,refund-policy,cancellation-policy,payment-policy,complaints}/page.tsx`; footer links in `components/site-footer.tsx`; app links in `peri_q_app/lib/src/core/external_links.dart`, `privacy_and_support_screen.dart`; `docs/compliance/02`–`05` | — | Publishing unreviewed legal text. Mitigation: mark it as a draft and get attorney sign-off before deploy. | E.2/E.3 inputs |
| **2** | **POPIA consent and privacy rights** | Signup/checkout UIs (`checkout-client.tsx`, `account-client.tsx`, `peri_q_app/lib/src/screens/{auth_screen,checkout_screen}.dart`) | New `policy_acceptances(user_id, document, version, accepted_at)` with owner-insert/read RLS; possibly `privacy_requests` | Adds checkout friction; RLS mistakes. Mitigation: RLS tests. | Stage 1 versions |
| **3** | **Account and data management** | `website/app/account/*`, `delete-account/page.tsx`, `lib/customer-account.ts`; app `profile_screen.dart` | Replace `delete_own_account` (anonymise PII on `orders`/`checkout_intents`, detach `user_id`, delete profile/push/proofs); change `orders.user_id` FK to `on delete set null` (needs nullable `user_id` and RLS review); purge job for drafts/anon users (pg_cron) | **Highest DB risk**: an FK change on `orders`, and RLS on null owners. Must be rehearsed. The retention period needs an attorney. | E.3 retention decision |
| **4** | **ECTA checkout review** | `checkout-client.tsx`, `checkout_screen.dart`, `cart` screens | — | UX change in the payment flow; regression risk to the recently merged in-app payment sheet | Stage 1 |
| **5** | **Yoco payment hardening** | `website/app/api/yoco/{checkout,webhook}/route.ts`, `website/lib/yoco.ts`, tests | `payments.status` gains `refunded` (additive check change); optional `refunds` table; rate-limit store | Breaking a working payment path. Mitigation: test-mode end-to-end run and webhook replay tests. | — |
| **6** | **Database security** | `peri_q_app/supabase/migrations/*` (new baseline + hardening), `schema.sql` | Live read-only RLS/grant diff first; drop legacy `payment_proofs_owner_insert`; `menu_images_public_read` scoped; column-limited admin updates (or audit trigger); `admin_audit_log` table; `profiles.email` guard; idempotent trigger creation | Admin workflows may break if column limits are too strict | Supabase MCP access or a dashboard SQL export |
| **7** | **Food information** | `menu_items` UI on web and app; admin item editor `admin_menu_item_editor_screen.dart` | Additive columns `menu_items.allergens text[]`, `ingredients text`, `allergen_note text` | Wrong data is worse than none. Data must come from the kitchen. | E.2 allergen data |
| **8** | **Complaints** | New complaints page; app support screen | Optional `complaints` table with owner RLS | Handling SLA must be agreed | Stage 1, owner process |
| **9** | **Compliance admin** | App admin screens (privacy requests, complaints, audit log view) | Read views over Stage 2/3/6/8 tables | Scope creep. Keep it minimal. | Stages 2, 3, 6, 8 |
| **10** | **Ownership and business information docs** | `docs/compliance/06`–`10`; business info section in footer/T&C; `website/lib/site.ts` | — | Publishing unconfirmed company data | E.2 inputs |

**Recommended order:** 0 → 6 (read-only live check only) → 5 → 1 → 2 → 3 → 4 → 7 → 8 → 9 → 10.

---

## G. Approval requested

Phase One is complete. **Nothing has been implemented.** Before Phase Two starts, the business owner needs to:

1. Approve or amend the stage order in §F, especially whether Stage 0 (Next.js security upgrade) goes first.
2. Supply the E.2 information, or approve placeholders being used in draft legal pages.
3. Engage an attorney for the E.3 decisions. Stage 3 (deletion/retention) should not start without a retention decision.
4. Authorise read-only access to the live Supabase project (Supabase MCP `/mcp` authorisation or a dashboard export), so that live RLS and grants can be compared with this audit.
