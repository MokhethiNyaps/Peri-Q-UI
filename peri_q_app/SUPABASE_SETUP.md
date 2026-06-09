# Supabase Setup

This app now expects Supabase configuration and no longer uses demo/mock data.

## 1. Add local configuration

Create a `.env` file in `peri_q_app/` with:

```env
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

You can also pass the same values with `--dart-define` when building or running the app.

## 2. Create the database schema

Open the SQL editor in your Supabase project and run:

```sql
-- paste the contents of supabase/schema.sql
```

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

## 5. Run the Flutter app against Supabase

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

To build the debug APK against Supabase:

```bash
flutter build apk --debug --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

## 6. Connected tables

- `profiles`: stores app profile data and admin role.
- `app_settings`: stores shared store state like `store_open` plus Today's
  Special text, image path/URL, visibility, and linked menu item.
- `menu_items`: public menu catalog.
- `orders`: order headers tied to the signed-in user.
- `order_items`: snapshot of the items inside each order.

## Production services

Mandatory for the current production APK:

- Supabase project with `supabase/schema.sql` applied.
- Supabase Auth email/password enabled.
- Anonymous sign-ins enabled for guest and phone-first checkout.
- Custom SMTP provider for reliable auth emails and password resets.
- A production signing key before publishing to an app store.

Optional or future-facing:

- Google Sign-In: configure Google OAuth in Supabase and add mobile redirect
  handling before exposing a Google button in-app.
- Apple Sign-In: required for iOS App Store distribution if other third-party
  social login is offered; not required for Android-only release.
- Push notifications: use Firebase Cloud Messaging if order status alerts are
  needed outside the open app.
- File/image storage: use Supabase Storage or another CDN if admins need to
  upload new promotional/menu images. The current admin form accepts bundled
  asset paths or public HTTPS image URLs.
- Domain/hosting: needed for branded email sender domains, privacy/support
  pages, OAuth redirect URLs, and password reset/deep-link callbacks.

## Notes

- Google sign-in still needs OAuth provider setup and mobile deep-link configuration before it can be enabled in-app.
- Password reset uses Supabase email templates, so configure the sender and redirect URL in the Supabase dashboard before using it in production.
- The app uses the Supabase publishable key on the client, so RLS policies are what protect your data.
- If you launch the app without Supabase values in `.env` or `--dart-define`, the app will show a configuration screen instead of falling back to mock data.
