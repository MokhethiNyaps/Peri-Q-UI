# Supabase Setup

This app can run in two modes:

- `Mock mode`: no Supabase keys provided, so the app keeps using local demo data.
- `Supabase mode`: provide a project URL and publishable key, and the app will use Supabase Auth + Postgres.

## 1. Create the database schema

Open the SQL editor in your Supabase project and run:

```sql
-- paste the contents of supabase/schema.sql
```

## 2. Enable authentication providers

In the Supabase dashboard:

1. Enable `Email` sign-in if you want staff/admin logins.
2. Enable `Anonymous` sign-ins for guest checkout and phone-first sessions.

Anonymous sign-ins are required because customer ordering is currently backed by anonymous authenticated sessions instead of SMS OTP.

## 3. Seed admin access

Create or sign in with an email/password user, then promote that profile:

```sql
update public.profiles
set role = 'admin'
where email = 'owner@example.com';
```

## 4. Run the Flutter app against Supabase

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

To build the debug APK against Supabase:

```bash
flutter build apk --debug --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

## 5. Connected tables

- `profiles`: stores app profile data and admin role.
- `app_settings`: stores shared store state like `store_open`.
- `menu_items`: public menu catalog.
- `orders`: order headers tied to the signed-in user.
- `order_items`: snapshot of the items inside each order.

## Notes

- Google sign-in still needs OAuth provider setup and mobile deep-link configuration before it can be enabled in-app.
- The app uses the Supabase publishable key on the client, so RLS policies are what protect your data.
- If you launch the app without the two `--dart-define` values, it will stay in mock mode automatically.
