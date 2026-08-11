# Closed-Test Branding Release Report — v1.0.3 (build 4)

## Outcome

This release is ready for upload to the existing Google Play Closed Testing
track. The project was inspected before changing release values: the previous
local Android version was `1.0.2+3`, so this candidate uses version `1.0.3`
with `versionCode` `4`.

## Branding

- Brand text was standardised to `RastasperiQ` across website and app source.
- Icon-only usage now points to `white-app-icon.png`.
- Full-logo website usage now points to `Logo.png` or `logo-squere.png` without
  adjacent duplicate `RastasperiQ` text.

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
| `release/android/rastasperiq-v1.0.3-build4-closed-test-release.apk` | 56,678,574 | `B1EE86003DA2D0877FB99FF5F13616C4113F9BA63082D22ABCDB11FF9177BE06` |
| `release/android/rastasperiq-v1.0.3-build4-closed-test-release.aab` | 55,578,023 | `54BF6A615FAFD3311AA19389F086619FA7910A93C2E2EAE25F49CD474B3EEACE` |

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
