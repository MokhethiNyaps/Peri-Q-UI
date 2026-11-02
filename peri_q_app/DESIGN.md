# Rasta’s Peri Q mobile direction

Flame-grilled chesanyama in Bloemfontein: a food ordering app, with the existing brand wordmark as its strongest identity.

## Palette
Use existing Peri red #C8240B for the brand, charcoal #1A1715 for the grill identity, ember orange #F07820 sparingly, and warm white #FFF9F4. Material semantic foreground/background pairs adapt to light, dark and system settings. Existing automated contrast checks cover the text pairs; no blanket claim is made for every photograph.

## Typography
Use Roboto for labels, descriptions, prices and controls. It preserves familiar Android reading shapes and avoids downloading fonts during checkout. Use the existing logo artwork for the brand lettering. Strong 700–800 headings, regular body copy and clear price weight provide hierarchy without adding competing display fonts.

## Layout and imagery
Use flat food rows on phone widths, larger food layouts when space permits, consistent 4-pixel spacing steps, and restrained 8–16 pixel corners. Keep controls at least 48 pixels. Real menu imagery remains supplied by the existing menu records; do not substitute generic stock food. Crop food images consistently with cover sizing. The hero’s charcoal image overlay exists to keep offer text legible. Remove the decorative orange orb and food-card shadows.

## Motion and accessibility
The short add-to-cart checkmark confirms a completed action and respects reduced motion. Checkout progress communicates that payment confirmation is pending. Safe-area protection is applied to the customer shell. Test the actual customer shell and checkout in portrait and landscape, under light and dark themes. Theme contrast and large-text tests are part of the regression suite. Physical low-end Android performance and real Yoco card entry remain separate device/integration checks.

## Night Grill update (November 2026)
New installs open in the dark theme (surface #141110, matching the website). Headlines (display and headline large/medium) use Big Shoulders Display; body stays Roboto. Menu photos are set down with a short plate-turn (`PlateEntrance`) and order tracking shows a flame progress bar (`FlameProgress`); both are skipped when the system asks for reduced motion. The home and sign-in headers use the transparent flame mark (`assets/images/flame_mark.png`).
