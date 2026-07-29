# Google Play Reviewer Access

## Customer access

The menu can be reached through **Continue as Guest**. Guest checkout uses Supabase Anonymous Auth; no OTP is required. Email/password account features can be tested with a dedicated reviewer customer account supplied privately in Play Console. Phone-number-only authentication is not offered; a phone number is collected only as contact/order information. Do not store reviewer credentials in this repository or screenshots.

## Reviewer preparation (owner action)

1. Keep a clearly labelled test menu item available and the review environment operational throughout review.
2. Supply reviewer customer credentials privately if account creation/deletion must be tested without email-confirmation delays.
3. If review occurs outside store hours, temporarily configure staging/review store hours to cover the full day (`00:00` opening and closing is treated as always open), or give precise Play app-access instructions. Do not expose an admin bypass in the public app.
4. Enable at least one pickup method and a non-card payment. Mark the order/test environment clearly so staff do not prepare real food or collect money.
5. Provide any regional network limitations and a support contact in Play Console.

## Admin access

Admin UI appears only when the authenticated user's trusted `profiles.role` is `admin`; database policies independently enforce it. If admin functionality is within review scope, create a dedicated reviewer-admin account, promote it from a trusted Supabase admin session, enter its credentials only in Play Console, and remove/demote it after review. Never provide the owner's account or service-role key.

## Suggested review flow

1. Launch and select **Continue as Guest**.
2. Browse today's menu/categories and add the labelled test item.
3. Change quantity/add a note, choose pickup, select cash, and place the non-real test order.
4. View the stored order number/estimate and My Orders status.
5. Use the dedicated admin account if supplied to advance Pending → Preparing → Ready → Completed, then return to customer view to observe realtime status.
6. For EFT testing, choose EFT and upload a small non-sensitive sample JPG/PDF; confirm it remains private.
7. For account deletion, use the dedicated reviewer customer account and **Profile → Delete Account**. A guest session does not show the registered-account deletion action.

Reviewer constraints: push notifications are not configured and are not needed; status is visible inside the app. There is no driver/map tracking. Production orders/store-hours must not block evaluation.
