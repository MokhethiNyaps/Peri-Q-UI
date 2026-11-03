# Go-live checklist: what we need from the client

RastasperiQ (PERI Q CHISANYAMA (PTY) LTD), website `rastasperiq.co.za` and the Android app.
Prepared 3 November 2026. The site currently runs in **Yoco test mode**, so no real money is collected.

## 1. Already confirmed by the client

These are the client's confirmations. They still need technical verification, done in section 4.

| Requirement | Status |
|---|---|
| Yoco account activated | Confirmed |
| Domain `rastasperiq.co.za` verified with Yoco | Confirmed |
| Yoco account in the company's name (matches CIPC) | Confirmed |
| Capitec payout account belongs to the company | Confirmed |
| Yoco merchant terms accepted | Confirmed |
| Yoco data-processing terms accepted | Confirmed |
| Who issues refunds | The owner |
| Who has Yoco dashboard access | The owner |
| Available for a live payment test | Yes |

## 2. Keys: what they are and where they go

Only **two** values are needed from the Yoco account. Neither goes into the Android app or GitHub. Both go only into **Vercel → Project → Settings → Environment Variables → Production**.

| Vercel variable | What it is | Starts with | Where it comes from |
|---|---|---|---|
| `YOCO_SECRET_KEY` | Yoco **live secret key**. It lets our server create card checkouts. Replaces the current test key (`sk_test_…`). | `sk_live_` | Yoco App → Sales → Payment Gateway → How to connect → **Live keys** |
| `YOCO_WEBHOOK_SECRET` | Secret that proves payment notifications really come from Yoco. Replaces the test webhook secret. | `whsec_` | Shown **once** when the live webhook is registered (step 3b) |

Not needed: the Yoco **public** key (`pk_live_…`). Our server uses only the secret key.

**How to hand them over:**
- Best: the owner types them into Vercel during a call with the developer.
- Otherwise: through a password manager's secure share.
- **Never** by WhatsApp, SMS or email, and never in a document or screenshot.

## 3. What the owner does in the Yoco account

### 3a. Before the switch
1. **Live keys:** open Sales → Payment Gateway → How to connect → **Live keys**, and have the live secret key ready for step 2.
2. **Payment methods:** check which methods the online checkout offers. The business is **card only**. If anything else is switched on, such as instant EFT, tell the developer before go-live.
3. **Refund access:** confirm you can open a past online transaction and see the **Refund** option. Refunds are only possible on live payments.

### 3b. During the switch (with the developer, about 15 minutes)
1. Put the live secret key into Vercel as `YOCO_SECRET_KEY`.
2. **Register the live webhook.** The developer runs `website/scripts/register-yoco-webhook.ps1`, and the owner enters the live secret key when the script asks. It registers `https://rastasperiq.co.za/api/yoco/webhook/` for the events `payment.succeeded`, `refund.succeeded` and `refund.failed`, Yoco's defaults.
3. The script shows the webhook secret **once**. Save it in Vercel as `YOCO_WEBHOOK_SECRET` straight away.
4. **Redeploy** the website in Vercel.
5. Open `https://rastasperiq.co.za/api/yoco/checkout/`. It must show `"mode":"live"`.

### 3c. Every day after go-live
- **Refunds go through Yoco only:** Yoco dashboard → transaction → Refund. Never refund in cash. A Yoco refund updates the order in our system automatically; a cash refund leaves no record.
- **Cancelling a paid order** in the admin app does **not** refund the customer. The owner must also refund it in Yoco.

## 4. Live verification (developer and owner together)

1. Order one cheap item on the website (minimum R2, for example a R12 water) and pay with a **real card**.
2. The developer confirms in the database:
   - one paid order;
   - one payment record;
   - the payment notification processed;
   - the policy acceptance saved;
   - the "New order" alert sent to the admin phone.
3. The owner refunds that payment in the Yoco dashboard.
4. The developer confirms the refund was recorded and the order shows as **refunded**.
5. Repeat one order from the Android app.

Until step 4 passes, the go-live is not verified.

## 5. Other information we need from the client

These complete the legal pages (draft PR #10) and the remaining stages. Each one shows as a "To be confirmed" placeholder on the draft pages until it's answered.

**Company**
- [ ] Directors' names (page 3 of the CIPC COR39 certificate)
- [ ] Information Officer: name, email and phone (plus any deputies)
- [ ] Trading address: is "28 King Edward Rd" the same premises as the CIPC "28 King Edward Willows"?
- [ ] VAT number, or confirmation that the company is not VAT-registered; and whether menu prices include VAT
- [ ] Certificate of Acceptability (food premises) number, if held
- [ ] Whether the company has employees

**Food**
- [ ] Allergens and main ingredients for every menu item
- [ ] Any certification claims (for example halaal), with proof

**Orders and refunds**
- [ ] Delivery area, and what happens when the driver cannot reach the customer
- [ ] How long a collection order is kept, and whether an uncollected order is refunded
- [ ] Can a customer cancel a paid order before preparation starts? After? For what refund?
- [ ] Faulty or missing items: replacement or refund?
- [ ] How many days to approve a refund request
- [ ] Complaints: who handles them, and how many days to acknowledge and to resolve

**Retention (with the accountant or attorney)**
- [ ] How long to keep orders and payment records after a customer deletes their account (tax law)
- [ ] Approve or change the proposals: unfinished checkouts 30 days, guest sign-ins with no order 90 days
- [ ] How long to keep payment notifications and the admin audit log

**Supabase dashboard (owner or developer, a few minutes)**
- [ ] Authentication → Policies: switch on **leaked-password protection**
- [ ] Switch on two-step sign-in (MFA) for both admin accounts

**For the attorney**
- Wording of the terms, privacy policy, PAIA manual and refund, cancellation and complaints policies (draft PR #10)
- Limitation of liability; whether ECTA's cooling-off period excludes prepared food
- Legal basis for storing data outside South Africa (Supabase in Ireland, Vercel, Google)
- Whether a PAIA manual is required now, or an exemption applies

## 6. Android app

- **Signed release APK:** version **1.0.6 (build 7)**, in `peri_q_app/release/android/`.
- **Contents:** everything live on the website (consent tick boxes, the full order review, the updated deletion wording and the legal links).
- **Play Console:** the APK isn't uploaded yet. If the upload is an app bundle (`.aab`), build it with `peri_q_app/tool/build_android_release.ps1 -Target appbundle`.
- **Yoco keys:** the app holds none. Switching to live keys needs **no** new app build.
