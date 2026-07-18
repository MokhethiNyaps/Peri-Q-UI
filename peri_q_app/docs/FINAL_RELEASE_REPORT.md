# Final Release Report

## Executive summary

The application received a full production-hardening pass across checkout reliability, Supabase trust boundaries, account lifecycle, scoped proof upload, offline/menu recovery, responsive/accessibility states, Android API 36 configuration, signing safety, shrinking, dependency cleanup, tests and Play documentation.

A release AAB was generated and validated:

- Path: `release/android/rastas_peri_q_chesanyama-v1.0.0-build1-unsigned.aab`
- Size: 51,667,589 bytes (49.3 MB displayed by Flutter)
- SHA-256: `F11DB4782B8073399607FBCDF7CBFC5F3722A8E45E51861C68F6006D7C543676`
- Package: `za.co.rastasperiq.ordering`
- Version: `1.0.0` / code `1`
- Target SDK: 36
- Build time: 2026-07-18 11:58:50 UTC (13:58:50 Africa/Johannesburg)

The bundle is **unsigned by design** because no owner upload key was available. It is valid but not ready for Play upload/internal testing until rebuilt with the production upload key. The updated Supabase schema must also be applied/tested before functional distribution.

## Verification results

| Gate | Exact result |
|---|---|
| Formatter | `dart format --output=none --set-exit-if-changed lib test` passed |
| Flutter analysis | `flutter analyze` — No issues found |
| Automated tests | `flutter test` — 19 passed |
| Android debug build | Passed; `app-debug.apk` generated |
| Release AAB build | Passed with R8/resource shrinking, Dart obfuscation and split debug info |
| Bundle validation | bundletool 1.18.3 `validate` passed; package/API/version inspected |
| Signing verification | `jarsigner` reports unsigned (expected blocker; debug signing removed) |
| App-size analysis | arm64 release APK 19.5 MB; JSON/snapshot/trace saved |
| Dependency audit | Direct packages current except intentional file-picker 10.x compatibility pin; unused font/dotenv/icon packages removed |
| Permission audit | Merged source declares only `android.permission.INTERNET`; no broad media/storage/location/camera permission |
| Security audit | Static schema/client review completed; trusted RPC/RLS fixes implemented in SQL; production database execution not run |
| Emulator testing | Not tested—no Android emulator available |
| Physical-device testing | Not tested—no Android device connected |
| Git diff check | `git diff --check` passed (line-ending notices only) |

## Toolchain and build inputs

- Flutter 3.44.0 stable, revision `559ffa3f75`
- Dart 3.12.0
- OpenJDK 21.0.4; Android source/JVM compatibility 17
- Android Gradle Plugin 9.0.1
- Gradle 9.1.0
- Kotlin plugin declaration 2.3.20; compatibility mode retained
- Application source tree represented by commit: `6f328e3129b3c1acd183e7c1cbb11b300f46c4fb`
- Build command:

```powershell
flutter build appbundle --release --obfuscate `
  --split-debug-info=release/android/symbols `
  --dart-define=SUPABASE_URL=... `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=...
```

## Release artifacts

- Unsigned AAB: `release/android/rastas_peri_q_chesanyama-v1.0.0-build1-unsigned.aab`
- R8 mapping: `release/android/r8-mapping.txt`
- Native debug symbols: `release/android/native-debug-symbols.zip`
- Dart symbols: `release/android/symbols/app.android-{arm,arm64,x64}.symbols`
- Size analysis: `release/android/size-analysis/`

Keep all symbols/mappings paired with this exact AAB. Rebuilding with signing or code changes creates a new artifact set/checksum.

## Changes made

### UI, UX and accessibility

- Centralised theme/spacing/radius tokens and reliable system fonts.
- Added clear offline, initial connection, empty-menu, unavailable fulfilment, closed-store, loading, upload and submission error states.
- Made home grid adapt to narrow screens and large text; retained keyboard-safe scrollable forms.
- Added semantic food-image labels, decode-sized images, tooltips/labels and minimum themed button heights.
- Added in-app Privacy & Help and visible registered-account deletion.

### Reliability and performance

- Added checkout submit locking and server idempotency; cart remains on recoverable failure.
- Added cached last menu with stale indication, pull-to-refresh, resume refresh and Supabase realtime order refresh without polling.
- Bounded order queries to 100; removed fake stored profile defaults; validated uploads and friendly failures.

### Security and backend

- Server-side atomic trusted pricing/order RPC; direct customer order inserts removed.
- Profile role-escalation protections and strict admin status transitions.
- Private scoped EFT proof storage/linking and account deletion cleanup.
- `.env` removed from assets; service/server secrets remain prohibited.

### Android and size

- Permanent candidate package/namespace, API 36, predictive-back declaration, no cleartext traffic, no backup and INTERNET-only permission.
- Non-committed upload-key configuration; debug signing removed.
- R8/resource shrinking and Dart obfuscation enabled; AAB reduced 6.76% from the measured 55,415,697-byte baseline.

## Remaining manual actions

1. Apply/test `supabase/schema.sql` in staging, then production with a backup.
2. Confirm the package ID before Play app creation.
3. Generate/back up the upload key, configure ignored `android/key.properties`, rebuild, revalidate and recalculate checksum.
4. Publish privacy and account-deletion pages; insert final business/support details and URLs.
5. Configure Supabase Auth providers, anonymous sign-in, custom SMTP and reset redirects.
6. Run every applicable item in `MANUAL_QA_CHECKLIST.md` on physical Android devices and Play-generated installs.
7. Upload to Internal testing, then complete closed testing/12-testers-for-14-days if Play requires it for the account.
8. Complete Data Safety, content rating, target audience, app access, ads/financial/health/news/government declarations and developer identity verification.
9. Review Play Pre-launch report, Android vitals, crashes/ANRs and device exclusions.
10. Decide whether to add FCM/crash reporting later; neither is required for current in-app ordering/status.

## Blockers and risks

- Unsigned artifact: Play upload blocked until owner signing action.
- Backend migration not deployed/tested: secure order RPC features will fail against the old schema.
- No emulator/physical-device verification: visual, accessibility, OS and picker behaviour still require device testing.
- Public privacy/account-deletion URLs and legal retention decisions are missing.
- File-picker/Kotlin future migration warning remains; current API 36 debug/release builds pass.

## Final status

`BLOCKED — OWNER ACTION REQUIRED`

The engineering package is prepared, but signing credentials, Supabase deployment, public legal URLs and device/Play testing are mandatory owner/external actions. Google Play approval is not guaranteed.
