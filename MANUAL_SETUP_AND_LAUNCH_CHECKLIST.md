# PeriQ Chesanyama — Manual Setup & Launch Checklist

> **You are a beginner — this file tells you exactly what to click, what to copy, and when.**  
> **Do the sections in order: A → B → C → D → E. Each section says if it’s *before testing*, *before deployment*, or *before real payments*.**  
> Domain: **rastasperiq.co.za** • Website folder: `website/` • Mobile app folder: `peri_q_app/` • Supabase project shared by both.

---

## A. Things you must obtain from the restaurant owner

**When:** Before testing (A1–A3), before live payments (A4–A6).  
**Why:** Secrets and legal approvals cannot be faked — only the account holder can open them.

| # | What to ask for | Why you need it | Owner must do personally? | Where they find it |
|---|---|---|---|---|
| A1 | **Supabase project URL** + **publishable key** + **service-role key** | Website and app both read/write the same Postgres. Service-role lets the website verify Yoco webhooks server-side. | Yes — only a Supabase project owner/member can see service-role. | Supabase Dashboard → your project → **Project Settings → API** → `Project URL` (`https://<ref>.supabase.co`), `anon public` (publishable) and `service_role` (secret, eye-icon). |
| A2 | **Yoco Business App login** (email + phone with 2FA) | Only the logged-in Yoco account can reveal test/live keys and verify a domain. | **Yes** — don’t ask them to paste keys in chat. Ask them to do steps B2/B4 themselves or screen-share while you watch. | Install **Yoco App** on their phone / log in at **app.yoco.com** → **Sales → Payment Gateway**. |
| A3 | Confirm **business details for the site footer & privacy policy**: legal name, support email (`contact@rastasperiq.co.za` is current), support phone(s), street address. | Shown on `rastasperiq.co.za` footer, contact page and legal pages. Must be accurate before publishing. | Yes — owner/legal. | Owner’s CK docs / previous invoice. |
| A4 | **Yoco Test keys** (`sk_test_...` + `whsec_...`) | You test checkout without moving real money. | Owner taps **How to connect → Test keys** and copies. | Yoco App → Sales → Payment Gateway → **How to connect → Test keys** tab. |
| A5 | **Yoco Live keys** (`sk_live_...` + `whsec_...`) + **Verified Domain approval** | Live keys stay locked until at least one domain is verified. Live money only works after approval. | **Yes** — owner adds domain and waits for Yoco review (often hours). | Yoco App → Sales → Payment Gateway → **How to connect → Verified Domains → Add domain → https://rastasperiq.co.za** → wait → **Live keys** tab unlocks. |
| A6 | Approve **legal wording** (privacy policy + terms and conditions pages) | You must not publish inaccurate legal claims about data handling. | Yes — owner or legal adviser reads `/privacy-policy/` + `/terms-and-conditions/` and signs off. | Open `https://rastasperiq.co.za/privacy-policy/` after deployment. |

> **Never ask the owner to paste private keys into WhatsApp or email in plain text.** Have them **add directly into Vercel/Supabase dashboards** themselves, or use a password manager share.

---

## B. Things you must configure (actual service names + exact clicks)

### B1. Supabase — enable website guest checkout + apply migration

**Required before: testing (both), and before any website order.**

1. Open **Supabase Dashboard** → your project (same one the Android app already uses).
2. **Authentication → Providers → Email** → ensure **Enabled** (already for app).
3. **Authentication → Providers → Anonymous** → **Enabled** (required for guest checkout — website calls `auth.signInAnonymously()` like the app does). Save.
4. **Authentication → URL Configuration → Redirect URLs** — ensure `https://rastasperiq.co.za/**` is allowed (for later password resets, harmless).
5. **Backup first:** **Database → Backups** → **Create backup** (or use **Database → PITR** snapshot). Download a dump if possible: **Database → … → Download**. Do not run migrations without this.
6. **Staging first if you have one:** create a second Supabase project (“staging”), apply the migration there and test menu load + checkout before production.
7. **Apply migration:** **SQL Editor → New query** → open `peri_q_app/supabase/migrations/20261012_yoco_payments.sql` (and also note `supabase/schema.sql` already patched for fresh installs) → paste → **Run**. Also re-run `supabase/schema.sql` if you are on a brand-new project; on an existing project run *only* the migration file — it is idempotent (`if not exists`).
8. Verify: **Table Editor** → `orders` now has columns `yoco_checkout_id`, `payment_status`, `paid_at`, `payment_amount_cents`, `yoco_payment_id`, `yoco_mode`. **Table Editor** → new tables `payments` and `yoco_webhook_events` exist. **Database → Roles** → no errors.
9. **Storage** — nothing to change: buckets `menu-images` (public) and `payment-proofs` (private) already exist.

> If the production project already had orders, the migration backfills `payment_status = 'unpaid'` safely and does **not** delete any rows.

### B2. Yoco — obtain test credentials and register webhook (owner does this)

**Required before: Yoco testing (section C). Test domain does NOT need verification.**

1. Owner logs into **Yoco App** → **Sales → Payment Gateway** → **How to connect**.
2. Tab **Test keys** → copy **Test secret key** (`sk_test_...`) and **Webhook secret** (`whsec_...`) — they are under “Test keys”. If you only see public key, tap “Reveal”.
3. **Webhooks:** In the same screen → **Webhooks** → **Add webhook** (or **Register webhook**):  
   **Name:** `rastasperiq-website`  
   **URL:** `https://rastasperiq.co.za/api/yoco/webhook`  
   **Events:** tick **payment.succeeded** and **payment.failed** (uncheck others). Save.  
   You can also register via API directly (see below) — but dashboard is the manual step.
4. Keep this browser tab open for **Test card details** (Yoco shows them on the same “How to connect” page under **Test card details**). Typical test card: `4242 4242 4242 4242`, expiry any future date, CVC `123`. Owner can screenshot it for you.

### B3. Vercel — connect Supabase + site URL to the website deployment

**Required before: testing on Vercel Preview *and* before production deployment.**

1. Open **vercel.com** → log in → **Dashboard → your project** (imported from GitHub with **Root Directory = `website`** — keep that).
2. **Settings → Environment Variables** → add **all** of these for **Production** (and Preview if you want previews to order). Use the *value only* — don’t include the `NAME=` prefix or quotes.

   | Variable | Where to get the value | Example (placeholder only) |
   |---|---|---|
   | `NEXT_PUBLIC_SUPABASE_URL` | Supabase Project Settings → API → Project URL | `https://abcdefghijk.supabase.co` |
   | `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Supabase Project Settings → API → `anon public` (publishable) | `sb_publishable_xxx` or JWT anon |
   | `NEXT_PUBLIC_SITE_URL` | Your canonical site | `https://rastasperiq.co.za` |
   | `SUPABASE_URL` | Same as `NEXT_PUBLIC_SUPABASE_URL` but server-only copy | `https://abcdefghijk.supabase.co` |
   | `SUPABASE_SERVICE_ROLE_KEY` | Supabase Project Settings → API → `service_role` (secret) — **never put in `NEXT_PUBLIC_`** | `sb_secret_xxx` |
   | `YOCO_SECRET_KEY` | **Test first:** `sk_test_...` from B2. **Later live:** `sk_live_...` from B4 | `sk_test_...` |
   | `YOCO_WEBHOOK_SECRET` | `whsec_...` from B2/B4 (must match the webhook’s secret) | `whsec_...` |
   | `SITE_URL` (fallback) | Same as NEXT_PUBLIC_SITE_URL | `https://rastasperiq.co.za` |
   | `NEXT_PUBLIC_INSTAGRAM_URL` etc | Only if you have them (footer socials). Otherwise leave empty — they simply hide. | `https://instagram.com/...` |

3. **Redeploy** is required after any `NEXT_PUBLIC_*` change (Next.js inlines them at build time). Click **Deployments → … → Redeploy** → uncheck “Use existing Build Cache” for safety.

4. Keep **Root Directory = `website`**, **Framework = Next.js**, **Build Command = `pnpm build`** (auto-detected). **No `Output Directory` override** — new build is serverless (not `out/`).

### B4. Yoco — go live (only when ready for real money)

**Required before: accepting real payments (section E). Do NOT do before testing.**

1. Deploy your website to **https://rastasperiq.co.za** (section D) — Yoco requires the live URL exists.
2. Owner → Yoco App → **Sales → Payment Gateway → How to connect → Verified Domains → Add domain** → enter exactly `https://rastasperiq.co.za` → **Submit** → wait for Yoco review (email notification). Live keys stay locked until approved.
3. After approval, same screen → **Live keys** tab → copy **Live secret key** (`sk_live_...`) and **Live webhook secret** (`whsec_...` may be same or new). Update Vercel env vars `YOCO_SECRET_KEY` and `YOCO_WEBHOOK_SECRET` to live values, **Redeploy** (Production).
4. Re-register the webhook with the live key if it was created with test key:  
   ```bash
   curl -X POST https://payments.yoco.com/api/webhooks \
     -H "Authorization: Bearer sk_live_..." \
     -H "Content-Type: application/json" \
     -d '{"name":"rastasperiq-website-live","url":"https://rastasperiq.co.za/api/yoco/webhook"}'
   ```
   Or re-add in the Yoco dashboard under **Live** webhook section.

### B5. Domain & HTTPS (if not already live)

**Required before: deployment (section D) if domain not yet pointing to Vercel.**

1. Vercel → **Project → Settings → Domains** → add `rastasperiq.co.za` and `www.rastasperiq.co.za`.
2. Vercel shows the DNS records (usually `A 76.76.21.21` or `CNAME cname.vercel-dns.com`). At your domain registrar (where `rastasperiq.co.za` was bought), add exactly those records.
3. Wait for **Valid Configuration** green tick (minutes to hours). HTTPS cert is auto-provisioned — **never** handle TLS yourself.

---

## C. Yoco testing (step-by-step, no real money)

**Do this on a Vercel Preview deployment with `sk_test_...` + `whsec_...` configured. Use Yoco’s official test card — not a real card.**

### C1. Prepare

1. In Vercel, ensure **Preview** environment has the **test** `YOCO_SECRET_KEY` + `YOCO_WEBHOOK_SECRET` + Supabase vars, then **Redeploy Preview** (get the preview URL, e.g., `https://peri-q-ui-xxx.vercel.app`).
2. Alternatively test directly on `https://rastasperiq.co.za` preview after switching it to test keys (but warn owner it’s test mode — no real money moves).

### C2. Test happy path — website checkout via Yoco

1. Open `https://<preview-url>/menu/` (or `/menu/` on production if test keys there).
2. Add **2–3 items** to cart (pick items with known prices). Note the subtotal.
3. Go to **Cart** → increase/decrease quantity → verify subtotal updates.
4. Click **Proceed to checkout** → fill:
   - Full name (>=2 chars)
   - Phone (>=7 chars)
   - Choose **Home Delivery** → enter a full address (>=8 chars) OR **Pickup**.
   - Choose **Pay online with Card (Yoco)**.
5. Click **Place order & Pay with Yoco**.
6. You should be **redirected to `yoco.pay` / Yoco hosted checkout** (`https://payments.yoco.com/...` redirectUrl). If you see an error page instead: check Vercel logs (Deployments → View Function Logs) for `Yoco checkout failed` — usually missing/invalid `YOCO_SECRET_KEY` or amount < R2.00.
7. On Yoco checkout page, enter **test card**:
   - Card number `4242 4242 4242 4242`
   - Expiry: any future `12/30`
   - CVC `123` (Yoco dashboard shows exact test card to use — they sometimes rotate).
8. Complete the payment → You are redirected to `https://<site>/order/<uuid>/?checkout=success`.
9. The order page initially says **“Return from Yoco — verifying payment … Do not pay again”**. Wait 5–20 seconds and **refresh** (or let the 8-second poll update). The **Payment** pill should flip to **Paid ✓** and the “Complete payment” button disappears. **Crucial:** the order is only marked paid after the server verifies the Yoco webhook — NOT on the browser redirect alone. Refresh until you see **Paid**.
10. **Verify in Supabase:** SQL Editor → run:
    ```sql
    select id, order_number, payment_status, paid_at, yoco_checkout_id, total_price
    from orders where id = '<order-uuid>' ; -- paste your order id
    select * from payments where order_id = '<order-uuid>';
    select * from yoco_webhook_events order by created_at desc limit 5;
    ```
    `orders.payment_status` should be `paid`, `payments.status` `succeeded`, latest `yoco_webhook_events.type` `payment.succeeded` and `processed = true`.

### C3. Test payment failures and cancellations

| Scenario | How to trigger | Expected outcome |
|---|---|---|
| **Cancel** | At Yoco checkout, click **Cancel / Back** or close tab without paying | Redirected to `/order/<id>/?checkout=cancel` → yellow “Payment was cancelled — You left the Yoco checkout without completing. Order saved — retry.” → **Payment remains `pending`**, order **not** marked paid. Clicking **Pay R… with Yoco** again should reopen Yoco checkout (idempotent retry). |
| **Declined card** | Use Yoco’s **declined test card** (`4000000000000002` often, or whatever Yoco lists as test-decline) | Redirected to `/order/<id>/?checkout=failure` → red “Payment did not complete — Card declined.” Webhook `payment.failed` arrives → server sets `orders.payment_status = 'failed'` and `payments.status = 'failed'`. Order page shows **Payment failed**. You can retry (new checkout) or switch to **Cash** by creating a new order. |
| **Pending / 3DS** | Use Yoco’s 3DS test card if provided (requires challenge) → complete or abandon challenge | Shows pending then either `paid` or `failed` after webhook. |
| **Expired** | Start checkout and **wait without paying** (Yoco checkout expires; Yoco may send `checkout.expired`) — or just leave order pending | Order stays `pending`. Webhook `checkout.expired` (if subscribed) or manual retry. No money taken. |

### C4. Verify payment verification works (no real money)

1. **Webhook secret check:** In Vercel → **Settings → Environment Variables** → temporarily change `YOCO_WEBHOOK_SECRET` to a wrong `whsec_fake` → redeploy → redo a test checkout + pay with test card → order page stays `pending` forever, Vercel logs show `Webhook signature invalid`. Fix secret back to correct `whsec_...` → redeploy → Yoco **retries** the webhook (up to 8 times over 25h) → on next retry (5 sec → 5 min → 30 min etc) it will succeed and mark paid. This proves signature verification is working.
2. **Amount tampering check:** Try to intercept with browser devtools and change the JSON `amount` before Yoco call — impossible because Yoco amount is set server-side in `/api/yoco/checkout` from `orders.total_price * 100`. Even if you post a fake amount to Yoco, the webhook handler compares `webhook amount` vs `trusted amount` and **will NOT mark paid** on mismatch (see Vercel logs `amount mismatch`). Correct behavior.
3. **Duplicate webhook:** In Supabase, note a `yoco_webhook_events.id` (e.g., `evt_123`). Manually re-POST the same webhook body (copy from Vercel logs or test via `curl`) to `https://<site>/api/yoco/webhook` with same headers — server should respond `200 duplicate: true` and **not** create a second `payments` row (unique `webhook_event_id`). Check Table Editor `yoco_webhook_events` — only one row with that id.
4. **Duplicate checkout on refresh:** After clicking **Place order & Pay with Yoco**, hit browser **Refresh** quickly before redirect. Network tab shows only one `POST /api/yoco/checkout`? Our API uses `Idempotency-Key: client_request_id` — Yoco will return the **same** `redirectUrl`/`id` instead of charging twice. Verify in Supabase: `orders.yoco_checkout_id` set once, `payments` single row, not duplicated.

### C5. How to confirm webhook reached the server without using real money

- **Vercel logs:** Deployments → Latest deployment → **Runtime Logs** → filter `yoco` → see `yoco webhook: payment.succeeded` or signature logs.
- **Supabase tables:** As in C2 step 10, check `yoco_webhook_events` new row appears within seconds of paying with test card. If not, check Vercel env `YOCO_WEBHOOK_SECRET` (must start `whsec_` and be base64), check Yoco dashboard webhook URL exactly `https://rastasperiq.co.za/api/yoco/webhook` with `payment.succeeded` + `payment.failed` ticked.
- **ngrok local test (optional):** For localhost, run `npx ngrok http 3000` → put `https://<ngrok>.ngrok-free.app/api/yoco/webhook` as webhook URL in Yoco dashboard (test only) → redo checkout → see ngrok request inspector and local server logs. Remove ngrok URL after testing.

---

## D. Website deployment (how to deploy, configure domain, HTTPS, and check live)

**Assumes you already configured env vars in B3 and applied migration in B1.**

### D1. Run locally (before pushing)

```bash
cd website
cp .env.example .env.local          # fill with your test Supabase + Yoco test keys + NEXT_PUBLIC_SITE_URL=http://localhost:3000
pnpm install
pnpm dev    # open http://localhost:3000
pnpm build  # must succeed without type errors
pnpm test   # 29 website tests (cart + menu + yoco)
```

> Need to test webhook locally? Keep `pnpm dev` running, expose with `npx ngrok http 3000`, temporarily set Yoco webhook URL to your ngrok URL.

### D2. Deploy to Vercel

1. **GitHub:** `git add` + `git commit` + `git push origin arena/aa6bfb2c-peri-q-ui` (you are already on this branch). Ensure `website/.env.local` is **not** committed (it’s gitignored).

2. **Vercel Dashboard → Project → Deployments:** If the project is already linked to GitHub, a preview deployment triggers automatically on push. Otherwise:
   - **Add New → Project → Import Git Repository →** select `MokhethiNyaps/Peri-Q-UI` → **Framework Preset: Next.js** → **Root Directory: `website`** → **Build Command:** `pnpm build` (auto) → **Environment Variables:** paste the production vars from B3 → **Deploy**.

3. **Production promotion:** In Deployments, click **… → Promote to Production** (or merge branch to `main` if your Git integration promotes `main` automatically).

4. **Caching:** After adding/changing any `NEXT_PUBLIC_*` variable, you **must Redeploy** (Deployments → … → Redeploy) because Next.js embeds them at build time.

### D3. Domain & HTTPS check

1. **Settings → Domains** should show `rastasperiq.co.za` and `www.rastasperiq.co.za` as **Valid Configuration** with a green check. If not, fix DNS as in B5.
2. Visit `https://rastasperiq.co.za` → header should show **Menu & Order** + **Cart**. Visit `https://rastasperiq.co.za/api/yoco/webhook` via GET in browser → should return JSON `{ ok:true, message:"Yoco webhook endpoint..." }` (proves serverless functions are live, not static `out/`).
3. Visit `https://rastasperiq.co.za/menu/` → menu items load without “Menu is not yet connected” error (if you see that, Vercel env `NEXT_PUBLIC_SUPABASE_URL/_PUBLISHABLE_KEY` is missing/typo).
4. Check **HTTPS** padlock is valid (Vercel auto-issues Let’s Encrypt). If mixed-content warnings, ensure `NEXT_PUBLIC_SITE_URL` uses `https://`.

### D4. Verify build mode changed (no longer static export)

- Old docs said `pnpm build` → `out/` folder. **New** `next.config.ts` removes `output:"export"`. Now `pnpm build` creates `.next/` + serverless functions (shown as `ƒ /api/yoco/checkout` in build logs). **Do not** look for `out/` anymore. Vercel’s “Build Output” must show `λ`/`ƒ` for API routes, not `○` only.

---

## E. Final launch checks (practical end-to-end checklist before accepting real payments)

Do this **after** B4 live keys approved **and** after D3 domain is green. Use a **real** card with R2.00 test? No — for final live check use a real card but **small amount**: order the cheapest menu item (e.g., `R15 Cold Drink`) for collection and pay R15 via Yoco **or** ask the owner to do a live R5 checkout and immediately refund via Yoco dashboard (`payment.failed` not refunded in test mode, but live refund via `POST /checkouts/{checkoutId}/refund`).

- [ ] **Menu parity:** Open `https://rastasperiq.co.za/menu/` and the Android app side-by-side → same categories, same item names, same `R` prices for at least 5 items (e.g., Wors Meals, Combo Plates). If not, check that Vercel env points at **same Supabase project** as the app (`SUPABASE_URL`). Table Editor `menu_items` should be single source.
- [ ] **Guest ordering still works on website:** In a Chrome **Incognito** window (no login), add to cart → checkout as guest with name/phone → choose **Cash on Collection** → confirm → order appears in Supabase Table Editor `orders` with `payment_method = cash_collection` and `payment_status = unpaid`.
- [ ] **Mobile app regression:** On an **Android phone** (or emulator) with the PeriQ app → place a **cash** order → it appears in the same `orders` table and in the app’s **Orders** screen. No “store closed” error regressions.
- [ ] **Admin sees website orders:** In the Android app logged in as **admin** (or via Supabase Table Editor filtering `orders` → `order by created_at desc`) → verify the website order appears with correct `customer_name`, `order_type`, `delivery_address` (if delivery) and `payment_method`. Realtime update works: place a website order while admin app is open — new order row appears without manual refresh.
- [ ] **Yoco live checkout:** Create a **live** website order → choose **Pay online with Card (Yoco)** → pay with a **real** card (use the owner’s card, small amount) → redirect → wait → order page shows **Paid ✓** and Supabase `orders.payment_status = paid` + `paid_at` set + `payments.status = succeeded`. If owner’s Yoco balance increases even a few cents, money moved — then refund it immediately in Yoco dashboard to prove refunds path.
- [ ] **Failed then retry:** Intentionally enter wrong CVC or use a declined test card on live? Better: cancel the Yoco page → see **Payment was cancelled**, `payment_status = pending` still, **Pay again** button still works, **no second charge** without re-authorizing.
- [ ] **Duplicate prevention:** Click **Place order & Pay with Yoco** twice quickly (double-click) — only **one** `orders` row with that `client_request_id` should exist (`unique(user_id, client_request_id)` advisory lock). Network tab should show second RPC returning same `id`. No double charge in Yoco dashboard (one `checkoutId`).
- [ ] **Unauthorized access:** Try to fetch another user’s order ID by guessing UUID in a logged-out browser → `Order not found` page (RLS requires owner OR `user_id = auth.uid()`). Admin can still see all via service-role.
- [ ] **No secrets in browser bundle:** Open `view-source` on `https://rastasperiq.co.za/menu/` and search for `sk_live`, `service_role`, `whsec` → **none** found. Those strings only live in Vercel server env and Supabase.

---

## F. Troubleshooting (what to check when something fails)

### 1. Website cannot load the menu (“Menu is not yet connected” or empty)

| Check | Fix |
|---|---|
| Vercel → **Settings → Env** → `NEXT_PUBLIC_SUPABASE_URL` & `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` present and exactly the URL `https://<ref>.supabase.co` (no `=` / quotes / trailing slash)? | Fix value, **Redeploy** (required for `NEXT_PUBLIC_*`). |
| Supabase → **Authentication → Anonymous enabled**? | Enable and retry (guest menu read still works without auth, but checkout will fail). |
| Supabase → **Table Editor** → `menu_items` has rows? RLS policy `menu_items_read_all` exists (`select true for anon,authenticated`)? | Re-run `supabase/schema.sql` or migration; check **Database → Roles**. |
| Browser DevTools → Console → `Failed to load menu` network 401? | Publishable key wrong or not `sb_publishable_...` format. Check `SUPABASE_SETUP.md` key types. |
| Local `.env.local` vs Vercel mismatch? | `NEXT_PUBLIC_*` values must match between local and Vercel to see same menu. |

### 2. Order does not appear in restaurant system (app/Table Editor)

| Check | Fix |
|---|---|
| Website showed “Could not place order” snackbar with `Price changed`? | Delivery fee or menu price changed after you loaded menu → **refresh `/menu/`** → re-add cart → retry. Server is protecting you from stale price — correct. |
| Supabase → **Logs → API** has `place_order` error `Ordering is paused` / `Store is closed`? | Check `app_settings` row (`id=default`) → `store_open = true`, `opening_time`/`closing_time` vs local time `Africa/Johannesburg`, and `pickup_available`/`delivery_available` toggles in admin dashboard. |
| Order appears in `orders` Table Editor but not in admin app? | Admin app `fetchOrders(includeAll:true)` limits to 100 newest; ensure you’re logged in as `profiles.role='admin'` (`update profiles set role='admin' where email=...`). Check admin filter “All” vs own. |
| Used different Supabase projects for website vs app? | Align envs — both must point at same `SUPABASE_URL` project `ref`. Query `select count(*) from orders` on both dashboards — should match. |

### 3. Yoco rejects a payment (error before card form or “Yoco checkout failed”)

| Check | Fix |
|---|---|
| Vercel → `YOCO_SECRET_KEY` starts `sk_test_` (for test) or `sk_live_` (for live) and not `pk_test`? | Only `sk_...` works server-side. Copy from **How to connect → Test/Live secret key** (not public). Redeploy. |
| Amount < R2.00 (200c)? | Cheapest menu item must be ≥ R2; empty cart → 0 fails. Check `orders.total_price` math. |
| Live checkout with test key used on `https://rastasperiq.co.za`? Live domain with test key should still work, but live payments with test key will show `test` mode; no real settlement — expected. |
| Live checkout fails with `Domain not verified`? | Live `sk_live_` only works after Yoco approved the domain in **Verified Domains**. Until then you’ll see `Domain not verified` — switch back to `sk_test_` for testing, or wait for approval and retry with live key. |
| Vercel logs show `401 Unauthorized` from `payments.yoco.com`? | Secret key typo or base64 whitespace. Copy again cleanly (no trailing newline). |
| CORS error on browser? | You should **never** call `payments.yoco.com` from the browser — only from `/api/yoco/checkout` server. If you see CORS, you moved secret to client — revert. |

### 4. Payment succeeds but order remains pending (webhook not marking paid)

**This is the most common Yoco issue. The browser `success` redirect never marks paid — only the webhook does.**

| Check | Fix |
|---|---|
| **Is Vercel webhook secret correct?** `YOCO_WEBHOOK_SECRET` must be exactly `whsec_...` from the **same** key tab (Test vs Live) that the checkout used. Mismatched test/live secret → signature fails → `Webhook signature invalid` in Vercel logs → webhook keeps retrying (5s → 5m → 30m). | Set correct `whsec_...` in Vercel env matching the key used; Redeploy; wait for next retry (check logs). |
| **Is webhook URL exactly registered?** Must be `https://rastasperiq.co.za/api/yoco/webhook` (note `https`, not `http`, and `/api/yoco/webhook` not `/api/yoco/webhook/`). | In Yoco App → Sales → Payment Gateway → **Webhooks** → edit to exact URL → Save. Or re-POST via API: see B4. |
| **Did Vercel receive the POST?** Vercel → Deployments → Latest → **Runtime Logs** (or **Web Analytics → Functions**) filter `webhook`/`yoco` — you should see a POST within seconds of paying. If no log at all, Yoco isn’t reaching Vercel: check that `https://rastasperiq.co.za/api/yoco/webhook` is publicly reachable (`curl -i https://rastasperiq.co.za/api/yoco/webhook` returns 200 JSON message). Cloudflare or other proxy blocking? |
| **Amount mismatch?** Vercel logs `amount mismatch — NOT marking paid` | Webhook amount (`payload.amount`) vs trusted `orders.payment_amount_cents` differ. Did you change `orders.total_price` manually after checkout? Don’t edit orders manually before webhook arrives. The handler refuses to mark paid on mismatch to prevent underpayment — admin must reconcile via Table Editor and contact support. |
| **Event already processed?** Check `yoco_webhook_events` → row `processed = true`. Second identical webhook will be `duplicate:true` and ack 200 but not re-update. That’s correct idempotency. |
| **Check service-role key still valid?** Rotate? Vercel → `SUPABASE_SERVICE_ROLE_KEY` must be current. If you rotated it in Supabase dashboard, update Vercel. |
| **Polling fallback:** Keep order page open → it polls every 8s; or manually run SQL: `select payment_status,paid_at from orders where id='...'` to see if webhook finally landed after a retry window. Yoco retries for ~25h even if server was briefly down. |

---

## When is each manual task required?

| Timing | Tasks |
|---|---|
| **Before any testing** | A1 (Supabase keys), A3 (business details for footer), B1 (enable Anonymous + backup + migration), B3 (Vercel env vars with *test* Yoco keys + Supabase keys + redeploy) |
| **Before Yoco test transactions** | A4 + B2 (test keys + webhook URL + test card) |
| **Before deployment to `rastasperiq.co.za` production** | D1–D3 (local build passes, push to GitHub, Vercel import with Root `website`, DNS valid, webhook reachable) |
| **Before accepting real money / going live** | A5 + B4 (Live keys + Verified Domain approved + switch Vercel to `sk_live` + re-register webhook live), A6 (legal sign-off), E full checklist (small live payment + refund) |

---

## Quick command reference

```bash
# Website local
cd website
cp .env.example .env.local   # fill with test keys, set NEXT_PUBLIC_SITE_URL=http://localhost:3000
pnpm install
pnpm dev                     # http://localhost:3000/menu
pnpm build                   # must say ✓ Compiled + no type errors
pnpm test                    # 29 tests
pnpm lint                    # warnings only, 0 errors

# Trigger webhook registration manually (owner must have sk_...):
curl -X POST https://payments.yoco.com/api/webhooks \
  -H "Authorization: Bearer sk_test_..." \
  -H "Content-Type: application/json" \
  -d '{"name":"rastasperiq-website","url":"https://rastasperiq.co.za/api/yoco/webhook"}'

# Supabase verify
# SQL Editor → paste migration file, run → Table Editor checks
```

---

## Support contacts included in repo

- **Site config:** `website/lib/site.ts` (email `contact@rastasperiq.co.za`, phones +27 73 642 3549, address 28 King Edward Rd).
- **Schema source:** `peri_q_app/supabase/schema.sql` + migration `20261012_yoco_payments.sql`.
- **Owner docs to hand over:** `IMPLEMENTATION_PLAN.md` (this repo) + this checklist. Never include `service_role` or `sk_...` in any doc or Git commit.

