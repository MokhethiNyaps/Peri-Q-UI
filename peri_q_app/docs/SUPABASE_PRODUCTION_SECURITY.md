# Supabase Production Security

The mobile app contains only the Supabase URL and publishable key. These identify the project but do not grant trusted access; RLS and RPCs are the security boundary. Never place a service-role key in Flutter source, `.env`, CI logs or Play artifacts.

## Changes in `supabase/schema.sql`

- RLS remains enabled on `profiles`, `app_settings`, `menu_categories`, `menu_items`, `orders` and `order_items`.
- `profiles_insert_own` requires a customer role. `profiles_protect_role` blocks client role escalation; only an existing database-authorised admin can change roles.
- Customers can read only their own orders/items. Admin access is evaluated by `public.is_admin()` against the trusted profile row.
- Direct customer inserts into `orders`/`order_items` were removed.
- `public.place_order` is a security-definer RPC granted only to `authenticated`. It validates store hours in `Africa/Johannesburg`, fulfilment availability, address/payment compatibility, menu availability, quantities, spice options, add-ons, trusted prices, trusted delivery fee and expected total. It uses a per-user unique idempotency key and commits header/items atomically.
- `orders_validate_status` permits only `Pending → Preparing → Ready → Completed`, plus `Pending → Cancelled`, and only for admins.
- Order queries are bounded in the client; realtime visibility remains subject to RLS.
- `payment-proofs` is private, limited to 5 MB and JPG/PNG/WebP/PDF. Object paths are `{userId}/{orderId}/{timestamp-safeName}`. Owners can access their prefix; admins can read for reconciliation.
- `attach_payment_proof` verifies order ownership, EFT payment method and the exact user/order path before linking the private object.
- `delete_own_account` deletes only `auth.uid()`. The client removes that user's private proof objects first; `profiles` and `orders` cascade from `auth.users`.
- Menu image writes remain admin-only. File names are sanitised, uploads are limited to 5 MB image types, and the public bucket is intentional because menu photos are public catalogue content.

## Deployment procedure (owner action)

1. Back up the production database and export current policies/functions.
2. Apply the schema to a staging project first. The file is idempotent for its tables/policies but still changes live authorisation and ordering behaviour.
3. Enable Email and Anonymous Auth. Do not enable anonymous auto-cleanup that would remove active guest order history prematurely.
4. Run the supplied SQL in the Supabase SQL editor or established migration pipeline.
5. Confirm both buckets exist: public `menu-images`, private `payment-proofs` with the documented size/MIME limits.
6. Promote an owner only from a trusted SQL/admin session: `update public.profiles set role = 'admin' where email = 'OWNER_EMAIL';`.
7. Test malicious cases in staging: fake price, fake delivery fee, unavailable item, other user's order/proof, role update, invalid status jump, duplicate request ID and oversized upload.
8. Configure custom SMTP and password-reset redirect URLs. Rotate any key that has ever been exposed.

## Production tests not executed here

No migration was applied to the live project. RLS/RPC behaviour was reviewed statically and the Flutter callers compile/test, but database execution must be verified in staging before rollout.
