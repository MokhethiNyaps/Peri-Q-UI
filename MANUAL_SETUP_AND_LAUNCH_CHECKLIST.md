# Card-payment rollout checklist — 20 October 2026

This replaces the previous checklist's stale cash/EFT instructions. Historical claims in earlier revisions are not evidence that the current card-only flow is deployed.

## Current production gate

Read-only inspection of the connected **Peri Q** Supabase project found `orders`, `payments`, `yoco_webhook_events`, and `place_order`, but no `checkout_intents`, `prepare_card_checkout`, or `finalize_card_checkout`. The source already depends on those objects. Live card-only ordering is not verified or ready to release.

Vercel metadata confirms the production server secret names already exist. Do not paste or replace them merely to repeat setup; verify that their mode and registered webhook match. Preview has only public client configuration, so it cannot currently process payments.

No production migration, credential change, payment, app publication, or manual deployment was performed in this implementation.

## Safe rollout order

1. Prepare a separate staging Supabase project. Copy schema/configuration without private customer data. Confirm a backup and recovery route for production.
2. Compare actual migration history and schema with `peri_q_app/supabase/schema.sql`. Test the existing `20261017000000_card_only_checkout.sql` against a staging copy of the previous schema. Do not apply the entire schema file to production and do not blindly rerun this migration: its policy, primary-key, column, and trigger additions are not all repeatable.
3. Configure a staging website with the matching public Supabase URL/key and server-only `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `YOCO_SECRET_KEY`, `YOCO_WEBHOOK_SECRET`, and staging `NEXT_PUBLIC_SITE_URL`. Do not put server secrets in `NEXT_PUBLIC_*`, Dart defines, chat, or GitHub.
4. Register the canonical HTTPS webhook `/api/yoco/webhook/` with Yoco using the same test key. Verify signed success/failure events and retry behavior. The helper `website/scripts/register-yoco-webhook.ps1` can register the endpoint; save the returned webhook secret securely.
5. Confirm with the merchant dashboard or Yoco support that the hosted checkout only offers cards. The documented create-checkout request has no per-request payment-method filter; the application's card-only UI cannot enforce dashboard settings. Do not invent a parameter or silently reject money already collected by another enabled method.
6. Run staging payment success, decline, cancellation, lost connection, late webhook, duplicate/concurrent delivery, duplicate tap, changed price, wrong owner/amount/currency/mode, expiry, and interrupted mobile lifecycle tests. Confirm one paid order, one fulfilment/notification, correct amount, and reconciliation. URL query strings are not proof of payment.
7. Obtain separate authorization before changing production credentials or applying production migrations. Coordinate the backend cutover and client availability: the card-only migration deliberately disables old `place_order` calls, so previously installed cash-only apps cannot create new orders after cutover. Notify users to update; preserve historical orders, sessions and payment records.
8. Deploy the reviewed backend migration, compatible website/webhook and test the public readiness endpoint, then release the compatible mobile update through a test track. Verify old clients fail clearly. Only enable live payments after merchant approval and a supervised small authorized payment/reconciliation.

## Android testing and release

- Package: `za.co.rastasperiq.ordering`; checked-in version `1.0.5+6`.
- Use Java 21, Android API 36/build tools 36.0.0, and the supported Flutter SDK. This pass used Flutter 3.47.7/Dart 3.13.5 for analysis/tests.
- Build an installable debug test APK with `flutter build apk --debug --dart-define-from-file=<local-test-config.json>`. The file contains only a staging Supabase URL and publishable key.
- Never distribute a test APK with server keys or a payment bypass. A debug-signed APK generally cannot replace a Play-installed app signed with the production key; do not uninstall a live app without considering local data loss.
- Production signing requires the existing protected signing credentials. Check the current Play versionCode and increment it before an actual release. No signing credentials were created and no Play release was submitted.

## Recovery

Keep payments disabled if migration or verification fails. Do not revert to accepting unverified/cash orders as an emergency shortcut. Preserve payment intents, verified events and historical rows for reconciliation. Prefer rolling back the website/client to the last compatible release while investigating; the card-only migration does not provide a tested down migration. Have a DBA prepare a reviewed recovery script and take a backup before production schema changes. Reconcile payments received during any outage before retrying or issuing refunds.

See `IMPLEMENTATION_REPORT_20261020.md` for actual checks and remaining limitations.
