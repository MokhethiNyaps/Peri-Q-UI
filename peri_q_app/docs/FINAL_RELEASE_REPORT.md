# Final Release Report

## Release outcome

The corrected Android release is ready for manual device testing and Play Console
Internal testing. Email/password registration, sign-in and password recovery are
available again. **Continue as Guest** remains available. Phone-number-only sign-in
has been removed, so this build does not require SMS, OTP or Twilio.

The phone number collected during email registration and checkout is contact and
order-fulfilment information only; it is not an authentication method.

## Corrected release identity

- Package: `za.co.rastasperiq.ordering`
- Version: `1.0.0`
- Version code: `1`
- Compile/target SDK: 36
- Build type: signed release, R8/resource shrinking, Dart obfuscation and split
  debug information
- Build date: 29 July 2026 (Africa/Johannesburg)

## Release artifacts

| Artifact | Size (bytes) | SHA-256 |
|---|---:|---|
| `release/android/rastas-peri-q-v1.0.0-build1-release.apk` | 53,846,927 | `F767136C79AA3218E33F780BE93E48674CADFA5C8D24A396EE9EAD7943C1B3C4` |
| `release/android/rastas-peri-q-v1.0.0-build1-release.aab` | 52,689,227 | `851876E338083F6A17BC0B7505494ACE21925E1113D074B40D7EB739BB4A2425` |
| `release/android/rastas-peri-q-v1.0.0-build1-r8-mapping.txt` | 11,917,671 | `E3171A3965EBC8DECCB79F0724347DB5816656D24947CB70811A7207DBADE025` |
| `release/android/rastas-peri-q-v1.0.0-build1-dart-symbols.zip` | 3,187,861 | `40E71CC183795DF30AAC9111966C5BCC711165272BF9511136E0AEBD0D7D0231` |

The ignored `release/android/` directory contains local release outputs and is not
committed to Git. Keep the mapping and Dart symbols paired with this exact AAB.

## Verification evidence

| Gate | Result |
|---|---|
| Formatting | `dart format lib test` completed |
| Static analysis | `flutter analyze --no-pub` — no issues found |
| Automated tests | `flutter test --no-pub` — all 27 tests passed |
| Release APK | Built successfully; APK Signature Scheme v2 verified |
| Release AAB | Built successfully; `jarsigner` verified the bundle |
| Bundle validation | bundletool 1.18.3 `validate` passed |
| Manifest | package/version confirmed as `za.co.rastasperiq.ordering`, `1.0.0` / code `1` |
| Signing identity | APK and AAB certificate SHA-256: `0BCCBE0AD6A15CD2FEFA9C8E507099259C60BE302ECFD917BA2BFBF28BB218AF` |
| Phone auth removal | No phone sign-in action, OTP verification, SMS or Twilio integration remains |
| Account access | Email/password sign-in, registration, recovery and guest access remain covered by tests |

## What changed in this correction

- Reverted the accidental removal of the entire account-authentication experience.
- Restored email/password sign-in, account creation, password-reset deep links,
  profile/account lifecycle and authenticated order access.
- Removed only the standalone **Continue with Phone** authentication path and its
  anonymous-session wrapper.
- Kept **Continue as Guest** on the sign-in screen.
- Kept the sign-up phone field as customer contact data.
- Reset the unreleased app identity to the first Play version, `1.0.0+1`.
- Deleted all old APK and AAB outputs before producing this corrected release.

## Remaining owner testing

1. Install the release APK manually on a phone and test email registration,
   email/password sign-in, password recovery, guest checkout and order contact.
2. Confirm the password-reset email opens the app through
   `rastasperiq://reset-password` and allows a password update.
3. Test a fresh installation and a signed release installation before uploading.
4. Upload the signed AAB to Play Console **Internal testing** first, then inspect
   the pre-launch report and tester feedback.
5. Keep a secure backup of the upload keystore and its passwords. Do not commit
   them to Git.

## Supabase note

The production schema was reported as already applied directly in Supabase. That
does not invalidate this build, but future database changes should first be applied
to a separate staging Supabase project populated with non-production test data.
Confirm Email and Anonymous Auth are enabled. Phone Auth can remain disabled.

## Final status

`READY FOR MANUAL APK TESTING AND PLAY INTERNAL TESTING`

Play approval is external and cannot be guaranteed. Do not upload the APK to Play;
use the AAB for Play Console and keep the APK for manual device testing.
