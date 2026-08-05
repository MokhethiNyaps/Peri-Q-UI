# Google Play Release Checklist

Checked against official Google Play guidance available on 18 July 2026. The exact requirements shown in the owner's Play Console are authoritative.

## Technical release

- [x] Permanent candidate application ID/namespace: `za.co.rastasperiq.ordering` (owner must confirm before app creation).
- [x] Closed-test releases use increasing version codes: `1.0.0` / code `1`,
  `1.0.1` / code `2`, and this candidate `1.0.2` / code `3`, preserving the
  existing package and signing identity.
- [x] Compile/target Android 16 API 36. From 31 August 2026, Play requires API 36 for new phone/tablet apps/updates: https://support.google.com/googleplay/android-developer/answer/11926878
- [x] 64-bit `arm64-v8a` present; App Bundle also contains armv7/x86_64 and Play will split per device.
- [x] INTERNET, POST_NOTIFICATIONS and VIBRATE are present for transactional
  order alerts; system picker needs no broad storage/media permission.
- [x] Release shrinking/obfuscation and symbol artifacts generated.
- [x] Production AAB built and validated with bundletool 1.18.3.
- [x] Release APK and AAB signed with the configured upload key and independently verified.
- [ ] Apply/test the production push-token migration, Edge Function secrets and
  `order-push` deployment using `FCM_MANUAL_SETUP.md`.
- [ ] Upload to Internal testing; review supported-device catalogue and App Integrity certificate fingerprints.
- [ ] Run Pre-launch report; triage crashes, ANRs, accessibility and security warnings.
- [ ] Enable/monitor Android vitals. No crash SDK is currently included; decide whether Play vitals alone is sufficient.

## Store listing draft

**App name:** Rasta's Peri Q  
**Short description (draft):** Order today's flame-grilled meals for pickup or local delivery.  

**Full description (draft):**

Rasta's Peri Q Chesanyama makes local food ordering simple. Browse today's menu and specials, customise your meal, add a note, and choose pickup or available local delivery. Check out as a guest or sign in, select cash or EFT where available, and follow your order from Pending to Preparing, Ready and Completed inside the app.

Features:

- Today's menu, specials and food categories
- Clear prices and availability
- Guest checkout
- Pickup and available local delivery
- Cash and EFT options configured by the store
- Order number, preparation estimate and in-app status
- Direct store support

No marketplace, driver tracking or subscription is included.

**Release notes (1.0.0 draft):** Order with an email/password account or
continue as a guest. Phone-only authentication has been removed, so no SMS or
OTP is required. Includes high-priority new-order alerts for administrators and
order-status updates for customers, plus menu, checkout, password-recovery,
privacy and account-deletion improvements.

**Release notes (1.0.1 draft):** Customer contact and fulfilment details are now
clearer for authorised staff. The owner dashboard prominently shows whether an
order is for delivery or pickup, with the customer phone number and delivery
address/instructions where required. Includes compatibility handling for older
orders and reliability checks for both fulfilment types.

**Release notes (1.0.2 draft):** Faster, more reliable app launch and clearer
feedback while placing an order. Improved phone-number validation during
sign-up. Includes closed-test stability and release validation updates.

- [x] Support email: `contact@rastasperiq.co.za`
- [x] Support website: `https://rastasperiq.co.za/`
- [x] Privacy URL: `https://rastasperiq.co.za/privacy-policy/`
- [x] Account deletion URL: `https://rastasperiq.co.za/delete-account/`
- [ ] Confirm the new Terms URL resolves after Vercel deployment: `https://rastasperiq.co.za/terms-and-conditions/`

## Visual assets

- [ ] 512×512 high-resolution Play icon (verify current icon quality/safe zone; do not upload a screenshot).
- [ ] 1024×500 feature graphic, truthful and free of unsupported claims.
- [ ] At least required phone screenshots from the final signed build: Home, Menu, Cart/Checkout, Confirmation/Status.
- [ ] 7-inch and 10-inch tablet screenshots only if tablet support/listing is retained and tested.
- [ ] Verify splash branding, status/navigation bars, no personal/test credentials, correct prices and no fake notification claims.
- [ ] Keep a repeatable screenshot data/setup procedure; no automated capture environment exists in this repository.

## App content and policy declarations

- [ ] Data Safety based on `PLAY_DATA_SAFETY_DRAFT.md`; owner verifies Supabase/provider practices. Required for closed/open/production tracks: https://support.google.com/googleplay/android-developer/answer/10787469
- [x] Public privacy policy and in-app link/summary implemented; recheck after each deployment.
- [x] Account deletion: in-app path plus public web request URL implemented. Google requires both when account creation is offered: https://support.google.com/googleplay/android-developer/answer/13327111
- [ ] App access instructions and reviewer accounts from `PLAY_REVIEWER_ACCESS.md`.
- [ ] Ads: likely **No** (no ad SDK)—owner verifies final build.
- [ ] Content rating questionnaire: prepared-food ordering; answer accurately.
- [ ] Target audience: owner chooses actual audience; app is not designed specifically for children.
- [ ] News app: likely **No**; government app: likely **No**; health app: likely **No**; financial features: likely **No** (EFT proof for food payment is not a financial product)—verify questions shown.
- [ ] Permissions declaration: INTERNET, POST_NOTIFICATIONS and VIBRATE, with
  notification use explained as transactional order updates; verify Play
  warnings and Data Safety answers.
- [ ] Developer identity, business/contact verification and payments profile as requested by Play.

## Testing tracks

1. **Internal testing:** upload the signed AAB for fast team distribution; replace builds by incrementing version code.
2. **Closed testing:** create tester list/group, share opt-in link, keep feedback records, and upload replacement AABs with higher version codes without deleting the track/testers.
3. Personal developer accounts created after 13 November 2023 may need at least **12 opted-in testers continuously for 14 days** before applying for production access: https://support.google.com/googleplay/android-developer/answer/14151465
4. Apply for production access only when Play shows eligibility; answer the testing/feedback questions honestly. The requirement displayed in the owner's account overrides this summary.
5. Review Pre-launch report and tester findings, fix issues, upload a higher-code AAB, and re-test before production rollout.

## Release decision

After completing the v1.0.2 smoke test in
`docs/CLOSED_TEST_V1_0_2_REPORT.md`, upload
`release/android/rastas-peri-q-v1.0.2-build3-closed-test-maintenance-release.aab`
as the next closed-test release. Keep the matching APK for direct device
testing. Google Play approval cannot be guaranteed.
