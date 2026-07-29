# Production Readiness — 27 July 2026

> Historical version 1.0.1 readiness snapshot. Version 1.0.2 removes customer login/account creation; use `FINAL_RELEASE_REPORT.md` for the current signed release.

This report distinguishes implementation and compile checks from production
verification. It contains no signing credentials or private keys.

## Release identity

- Package/application ID: `za.co.rastasperiq.ordering`
- Version name: `1.0.1`
- Version code: `2` (the owner must confirm it is higher than Play Console)
- Working branch: `codex/mobile-production-readiness`

## Implemented

- Premium, responsive Login/Sign-up and Home presentation while retaining the
  existing brand colours and business flows.
- Better loading, offline, retry, empty, disabled and error states on the
  redesigned surfaces.
- Today's Special gallery selection, JPG/PNG/WebP validation, 5 MB limit,
  corruption check, pre-save preview, replace/reset, upload progress and clear
  success/error feedback.
- Client-side image optimisation for larger uploads (WebP, quality 82, EXIF
  removed) with safe original-image fallback.
- Supabase Storage server-side MIME/size limits and a migration for projects
  where the original schema was already applied.
- Realtime app settings, menu and category subscriptions with coalesced refresh,
  keeping the last successful data if a refresh fails.
- A website Today’s Special section that reads the public `app_settings` row and
  follows Realtime updates from the same Supabase project.
- Public Terms and Conditions page and in-app HTTPS links to the website,
  Privacy Policy, Terms and account-deletion page, plus email/phone/WhatsApp.
- Encrypted Android storage for the Supabase session and PKCE verifier with
  migration away from the previous SharedPreferences session entry.
- HTTPS-only production configuration validation; client code rejects
  `service_role`/secret keys.
- Cleartext traffic disabled in the manifest and Network Security Configuration;
  Android backup remains disabled.
- Edge-to-edge system UI, branded splash resources, adaptive/round launcher
  icons and Android 12 splash resources.
- Release signing can read the ignored `android/key.properties` file or four
  private `PERIQ_*` environment variables. No signing value is stored in Git.
- Production Supabase values can be supplied through ignored
  `release-config.json`; an example file is committed without real values.

## Backend and database

- No custom API endpoint was added. Mobile and web use Supabase HTTPS/PostgREST,
  Auth, Storage and Realtime directly, protected by the existing RLS policies.
- Updated `supabase/schema.sql` configures the public `menu-images` bucket with a
  5 MB limit and only `image/jpeg`, `image/png`, and `image/webp`.
- Because the owner already ran the schema, run only
  `supabase/migrations/20260727_harden_menu_image_uploads.sql` now.
- Existing `app_settings`, `menu_items`, and `menu_categories` Realtime
  publication entries are reused; no new table or field is required.
- No CORS change is required because there is no custom browser API server; the
  Supabase browser client accesses the project through Supabase's HTTPS APIs.

## Website deployment

- Add `NEXT_PUBLIC_SUPABASE_URL` and
  `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` to the Vercel Production environment,
  then redeploy.
- On 27 July 2026, the deployed home, privacy and deletion URLs returned HTTP
  200 and the two policy pages contained `contact@rastasperiq.co.za`.
- The new `/terms-and-conditions/` route is implemented and builds locally but
  is not public until the updated website is deployed; the deployed URL
  currently does not return 200.

## Android permissions and Play checks

- `INTERNET` remains the only requested permission.
- Gallery selection uses the system picker, so no broad photo/media/storage
  permission was added.
- No notification permission is needed because the app does not implement push
  notifications.
- Compile/target SDK is 36. Minimum SDK remains Flutter's supported default.
- In-app and public web account-deletion paths are implemented.
- Data Safety and Play release drafts were updated for encrypted session storage
  and the real public URLs. The owner must still confirm actual retention,
  Supabase processing, target audience, account type/testing requirements and
  every answer shown in Play Console.

## Checks completed

- `flutter analyze`: no issues.
- `flutter test`: 27 tests passed.
- Debug APK assembly: passed.
- Signed, obfuscated release AAB build: passed.
- Signed, obfuscated release APK build: passed.
- Google bundletool 1.18.3 validation: passed.
- AAB JAR signature and certificate inspection: passed.
- APK Signature Scheme v2 verification: passed.
- AAB and APK signing-certificate comparison: identical.
- `pnpm lint`: passed.
- `pnpm build`: passed and statically generated `/`, `/privacy-policy`,
  `/delete-account`, and `/terms-and-conditions`.
- `git diff --check`: no whitespace errors.
- Secret scan of source/config changes: no real Supabase or signing secret found.

## Signed release verification — 28 July 2026

The existing keystore at
`C:\Users\hp\Desktop\Mokhethi\Keys\peri-q-keys.jks` was used without modifying
or exposing it. The production client configuration and signing properties
remained in their Git-ignored local files.

- AAB: `release/android/rastas-peri-q-v1.0.1-build2-release.aab`
- AAB SHA-256:
  `60a24e5c602256b80dee122d14b9e68ddeb4273a15b5a77055356596b3385946`
- APK: `release/android/rastas-peri-q-v1.0.1-build2-release.apk`
- APK SHA-256:
  `5b32f7a6c01fe2e76eeb69741f86259de28de02bc0781636c779bd6e5c5376fb`
- Package: `za.co.rastasperiq.ordering`
- Version: `1.0.1` (`versionCode` 2)
- Minimum/target SDK: 24/36
- Architectures: arm64-v8a, armeabi-v7a, x86_64

Read-only production checks returned HTTP 200 for Supabase Auth settings,
`app_settings`, and `menu_items` through the publishable client/RLS path.

BlueStacks local ADB access was enabled (remote ADB remained disabled). The old
debug-signed version 1.0.0 emulator copy was uninstalled, which removed only its
local emulator app data. The signed 1.0.1 APK was then installed successfully
on Android 9/API 28. It launched to the redesigned Sign In screen, switched to
Create Account, remained alive, and produced no fatal Android log entries.

No production account was created automatically. Authenticated Home/menu,
Today's Special upload/persistence, logout, password recovery, orders and
in-app website links still require the owner's manual account/device test.

## Remaining release steps

1. Confirm the package ID and version code 2 are accepted by Play Console.
2. Manually install the release APK on a physical Android device and test
   auth, home/menu, Today’s Special upload/sync, logout and every public link.
3. Upload the verified AAB to Internal testing, run the Pre-launch report, and
   complete Play App Content/Data Safety declarations before wider release.
