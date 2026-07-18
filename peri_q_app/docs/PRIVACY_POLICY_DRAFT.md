# Privacy Policy Draft — Rasta's Peri Q Chesanyama

**Status: owner/legal review required.** Replace every bracketed placeholder and publish the final version at an active public HTTPS URL that is non-geofenced and accessible without login. Link that URL in the app and Play Console. This Markdown file alone is not sufficient for Google Play.

Effective date: [DATE]  
Business/legal operator: [LEGAL BUSINESS NAME]  
Physical/postal address: [BUSINESS ADDRESS]  
Privacy/support email: [SUPPORT EMAIL]  
Telephone/WhatsApp: +27 73 642 3549 [OWNER VERIFY]

## What the app does

Rasta's Peri Q Chesanyama is a single-store food-ordering app. Customers may browse the menu without a registered email account, use guest checkout, choose pickup or delivery, submit order contact details, choose an available payment method and view order status. Staff manage the menu, store availability and order status through protected admin access.

## Information we process

We process the name and phone number supplied at checkout; email and authentication information for email accounts; delivery address for delivery orders; saved addresses if chosen; ordered items, notes, totals, payment method, order number/status and timestamps; and an EFT proof image or PDF when voluntarily uploaded for an EFT order. Guest checkout uses an anonymous Supabase account identifier so one customer cannot read another customer's orders.

The current app does not include advertising, analytics, location, contacts, SMS/call-log collection, card-payment processing, Firebase Cloud Messaging or crash-reporting SDKs.

## Why we process it

We use the information to authenticate accounts, accept and prepare orders, contact customers about fulfilment, deliver orders, reconcile EFT payments, provide order status, prevent duplicate/invalid orders, secure admin functions, respond to support/privacy requests and maintain the service.

## Service providers and disclosure

Data is hosted and processed in the business's Supabase project (Auth, PostgreSQL, Realtime and Storage). We may disclose order details to authorised staff and a delivery person only as needed to fulfil a delivery. We do not sell personal information or use it for third-party advertising. [OWNER: list any accountants, support tools, hosting regions, exporters or other recipients.]

## Storage, security and retention

Connections use HTTPS/WSS. Database Row Level Security separates customer records, admin rights are checked by trusted database policies, order prices are calculated by a database function, and EFT proofs are stored in a private bucket. No mobile or server-only secret is embedded in the app.

The current deletion implementation removes the user's private proof objects and deletes the Supabase account, profile and linked order records. [OWNER/LEGAL: confirm whether tax, accounting, fraud or other law requires retention. If so, specify categories, periods, legal basis and an anonymisation design before release.] Supabase backups and security logs may follow separate configured retention periods; [OWNER VERIFY].

Saved addresses and preferences are stored in the Android app's private storage. Android cloud backup is disabled. Uninstalling clears normal local app data; account deletion clears the in-app saved data through the application flow.

## Choices and rights

Browsing and guest checkout do not require an email account. A delivery address is needed only for delivery. EFT proof is relevant only if EFT is selected. Users may edit/delete saved addresses, sign out, and delete a non-guest account from **Profile → Delete Account**. Users may also contact us to request access, correction or deletion, subject to applicable law.

Account deletion web page: [PUBLIC ACCOUNT-DELETION URL]. The page must let a user request deletion without reinstalling the app.

## Children

The app sells prepared food and is not designed specifically for children. [OWNER: confirm target audience and whether age restrictions/parental consent are needed.]

## International processing and changes

[OWNER: identify Supabase hosting region and lawful transfer safeguards if data leaves South Africa.] We may update this policy when features, providers or legal requirements change. The effective date above will be revised and material changes communicated appropriately.

## Contact

For privacy questions or requests, contact [SUPPORT EMAIL], [BUSINESS ADDRESS], or the verified phone/WhatsApp number above.
