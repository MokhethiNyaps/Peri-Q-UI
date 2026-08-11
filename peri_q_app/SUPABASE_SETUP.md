# Supabase Setup

This app now expects Supabase configuration and no longer uses demo/mock data.

## 1. Add local configuration

For local convenience you may keep an ignored `.env`, but the app does not load or bundle it. Pass values with `--dart-define`:

```env
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Only use the project URL and publishable key. Never use a service-role key.

## 2. Create the database schema

Open the SQL editor in your Supabase project and run:

```sql
-- paste the contents of supabase/schema.sql
```

The schema seeds the catalogue, creates public `menu-images` and private
`payment-proofs`, enables RLS, prevents role escalation, restricts order
status transitions, and installs the trusted `place_order`,
`attach_payment_proof`, and `delete_own_account` RPCs.

If you already ran `supabase/schema.sql`, do not rerun the entire file just to
pick up image-upload hardening. Run this migration in the SQL editor instead:

```text
supabase/migrations/20260727_harden_menu_image_uploads.sql
```

It applies a 5 MB server-side limit and restricts menu/special uploads to JPG,
PNG, and WebP. The existing schema also adds `app_settings`, `menu_items`, and
`menu_categories` to Supabase Realtime so published changes reach the app and
website without a redeploy.

## 3. Enable authentication providers

In the Supabase dashboard:

1. Enable `Email` sign-in for customer registration, password login, and owner/admin logins.
2. Enable `Anonymous` sign-ins for guest checkout and phone-first sessions.

Anonymous sign-ins are required because customer ordering is currently backed by anonymous authenticated sessions instead of SMS OTP.

## 4. Seed admin access

Create or sign in with an email/password user, then promote that profile:

```sql
update public.profiles
set role = 'admin'
where email = 'owner@example.com';
```

Admins can add, edit, and delete menu items, update store availability, and
manage the Today's Special banner. To remove access later:

```sql
update public.profiles
set role = 'customer'
where email = 'owner@example.com';
```

The app enforces this through the `profiles.role = 'admin'` value and the RLS
policies in `supabase/schema.sql`.

## 5. Configure the Android password-reset deep link

In **Authentication → URL Configuration** in the Supabase dashboard, add this
exact value to **Redirect URLs**:

```text
rastasperiq://reset-password
```

Keep the URL scheme lowercase. The Android manifest registers this scheme and
the password-reset request supplies it as `redirectTo`. Supabase Flutter uses
PKCE, detects the returned `?code=...` callback, exchanges it for a recovery
session, and the app opens the Update Password screen.

If the redirect URL is not allowed, Supabase can fall back to the configured
Site URL (for example, `http://localhost:3000`). The recovery email template
must use Supabase's confirmation URL rather than hard-coding the Site URL.

## 6. Run the Flutter app against Supabase

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

To build the debug APK against Supabase:

```bash
flutter build apk --debug --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

For production builds, copy `release-config.example.json` to the ignored
`release-config.json`, fill in the same two public client values, and use
`--dart-define-from-file=release-config.json`. This keeps local values out of
terminal history and Git.

## 7. Connected tables

- `profiles`: stores app profile data and admin role.
- `app_settings`: stores shared store state like `store_open` plus Today's
  Special text, image path/URL, visibility, linked menu item, and operating
  hours.
- `menu_categories`: public category list managed from the owner dashboard.
- `menu_items`: public menu catalog seeded with the RastasperiQ
  menu.
- `orders`: order headers tied to the signed-in user and idempotent request.
- `order_items`: snapshot of the items inside each order.
- `storage.objects` / `menu-images`: public catalogue photos, admin writes.
- `storage.objects` / `payment-proofs`: private, owner/admin-scoped EFT files.

## 8. Connect the Vercel website

Add these Production environment variables in the Vercel project and redeploy:

```env
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

These values are intentionally public client configuration; RLS remains the
security boundary. Never put a secret/service-role key in a `NEXT_PUBLIC_*`
variable. The website reads only the public Today's Special row and subscribes
to its Realtime updates.

## Production services

Mandatory for the current production APK:

- Supabase project with `supabase/schema.sql` applied.
- Supabase Auth email/password enabled.
- Anonymous sign-ins enabled for guest and phone-first checkout.
- Supabase Storage bucket `menu-images` from `schema.sql` if admins will upload
  menu item photos from the app.
- Custom SMTP provider for reliable auth emails and password resets.
- A production signing key before publishing to an app store.

Optional or future-facing:

- Google Sign-In: configure Google OAuth in Supabase and add mobile redirect
  handling before exposing a Google button in-app.
- Apple Sign-In: required for iOS App Store distribution if other third-party
  social login is offered; not required for Android-only release.
- Push notifications: use Firebase Cloud Messaging if order status alerts are
  needed outside the open app.
- File/image storage outside Supabase: optional. The app now uses Supabase
  Storage for menu item uploads and can still display public HTTPS image URLs.
- Domain/hosting: needed for branded email sender domains, privacy/support
  pages, OAuth redirect URLs, and password reset/deep-link callbacks.

## Notes

- Google sign-in still needs OAuth provider setup and mobile deep-link configuration before it can be enabled in-app.
- Password reset uses Supabase email templates. Configure the sender and allow
  `rastasperiq://reset-password` as an Auth redirect URL before using it in
  production.
- The app uses the Supabase publishable key on the client, so RLS policies are what protect your data.
- If you launch the app without Supabase values in `.env` or `--dart-define`, the app will show a configuration screen instead of falling back to mock data.
