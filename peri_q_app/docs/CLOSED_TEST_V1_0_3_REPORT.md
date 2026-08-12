# Closed-Test Branding Release Report — v1.0.3 (build 4)

## Outcome

This release is ready for future upload to the existing Google Play Closed
Testing track. The AAB has not been uploaded. The project was inspected before
release work: the current local Android version is `1.0.3+4`, and this task
preserved version `1.0.3` with `versionCode` `4`.

## Branding

- Brand text was standardised to `RastasperiQ` across website and app source.
- Icon-only usage now points to `white-app-icon.png`.
- Full-logo website usage now points to `Logo.png` or `logo-squere.png` without
  adjacent duplicate `RastasperiQ` text.
- Android launcher resources now use the icon-only `White-App-Icon.png` master.
- Native and Flutter splash screens now use the full-logo `Logo-squere.png`
  master without separate `RastasperiQ` text.
- The home header switches to a two-row layout on narrow screens so the store
  status badge no longer compresses the brand title.

## Android release configuration

| Field | Value |
|---|---|
| Application ID | `za.co.rastasperiq.ordering` |
| Namespace | `za.co.rastasperiq.ordering` |
| Version name | `1.0.3` |
| Version code | `4` |
| Compile SDK | `36` |
| Target SDK | `36` |
| Minimum SDK | `24` |
| Build type | `release` |
| Signing | Existing ignored `android/key.properties` upload-signing config |

## Generated artifacts

| Artifact | Size (bytes) | SHA-256 |
|---|---:|---|
| `release/android/rastasperiq-v1.0.3-build4-closed-test-release.apk` | 58,097,767 | `0CEC5969AA161CDAE5605FAB425D5F0A9D47BA73F423E96886A6A6D8AFC12C7F` |
| `release/android/rastasperiq-v1.0.3-build4-closed-test-release.aab` | 56,988,546 | `4CC37EC1AAD5BF00A05E0A45B4EF6374D007436DD3877D18657CF1D6791A0479` |

`release/android/` is intentionally ignored by Git. Keep the matching symbol
folder `release/android/symbols-v1.0.3-build4-closed-test` with this AAB.

## Verification

| Check | Result |
|---|---|
| `dart format lib test` | Passed |
| `flutter analyze --no-pub` | Passed |
| `flutter test --no-pub` | Passed: 35 tests |
| `corepack pnpm lint` | Passed |
| `corepack pnpm build` | Passed |
| APK signing | `apksigner verify` passed, APK Signature Scheme v2 |
| AAB signing | `jarsigner -verify` returned `jar verified` |
| AAB validation | `bundletool validate` passed |
| APK manifest | Package `za.co.rastasperiq.ordering`, version `1.0.3`, code `4`, target SDK `36`, label `RastasperiQ` |
| AAB manifest | Package `za.co.rastasperiq.ordering`, version `1.0.3`, code `4` |

## Policy notes

Checked against official guidance available on 11 August 2026. Current Play
guidance requires app updates to target Android 16 / API 36 from 31 August
2026; this release targets API 36. The app already has privacy-policy and
account-deletion website routes, and the Play checklist keeps Data Safety,
reviewer access, and store-listing declarations as owner-controlled Play
Console tasks.
