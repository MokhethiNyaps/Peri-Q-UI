# Firebase Cloud Messaging Manual Setup

The Android client is registered in the dedicated Firebase project
`rastas-peri-q` for package `za.co.rastasperiq.ordering`. The checked-in
`android/app/google-services.json` contains public app identifiers, not a
server credential.

The following production backend steps cannot be completed from the local
repository because Supabase deployment credentials are not available on this
machine.

## 1. Apply the push-token database migration

In Supabase Dashboard, open **SQL Editor** for project
`nxzelriapklqaxcxmoys`, paste the complete contents of:

`supabase/migrations/20260731_add_push_notifications.sql`

Run it once. It creates:

- private per-user FCM token storage;
- role validation so customers cannot register an admin token;
- token registration/unregistration RPCs;
- an idempotency table that prevents duplicate order notification dispatches.

The token tables have RLS enabled and no direct client table access. The app
uses the restricted RPCs; the Edge Function uses the Supabase service role.

## 2. Create a least-privilege FCM sender service account

1. Open Google Cloud Console for project `rastas-peri-q`.
2. Go to **IAM & Admin → Service Accounts → Create service account**.
3. Name it `peri-q-fcm-sender`.
4. Grant only **Firebase Cloud Messaging API Admin**
   (`roles/firebasecloudmessaging.admin`).
5. Open the created account, choose **Keys → Add key → Create new key → JSON**.
6. Download the JSON once and keep it outside this repository.

Do not use or commit the downloaded JSON as an Android `google-services.json`.
They are different files: the service-account JSON contains a private key.

## 3. Add Supabase Edge Function secrets

In **Supabase Dashboard → Edge Functions → Secrets**, add:

| Secret | Value |
|---|---|
| `FCM_PROJECT_ID` | `rastas-peri-q` |
| `FCM_CLIENT_EMAIL` | The service-account JSON `client_email` value |
| `FCM_PRIVATE_KEY` | The complete service-account JSON `private_key` value, including its BEGIN/END lines |

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are
provided automatically to hosted Supabase Edge Functions. Never put the
service-role key or FCM private key in Flutter, `google-services.json`, Git, or
Play Console.

## 4. Deploy the order notification function

The function source is:

`supabase/functions/order-push/index.ts`

Deploy through the Supabase Dashboard editor, or use:

```powershell
npx supabase@latest login
npx supabase@latest functions deploy order-push `
  --project-ref nxzelriapklqaxcxmoys
```

JWT verification must remain enabled. The function independently verifies:

- a new-order alert was requested by the customer who owns that pending order;
- a status alert was requested by an authenticated Supabase administrator;
- notification content and target tokens come from trusted database records;
- each order/status event is dispatched only once.

## 5. Production test

1. Install the signed APK on two Google Play-enabled Android devices/emulators.
2. Accept notification permission on Android 13 or newer.
3. Sign into the admin account on one device. This registers an `admin` token.
4. Sign in or continue as guest on the customer device and place an order.
5. Confirm the admin receives a loud `admin_orders` notification while the app
   is foregrounded, backgrounded, and terminated.
6. Change the order from Pending → Preparing → Ready → Completed on the admin
   device.
7. Confirm the customer receives `client_order_updates` alerts, especially
   **Ready** and **Completed**, in all three app states.
8. Sign out and verify that the former account no longer receives targeted
   updates on that installation.

Android force-stop disables FCM delivery until the user opens the app again.
Use normal swipe-away/terminated testing rather than **Force stop**.

## iOS note

The Dart notification service requests Apple notification permission and
supports APNs payloads, but this repository currently has no iOS runner. Before
an iOS release, create/register the iOS target, upload an APNs authentication
key in Firebase, add `GoogleService-Info.plist`, and enable Push Notifications
plus Background Modes in Xcode.
