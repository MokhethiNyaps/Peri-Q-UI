# Peri-Q continuation — what was finished, what is left

Written 20 October 2026 from a cloud workspace (Node 22, PostgreSQL 16.2). This is a companion to
`IMPLEMENTATION_REPORT_20261020.md` and `MANUAL_SETUP_AND_LAUNCH_CHECKLIST.md`, which live on the
`codex/card-checkout-recovery-and-polish` branch (PR #2).

**Verdict: the implementation is code-complete and now database-verified, but the release is still not
finished.** What remains cannot be done from this kind of environment: it needs a staging Supabase
project, merchant (Yoco) test credentials, the Flutter/Android toolchain, and a physical device. Section 5
is the copy-paste brief for a local agent; section 6 is the short list of things only you can do.

---

## 1. Repo state found

| Item | State |
| --- | --- |
| `main` | `b20cbd3ddced8ab3021b5c3b0178da1a899f95dc` (unchanged) |
| PR #2 head | `0aff26cd975ebbe4cef35123f70ed2b98621bd51`, draft, mergeable, 2 commits, clean vs `main` |
| Branches | `main`, `codex/card-checkout-recovery-and-polish`, this session branch |
| Differences | 32 files, +701/−314 — website checkout/webhook/payment UI, Flutter payment config, shared design, docs |

The PR's changes are present and match the description in the report: neutral card wording, database-authoritative
payment status, non-overlapping polling, cart-preservation on late payments, bounded provider calls with
idempotency-window handling, webhook finalisation gated on the RPC result, and a validated public
`CARD_CHECKOUT_URL` define.

## 2. What was verified in this session (reproduced, not re-quoted)

Everything below was executed here; none of it is copied from the earlier report.

**Website on the PR tree** (`git archive` of `0aff26cd`, `pnpm 11.9.0 install --frozen-lockfile`):

| Check | Result |
| --- | --- |
| `pnpm test` | **54 tests passed, 7 files** |
| `pnpm lint` (ESLint 9) | clean |
| `npx tsc --noEmit` | clean |
| `pnpm build` (Next.js 16.2.12, no merchant env) | compiled, TypeScript finished, **12 static pages + 4 dynamic routes** |

**Database rehearsal** — PostgreSQL 16.2, prior schema reconstructed from `main`'s `schema.sql` (everything
before the checkout-draft block, which is exactly the production shape the earlier session found: `orders`,
`payments`, `yoco_webhook_events`, `place_order`, and no `checkout_intents` / `prepare_card_checkout` /
`finalize_card_checkout`):

| Check | Result |
| --- | --- |
| `20261017000000_card_only_checkout.sql` applied to the prior schema | applies cleanly, creates both tables, both functions, RLS and the fulfilment trigger |
| Behaviour suite (`tools/staging-rehearsal/rehearsal_test.py`) | **24 passed, 0 failed** — covers anon/owner/other-customer RLS, direct-write blocking, trusted pricing and add-ons, unavailable items, delivery fee, cash rejection, draft idempotency, amount/mode/payment-id/unknown-checkout mismatches, one paid order with copied items, duplicate replay, **concurrent double finalize → exactly one order**, forged paid orders, admin-only status moves, `place_order` disabled, payment audit ownership |
| Historic data preservation (`historic_data_check.sh`) | 3 orders / 3 items / 1 payment / 1 webhook event identical before and after the migration (row hash compared) |
| Consolidated `schema.sql` from scratch | applies cleanly and contains the same guard |
| Migration applied twice | fails at `multiple primary keys for table "checkout_intents" are not allowed`; the single transaction rolls back, so a failed rerun leaves the migrated database intact — but it must be recorded in Supabase migration history, not re-run |
| Older Yoco migration re-run **after** the card-only one | succeeds and silently restores the pre-card-only `place_order` body; `require_verified_card_order` still blocks the inserts, so no unpaid order is created, but the friendly "pay by card" error is lost — apply migrations in timestamp order only |

The harness is committed under `tools/staging-rehearsal/` so these checks can be repeated (locally or
against a disposable staging project) without a payment provider or credentials.

## 3. Defect found and fixed

**Reusing a checkout request identifier after the basket or fulfilment changed returned the original draft
and its price.**

`prepare_card_checkout` returned the existing draft as soon as `(user_id, client_request_id)` matched,
without re-checking the request. The web client hashes items, fulfilment, total, name, phone, address and
owner into its identifier, so it rotates correctly. The mobile client only resets its identifier on cart
mutations — changing pickup to delivery (or the address) between attempts reuses it. Measured on the real
function before the fix:

```
prepare(... 'pickup',   45.00, 'mobile-reuse-01') -> {"id": "12ba3403-…"}
prepare(... 'delivery', 75.00, 'mobile-reuse-01') -> {"id": "12ba3403-…"}   # same draft
stored row: pickup | 45.00 | 4500 | (no address)
```

The customer would be shown R75 and charged R45 for a pickup order with no address.

Fixed in `peri_q_app/supabase/migrations/20261017000000_card_only_checkout.sql` (and the same function in
`peri_q_app/supabase/schema.sql`): the draft is only reused when `order_type`, `total_price` and the
delivery address still match, otherwise it raises `Checkout details changed. Please restart checkout.`
(`errcode P0001`). Unchanged retries still return the same draft, so idempotency is preserved. The regression
is covered by the harness (`reused request id is rejected when the fulfilment, address or total changed`).

Both files are byte-identical on `main` and on the PR branch, so this applies cleanly to either.

## 4. Other findings to decide on (not changed)

1. **`checkout_intent_items` has RLS enabled but no policy and no grant for `authenticated`.** No client reads
   draft line items today (the payment page only reads `checkout_intents.payment_status`), so nothing is
   broken — but a future "review your order" screen on the draft will silently return nothing. Add an owner
   policy before relying on it.
2. **`require_verified_card_order` blocks every insert that is not service-role + `yoco` + paid.** That is
   correct for card-only ordering, and it is why a reverted `place_order` still cannot create orders. It also
   means admin-created or imported orders now need a service-role path or an explicit exception.
3. **A draft prepared before closing time can still be paid and fulfilled after closing.** `prepare` returns
   the existing draft before the store-hours check, and `finalize` never checks hours. Money has already been
   taken at that point, so creating the order is the sane outcome — confirm that this is the intended policy.
4. **The migration is not idempotent** (see §2). The `MANUAL_SETUP_AND_LAUNCH_CHECKLIST.md` already warns
   about this; record the version in migration history rather than re-running the file.
5. **Client copy for the new error.** Mobile `_friendlyOrderError` and the web checkout fallback would show a
   generic "check your connection" message. Map `checkout details changed` to "Your order details changed —
   review your order and try again", and reset `_pendingOrderRequestId` in `placeOrder` when the order type
   changed since the last attempt.
6. Housekeeping: `hs_err_pid23492.log` (80 KB JVM crash dump) is committed at the repo root and should be
   deleted and git-ignored.

## 5. Prompt for your local agent

Copy everything inside the block into the local agent. It assumes the repo at
`C:\Users\hp\Desktop\Mokhethi\Peri-Q-UI`, PR #2, and the authorization boundary in the original brief.

```text
Continue the Peri-Q card-checkout release from where the cloud verification session stopped.
Repository: https://github.com/MokhethiNyaps/Peri-Q-UI, PR #2 (draft),
branch codex/card-checkout-recovery-and-polish, head 0aff26cd975ebbe4cef35123f70ed2b98621bd51,
main b20cbd3ddced8ab3021b5c3b0178da1a899f95dc. Fetch first; do not assume these refs are current.

READ FIRST: IMPLEMENTATION_REPORT_20261020.md, MANUAL_SETUP_AND_LAUNCH_CHECKLIST.md, DESIGN.md,
and CONTINUATION_HANDOFF_20261020.md (on branch arena/a3ab8541-peri-q-ui, also in the cloud
session's PR). The handoff records what is already proven so you do not repeat it.

ALREADY VERIFIED — do not redo, do not "fix" without evidence:
- Website on the PR tree: 54 tests / 7 files pass, ESLint clean, tsc --noEmit clean,
  next build produces 12 static + 4 dynamic routes.
- The card-only migration applies cleanly to the real prior schema (orders, payments,
  yoco_webhook_events, place_order; no checkout_intents) on PostgreSQL 16.
- 24 SQL checks pass, including RLS isolation, trusted pricing, forged-order blocking,
  duplicate replay and concurrent double finalize producing exactly one order.
- Historic orders/items/payments/webhook rows survive the migration unchanged.

STEP 0 — bring in the one code change found after that verification.
A defect was found and fixed: prepare_card_checkout returned the existing draft for a reused
client_request_id even when the order type, address or total had changed, so a mobile retry that
switched pickup to delivery could be shown R75 and charged R45. The fix validates the reused draft
and raises 'Checkout details changed. Please restart checkout.' in
peri_q_app/supabase/migrations/20261017000000_card_only_checkout.sql and the matching function in
peri_q_app/supabase/schema.sql. Merge PR #3 (arena/a3ab8541-peri-q-ui -> main; the fix is commit a44ef2e) or cherry-pick commit a44ef2e onto the PR branch. PR #3 touches only files that PR #2 does not,
so it merges into main cleanly before or after PR #2; after merging, run `git merge main` (or rebase) on
the PR branch so the staging tests use the fixed function.
Then: in peri_q_app/lib/src/data/supabase/supabase_order_repository.dart map
'checkout details changed' to a clear message in _friendlyOrderError, and reset
_pendingOrderRequestId in AppController.placeOrder when orderType differs from the previous attempt.
Add a Flutter test for both.

STEP 1 — staging database.
Create a disposable Supabase staging project (free tier). Apply the prior schema, then
supabase/migrations/20261012155629_yoco_payments.sql, then 20261017000000_card_only_checkout.sql, in
timestamp order, and record them in migration history. Never re-run 2026-10-12 after 2026-10-17: it
silently restores the old place_order body. Creating a staging project and applying these migrations
to it is authorised; production is not (see boundary). Afterwards run the rehearsal suite against it
with tools/staging-rehearsal/rehearsal_test.py (REHEARSAL_DSN=...), after seeding two test users and
the kota-1/off-1 menu rows. Do not run stub.sql against Supabase.

STEP 2 — staging website and merchant test payments.
Deploy the PR branch to a staging Vercel project (separate from production) with
NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY / NEXT_PUBLIC_SITE_URL pointing at
staging, and server-only SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, YOCO_SECRET_KEY (sk_test_) and
YOCO_WEBHOOK_SECRET. Register /api/yoco/webhook/ with Yoco for that host and use the secret Yoco
returns for that registration — a webhook secret is bound to its endpoint. Keep every secret out of
chat, source, commits, logs and builds. Then run, recording each outcome: successful payment,
declined card, cancellation, browser back / interrupted return, late webhook, duplicate webhook,
two concurrent webhooks, double tap on Pay, cart changed after failure, wrong owner, wrong amount,
wrong currency, wrong mode, expired intent. Accept only a database-confirmed paid order; a success
query parameter is not proof. Confirm exactly one order and one fulfilment/notification, correct
totals, and that a newer cart survives. Do not take a live payment.

STEP 3 — Android.
Install the supported Flutter (3.47.7/Dart 3.13.5 was used previously), Java 21, Android API 36 /
build-tools 36.0.0, NDK 28.2.13676358. Set CI=true for Flutter. Run flutter pub get, flutter analyze
and flutter test. Then build:
  flutter build apk --debug --dart-define-from-file=<private staging json>
containing only SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY and
CARD_CHECKOUT_URL=https://<staging-host>/api/yoco/checkout/. Package stays
za.co.rastasperiq.ordering; output peri_q_app/build/app/outputs/flutter-apk/app-debug.apk.
The earlier attempt failed on HTTP 403 for org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3 from
Maven; fix the repository/network access through the approved route, do not swap versions or
disable TLS. Verify package/signature, scan for secrets, install on a device and test: external
browser return, back button, app resume, slow network, payment failure then retry.

STEP 4 — re-run the web gates after any change (tests, lint, tsc, build, plus the browser flow
against the staging deployment), update IMPLEMENTATION_REPORT_20261020.md with what is now verified
by you versus what was verified earlier, and keep PR #2 in draft until migration, staging payment
and APK gates all pass.

BOUNDARY: continued implementation, safe checks, builds and GitHub updates are authorised.
Production migrations or data changes, live credential changes, production deployment, Play
publication and any real card charge need separate explicit approval from the owner — ask, do not
assume. Never fabricate a payment, migration, build, artifact or merge. If a gate is blocked, finish
the independent work and report precisely what is blocked and why.
```

## 6. What you need to do on your side

Ordered; each item is something an environment like this one cannot do.

1. **Decide the cutover and approve the production migration.** Nothing has been applied to production;
   it still lacks the three checkout objects, so deploying the new website *before* the migration would break
   checkout. Migration first, then web, then app update.
2. **Create a staging Supabase project** (dashboard → New project, free tier). Keep it separate from
   `nxzelriapklqaxcxmoys`, which is production.
3. **Get Yoco test credentials**: a test-secret key (`sk_test_…`) and a webhook endpoint registration for the
   staging host (`whsec_…`). Enter them directly into the staging Vercel project's environment variables —
   never into chat, source or a Dart define.
4. **Give the local agent the staging project's URL, publishable key and service-role key** through your own
   password manager / Vercel UI, not this conversation.
5. **Approve the migration files for staging** so the agent can apply them in timestamp order and record them
   in migration history.
6. **Tell users to update** before the cutover: the migration deliberately disables the old `place_order`
   RPC, so previously installed apps cannot create new orders afterwards. Plan an in-app update notice.
7. **Supply production signing credentials** only when you actually want a Play release; check the published
   `versionCode` and bump it (the repo is at `1.0.5+6`) and use a test track first.
8. **Confirm with Yoco/merchant dashboard that hosted checkout offers cards only.** The create-checkout API
   has no per-request payment-method filter, so this cannot be enforced in code.
9. **Merge PR #2 only after the agent reports the migration, staging payment and APK gates as passed.**
   Merging to `main` triggers the automatic Vercel production deployment — sequence it deliberately.
10. Merge the small fix PR **#3** (`arena/a3ab8541-peri-q-ui` → `main`, commit `a44ef2e`) — or have the
    agent cherry-pick `a44ef2e` onto the PR branch — before the staging payment tests, since those are
    exactly the paths it protects. Vercel reports "Deployment was blocked" on that PR rather than a build
    failure: the commit author is not a Vercel team member, and this PR changes no website code. Re-run the
    deployment from the Vercel dashboard after merging, or verify the preview on PR #2, which builds from
    the same website source.

## 7. What this session did not do

No production database, credential, deployment or payment was touched. No Yoco request was made. No
Supabase project was contacted. No Flutter, Dart, Java, Android SDK or Docker was available here, so
`flutter test`, `flutter build apk`, APK signing and device testing were **not** run and no APK exists.
The staging payment scenarios and the merchant-side card-only confirmation remain open, as do the
browser/deep-link/lifecycle checks on a real device.
