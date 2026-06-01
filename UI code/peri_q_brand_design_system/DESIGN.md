# Rasta's Peri Q Chesanyama — Design System

## Brand Identity

**Business**: Rasta's Peri Q Chesanyama — a South African township-style peri-peri and chesa nyama (grilled meat) food ordering app.

**Brand Personality**: Bold, warm, authentic, community-driven, appetizing, street-food energy

**Short Name for UI**: "Peri Q" (used in compact components, navigation, app bar)
**Full Name for Logo**: "Rasta's Peri Q Chesanyama"

---

## Color Palette

### Primary
- **Peri Red** `#C8240B` — Fiery peri-peri red, used for primary CTAs, active states, logo accent
- **Chesa Orange** `#F07820` — Warm braai ember orange, used for highlights, secondary actions, ratings

### Secondary
- **Smoke Charcoal** `#1A1A1A` — Deep charcoal for text, headers, bottom nav backgrounds
- **Ash Grey** `#4A4A4A` — Secondary text, icons, dividers

### Surface / Backgrounds
- **Cream White** `#FFF8F5` — App background, warm and appetizing
- **Light Surface** `#FFFFFF` — Card backgrounds
- **Muted Surface** `#F5F0ED` — Input backgrounds, subtle containers

### Semantic
- **Success Green** `#2A8C5A` — Order ready, available, success states
- **Warning Amber** `#E8A400` — Preparing state, pending
- **Error Red** `#C8240B` — Same as primary, reused for errors
- **Info Blue** `#1A6AB1` — Informational states

---

## Typography

### Headlines (Oswald)
- **Display**: Oswald Bold 32px — Screen titles, hero text
- **H1**: Oswald SemiBold 28px — Page headers
- **H2**: Oswald SemiBold 22px — Section headers
- **H3**: Oswald Medium 18px — Card titles, menu item names

### Body (Nunito Sans)
- **Body Large**: Nunito Sans Regular 16px, line-height 1.6 — Primary body text
- **Body Medium**: Nunito Sans Regular 14px — Secondary body, descriptions
- **Body Small**: Nunito Sans Regular 12px — Captions, metadata
- **Label**: Nunito Sans SemiBold 14px — Button labels, form labels
- **Price**: Oswald Bold 20px, Peri Red — Pricing always uses brand red

---

## Spacing Scale
- xs: 4px
- sm: 8px
- md: 16px
- lg: 24px
- xl: 32px
- 2xl: 48px
- 3xl: 64px

---

## Components

### Buttons
- **Primary CTA**: Peri Red background, white text, 48px height, 8px radius, Nunito Sans SemiBold
  - Example: "Add to Cart", "Place Order", "Proceed to Checkout"
- **Secondary**: White background, Peri Red border and text, 48px height
  - Example: "Continue as Guest", "Cancel"
- **Ghost/Text**: No border, Peri Red text only
  - Example: "Skip", "View All"
- **Disabled**: Grey `#BEBEBE` background, white text

### Cards
- **Food Card**: White background, 12px radius, subtle shadow (0 2px 12px rgba(0,0,0,0.08))
  - Landscape: Image left (100x100px), content right
  - Grid: Image top, content below
  - Contains: Food image, name (H3 Oswald), short description (Body Small), price (Peri Red Oswald Bold), +/- quantity control
- **Order Card**: White card with status badge, order number, items summary, total
- **Category Pill**: Horizontal scrollable pills, active = Peri Red fill, inactive = light grey outline

### Navigation
- **Bottom Nav**: White background, 5 tabs: Home, Menu, Cart (center, elevated Peri Red FAB), Orders, Profile
  - Active tab: Peri Red icon + label
  - Inactive: Ash Grey
  - Cart FAB: Circular, 56px, Peri Red, white cart icon with badge count
- **Top App Bar**: White/transparent background, store name or screen title (Oswald Medium), back arrow (left), action icons (right)

### Status Badges
- Pending: Amber `#E8A400` background pill
- Preparing: Orange `#F07820` background pill
- Ready: Green `#2A8C5A` background pill
- Completed: Grey `#BEBEBE` background pill
- Available: Green dot
- Unavailable: Grey dot with strikethrough text

### Input Fields
- 56px height, `#F5F0ED` background, 8px radius, subtle border on focus (Peri Red)
- Label above field, Nunito Sans SemiBold 14px
- Placeholder: Ash Grey, regular weight

### Store Status Banner
- **Open**: Green `#2A8C5A` background pill or banner with white text "🟢 Open Now"
- **Closed**: Red `#C8240B` background pill "🔴 Closed"

---

## Icons
Use Material Design Icons (filled style) throughout. Key icons:
- Home, Restaurant menu, Shopping cart, Receipt long, Person
- Add, Remove, Delete, Edit, Search, Notifications
- Check circle, Error, Info, Arrow back, Arrow forward
- Local fire department (for specials/featured)
- Delivery dining (for delivery option)
- Storefront (for pickup option)

---

## Imagery Direction
- Food photography: Warm, golden-hour-style lighting, vibrant colors
- Background textures: Subtle dark charcoal with ember glow for splash/hero
- Always show food with visible steam or grill marks where possible
- Food card thumbnails: Square format, full-bleed with slight overlay gradient

---

## Interaction Patterns
- Haptic feedback on add to cart, order confirmation
- Spring animations on card press (slight scale 0.97)
- Slide-up modals for item customization, payment selection
- Swipe to remove cart items
- Pull to refresh on menu, orders
- Toast notifications for cart actions, errors

---

## Screen Dimensions
- Design for 390x844px (iPhone 14 / modern Android equivalent)
- Safe area: 48px top status bar, 34px bottom home indicator
- Content area: 390x762px
- Bottom nav height: 80px (including home indicator padding)
