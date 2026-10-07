# Final Production Audit

Audit date: 18 July 2026  
Scope: Flutter/Dart source, Supabase schema and policies, Android release configuration, assets, dependencies, tests, documentation and generated release outputs.

## Critical

- **Fixed in source — client-controlled prices and non-atomic orders.** The old client inserted `orders` and `order_items` separately and supplied totals/unit prices. `public.place_order(...)` now validates the authenticated user, store hours, fulfilment mode, payment method, current menu availability, add-ons, delivery fee and expected total, then writes the order atomically. Direct customer insert policies were removed.
- **Fixed in source — customer role escalation.** The former profile policy allowed an owner of a profile row to update any column, including `role`. Inserts now require `role = 'customer'`, and a trigger rejects non-admin role changes.
- **Fixed in source — fake release signing.** Release builds no longer use the debug key. A real upload key can be loaded from ignored `android/key.properties`; without it, the bundle is deliberately unsigned.
- **Fixed in source — placeholder Android identity.** `com.example.simple_phone_test` was replaced with `za.co.rastasperiq.ordering`. The owner must confirm this ID has not already been reserved elsewhere before creating the Play app; an existing registered Play application ID must never be changed.
- **Owner action required — apply `supabase/schema.sql`.** Until the updated schema is applied to the production Supabase project, the new app cannot place orders, upload EFT proofs, or complete account deletion through the new secure RPCs.

## High priority

- **Fixed:** duplicate order taps are blocked in the checkout UI, and retries reuse a server-enforced idempotency key.
- **Fixed:** checkout now preserves the cart and shows a friendly error when persistence fails; success is shown only after the server returns the stored order.
- **Fixed:** store hours, pickup availability, delivery availability and the trusted delivery fee are enforced in both the UI and database.
- **Fixed:** in-app account deletion removes private proof files first, then deletes the Supabase user; profile and orders cascade.
- **Fixed:** EFT proof upload now uses the Android system picker, accepts only JPG/PNG/WebP/PDF up to 5 MB, and stores files in a private bucket.
- **Fixed:** payment proofs are no longer implied as a dead-end feature; the confirmation screen provides a real retryable upload path.
- **Fixed:** no `.env` file is bundled as a Flutter asset. Production values must be supplied with `--dart-define`; service-role/server keys remain forbidden.
- **Fixed:** release minification, resource shrinking, Dart obfuscation, R8 mapping and symbol generation are configured and verified by a release build.
- **Owner action required:** create and securely back up the upload key, publish the privacy policy, configure SMTP/password-reset redirects, and supply final support/business details.

## Medium priority

- **Fixed:** last successful menu data is cached locally and clearly marked stale when used offline; pull-to-refresh and resume refresh are supported.
- **Fixed:** Supabase realtime order changes refresh active orders without polling; order lists are bounded to 100 records.
- **Fixed:** raw backend errors are no longer shown in checkout, proof upload, startup, or admin image-upload paths.
- **Fixed:** legacy sample customer name/phone defaults were removed and are cleared if present in existing preferences.
- **Fixed:** responsive home grids fall back to one column on narrow/large-text layouts; menu/home have useful empty and offline states.
- **Fixed:** remote images are decode-sized, labelled for accessibility, and retain loading/error fallbacks.
- **Fixed:** customer name, phone number, saved addresses and delivery notes are stored with platform-backed secure storage. Existing plaintext preference values are migrated once and removed; non-sensitive UI preferences remain in SharedPreferences. Android backup and device-transfer extraction are disabled/excluded for app preferences.
- **Known risk:** file-picker 11 requires AGP 9 built-in Kotlin while current Supabase `app_links` still applies KGP. File-picker 10.3.10 is intentionally retained; Flutter emits a future-migration warning, not a current build failure.

## Low priority

- The official brand PNG is 438,135 bytes. It was retained unchanged because destructive logo recompression could degrade the supplied brand master; it is not a major contributor compared with Flutter native libraries.
- Push notifications are not configured. Order state remains available in-app and notifications are not required for order success. FCM can be added later when the owner has a Firebase project and server-side notification trigger.
- Tablet layouts are responsive but have not been visually approved on physical tablets.

## Owner action required

1. Review and apply `supabase/schema.sql` in a staging Supabase project, test it, then apply it to production with a backup/change window.
2. Confirm `za.co.rastasperiq.ordering` is the permanent Play application ID.
3. Generate and back up the upload keystore; create ignored `android/key.properties`; rebuild the signed AAB.
4. Publish the final privacy policy and account-deletion page at public HTTPS URLs.
5. Replace all placeholders in the release documentation with legal business name, address, support email and public URLs.
6. Run the manual QA matrix on real Android devices and the required Play testing track.
7. Configure Supabase production Auth (anonymous + email), SMTP and password-reset/deep-link URLs.
8. Complete Play Console Data Safety, content rating, app access, target audience and developer verification declarations.

## Verification boundary

Automated analysis, tests, debug build, release build, size analysis and bundletool validation were run locally. No Android emulator or physical Android device was connected. Production Supabase migrations and Play Console actions were not executed.
