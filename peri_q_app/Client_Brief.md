# Client Brief — Simple Food Ordering App

I own a local food business. We sell prepared food plates daily. I want a simple mobile app for customers to place orders from their phones.

I do **NOT** want:

- Live driver tracking
- Uber-style delivery system
- Complicated logistics
- Advanced restaurant marketplace features
- Multiple vendors

This is a single-store food ordering app.

---

## Main Goal

Customers should:

1. Open the app
2. See today's menu
3. Add food to cart
4. Place order
5. Choose: Pickup in store or Delivery
6. Pay or choose cash
7. Receive confirmation

That is the core system.

---

## Target Users

- Local customers
- Workers ordering lunch
- Returning customers
- People using Android mostly

The app must be **simple**, **fast**, and **easy for non-technical people**.

---

## App Structure

### 1. Splash Screen

- Logo
- Business name / Rasta's Peri Q Chesanyama

Then automatically go to the home screen.

### 2. Authentication

Simple login:

- Phone number, or
- Email + password

Also allow:

- **Guest checkout** (important)

Do not make onboarding complicated.

### 3. Home Screen

Show:

- Featured meals
- Today's specials
- Food categories (e.g. Kota, Pap & Meat, Burgers, Drinks, Desserts)
- Store operating status (Open / Closed)

### 4. Food Menu Screen

Each food item must have:

- Image
- Name
- Short description
- Price
- Availability

**Example:** *"Chicken Kota. With chips and Russian." — R65*

Customer can:

- Increase quantity
- Add notes (e.g. "No onions")

### 5. Cart Screen

Show:

- Selected items
- Quantity
- Total price

Customer can:

- Remove item
- Edit quantity

Then click **Proceed to Checkout**.

### 6. Checkout Screen

Customer enters:

- Name
- Phone number
- Address (only if delivery selected)

Order type:

- Pickup
- Delivery

Payment options:

- Cash on collection
- Cash on delivery
- EFT proof upload
- Card payment *(optional future feature)*

### 7. Order Confirmation

After placing the order, show:

- Order number
- Estimated preparation time

**Example:** *"Order #104 — Ready in 25 minutes."*

Also send:

- Push notification, or
- SMS *(later)*

### 8. Owner / Admin Side

A simple admin dashboard. The owner should be able to:

- Add food items
- Edit prices
- Mark item unavailable
- See incoming orders
- Change order status

**Order statuses:** Pending → Preparing → Ready → Completed

### 9. Order Management Flow

1. Customer places order
2. Store receives notification
3. Staff prepares food
4. Staff changes status
5. Customer sees updates

Very simple workflow.

### 10. Delivery Handling

No driver tracking system.

If delivery is selected:

- Driver manually receives the address
- Driver delivers food normally

No maps needed initially.

---

## Important Requirements

The app must:

- Work smoothly on Android
- Load fast
- Use little data
- Have a clean design
- Be easy for older customers too

---

## Recommended Tech Stack

| Layer | Technology |
|---|---|
| Frontend | [Flutter](https://flutter.dev) |
| Backend | [Supabase](https://supabase.com) |
| Authentication | Supabase Auth |
| Database | PostgreSQL via Supabase |
| Notifications | [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) |
| Admin Dashboard | Flutter Web or simple React dashboard |

---

## MVP Features Only

**Build version 1 with:**

- Authentication
- Menu
- Cart
- Checkout
- Order management
- Admin dashboard

**Do NOT build:**

- Loyalty systems
- AI recommendations
- Coupons
- Live tracking
- Subscriptions
- Marketplace features

Keep it lean and reliable first.
