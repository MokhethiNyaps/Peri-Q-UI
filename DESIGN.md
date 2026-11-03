# Rasta’s Peri Q shared interface system

## "Night Grill" (November 2026)

Browsing (home, menu, dish sheet, page headers) uses a dark stage: Soot `#141110`, Charcoal `#1A1715` surfaces, Warm white `#FFF9F4` text (18.0:1), Smoke `#B9AEA6` secondary text (8.65:1) and Ember `#F07820` for accent text and glow (6.63:1). Peri red `#C8240B` is for filled buttons only (white text 5.66:1); never use it as text on Soot (3.32:1). Cart, checkout, account and legal content stay on the light warm-white surface so forms are easy to read.

Headlines use Big Shoulders Display (SIL OFL, self-hosted: `website/app/fonts`, `peri_q_app/assets/fonts`). Body, prices in forms and controls stay Roboto. The Android app opens in the dark theme for new installs; a saved light/dark/system choice is respected.

Food imagery is only the restaurant's own menu photos from Supabase `menu-images`. Plate cut-outs (`website/public/plates`, made by `tools/plate-cutouts`) remove only the table around the plate and are used only while a dish still points at the exact stored photo they came from. Motion: GSAP ScrollTrigger on the website (plate turn-in, grill-bar reveals, ember spark to cart) and Flutter implicit animations in the app (plate entrance, flame progress). Everything respects reduced motion and animates transform/opacity only.

The flame wordmark and Peri red identify the product. Food, fulfilment and payment status carry the interface; decoration must not slow ordering. Existing business facts, product photographs, account behavior and historical records remain authoritative.

## Implementation sources

- Android: `peri_q_app/lib/src/core/app_theme.dart`, including semantic light/dark pairs, spacing, corner and typography definitions.
- Web: `website/app/globals.css`, with Tailwind's four-pixel spacing scale and existing reusable site components.
- Mobile-specific detail: `peri_q_app/DESIGN.md`.

Keep shared role and hierarchy consistent while using Material components on Android and semantic HTML on the web. The website currently ships a light content theme; the Android application retains its existing light/dark/system preferences.

| Role | Web value / treatment | Native relationship |
| --- | --- | --- |
| Primary action | Peri red `#C8240B`, white foreground, contrast 5.66:1 | Preserve Material theme's accessible primary/onPrimary pair |
| Main surface | Warm white `#FFF9F4` | Existing warm light surface and semantic dark counterpart |
| Primary content / hero | Charcoal `#1A1715`, contrast 17.08:1 on warm white | Existing grill/hero semantic surface |
| Secondary content | Ash `#4A4A4A`, contrast 8.49:1 on warm white | onSurfaceVariant; avoid ad hoc opacity reductions |
| Success | Existing leaf semantic token and a text/icon cue | Existing success/onSuccess pairs |
| Accent | Ember orange `#F07820`, used sparingly | Existing accent pair; not a replacement for readable text/focus |

## Type, layout and controls

Use familiar sans-serif body/control text; the web body stack starts with Roboto, with local system fallbacks. The wordmark is the signature display lettering. Keep prices tabular, headings balanced, explanatory text brief and form labels visible. Existing condensed display styling remains on marketing/section headings; it is not a new downloaded font dependency.

Group related fields tightly, separate task sections generously and use four-pixel spacing steps. Preserve native input/card/panel radii from `AppRadii`; web buttons use a restrained 12px radius and shared structural surfaces use 16px where appropriate. Do not force identical pixel dimensions across platforms. Controls should support at least 44px touch targets on the web and Material's 48dp target on Android.

Every action needs a meaningful label, selected/disabled state, loading response and recoverable error. Keyboard focus must remain visible; the web's red three-pixel outline is a functional state, not decoration. Use real disabled controls for unavailable actions. Forms use name/phone/address autofill and compatible validation bounds. Keep the primary payment action and total together.

## Payment language and state

Use “Pay by card”, “Opening payment”, “Payment pending”, “Payment successful” and actionable failure messages. Explain that card entry happens on a hosted payment page. Do not show internal provider names, webhook mechanics, environment-variable instructions or raw upstream errors to customers.

Pending confirmation is not success. Browser return parameters are hints about navigation, never proof of payment. Show database-confirmed status, preserve the cart on failure/interruption, and advise checking orders before paying again. Preserve historical payment-method labels accurately without offering those methods on new checkout.

## Motion

The web uses a 150ms quick duration and a smooth-out curve for brief, interruptible control feedback, with explicit transition properties. Native checkout progress respects reduced motion. Favor transforms/opacity over layout animation, remove hover movement on touch/reduced-motion contexts, and avoid frequent entrance sequences. No second animation engine is necessary for this flow.

## Verification boundary

Source tests and local rendered fixtures cover the shared system and checkout states. They do not certify physical-device accessibility, every native screen, merchant card entry or live payments. Preserve those limits in future release reports.
