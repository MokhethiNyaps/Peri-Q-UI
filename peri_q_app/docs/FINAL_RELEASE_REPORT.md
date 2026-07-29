# Final Release Report

## Release summary

Version `1.0.2` (build `3`) removes customer login, account creation, password recovery, sign-out and registered-account deletion from the Android app. A fresh installation now creates a private Supabase anonymous session during bootstrap and opens the customer experience after the splash screen. The anonymous session is still required for secure order ownership and tracking.

Existing locally stored Supabase sessions are restored, so an already authenticated owner session can retain admin access. No customer or owner password-login entry point is exposed in this release.

## Release artifacts

| Artifact | Size | SHA-256 |
|---|---:|---|
| `release/android/rastas-peri-q-v1.0.2-build3-release.apk` | 53,502,051 bytes | `9D8A9FD9973DBEDAFBF484FAE88E85E641AA29EC853BBC9B9FA6AC5A8B0A77DB` |
| `release/android/rastas-peri-q-v1.0.2-build3-release.aab` | 52,479,426 bytes | `61C1118C8F94591EB5EC2758FD810890E713564E7C13AD4E10094A53B567703A` |
| `release/android/rastas-peri-q-v1.0.2-build3-r8-mapping.txt` | 11,917,671 bytes | `E3171A3965EBC8DECCB79F0724347DB5816656D24947CB70811A7207DBADE025` |
| `release/android/rastas-peri-q-v1.0.2-build3-dart-symbols.zip` | 3,149,737 bytes | `6DC8D3D53041A0A6103287AA6A68AE3F95FAA7CF6DE89A607DD71EDB90F2673F` |

Release artifacts and signing material are intentionally ignored by Git. Keep the mapping and Dart symbols paired with this exact AAB.

## Android identity and signing

- Package: `za.co.rastasperiq.ordering`
- Version name: `1.0.2`
- Version code: `3`
- Minimum SDK: 24
- Target/compile SDK: 36
- APK signature: valid APK Signature Scheme v2, one signer
- AAB signature: valid JAR signature, same signer certificate as the APK
- Signing certificate SHA-256: `0BCCBE0AD6A15CD2FEFA9C8E507099259C60BE302ECFD917BA2BFBF28BB218AF`
- Bundletool 1.18.3 validation: passed

## Verification

| Gate | Result |
|---|---|
| Dart formatter | Passed after formatting all changed Dart files |
| Flutter analysis | `No issues found` |
| Automated tests | 21 passed |
| Production Supabase Auth settings | Reachable; anonymous sign-in enabled |
| Signed release APK | Built and signature/package/version verified |
| Signed release AAB | Built, signature verified and Bundletool validation passed |
| Signing certificate comparison | APK and AAB SHA-256 certificate fingerprints match |
| Connected Android device | None detected by ADB; BlueStacks launch test not run |

## User-facing changes

- Removed login, create-account and password-reset screens and deep-link handling.
- Removed sign-out and registered-account deletion controls from Profile.
- Removed customer-facing admin-login guidance.
- New users receive an anonymous ordering session automatically.
- Checkout still requests the name and phone number required to fulfil an order.
- Saved addresses and payment preferences remain local to the app.
- Existing restored admin sessions can still open the owner dashboard.

## Release notes draft

Removed customer login and account creation for a faster checkout. New installations now open directly into a private guest ordering session, with refreshed home, menu and Today's Special experiences.

## Remaining manual checks

1. Install the APK on a physical phone and confirm splash → Home without any login/sign-up screen.
2. Place a complete pickup test order and, if enabled, a delivery/EFT test order.
3. Upload the AAB to Play Console Internal testing before wider distribution.
4. Retain the upload keystore, R8 mapping and Dart symbols in secure backups.
5. Review Play Data Safety and App Access answers against the guest-only experience before submission.

## Known warning

The release build passes, but Flutter warns that current `file_picker` and `flutter_image_compress_common` versions still apply the Kotlin Gradle Plugin. This is a future migration warning and does not invalidate version 1.0.2.
