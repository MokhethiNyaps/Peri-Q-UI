# Yoco setup for RastasperiQ

The database and website are prepared. Card payments stay unavailable until the server credentials below are configured. Cash and EFT remain available.

## Already completed

- Merged all GitHub branches into `main`; removed the merged branches.
- Applied the Yoco payment database migration to the existing Peri Q Supabase project.
- Verified cash orders, Yoco pending status, duplicate-request protection and changed-price rejection inside a rolled-back transaction. The 22 existing orders were preserved.
- Confirmed Supabase email and anonymous sign-ins are enabled.
- Configured Vercel production `SUPABASE_URL` and `NEXT_PUBLIC_SITE_URL`. The existing public Supabase variables are already present.
- Website menu, cart and checkout pages are deployed on https://rastasperiq.co.za.

## 1. Open Yoco Checkout API

Create or sign in to the restaurant's Yoco account and complete its business/payout profile.

In the Yoco App or https://app.yoco.com, go to **Sales → e-Commerce integrations → Checkout API → How to connect**. If your account does not show Checkout API, use Yoco's in-app support.

Under **Verified domains**, add **rastasperiq.co.za**. Yoco reviews the website before unlocking live keys. You can start with test keys while waiting.

Official instructions: https://support.yoco.help/en/articles/739322-yoco-checkout-api

## 2. Add the server credentials in Vercel

Open https://vercel.com/mokhethi/peri-q-ui/settings/environment-variables and add these to **Production**:

| Variable | Value / source |
| --- | --- |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase → Peri Q project → Project Settings → API Keys → server secret key, or the legacy `service_role` key. This is different from the publishable key. |
| `YOCO_SECRET_KEY` | Start with the Yoco test secret key, normally `sk_test_...`. After testing and domain approval, replace it with the live secret key, normally `sk_live_...`. |
| `YOCO_WEBHOOK_SECRET` | The secret returned when the Yoco webhook is registered, normally `whsec_...`. Save it immediately: Yoco provides it once. Use the webhook registered with the same test/live key as checkout. |

Use plain values only: do not include the variable name, quotation marks, or spaces around the value. Keep these three values server-only; do not create `NEXT_PUBLIC_` versions and do not paste secrets into chat or GitHub.

A Yoco public key (`pk_...`) is not needed by this website's hosted Checkout API integration.

## 3. Register the webhook

Register the following HTTPS endpoint with Yoco:

**https://rastasperiq.co.za/api/yoco/webhook/**

Keep the final slash: this is the site's canonical URL, so Yoco can POST directly without a redirect.

Yoco's documented registration method is **POST https://payments.yoco.com/api/webhooks**, authenticated with the test secret key first. The registration name can be `rastasperiq-website` and the URL is the endpoint above. Save the returned `secret` as `YOCO_WEBHOOK_SECRET` in Vercel.

If your Yoco interface offers webhook registration, use it. Otherwise use the prepared local helper: `website/scripts/register-yoco-webhook.ps1`. Right-click it and choose **Run with PowerShell**, or run it from a PowerShell terminal. It prompts privately for the Yoco secret key, registers the endpoint, and displays the webhook secret for you to copy directly into Vercel. Run this only once per mode unless you intentionally need a replacement webhook. Do not register multiple duplicate webhooks.

When switching to live, register the webhook using the live key and replace the Vercel webhook secret with the value returned for that registration.

Official webhook guide: https://developer.yoco.com/guides/online-payments/webhooks/listen-for-events

## 4. Redeploy and test

After all three secrets are saved, open Vercel → peri-q-ui → Deployments → latest production deployment → Redeploy.

- Open https://rastasperiq.co.za/checkout/. Card payment becomes selectable when server credentials and the payment tables are accessible.
- Use Yoco's current sandbox card details from its developer documentation.
- Test a successful payment, a declined payment and a cancelled checkout.
- Confirm the order shows **Paid** only after the signed webhook arrives. A successful browser redirect alone does not mark an order paid.
- Confirm the restaurant's mobile owner dashboard shows the website order.
- After test success and domain approval, replace the test secret key and webhook secret with the live values, redeploy, and have the owner perform and reconcile a small authorised live payment.

No real Yoco transaction has been tested yet because your Yoco account has not been set up.

## 5. Remaining manual checks

- Confirm Yoco's business verification and payout/bank details are complete.
- Check the business contact information, privacy policy and terms on the site are accurate for the restaurant.
- Verify the Android app on a real phone: cash order, order tracking, owner dashboard and notifications. No Android phone was connected during the automated checks.
- Optional security improvement: enable Supabase leaked-password protection if your plan supports it. Supabase's advisor reports that it is currently disabled: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

The menu and store settings use the same Supabase project as the mobile app. Changing menu items or store hours in the mobile owner dashboard also changes the website's data.
