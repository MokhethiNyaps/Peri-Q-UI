# Order Fulfilment Data Audit

## Outcome

The customer name, phone number, order type, and delivery address were already
collected, submitted, stored, and retrieved correctly. The defect was limited
to the Flutter owner-dashboard presentation: the incoming-order card rendered
the customer name and order type but did not render the `customerPhone` or
`deliveryAddress` values already present in its `OrderModel`.

There is no separate order-management website in this repository. The
`website/` Next.js application is the public landing, privacy, terms, and
account-deletion site. The protected owner dashboard is part of the Flutter
application.

## Evidence trace

1. `checkout_screen.dart` requires a customer name and phone number. It shows
   and requires the address field only when **Home Delivery** is selected.
2. `app_controller.dart` blocks a delivery submission with an empty address
   and creates an `OrderDraft` containing the customer and fulfilment values.
3. `supabase_order_repository.dart` passes those values to the `place_order`
   RPC as `p_customer_name`, `p_customer_phone`, `p_order_type`, and
   `p_delivery_address`.
4. `supabase/schema.sql` validates the name and phone, rejects a delivery
   address shorter than eight characters, and inserts the values into
   `orders.customer_name`, `orders.customer_phone`, `orders.order_type`, and
   `orders.delivery_address`. Pickup addresses are stored as `null`.
5. The same repository selects and maps all four fields when orders are loaded
   for customers or administrators.
6. The owner dashboard requests all orders only for an authenticated user whose
   profile role is `admin`.
7. The live production REST contract accepted a read selecting all four
   columns. The same unauthenticated request returned zero visible orders,
   confirming that public clients cannot read customer order records.

## Root cause

`_IncomingOrderCard` in `admin_dashboard_screen.dart` discarded
`order.customerPhone` and `order.deliveryAddress` during rendering. The data was
there, but the admin had no visible control or details view that exposed it.

Confidence: **High**. The conclusion is supported directly by checkout,
repository, SQL, model, RLS, dashboard, and live read-only API evidence.

## Fix

The incoming-order card now includes an admin-only fulfilment panel showing:

- a prominent **Home Delivery** or **Pickup in Store** label;
- customer name;
- selectable phone number;
- delivery address and saved address instructions for delivery orders;
- a clear no-address-required message for pickup orders; and
- payment method.

If a legacy delivery order has no address value, the panel shows
**Not recorded on this order** instead of crashing or hiding the problem.

## Security and compatibility

- No order table or RPC change was needed, so there is no database migration
  for this fix.
- Existing order structures remain compatible; nullable legacy values are
  handled explicitly.
- The owner-dashboard route and screen remain guarded by the Supabase admin
  role.
- Supabase RLS continues to allow an order owner to see only their own orders
  and an administrator to see all orders.
- No personal information is logged by the new UI or tests.
- The public Next.js website was not changed and does not receive order data.

## Validation

- Delivery without an address is rejected before repository submission.
- A valid delivery draft retains the customer name, normalised phone, order
  type, address, and instructions.
- Pickup succeeds without a delivery address.
- Widget tests cover delivery, pickup, and legacy missing-address rendering.
- The full Flutter test suite, Flutter static analysis, website ESLint,
  TypeScript, and the website production build pass.

## Live-data limitation

The live schema contract and anonymous RLS behaviour were checked read-only.
No production test order was created because doing so would add real operational
data and cannot be safely rolled back through the public API. The owner should
complete the final two-account test in the closed-test build: place one clearly
labelled test delivery order as a customer, verify the exact stored row in the
Supabase Table Editor, and view it from an administrator account before moving
the release forward.
