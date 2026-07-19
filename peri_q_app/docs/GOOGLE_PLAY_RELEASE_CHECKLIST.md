# Google Play Release Checklist

Checked against official Google Play guidance available on 18 July 2026. The exact requirements shown in the owner's Play Console are authoritative.

## Technical release

- [x] Permanent candidate application ID/namespace: `za.co.rastasperiq.ordering` (owner must confirm before app creation).
- [x] Version `1.0.0` / code `1`; increment code for every replacement upload.
- [x] Compile/target Android 16 API 36. From 31 August 2026, Play requires API 36 for new phone/tablet apps/updates: https://support.google.com/googleplay/android-developer/answer/11926878
- [x] 64-bit `arm64-v8a` present; App Bundle also contains armv7/x86_64 and Play will split per device.
- [x] INTERNET is the only permission; system picker needs no broad storage/media permission.
- [x] Release shrinking/obfuscation and symbol artifacts generated.
- [x] Unsigned AAB validated with bundletool.
- [ ] Generate upload key, enrol in Play App Signing, rebuild/verify signed AAB.
- [ ] Apply/test production Supabase schema and Auth/Storage settings.
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

**Release notes (1.0.0 draft):** Initial release for browsing the Rasta's Peri Q menu, guest/customer checkout, pickup or available delivery, secure EFT proof upload and in-app order status.

- [ ] Support email: `[SUPPORT EMAIL]`
- [ ] Support website: `[SUPPORT WEBSITE]`
- [ ] Privacy URL: `[PUBLIC PRIVACY POLICY URL]`
- [ ] Account deletion URL: `[PUBLIC ACCOUNT-DELETION URL]`

## Visual assets

- [ ] 512×512 high-resolution Play icon (verify current icon quality/safe zone; do not upload a screenshot).
- [ ] 1024×500 feature graphic, truthful and free of unsupported claims.
- [ ] At least required phone screenshots from the final signed build: Home, Menu, Cart/Checkout, Confirmation/Status.
- [ ] 7-inch and 10-inch tablet screenshots only if tablet support/listing is retained and tested.
- [ ] Verify splash branding, status/navigation bars, no personal/test credentials, correct prices and no fake notification claims.
- [ ] Keep a repeatable screenshot data/setup procedure; no automated capture environment exists in this repository.

## App content and policy declarations

- [ ] Data Safety based on `PLAY_DATA_SAFETY_DRAFT.md`; owner verifies Supabase/provider practices. Required for closed/open/production tracks: https://support.google.com/googleplay/android-developer/answer/10787469
- [ ] Public privacy policy and in-app link/summary.
- [ ] Account deletion: in-app path plus functional public web request URL. Google requires both when account creation is offered: https://support.google.com/googleplay/android-developer/answer/13327111
- [ ] App access instructions and reviewer accounts from `PLAY_REVIEWER_ACCESS.md`.
- [ ] Ads: likely **No** (no ad SDK)—owner verifies final build.
- [ ] Content rating questionnaire: prepared-food ordering; answer accurately.
- [ ] Target audience: owner chooses actual audience; app is not designed specifically for children.
- [ ] News app: likely **No**; government app: likely **No**; health app: likely **No**; financial features: likely **No** (EFT proof for food payment is not a financial product)—verify questions shown.
- [ ] Permissions declaration: only INTERNET, normally no sensitive-permission form; verify merged manifest/Play warnings.
- [ ] Developer identity, business/contact verification and payments profile as requested by Play.

## Testing tracks

1. **Internal testing:** upload the signed AAB for fast team distribution; replace builds by incrementing version code.
2. **Closed testing:** create tester list/group, share opt-in link, keep feedback records, and upload replacement AABs with higher version codes without deleting the track/testers.
3. Personal developer accounts created after 13 November 2023 may need at least **12 opted-in testers continuously for 14 days** before applying for production access: https://support.google.com/googleplay/android-developer/answer/14151465
4. Apply for production access only when Play shows eligibility; answer the testing/feedback questions honestly. The requirement displayed in the owner's account overrides this summary.
5. Review Pre-launch report and tester findings, fix issues, upload a higher-code AAB, and re-test before production rollout.

## Release decision

Do not upload the current `*-unsigned.aab`. After signing, use Internal testing first. Google Play approval cannot be guaranteed.
