# Manual Android QA Checklist

Status convention: `[A]` automated passed, `[E]` emulator passed, `[P]` physical device passed, `[ ]` not tested, `[O]` owner must verify. No emulator or physical device was available during this pass; do not convert an item to `[E]`/`[P]` without evidence.

## Automated/build evidence

- [A] `flutter analyze` has no issues.
- [A] 19 unit/widget tests pass.
- [A] Android debug APK builds.
- [A] Android release AAB builds with shrinking/obfuscation.
- [A] bundletool validates package `za.co.rastasperiq.ordering`, target SDK 36, version code 1.

## Device and layout matrix

- [ ] Small budget phone (about 360×640), portrait: no overflow; cart/checkout CTA reachable.
- [ ] Standard phone, portrait: complete guest order journey.
- [ ] Large phone and foldable outer display: grids/images remain proportionate.
- [ ] 7-inch and 10-inch tablet if listing tablet support: no excessive blank space/broken grids.
- [ ] Landscape checkout/address/auth: keyboard does not hide required fields/buttons.
- [ ] Android minimum supported API and a recent Android 16/API 36 device.
- [ ] Display cut-out, gesture navigation, three-button navigation, edge-to-edge/status bars.
- [ ] Predictive/system back from item, cart, checkout and confirmation.
- [ ] System text 1.3× and maximum practical accessibility size; buttons/text remain usable.
- [ ] TalkBack: food images, status, fields, errors and progress are understandable; focus order logical.
- [ ] Bright/outdoor display and high-contrast review.

## Customer journeys

- [ ] Fresh install with valid production `--dart-define` config.
- [ ] Upgrade over previous build; legacy sample profile values are cleared.
- [ ] Guest: launch → menu → customise → quantity/note → cart → pickup → cash → submit → confirmation → status.
- [ ] Delivery: saved/new address, trusted fee, cash delivery and EFT options.
- [ ] Email registration, confirmation requirement, sign-in, invalid credentials, reset email, session restore, sign out.
- [ ] Delete account deliberately; verify Supabase user/profile/orders/proofs and local addresses are removed.
- [ ] Empty menu, unpublished special, missing/broken food image and unavailable item.
- [ ] Store closed, ordering paused, pickup off, delivery off, both off, store closes during checkout.
- [ ] Price/fee/item availability changes between cart and submit: no order; friendly review message; cart retained.
- [ ] Repeated submit taps and retry after timeout: exactly one order.
- [ ] EFT proof: JPG/PNG/WebP/PDF success; invalid type; >5 MB; network failure; retry; private admin visibility.
- [ ] Order realtime progression Pending → Preparing → Ready → Completed; invalid transition rejected.
- [ ] Reorder completed order where an item changed/unavailable.

## Connectivity and lifecycle

- [ ] Slow mobile data: splash/menu/checkout progress remains clear.
- [ ] Offline after one successful menu load: stale banner and cached menu visible; ordering safely disabled when settings cannot be verified.
- [ ] Fresh install offline: retry screen, no fake success/data.
- [ ] Connection loss during checkout, proof upload and admin update; data retained and retry succeeds.
- [ ] Background/resume refreshes menu/settings/orders.
- [ ] OS kills process; session/cart expectations reviewed (cart is currently memory-only and will not survive process death—owner acceptance required).

## Admin and security

- [ ] Customer manipulates route/client state: admin screen remains blocked and RLS denies writes.
- [ ] Admin sees customer contact, notes, type, payment and proof; menu/category/settings CRUD succeeds.
- [ ] Destructive menu/category/order actions require confirmation and failures recover.
- [ ] Malicious REST/RPC tests from security guide all fail as expected.
- [ ] Proof URL/object is not public; one customer cannot list/read another's file.

## Play/internal test

- [O] Upload signed AAB to Internal testing and inspect supported-device exclusions.
- [O] Review Pre-launch report, accessibility report, crashes, ANRs and security findings.
- [O] Validate fresh/upgrade installs from Play-generated splits, not only local APK.
- [O] Verify store listing screenshots are captured from the final production build with realistic non-personal sample data.
