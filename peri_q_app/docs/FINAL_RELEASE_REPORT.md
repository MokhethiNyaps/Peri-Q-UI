# Final Release Report

## Release outcome

The signed Android `1.0.0+1` release with Firebase Cloud Messaging support is
ready for manual APK testing. The AAB is structurally valid and ready for Play
Console Internal testing after the manual Supabase/FCM backend setup in
`docs/FCM_MANUAL_SETUP.md` is completed and an end-to-end notification test
passes.

No existing screen, route, order payload, authentication method, or state model
was removed or redesigned. Email/password registration and sign-in, password
recovery, and **Continue as Guest** remain available. Phone-number
authentication remains removed; phone numbers collected during registration or
checkout are contact and fulfilment information only.

## Release identity

- Package: `za.co.rastasperiq.ordering`
- Version: `1.0.0`
- Version code: `1`
- Compile/target SDK: 36
- Minimum SDK: 24
- Build type: signed release, R8/resource shrinking, Dart obfuscation and split
  debug information
- Firebase project: `rastas-peri-q`
- Build date: 31 July 2026 (Africa/Johannesburg)

## Release artifacts

| Artifact | Size (bytes) | SHA-256 |
|---|---:|---|
| `release/android/rastas-peri-q-v1.0.0-build1-fcm-release.apk` | 54,460,956 | `B2F2724DCC9C6F4AE99341CBCF88EDB2818F7E170D83F2679230C5D4945B9244` |
| `release/android/rastas-peri-q-v1.0.0-build1-fcm-release.aab` | 53,703,594 | `18F3DDB4C2B4DBAFE369E5839CB5287E30F3B2C97F6217943C1FEAE404B92459` |
| `release/android/rastas-peri-q-v1.0.0-build1-fcm-r8-mapping.txt` | 16,849,045 | `152389278FD6CCEE0D015EB6FB355DF420E80AF2929BF1FF27E9FF70EBCC79C2` |
| `release/android/rastas-peri-q-v1.0.0-build1-fcm-dart-symbols.zip` | 3,222,363 | `B77924CF2CB5791AC32AEB2333A34538AB3C156F723D0C912EBFC28B6787136B` |

The ignored `release/android/` directory contains local outputs and is not
committed to Git. Keep the R8 mapping and Dart symbols paired with this exact
AAB.

## Verification evidence

| Gate | Result |
|---|---|
| Formatting | `dart format lib test` completed with no changes |
| Static analysis | `flutter analyze --no-pub` — no issues found |
| Automated tests | `flutter test --no-pub` — all 28 tests passed |
| Edge Function | Deno 2.5.4 formatting and type checks passed |
| Release APK | Built successfully; APK Signature Scheme v2 verified |
| Release AAB | Built successfully; `jarsigner` verified the bundle |
| Bundle validation | bundletool 1.18.3 `validate` passed |
| Manifest | Package `za.co.rastasperiq.ordering`, version `1.0.0` / code `1`, target SDK 36 |
| FCM manifest | `POST_NOTIFICATIONS`, Firebase messaging services, and default channel confirmed |
| Signing identity | Certificate SHA-256: `0BCCBE0AD6A15CD2FEFA9C8E507099259C60BE302ECFD917BA2BFBF28BB218AF` |
| Failure isolation | Tests confirm notification failures never roll back committed order work |

## FCM implementation

- Dedicated Firebase Android app registered for
  `za.co.rastasperiq.ordering`.
- Android 13+ notification permission request and iOS permission-capable Dart
  service.
- `admin_orders` channel at maximum importance with sound and vibration.
- `client_order_updates` channel at high importance with sound and vibration.
- Foreground notifications displayed locally; notification payloads support
  background and normally terminated delivery through the operating system.
- Per-installation FCM token registration, refresh, sign-out cleanup, and
  server-enforced admin/client roles.
- New-order alerts target administrators; server-derived status alerts target
  the customer who owns the order.
- Supabase RLS/RPC migration and an authenticated, idempotent Edge Function
  using FCM HTTP v1.
- No FCM service-account key, Supabase service-role key, or other server secret
  is stored in the app.

## Manual work required before end-to-end FCM testing

1. Run `supabase/migrations/20260731_add_push_notifications.sql` in the
   production Supabase SQL Editor.
2. Create the least-privilege Firebase sender service account and add its three
   values as Supabase Edge Function secrets.
3. Deploy `supabase/functions/order-push`.
4. Test customer and administrator delivery in foreground, background, and
   normally terminated states on two Google Play-enabled devices.

Exact instructions and security warnings are in `docs/FCM_MANUAL_SETUP.md`.
Until these backend steps are complete, the app remains usable but push
dispatch is not operational.

## Release testing

1. Install the release APK manually and test email registration,
   email/password sign-in, password recovery, guest checkout, ordering, and
   admin status changes.
2. Confirm the password-reset email opens
   `rastasperiq://reset-password` and permits a password update.
3. Complete the two-device notification test after deploying the backend.
4. Upload the signed AAB to Play Console **Internal testing** first, then review
   the pre-launch report and tester feedback.
5. Keep secure backups of the upload keystore, passwords, Firebase sender key,
   R8 mapping, and Dart symbols. Never commit the credentials.

## Final status

`READY FOR MANUAL APK TESTING`

`AAB VALIDATED; COMPLETE BACKEND SETUP AND FCM SMOKE TEST BEFORE PLAY INTERNAL TESTING`

Play approval is external and cannot be guaranteed. Use the AAB for Play
Console and the APK for direct device installation.
