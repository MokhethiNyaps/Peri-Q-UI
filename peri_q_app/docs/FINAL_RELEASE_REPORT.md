# Final Release Report

## Release outcome

The signed Android `1.0.1+2` release is ready for direct APK testing and, after
the manual delivery/pickup smoke test below, upload as the second Google Play
closed-test AAB.

The order data was not missing from checkout, submission, Supabase, or the
admin query. The Flutter owner-dashboard card retrieved the phone and address
but did not render them. This release fixes that presentation gap without
changing the order contract, database schema, RLS policies, public website,
branding, authentication, or unrelated functionality.

## Root cause and data trace

- Checkout already collects customer name and phone for every order.
- Delivery checkout already requires an address; pickup does not.
- `OrderDraft` and `place_order` already submit all required values.
- Supabase already validates and stores `customer_name`, `customer_phone`,
  `order_type`, and `delivery_address`.
- The order repository already selects and maps those columns for the owner.
- `_IncomingOrderCard` showed only the name and order type, discarding the
  mapped phone and address while rendering.
- The live Supabase REST contract accepted a select containing all four columns
  and returned zero orders to an unauthenticated request, consistent with the
  existing RLS protection.

The detailed evidence is in `docs/ORDER_FULFILMENT_AUDIT.md`.

## Fix

Each active order in the protected owner dashboard now displays:

- a prominent **Home Delivery** or **Pickup in Store** label;
- customer name;
- selectable phone number;
- delivery address and saved address instructions for delivery orders;
- an explicit no-address-required message for pickup orders; and
- payment method.

A legacy delivery order with no address displays **Not recorded on this order**
instead of failing or silently hiding the missing value.

## Database, backend, and deployment

- Database migration: **none required**.
- Supabase configuration change: **none required for this fix**.
- Edge Function change/deployment: **none required for this fix**.
- Website change/deployment: **none required**. The Next.js project is the
  public landing/policy site, not the order dashboard.
- Mobile deployment: upload the new AAB to the existing closed-test track only
  after completing the manual smoke test.

The earlier FCM backend steps in `docs/FCM_MANUAL_SETUP.md` remain separate and
must still be completed if they have not already been applied.

## Files changed

1. `lib/src/screens/admin_dashboard_screen.dart`
2. `lib/src/widgets/admin_order_fulfilment_panel.dart`
3. `test/admin_order_fulfilment_panel_test.dart`
4. `test/auth_and_menu_test.dart`
5. `pubspec.yaml`
6. `tool/build_android_release.ps1`
7. `docs/ORDER_FULFILMENT_AUDIT.md`
8. `docs/MANUAL_QA_CHECKLIST.md`
9. `docs/GOOGLE_PLAY_RELEASE_CHECKLIST.md`
10. `docs/FINAL_RELEASE_REPORT.md`

## Release identity

- Package/application ID: `za.co.rastasperiq.ordering` (unchanged)
- Version name: `1.0.1`
- Version code: `2`
- Compile/target SDK: 36
- Minimum SDK: 24
- Build type: release, R8/resource shrinking, Dart obfuscation and split debug
  information
- Signing certificate SHA-256:
  `0BCCBE0AD6A15CD2FEFA9C8E507099259C60BE302ECFD917BA2BFBF28BB218AF`
- Signing identity match: **same certificate as the uploaded build 1**
- Build date: 31 July 2026 (Africa/Johannesburg)

## Release artifacts

| Artifact | Size (bytes) | SHA-256 |
|---|---:|---|
| `release/android/rastas-peri-q-v1.0.1-build2-order-details-release.apk` | 54,493,948 | `325372B98921A89C819F373C04A6E67334336C793A85849819661E28EF64E972` |
| `release/android/rastas-peri-q-v1.0.1-build2-order-details-release.aab` | 53,743,854 | `136F386C3E211DE3923D26609470AF65D25F0A7E21BCA3833844EA42AFBCA9DC` |
| `release/android/rastas-peri-q-v1.0.1-build2-order-details-r8-mapping.txt` | 16,849,045 | `152389278FD6CCEE0D015EB6FB355DF420E80AF2929BF1FF27E9FF70EBCC79C2` |
| `release/android/rastas-peri-q-v1.0.1-build2-order-details-dart-symbols.zip` | 3,223,919 | `8A0A27A2584D73E1DE11622761637C98F0ADAB0803303769D06793EA08FAF808` |

The ignored `release/android/` directory is not committed. Keep the mapping and
Dart symbols paired with this exact AAB.

## Verification evidence

| Gate | Result |
|---|---|
| Formatting | `dart format lib test` passed |
| Flutter analysis | No issues found |
| Flutter tests | All 32 tests passed |
| Delivery rules | Missing delivery address rejected before submission |
| Pickup rules | Pickup accepted without an address |
| Admin rendering | Delivery, pickup, and legacy missing-address cases passed |
| Sensitive logging scan | No phone/address/password/token logging pattern found |
| Supabase live contract | Required columns accepted; anonymous visible order count `0` |
| Deno Edge Function | Formatting and type checks passed |
| Website lint/type check | ESLint and Next.js TypeScript build passed |
| Website production build | All public routes compiled and prerendered |
| Release APK | Built and verified with APK Signature Scheme v2 |
| Release AAB | `jarsigner` verified; bundletool 1.18.3 validation passed |
| Manifest | Package, version `1.0.1`, code `2`, target SDK 36 confirmed |
| Signing continuity | APK and AAB certificate matches build 1 |

No Android device or emulator was connected, so device-level UI and live
admin/customer authentication tests remain manual.

## Manual test before uploading the AAB

1. Install the signed build 2 APK on a customer test phone.
2. Place a clearly labelled **delivery** test order with a test name, reachable
   phone, complete address, and a short instruction such as “Ring the side gate
   bell.”
3. In Supabase Table Editor, inspect that order's actual `orders` row and
   confirm `customer_name`, `customer_phone`, `order_type = delivery`, and the
   full `delivery_address` value.
4. Sign in with the Supabase administrator account and open **Profile → Owner
   Dashboard**. Confirm the same name, phone, address/instruction, delivery
   label, payment, and items are visible.
5. Place a **pickup** order without an address. Confirm it succeeds, the stored
   delivery address is null, and the owner card says the customer collects at
   the store.
6. Sign in as a normal customer and confirm they cannot open the owner dashboard
   or read another customer's order.
7. Test an upgrade from Play build 1 to build 2 and confirm existing orders
   continue loading.
8. Upload the build 2 AAB to the same closed-test track; do not upload the APK
   to Play Console.

## Old-order limitations

- Existing orders with stored phone/address data will display it immediately;
  no backfill is needed.
- Old pickup orders correctly show no delivery address is required.
- A historical delivery order whose address was never stored cannot be
  reconstructed by this release. It remains loadable and shows a clear warning
  so staff know to contact the customer using the stored phone number.

## Final status

`READY FOR MANUAL APK AND LIVE ORDER-FLOW TESTING`

`AAB RELEASE-SIGNED AND VALIDATED FOR CLOSED TEST AFTER THE SMOKE TEST`
