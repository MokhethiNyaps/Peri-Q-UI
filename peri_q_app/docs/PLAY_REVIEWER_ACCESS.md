# Google Play Reviewer Access

## Customer access

The menu opens automatically after the splash screen. Quick checkout uses Supabase Anonymous Auth behind the scenes; no login, account creation, password or OTP is requested. Do not store private credentials in this repository or screenshots.

## Reviewer preparation (owner action)

1. Keep a clearly labelled test menu item available and the review environment operational throughout review.
2. Supply reviewer customer credentials privately if account creation/deletion must be tested without email-confirmation delays.
3. If review occurs outside store hours, temporarily configure staging/review store hours to cover the full day (`00:00` opening and closing is treated as always open), or give precise Play app-access instructions. Do not expose an admin bypass in the public app.
4. Enable at least one pickup method and a non-card payment. Mark the order/test environment clearly so staff do not prepare real food or collect money.
5. Provide any regional network limitations and a support contact in Play Console.

## Admin access

Admin UI appears only when a previously stored Supabase session has a trusted `profiles.role` of `admin`; database policies independently enforce it. Version 1.0.2 does not expose an admin/customer login screen, so the owner dashboard is not available from a fresh public installation. Never provide the owner's account or service-role key.

## Suggested review flow

1. Launch and select **Continue as Guest**.
2. Browse today's menu/categories and add the labelled test item.
3. Change quantity/add a note, choose pickup, select cash, and place the non-real test order.
4. View the stored order number/estimate and My Orders status.
5. Use the dedicated admin account if supplied to advance Pending → Preparing → Ready → Completed, then return to customer view to observe realtime status.
6. For EFT testing, choose EFT and upload a small non-sensitive sample JPG/PDF; confirm it remains private.
7. Confirm Profile has no login, sign-up, password-reset, sign-out or registered-account deletion controls. Public deletion/support requests remain available at `https://rastasperiq.co.za/delete-account/`.

Reviewer constraints: push notifications are not configured and are not needed; status is visible inside the app. There is no driver/map tracking. Production orders/store-hours must not block evaluation.
