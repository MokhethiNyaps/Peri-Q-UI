# Production Readiness — 27 July 2026

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
- Release AAB compile/shrink/package path without production config/signing:
  passed. This artifact is intentionally **not a deliverable**.
- AAB signing inspection: confirmed that compile-check AAB is unsigned.
- Debug APK signing inspection: Android debug certificate only; not a release
  deliverable.
- `pnpm lint`: passed.
- `pnpm build`: passed and statically generated `/`, `/privacy-policy`,
  `/delete-account`, and `/terms-and-conditions`.
- `git diff --check`: no whitespace errors.
- Secret scan of source/config changes: no real Supabase or signing secret found.

## Blocked production verification

The existing candidate keystore was found at
`C:\Users\hp\Desktop\Mokhethi\Keys\peri-q-keys.jks`. It was not altered.
Its alias/store password/key password are not available to this build process.
The production Supabase URL/publishable key are also not configured locally.
Therefore:

- No signed production AAB has been created or verified.
- No signed production APK has been created or verified.
- Authentication, live data, image persistence and cross-platform Realtime have
  not been exercised against the production project in this pass.
- No Android device or emulator is connected, so installation, launch and the
  physical-device user journey have not been tested.

The unsigned compile-check AAB and debug APK must not be uploaded or distributed
as production artifacts.

## Remaining release steps

1. Run the one SQL migration noted above.
2. Deploy the updated website with its two public Supabase environment values.
3. Create ignored `release-config.json` from the example.
4. Create ignored `android/key.properties` using the existing keystore (or set
   all four `PERIQ_*` variables) without sharing values in chat or Git.
5. Confirm the package ID and next version code in Play Console.
6. Build signed, obfuscated AAB and APK; verify with `jarsigner`, `keytool`, and
   `apksigner` as documented in `ANDROID_SIGNING_GUIDE.md`.
7. Connect a physical Android device, install the release APK, and manually test
   auth, home/menu, Today’s Special upload/sync, logout and every public link.
8. Upload the verified AAB to Internal testing, run the Pre-launch report, and
   complete Play App Content/Data Safety declarations before wider release.
