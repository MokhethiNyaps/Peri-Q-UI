# 01a — Live Supabase Security Check (read-only)

**Date:** 2026-11-03
**Project:** Peri Q (`nxzelriapklqaxcxmoys`, eu-west-1, Postgres 17)
**Method:** Supabase security advisors plus read-only catalogue queries: policies, grants, functions, triggers, foreign keys, buckets, and row counts only. Nothing in the database was changed. No customer records were read.

This check closes the "live policies not verified" gap in [01-initial-audit.md](01-initial-audit.md) §D.0.

## 1. Result in one line

The live database matches `schema.sql` on every protection that matters. Customers cannot read each other's data, create or alter orders, mark orders as paid, or make themselves admin. The audit's open findings are confirmed live, and the check adds two small new ones.

## 2. Key protections, confirmed live

| Protection | Live evidence |
|---|---|
| RLS on every `public` table | RLS is enabled on all 12 tables. |
| Customer isolation | `orders_select_owner_or_admin`, `order_items_select_owner_or_admin`, `payments_owner_read`, `profiles_select_own_or_admin` and `checkout_owner` all filter on `auth.uid()` or `is_admin()`. |
| No customer writes to orders | `orders` has only an admin `UPDATE` policy and a `SELECT` policy. There is no insert or delete policy. |
| Paid orders only from the verified webhook | The `require_verified_card_order` trigger (BEFORE INSERT OR UPDATE) requires `service_role` + `yoco` + `paid` + `paid_at` + `yoco_payment_id`. `finalize_card_checkout` cannot be executed by `anon` or `authenticated`. |
| Old order path closed | `place_order` is a stub that always raises "Pay by card through Yoco checkout". |
| No self-promotion to admin | `profiles_insert_own` forces `role = 'customer'`. The `profiles_protect_role` trigger blocks role changes by non-admins. |
| Server-only tables | `push_tokens`, `push_notification_dispatches` and `checkout_intent_items` have RLS with no policies and no grants to `anon`/`authenticated`. They are reachable only through the service role or security-definer RPCs. This is the intended design: the advisor reports it as INFO. |
| Function hardening | All security-definer functions pin `search_path`. The customer RPCs are not executable by `anon`. |

## 3. Audit findings confirmed live

| Audit ID | Live evidence |
|---|---|
| D-H2 (account deletion destroys financial records) | `orders_user_id_fkey` is **ON DELETE CASCADE** to `auth.users`. `payments_order_id_fkey` and `order_items_order_id_fkey` cascade from `orders`. Deleting a user deletes their orders, items and payments. |
| D-M2 (stale drafts and anonymous users) | 41 auth users, of which **32 are anonymous** (counts only). `checkout_intents` holds 3 drafts, the oldest from 2026-10-20. |
| D-M3 (admin can change any order column) | `orders_admin_update` checks `is_admin()` only, with no column restriction. There are 2 admin profiles. |
| D-M6 (legacy payment-proof uploads) | `payment_proofs_owner_insert` is still live. The `payment-proofs` bucket is private and holds **0 objects**, so removing the policy is cheap. `attach_payment_proof` is still callable but works only on `eft` orders, which can no longer be created. |
| D-M7 (schema not reproducible from migrations) | Only 2 migrations are recorded live (`yoco_payments`, `card_only_checkout`). Everything else was applied outside the migration history. |
| D-L2 (`menu-images` listing) | `menu_images_public_read` (SELECT for anon and authenticated) is live. The bucket is public with a 5 MB limit, images only. |
| D-L3 (`profiles` columns) | `profiles_update_own` has no column restriction. `role` is protected by the trigger, but `email`, `full_name` and `phone` are not validated. |
| D-L4 (password policy) | **Leaked-password protection is disabled** (Supabase advisor). |

## 4. New findings from the live check

**L-1 (Low). Broad default table grants.** `anon` and `authenticated` hold every table privilege (including `TRUNCATE`, `TRIGGER` and `REFERENCES`) on `orders`, `order_items`, `profiles`, `menu_items`, `menu_categories` and `app_settings`. These are Supabase's defaults. RLS still governs `SELECT`/`INSERT`/`UPDATE`/`DELETE`, and the REST API cannot issue `TRUNCATE`, so this is not exploitable today. As defence in depth, revoke `TRUNCATE, TRIGGER, REFERENCES` from both roles, and `INSERT, UPDATE, DELETE` from `anon` on tables that anon never writes.

**L-2 (Low). `touch_updated_at` has a mutable `search_path`** (advisor WARN). It is not security-definer, so the risk is low. Fix it by adding `set search_path = public, pg_temp`.

**Info.** The advisor's "anonymous access policies" warnings appear because anonymous sign-ins are enabled and the policies target `authenticated`, which includes anonymous users. Each policy's condition (`auth.uid()` ownership or `is_admin()`) still applies, so anonymous users see only their own rows. No action needed beyond D-M1/D-M2.

**Info.** `handle_new_user` and `is_admin` are executable by `anon` over RPC. `handle_new_user` is a trigger function and cannot run as an RPC. `is_admin` returns false for anon. Both are harmless, and revoking `EXECUTE` from `anon` is optional tidying.

## 5. Still not verifiable from SQL

These need the Supabase dashboard or the owner:
- Admin MFA enforcement, and Auth rate limits for anonymous sign-ins and sign-ups (D-M1, D-M3).
- Backups and point-in-time recovery (PITR) settings, and a tested restore (D-I8).
- Function and edge-function log retention.

## 6. Effect on the plan

Nothing here changes the stage order in 01-initial-audit §F. Findings L-1 and L-2, the D-M6 policy removal and the D-L2 policy scoping all belong in **Stage 6 (database security)**. Turning on leaked-password protection is a one-click dashboard setting the owner can do now (Authentication → Policies / Password security).
