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

| File | Use |
| --- | --- |
| `play-store-qr.svg` | Plain QR, vector. Best for large print (A3, signage, stickers). |
| `play-store-qr.png` | Plain QR, 1025 × 1025, white background. Web, menus, screen use. |
| `play-store-qr-transparent.png` | Plain QR, transparent background. Drops onto any layout. |
| `rastasperiq-play-store-qr-square.png` | Branded square, 1200 × 1200. Social posts, stories, screen. |
| `rastasperiq-play-store-qr-poster.png` | Branded A5 poster, 1748 × 2480 at 300 dpi. Table tents, flyers, counter cards. |

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

## Known limitation

`market://` is Android-only. An iPhone or a desktop scanner has no handler for
it and will show nothing or "no usable data". Both branded files therefore print
`rastasperiq.co.za` as a fallback, and the site's footer is the right place to
put a Play Store link for those visitors.

Web fallback link, if you need it on a poster or in a caption:

```
https://play.google.com/store/apps/details?id=za.co.rastasperiq.ordering
```

If you later want one QR that works on both platforms, encode a short URL on
`rastasperiq.co.za` (for example `/get-app/`) that redirects to `market://` on
Android and to the https listing everywhere else. That also lets you repoint
the QR after printing. Say the word and it can be added to the website.

## Regenerate

```bash
cd marketing/qr
python3 -m venv .venv && ./.venv/bin/pip install segno pillow zxing-cpp numpy
python3 generate_play_store_qr.py
```

The script re-renders every file and then decodes each one back with
`zxing-cpp`, failing loudly if any code does not read back as
`market://details?id=za.co.rastasperiq.ordering`. Change `PACKAGE_ID` or
`PLAY_STORE_DEEP_LINK` at the top of the script to repoint it.
