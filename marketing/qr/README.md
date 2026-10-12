# RastasperiQ Play Store QR codes

QR artwork that opens the **Google Play Store app** — not the play.google.com
website — when scanned on an Android phone.

## What the QR encodes

```
market://details?id=za.co.rastasperiq.ordering
```

`market://` is an Android deep link. The system hands it to the Play Store app
itself (or another installed store), so the listing opens inside Play Store.
It never lands in Chrome. That is the whole reason the QR does **not** use
`https://play.google.com/store/apps/details?id=...` — the https link is claimed
by Play Store on most Android devices, but in-app browsers (Instagram,
WhatsApp, Facebook) frequently open it as a web page instead.

**Package:** `za.co.rastasperiq.ordering`
**Listing:** Rasta's Peri Q Chesanyama · RastasperiQ · Food & Drink

## Files

| File | Encodes | Use |
| --- | --- | --- |
| `play-store-qr.svg` | `market://` | Plain QR, vector. Best for large print (A3, signage, stickers). |
| `play-store-qr.png` | `market://` | Plain QR, 1025 × 1025, white background. Web, menus, screen use. |
| `play-store-qr-transparent.png` | `market://` | Plain QR, transparent background. Drops onto any layout. |
| `rastasperiq-play-store-qr-square.png` | `market://` | Branded square, 1200 × 1200. Social posts, stories, screen. |
| `rastasperiq-play-store-qr-poster.png` | `market://` | Branded A5 poster, 1748 × 2480 at 300 dpi. Table tents, flyers, counter cards. |
| `get-app-qr.svg` | `/get-app/` | Vector QR for printing the redirect link. |
| `rastasperiq-get-app-qr-square.png` | `/get-app/` | Branded square, 1200 × 1200. Shown on the website's `/get-app/` page. |

The two branded files carry the app icon in the middle of the code and use
error-correction level **H (30%)**, which is what makes the centre badge safe.
The plain files use level **Q (25%)**.

## Print guidance

- Keep the QR at least **25 mm / 1 inch** wide for the plain code and **35 mm /
  1.4 inches** for the branded ones. Decoding was verified down to 120 px
  (plain) and 200 px (branded), but print gain and paper texture eat margin.
- The white border around the code is part of the code. Do not crop it, and do
  not let any background colour run into it.
- Do not recolour the modules. Red-on-cream artwork looks on-brand but drops
  contrast enough to hurt scanning — the brand colour is used around the QR,
  never inside it.
- Print a copy and scan it with two or three different phones before running a
  full batch: the stock camera app, Google Lens, and a scanner app.
- Place it where people can actually lift their phone to it — table height, not
  the floor, and flat rather than curved around a bottle or cup.

## Two payloads, and when to use each

**`market://` (the default files).** The most direct route into the Play Store
app, and what you want when the printed piece is squarely aimed at Android
phones. An iPhone or desktop scanner has no handler for it and will show
nothing or "no usable data", which is why both branded files print
`rastasperiq.co.za` as a fallback.

**`https://rastasperiq.co.za/get-app/` (the `get-app-*` files).** The website's
`/get-app/` page sends Android phones to the `market://` deep link and shows
everyone else the Play listing, so one printed code works on any phone. It can
also be repointed later — change where `/get-app/` sends people and the codes
already in the wild follow, no reprint. The trade-off is a browser hop before
Play Store opens.

Pick `market://` for an Android-first audience, `/get-app/` for mixed audiences
or anything you might want to change later.

Web listing, for captions and footers:

```
https://play.google.com/store/apps/details?id=za.co.rastasperiq.ordering
```

## Regenerate

```bash
cd marketing/qr
python3 -m venv .venv && ./.venv/bin/pip install segno pillow zxing-cpp numpy
python3 generate_play_store_qr.py
```

The script re-renders every file and then decodes each one back with
`zxing-cpp`, failing loudly if any code does not read back as the payload it was
generated from. Change `PACKAGE_ID`, `PLAY_STORE_DEEP_LINK`, or `GET_APP_LINK`
at the top of the script to repoint it.

The website serves the `/get-app/` square and SVG from `website/public/qr/`, so
after regenerating run `pnpm sync-qr` inside `website/` to copy them across.
