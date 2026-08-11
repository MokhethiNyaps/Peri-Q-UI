# Closed-Test Maintenance Release Report — v1.0.2 (build 3)

## Outcome

This replacement release is ready for the next Google Play closed-testing
upload. It keeps version `1.0.2` / code `3`, the existing application ID,
upload-signing identity, backend contract, UI structure, authentication
methods, and order flow unchanged. It supersedes the previously generated
build-3 files, which were removed before this release was produced.

## Launcher icon replacement

The installed Android launcher icon now uses
`assets/images/white-app-icon.png`. The adaptive-icon foreground and all legacy
Android density fallbacks were regenerated: mdpi (48 px), hdpi (72 px), xhdpi
(96 px), xxhdpi (144 px), and xxxhdpi (192 px). This removes the prior
small-text-heavy icon from the installed app while preserving the existing
adaptive icon background treatment on Android 8 and newer.

## Selected changes

1. **Bootstrap-aware splash screen** (`lib/src/screens/splash_screen.dart`)
   - The splash screen now waits for both application bootstrap and a 1.4-second
     minimum brand display time. This avoids an unnecessary two-second wait on
     fast starts while preventing navigation before bootstrap is complete.
2. **Checkout submission progress indicator**
   (`lib/src/screens/checkout_screen.dart`)
   - The Place Order button now shows an inline spinner and `Placing order…`
     while submission is in progress. This gives immediate, accessible feedback
     and helps prevent duplicate taps during an order request.
3. **Robust sign-up contact-number validation** (`lib/src/screens/auth_screen.dart`)
   - Phone formatting characters, including `+`, are ignored for validation and
     at least nine digits are required. Common South African international
     formatting such as `+27 73 642 3549` remains accepted.

These were selected because they are low-risk improvements on the most
time-sensitive customer paths: launch, checkout, and account registration.

## Items inspected and not implemented

- **Profile dialog controller disposal:** already correct. The controller is
  disposed after the dialog completes whether it is confirmed, cancelled, or
  dismissed.
- **Checkout step badges:** the existing `const` declaration is valid. Making
  the badges accurately reflect scroll/form progress needs a larger interaction
  design, so it remains deferred to v1.1 rather than shipping misleading partial
  state.
- **Dependency upgrade:** inspected with `flutter pub outdated`. Available
  upgrades include minor releases (not only safe patches), including Firebase
  and Supabase packages. No dependency update was made to keep this closed-test
  maintenance release narrowly scoped.
- **Other report candidates:** branded error borders, cart-label clarification,
  order empty-state icon, tracking contact-label adjustment, and confirmation
  icon semantics remain valid future enhancements but were not among the three
  selected changes.

## Release identity

| Field | Value |
|---|---|
| Application ID | `za.co.rastasperiq.ordering` |
| Version name | `1.0.2` |
| Version code | `3` |
| Minimum / target SDK | 24 / 36 |
| Signing certificate SHA-256 | `0BCCBE0AD6A15CD2FEFA9C8E507099259C60BE302ECFD917BA2BFBF28BB218AF` |

## Verification

| Check | Result |
|---|---|
| Dependency resolution | `flutter pub get` passed; no lockfile changes |
| Formatting | `dart format lib test` passed |
| Static analysis | `flutter analyze --no-pub` passed with no issues |
| Unit/widget tests | `flutter test --no-pub` passed: 35 tests |
| Release APK | Built, version/package inspected, and v2 signature verified |
| Release AAB | Built, manifest inspected, `jarsigner` verified, and bundletool validation passed |

The Android build emitted pre-existing third-party Kotlin Gradle Plugin
compatibility notices for `file_picker` and `flutter_image_compress`, plus an
unobfuscated DWARF-information notice. They did not fail the build and no new
errors or change-related warnings were introduced.

## Signed artifacts

| Artifact | SHA-256 |
|---|---|
| `release/android/rastas-peri-q-v1.0.2-build3-brand-mark-launcher-release.apk` | `FE2279C28FADDCBDE6DA1DC1E8F89243CCA77CE81F4CCFC82649AED69D74ADD9` |
| `release/android/rastas-peri-q-v1.0.2-build3-brand-mark-launcher-release.aab` | `466A990DEF20D3BF1CBD3AC827B17232DF2D8CD47D560C9D1B8947291B048B9D` |
| `release/android/rastas-peri-q-v1.0.2-build3-brand-mark-launcher-r8-mapping.txt` | `152389278FD6CCEE0D015EB6FB355DF420E80AF2929BF1FF27E9FF70EBCC79C2` |

`release/android/` is intentionally ignored by Git. Retain the mapping file
with this exact AAB for any future crash-symbolication need.

## Manual smoke test before upload

1. Install the signed APK on a test Android device and confirm the phone's
   launcher shows the RastasperiQ icon-only launcher asset.
2. Cold-launch it. Confirm that the splash is visible for at least 1.4 seconds
   and then routes normally.
3. On sign-up, verify a formatted valid number is accepted and a number with
   fewer than nine digits is rejected.
4. Place one pickup or delivery test order. Confirm the button immediately
   changes to the spinner state, completes once, and the usual confirmation and
   order-status flow remains intact.
5. Upload **only the AAB** to the existing closed-testing track. The APK is for
   direct device testing and must not be uploaded to Play Console.
