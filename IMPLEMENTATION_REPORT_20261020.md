# Peri-Q implementation and verification report

20 October 2026. Repository baseline: `b20cbd3ddced8ab3021b5c3b0178da1a899f95dc` on `main`. Working branch: `codex/card-checkout-recovery-and-polish`.

**Release status: incomplete.** The source improvements are tested, but a complete production payment journey has not been verified. The production schema lacks the card-checkout draft objects already required by the original source. No production database or credentials were changed. Vercel metadata confirms that production `YOCO_SECRET_KEY`, `YOCO_WEBHOOK_SECRET`, `SUPABASE_SERVICE_ROLE_KEY` and URL values are already present; their secret values were not decrypted or used locally, and preview lacks the server payment secrets. APK generation failed at native dependency resolution; details and the unmerged draft PR are recorded below.

## A. Implementation summary

The project is an existing Flutter/Dart Android app and a Next.js 16/React 19 website with shared Supabase authentication, menu, settings and orders. It already contained hosted Yoco checkout, signed webhooks, payment records and card-only migrations; this implementation repairs that work rather than replacing the architecture.

- Website: replaced provider advertising and technical setup messages with card-payment wording; simplified the single payment method; disabled unavailable checkout; improved labels, autofill, input bounds, selected/disabled semantics and status announcements.
- Payment return: database status is authoritative. A browser success/failure query parameter cannot confirm payment. Slow requests do not overlap; visibility/connection recovery retries safely. A delayed payment no longer clears a newer cart.
- Mobile: neutral card labels, matching form validation/autofill, reduced-motion checkout progress, removal of a no-op payment-selection helper, and a validated public `CARD_CHECKOUT_URL` compile-time setting so staging builds can use a matching staging payment backend. Historical payment enums and stored orders remain readable.
- Shared visual work: aligned charcoal/warm-white palette, quieter surfaces/shadows, clearer text contrast, visible red keyboard focus, tabular prices, balanced headings, and precise short transitions. Removed the decorative hero grid and glow.
- Backend: rejects a paid checkout before returning a saved link, validates processing mode, bounds the provider request, avoids recreating uncertain sessions beyond the provider's idempotency window, records correct mobile metadata and hides upstream diagnostics from customer errors.
- Webhook: retains failed-event audit records without creating kitchen orders, stores minimal event details, removes unreachable failure branches and redundant status writes, and requires the finalization RPC to return a confirmed payment before acknowledging success.
- Database: inspected the live schema read-only. No migration was created or applied in this pass; trusted pricing/finalization remain in the repository's existing SQL functions.

## B. Yoco payment integration

Both clients prepare a private checkout draft with `prepare_card_checkout`. Its existing SQL validates ownership/session, store hours, fulfilment, products, add-ons and server prices. The server reads the trusted draft total, creates hosted checkout with the Checkout API and an idempotency key, then saves linkage. Android opens the external browser and polls its authenticated Supabase session. The website polls the draft on return. The browser never supplies authoritative payment status.

The webhook verifies raw-body HMAC and timestamp, matches amount/ZAR/test-or-live mode/checkout linkage, then calls the existing service-role-only `finalize_card_checkout`. That RPC locks the draft and creates the paid order/items transactionally; duplicate deliveries reuse the order. Fully processed events are acknowledged without replaying writes. Failure writes cannot downgrade paid/refunded drafts. Failed drafts are audited without inventing orders.

Official documentation inspected: [create checkout](https://developer.yoco.com/api-reference/checkout-api/checkout/create-checkout), [idempotency](https://developer.yoco.com/docs/checkout-api/idempotency), [webhook verification](https://developer.yoco.com/docs/api/webhooks/verifying-events), and [payment events](https://developer.yoco.com/api-reference/checkout-api/webhook-events/payment-notification). Idempotency keys expire after 24 hours; uncertain unsaved sessions older than 23 hours fail closed for reconciliation instead of creating another charge.

Application screens use neutral card-payment wording. Provider identifiers remain in internal code and configuration. The hosted payment page can retain its provider-controlled branding. **Card-only hosted payment methods require merchant confirmation:** the documented creation request has no payment-method filter, and payment event docs include `instant_eft`. No unsupported API parameter was invented.

Automated scenarios tested include signature tampering/staleness, wrong amount/currency/mode, wrong owner, duplicates, persistence failure, trusted session creation, stable request key, late failure, paid-checkout retry, expired idempotency protection, neutral errors, return query tampering, interruption and cart preservation. These are mocked server/client tests, not merchant sandbox transactions or proof of live database concurrency.

## C. Dead-code cleanup

Removed the one-option website radio/selection mapping, its setter, an unreachable return after throw, mobile no-op payment selection, unreachable webhook failure handling after the earlier failure return, duplicate paid-status writes, unreferenced Yoco configuration/mode helpers, an unused test import, and decorative hero grid/glow markup/styles. Reduced customer-visible implementation explanations.

No Paystack SDK/integration was found in the inspected source. No dependency was removed speculatively. Historical cash/EFT/card enum values, proof-upload access, records and reconciliation compatibility were retained. No legacy transaction was renamed to Yoco. The Flutter SDK refreshed four transitive lockfile entries required by its test SDK; no new application runtime package was added.

## D. Design skill usage

All five repositories were cloned into temporary tooling, inspected and used within their relevant capabilities.

| Skill / inspected revision | Applied contribution | Limit or decision |
| --- | --- | --- |
| Apple design `914b6a3` | Lead review; accessibility, layout, typography, color, buttons, loading, feedback, motion and cross-platform references; clear payment states, shared palette, focus and native conventions | Apple foundations applied to Android/web; no imitation of iOS chrome. Final review does not certify the untested live payment flow. |
| Impeccable `374a0e1` | Context launcher, craft-floor/polish guidance and detector; simplified checkout, removed template decoration and excessive button shadows | Refined the established brand rather than inventing product claims. Detector's sole advisory was the decorative hero grid, which was removed. |
| Transitions.dev `7ec0b0b` | Inspected documented motion tokens and low-overhead/reduced-motion guidance; shared quick duration/easing in existing CSS | No full transition snippet copied and no runtime installed. Frequent checkout actions retain restrained feedback. |
| GSAP skills `aed9cfd` | Performance guidance: transform/opacity over layout motion; no broad layer promotion | No GSAP runtime added: existing CSS/Flutter motion is sufficient, and a second engine brings no meaningful benefit. |
| Make Interfaces Feel Better `35545ea` | Typography wrapping/smoothing, stable price numerals, explicit transition properties, hit-area/state review and motion restraint | Apple/Material conventions take precedence over decorative press/entrance animation. |

### Apple-led final review

The checkout's job is clear: confirm food, fulfilment and amount before external card payment. Brand remains the flame wordmark and Peri red, with quiet task surfaces. Corrected findings: provider jargon and ambiguous payment feedback; missing keyboard focus coverage; low-opacity secondary web text; misleading store availability when settings are missing; and motion ignoring reduced-motion preferences in the mobile submit control.

Selected web token contrast checks: Peri red `#C8240B` against white **5.66:1**, ash `#4A4A4A` against warm white `#FFF9F4` **8.49:1**, and charcoal `#1A1715` against warm white **17.08:1**, calculated from actual values. Existing mobile theme/large-text tests passed. Remaining review boundaries: no physical-device TalkBack/keyboard/lifecycle test, no complete native screen redesign, no low-end-device performance measurement, and no live hosted card-entry review. This is a verified checkout/shared-system refinement, not a claim that every requested screen received a complete new design.

## E. Testing results

| Check | Actual outcome |
| --- | --- |
| Baseline website suite | 42 tests passed |
| Baseline native suite | Toolchain initially absent; not run before edits. Final tests do not retroactively establish a native baseline. |
| Final website suite | 54 tests passed, 7 files |
| Website ESLint / TypeScript | Passed; build also type-checks |
| Website production build | Passed; Next.js generated all existing routes including dynamic checkout/webhook/payment/order endpoints |
| Flutter analysis | Passed, no issues after removing a redundant pre-existing test import |
| Changed Dart file formatting | Passed for changed Dart files; final config/test files formatted as well |
| Flutter suite | 55 tests passed, including phone/landscape, light/dark and existing authentication/menu/order checks |
| Mobile visual fixtures | Checkout/customer-shell rendered at 360×800 and 800×360 in light/dark with real Roboto/Material font files |
| Browser checks | 24 combinations: eight pages at widths 390, 768, 1440; all HTTP 200, no horizontal overflow, uncaught page exceptions, visible provider name or undefined text |
| Mechanical design detector | One decorative-grid advisory; grid removed |
| Production schema | Read-only inspection confirmed missing `checkout_intents`, `prepare_card_checkout`, `finalize_card_checkout`; `place_order` remains |
| Merchant test/live payments | Not run; production secret names exist, but no merchant test environment/secret values were used locally |
| Database concurrency / migration / production RLS execution | Not run against a disposable staging database; source inspection and mocks are not substitutes |
| Android APK | Failed: HTTP 403 for Maven `org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3`, required by `file_picker` → Flutter embedding → AndroidX Window |

Browser checks used a local production build without live Supabase/merchant server environment values, so they verify public/unconfigured/error layouts, not authenticated ordering. Existing simulated tests that mirror RLS/cart rules are smoke tests; they do not prove production authorization.

## F. APK download

**No APK is available. No install or launch test was performed.**

A real debug APK build was attempted with Java 21, Android API 36/build tools 36.0.0, NDK 28.2.13676358, Flutter 3.47.7 and the existing `za.co.rastasperiq.ordering` package ID. Only the connected project's public Supabase URL/key were used in an external local defines file; no server secret or signing key was included. The attempted configuration used the existing connected project, not a separate staging database.

Toolchain setup issues were diagnosed and corrected, including Flutter's bot probe, archive ownership, Java proxy/certificate configuration and the SDK CLI launcher. A cold build timed out after dependency setup; the cached retry compiled the Flutter kernel but failed at `:file_picker:compileDebugKotlin` because Maven returned HTTP 403 for `org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3`. The Flutter embedding/AndroidX dependency chain requires it. It was not replaced with an arbitrary version to force a build.

To finish: run the documented debug build in a CI/development environment that can resolve that dependency. Use a staging defines file containing `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, and `CARD_CHECKOUT_URL=https://<staging-web-host>/api/yoco/checkout/`. Then verify the APK signature/package, install on Android and exercise the real browser-return/payment lifecycle. The expected output path is `peri_q_app/build/app/outputs/flutter-apk/app-debug.apk`; that file does not currently exist and is not presented as a download.

## G. Git and merge status

Remote working branch: `codex/card-checkout-recovery-and-polish`, created from baseline `b20cbd3`. Source was retrieved through the authorized GitHub connector because direct cloning lacked credentials. Only deliberate changed paths will be written against the original remote tree; binary assets and unrelated history remain unchanged. Local snapshot-only commit IDs are not remote history. Source commit: `5db79defe91fa347be4b38df40286c99e762817a`. Draft pull request: [#2](https://github.com/MokhethiNyaps/Peri-Q-UI/pull/2). `main` remains at `b20cbd3`; this is not a completed merge or production-ready release. The production schema/payment verification gate is documented in the PR. The automatic Vercel preview for the source commit completed successfully; no manual deployment was triggered. The follow-up commit adds the staging endpoint configuration, formatting, shared design documentation and this final report. No merge was attempted because the full release gates remain unresolved; this follows the brief’s prohibition on merging known-breaking work or automatically changing production.

## H. Outstanding manual steps

1. Approve a staging/production rollout only after the migration is rehearsed against the current schema. Production mutation was explicitly excluded without separate authorization by the supplied brief.
2. Verify the existing production credentials and securely configure a separate staging test key and matching webhook; confirm the hosted checkout only offers cards and complete merchant/domain verification where required. Never send secret keys in chat.
3. Complete end-to-end staging card payments and database concurrency/authorization tests, then supervised live reconciliation. Verify old installed clients receive clear update instructions because the card-only migration disables their old ordering RPC.
4. Build the APK in an environment with access to the blocked Maven artifact, then test it on a real Android device; provide existing protected signing credentials only for a later production-signed release, increment Play versionCode against the actual published version and use a test track first.

Deployment order, canonical webhook URL, environment variable names and rollback/recovery are in `MANUAL_SETUP_AND_LAUNCH_CHECKLIST.md`.

## I. Remaining limitations

The complete definition of done is not met until live/staging payment verification, merchant card-only configuration, safe database rollout, a successful APK build and APK installation checks are complete. Existing SQL migration additions are not all rerunnable and have no tested down migration. No production migration, credential change, store release, manual deployment or real card charge was made. Refunds/reconciliation beyond existing historical support were not redesigned. Physical Android deep-link/back/keyboard interruptions, low-end performance and a complete every-screen visual overhaul remain unverified/incomplete.

The first Flutter invocation was automatically rejected for an environment-metadata probe. Source inspection identified Flutter's Azure bot detector; subsequent authorized CI-mode commands short-circuited that probe. Java/Android/browser dependencies required local tooling and network fixes; none of that tooling or temporary public-key build configuration is part of the repository patch.
