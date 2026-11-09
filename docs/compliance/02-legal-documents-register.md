# 02 — Legal Documents Register (Stage 1)

| | |
|---|---|
| Stage | 1: Legal documents |
| Branch / PR | `stage-1/legal-documents`, [draft PR #10](https://github.com/MokhethiNyaps/Peri-Q-UI/pull/10) |
| Date | 3 November 2026 |
| Status | Drafts written. **REQUIRES BUSINESS OWNER APPROVAL** and **REQUIRES ATTORNEY REVIEW** before merge. |

This register does not confirm legal compliance. The pages are drafts. Each page shows a "Draft under review" notice until `LEGAL_REVIEW_PENDING` in `website/lib/legal.ts` is set to `false`.

## 1. Documents

| Document | Route | Status |
|---|---|---|
| Privacy policy | `/privacy-policy/` | Rewritten — IMPLEMENTED BUT NOT FULLY TESTED · REQUIRES ATTORNEY REVIEW |
| Terms and conditions | `/terms-and-conditions/` | Rewritten — REQUIRES ATTORNEY REVIEW |
| Payment policy | `/payment-policy/` | New — REQUIRES BUSINESS OWNER APPROVAL |
| Cancellation policy | `/cancellation-policy/` | New — BLOCKED BY MISSING INFORMATION (owner rules) |
| Refund policy | `/refund-policy/` | New — BLOCKED BY MISSING INFORMATION (timelines) |
| Complaints procedure | `/complaints/` | New — BLOCKED BY MISSING INFORMATION (timelines, handler) |
| Cookie and storage notice | `/cookie-policy/` | New — REQUIRES ATTORNEY REVIEW (whether consent is needed) |
| PAIA manual | `/paia-manual/` | New — REQUIRES ATTORNEY REVIEW · BLOCKED BY MISSING INFORMATION |
| Legal index | `/legal/` | New |
| Account deletion page | `/delete-account/` | Corrected to describe current behaviour (orders are deleted with the account; see audit D-H2) |

The app's Privacy & Support screen links to `/legal/`, and its summary now names Yoco and Firebase. This reaches users only in the next app release.

## 2. Corrections to earlier text

- The old privacy policy said the app did not use Firebase Cloud Messaging. It does. This is fixed.
- The old privacy policy covered the app only. The new one covers the website too, including its local storage.
- Yoco, Vercel and Google are now named as recipients of information.
- The old delete-account page said order records "may be anonymised and kept for at least five years". The code deletes them. The page now states the actual behaviour, pending Stage 3.

## 3. Open placeholders and who answers them

| # | Placeholder | Answer from | Pages |
|---|---|---|---|
| 1 | Directors' names (COR39 page 3) | Owner | All pages with company details |
| 2 | Information Officer (and deputies): name, email, phone | Owner | Privacy, PAIA |
| 3 | Physical trading address. The site shows "28 King Edward Rd"; CIPC shows "28 King Edward Willows". | Owner | All pages with company details |
| 4 | VAT number, or confirmation the company is not VAT-registered; whether prices include VAT | Owner / accountant | Company details, terms |
| 5 | Allergen and ingredient data per menu item; any certification (e.g. halaal) | Owner (kitchen) | Terms |
| 6 | Delivery area; what happens if the driver cannot reach the customer | Owner | Terms |
| 7 | How long uncollected orders are kept, and whether they are refunded | Owner | Terms, cancellation |
| 8 | Whether a customer can cancel a pending order, or one being prepared, and for what refund | Owner | Cancellation |
| 9 | Replacement vs refund rule for faulty orders; refund decision and payout times | Owner (Yoco for payout time) | Refund |
| 10 | Complaint acknowledgement and resolution times; who handles complaints | Owner | Complaints |
| 11 | Limitation-of-liability wording | Attorney | Terms |
| 12 | Whether ECTA s42 cooling-off excludes prepared food | Attorney | Terms |
| 13 | Retention periods: orders and payments, unfinished checkouts, guest identifiers, messages | Attorney + accountant | Privacy |
| 14 | Section 72 basis for each cross-border transfer (Supabase EU, Vercel, Google) | Attorney | Privacy |
| 15 | Confirmation that operator agreements / DPAs are in place with Supabase, Vercel, Yoco, Google | Owner (accept provider terms) + attorney | Privacy |
| 16 | Vercel server region | Developer (Vercel project settings) | Privacy |
| 17 | Whether a PAIA manual is required now or an exemption applies | Attorney | PAIA |
| 18 | Complete list of record-keeping laws | Attorney | PAIA |
| 19 | Whether the company has employees, and the records kept | Owner | PAIA |
| 20 | PAIA request fees under the current regulations | Attorney | PAIA |
| 21 | Correct escalation bodies for a restaurant | Attorney | Complaints |
| 22 | Whether the storage notice needs a consent banner | Attorney | Cookie notice |

## 4. Before merging PR #10

1. Fill each placeholder in `website/lib/legal.ts` (company facts) or in the page text (policy decisions).
2. Attorney reviews all pages.
3. Set `LEGAL_REVIEW_PENDING = false` and update `LEGAL_VERSION` to the effective date.
4. Mark the PR ready for review and merge it. Ship the app change in the next release.

## 5. Checks run

- Website: 83 tests pass (4 new in `tests/legal.test.tsx`: every listed page exists, unknown facts show placeholders, every provider is named, drafts are marked). Type check, lint (0 errors) and production build pass.
- All 10 pages were rendered at 375 px width: no horizontal scroll, and the draft notice is present on every document page.
- App: 65 tests pass; `flutter analyze` is clean on the changed files.
