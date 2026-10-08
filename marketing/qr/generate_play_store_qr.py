#!/usr/bin/env python3
"""Generate RastasperiQ Play Store QR codes.

The QR payload is the Android ``market://`` deep link, so scanning it hands the
listing straight to the Google Play Store *app* on an Android device instead of
opening play.google.com in a browser.

Usage:
    python3 -m venv .venv && ./.venv/bin/pip install segno pillow zxing-cpp numpy
    python3 generate_play_store_qr.py

Two payloads are produced:

1. ``market://details?id=...`` — the Play Store deep link. Android hands this
   straight to the Play Store app.
2. ``https://rastasperiq.co.za/get-app/`` — the website redirect page, which
   sends Android phones to the deep link and everyone else to the Play listing.
   Use this one when the printed piece has to survive an iPhone scan, or when
   you want to repoint the code later without reprinting it.

Outputs (written next to this script):
    play-store-qr.svg                        market:// QR, vector (best for print)
    play-store-qr.png                        market:// QR, white background
    play-store-qr-transparent.png            market:// QR, transparent background
    rastasperiq-play-store-qr-square.png     market:// QR, branded square
    rastasperiq-play-store-qr-poster.png     market:// QR, branded A5 poster, 300 dpi
    get-app-qr.svg                           /get-app/ QR, vector
    rastasperiq-get-app-qr-square.png        /get-app/ QR, branded square
"""

from __future__ import annotations

import math
from pathlib import Path

import segno
from PIL import Image, ImageDraw, ImageFont
from PIL.Image import Resampling

# --------------------------------------------------------------------------- #
# Content
# --------------------------------------------------------------------------- #

PACKAGE_ID = "za.co.rastasperiq.ordering"

# market:// is handled by the Play Store app itself (and by any other store the
# user has installed). It never lands in a browser tab on Android.
PLAY_STORE_DEEP_LINK = f"market://details?id={PACKAGE_ID}"

# Kept only for the printed fallback line and the README; the QR does not use it.
PLAY_STORE_WEB_LINK = f"https://play.google.com/store/apps/details?id={PACKAGE_ID}"

# The website's /get-app/ page redirects Android to the deep link above and
# everyone else to the web listing, so one printed code can serve both.
SITE_URL = "https://rastasperiq.co.za"
GET_APP_LINK = f"{SITE_URL}/get-app/"

APP_TITLE = "Rasta's Peri Q Chesanyama"
BRAND = "RastasperiQ"
TAGLINE = "Flame. Flavour. Vibes."
WEBSITE = "rastasperiq.co.za"

# --------------------------------------------------------------------------- #
# Brand palette (matches website/app/globals.css)
# --------------------------------------------------------------------------- #

RED = (200, 36, 11)
ORANGE = (240, 120, 32)
CHARCOAL = (26, 26, 26)
ASH = (74, 74, 74)
CREAM = (255, 248, 245)
WHITE = (255, 255, 255)

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parent.parent
ICON_SOURCE = REPO_ROOT / "website" / "public" / "white-app-icon.png"
FONT_DIR = Path("/usr/share/fonts/truetype/dejavu")
FONT_BOLD = str(FONT_DIR / "DejaVuSans-Bold.ttf")
FONT_REGULAR = str(FONT_DIR / "DejaVuSans.ttf")

# Text colours used on the dark header band.
ON_DARK_SUBTLE = (255, 255, 255)


# --------------------------------------------------------------------------- #
# Small drawing helpers
# --------------------------------------------------------------------------- #


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size)


def text_size(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.FreeTypeFont) -> tuple[int, int]:
    """Return (width, height) of ``text`` rendered with ``fnt``."""
    box = draw.textbbox((0, 0), text, font=fnt)
    return box[2] - box[0], box[3] - box[1]


def fit_font(
    draw: ImageDraw.ImageDraw, text: str, font_path: str, max_width: int, start: int, minimum: int = 12
) -> ImageFont.FreeTypeFont:
    """Largest font size <= ``start`` whose rendering of ``text`` fits ``max_width``."""
    size = start
    while size > minimum:
        fnt = font(font_path, size)
        if text_size(draw, text, fnt)[0] <= max_width:
            return fnt
        size -= 2
    return font(font_path, minimum)


def centred_text(
    draw: ImageDraw.ImageDraw,
    xy_center: tuple[float, float],
    text: str,
    fnt: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int],
) -> None:
    width, height = text_size(draw, text, fnt)
    x = xy_center[0] - width / 2
    y = xy_center[1] - height / 2
    draw.text((x, y), text, font=fnt, fill=fill)


def rounded_rectangle(
    draw: ImageDraw.ImageDraw,
    box: tuple[float, float, float, float],
    radius: float,
    fill: tuple[int, int, int],
) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def paste_center(canvas: Image.Image, layer: Image.Image, center: tuple[float, float]) -> None:
    x = round(center[0] - layer.width / 2)
    y = round(center[1] - layer.height / 2)
    canvas.paste(layer, (x, y), layer)


# --------------------------------------------------------------------------- #
# QR generation
# --------------------------------------------------------------------------- #


def plain_qr_image(payload: str, scale: int, border: int) -> Image.Image:
    """Plain QR on a white background.

    Error correction Q (~25%) keeps it readable on printed material that picks
    up scuffs or creases.
    """
    qr = segno.make(payload, error="q", mode="byte")
    path = HERE / ".tmp-plain.png"
    qr.save(str(path), scale=scale, border=border, dark="#1A1A1A", light="#FFFFFF")
    image = Image.open(path).convert("RGB")
    path.unlink()
    return image


def branded_qr_image(payload: str, target: int, logo_ratio: float = 0.22) -> Image.Image:
    """QR with the app icon badge in the middle.

    Error correction H (~30%) is what makes the centre overlay safe: the badge
    covers roughly 5% of the symbol, well inside what H can reconstruct.
    """
    qr = segno.make(payload, error="h", mode="byte")
    path = HERE / ".tmp-branded.png"
    # Render large, then downsample so the module grid stays crisp after scaling.
    qr.save(str(path), scale=40, border=4, dark="#1A1A1A", light="#FFFFFF")
    image = Image.open(path).convert("RGB")
    path.unlink()

    size = image.width
    badge = round(size * logo_ratio)
    inner = round(badge * 0.74)

    icon = Image.open(ICON_SOURCE).convert("RGBA").resize((inner, inner), Resampling.LANCZOS)

    plate = Image.new("RGBA", (badge, badge), (0, 0, 0, 0))
    plate_draw = ImageDraw.Draw(plate)
    plate_draw.rounded_rectangle((0, 0, badge - 1, badge - 1), radius=round(badge * 0.24), fill=WHITE)
    plate.paste(icon, ((badge - inner) // 2, (badge - inner) // 2), icon)

    result = image.convert("RGBA")
    paste_center(result, plate, (size / 2, size / 2))
    return result.convert("RGB").resize((target, target), Resampling.LANCZOS)


def app_icon(size: int) -> Image.Image:
    return Image.open(ICON_SOURCE).convert("RGBA").resize((size, size), Resampling.LANCZOS)


# --------------------------------------------------------------------------- #
# Branded layouts
# --------------------------------------------------------------------------- #


def build_square(
    output: Path,
    payload: str,
    caption: str,
    note: str,
    size: int = 1200,
) -> Image.Image:
    canvas = Image.new("RGB", (size, size), CREAM)
    draw = ImageDraw.Draw(canvas)
    cx = size / 2

    card = (60, 60, size - 60, size - 60)
    shadow = (card[0] + 8, card[1] + 14, card[2] + 8, card[3] + 14)
    rounded_rectangle(draw, shadow, 56, (233, 214, 206))
    rounded_rectangle(draw, card, 56, WHITE)

    # ---- measure the vertical stack, then centre it inside the card ---- #
    badge = 140
    title_font = fit_font(draw, BRAND, FONT_BOLD, size - 240, 64)
    eyebrow_font = font(FONT_BOLD, 26)
    caption_font = font(FONT_BOLD, 40)
    note_font = font(FONT_REGULAR, 27)

    h_title = text_size(draw, BRAND, title_font)[1]
    h_eyebrow = text_size(draw, "CHESANYAMA", eyebrow_font)[1]
    h_caption = text_size(draw, caption, caption_font)[1]
    h_note = text_size(draw, note, note_font)[1]

    gaps = [30, 16, 40, 40, 14]  # after badge, title, eyebrow, QR, caption
    fixed_h = badge + h_title + h_eyebrow + h_caption + h_note + sum(gaps)

    inner_top = card[1] + 60
    inner_bottom = card[3] - 60
    qr_size = int(min((card[2] - card[0]) - 120, (inner_bottom - inner_top) - fixed_h))

    cursor = inner_top + (inner_bottom - inner_top - (fixed_h + qr_size)) / 2

    # Icon badge
    icon = app_icon(round(badge * 0.78))
    badge_layer = Image.new("RGBA", (badge, badge), (0, 0, 0, 0))
    ImageDraw.Draw(badge_layer).rounded_rectangle(
        (0, 0, badge - 1, badge - 1), radius=round(badge * 0.26), fill=CREAM
    )
    badge_layer.paste(icon, ((badge - icon.width) // 2, (badge - icon.height) // 2), icon)
    paste_center(canvas, badge_layer, (cx, cursor + badge / 2))
    cursor += badge + gaps[0]

    centred_text(draw, (cx, cursor + h_title / 2), BRAND, title_font, CHARCOAL)
    cursor += h_title + gaps[1]

    centred_text(draw, (cx, cursor + h_eyebrow / 2), "CHESANYAMA", eyebrow_font, RED)
    cursor += h_eyebrow + gaps[2]

    qr = branded_qr_image(payload, qr_size)
    canvas.paste(qr, (round(cx - qr_size / 2), round(cursor)))
    cursor += qr_size + gaps[3]

    centred_text(draw, (cx, cursor + h_caption / 2), caption, caption_font, CHARCOAL)
    cursor += h_caption + gaps[4]

    centred_text(draw, (cx, cursor + h_note / 2), note, note_font, ASH)

    canvas.save(output)
    return canvas


def build_poster(
    output: Path, payload: str = PLAY_STORE_DEEP_LINK, width: int = 1748, height: int = 2480
) -> Image.Image:
    """A5 portrait poster at 300 dpi (1748 x 2480 px)."""
    canvas = Image.new("RGB", (width, height), CREAM)
    draw = ImageDraw.Draw(canvas)
    cx = width / 2

    # ---- Header band -------------------------------------------------- #
    header_h = 640
    draw.rectangle((0, 0, width, header_h - 90), fill=CHARCOAL)
    rounded_rectangle(draw, (0, header_h - 180, width, header_h), 90, CHARCOAL)

    badge = 300
    icon = app_icon(round(badge * 0.8))
    badge_layer = Image.new("RGBA", (badge, badge), (0, 0, 0, 0))
    ImageDraw.Draw(badge_layer).rounded_rectangle(
        (0, 0, badge - 1, badge - 1), radius=round(badge * 0.26), fill=CREAM
    )
    badge_layer.paste(icon, ((badge - icon.width) // 2, (badge - icon.height) // 2), icon)
    paste_center(canvas, badge_layer, (cx, 120 + badge / 2))

    title_font = fit_font(draw, APP_TITLE, FONT_BOLD, width - 220, 82)
    centred_text(draw, (cx, 120 + badge + 56), APP_TITLE, title_font, WHITE)

    tagline_font = font(FONT_BOLD, 40)
    centred_text(draw, (cx, 120 + badge + 56 + 74), TAGLINE, tagline_font, ORANGE)

    # ---- Footer block (measured first so the card can claim the free space) #
    footer_margin = 96
    url_font = font(FONT_BOLD, 54)
    footer_font = font(FONT_REGULAR, 36)
    footer_text = "iPhone or desktop? Open the website above for the Play Store link."
    url_h = text_size(draw, WEBSITE, url_font)[1]
    footer_h = text_size(draw, footer_text, footer_font)[1]

    footer_bottom = height - footer_margin
    url_cy = footer_bottom - footer_h - 34 - url_h / 2
    footer_cy = footer_bottom - footer_h / 2
    centred_text(draw, (cx, url_cy), WEBSITE, url_font, CHARCOAL)
    centred_text(draw, (cx, footer_cy), footer_text, footer_font, ASH)

    # ---- White card ---------------------------------------------------- #
    card_left = 120
    card_right = width - 120
    card_top = header_h + 70
    card_bottom = url_cy - url_h / 2 - 104

    rounded_rectangle(draw, (card_left + 10, card_top + 18, card_right + 10, card_bottom + 18), 64, (233, 214, 206))
    rounded_rectangle(draw, (card_left, card_top, card_right, card_bottom), 64, WHITE)

    card_w = card_right - card_left
    content_cx = (card_left + card_right) / 2

    heading_font = fit_font(draw, "Scan to install", FONT_BOLD, card_w - 200, 96)
    sub_font = fit_font(draw, "Opens the Play Store app on Android", FONT_REGULAR, card_w - 220, 46)
    note_font = font(FONT_REGULAR, 34)
    note_text = "Point your camera at the code, then tap the link."

    h_heading = text_size(draw, "Scan to install", heading_font)[1]
    h_sub = text_size(draw, "Opens the Play Store app on Android", sub_font)[1]
    h_note = text_size(draw, note_text, note_font)[1]

    gaps = [34, 56, 54]  # after heading, sub, QR
    fixed_h = h_heading + h_sub + h_note + sum(gaps)

    inner_top = card_top + 70
    inner_bottom = card_bottom - 70
    qr_size = int(min(card_w - 140, (inner_bottom - inner_top) - fixed_h))
    if qr_size < 400:
        raise SystemExit(f"Poster QR would be too small to scan reliably: {qr_size}px")

    cursor = inner_top + (inner_bottom - inner_top - (fixed_h + qr_size)) / 2

    centred_text(draw, (content_cx, cursor + h_heading / 2), "Scan to install", heading_font, CHARCOAL)
    cursor += h_heading + gaps[0]

    centred_text(
        draw,
        (content_cx, cursor + h_sub / 2),
        "Opens the Play Store app on Android",
        sub_font,
        ASH,
    )
    cursor += h_sub + gaps[1]

    qr = branded_qr_image(payload, qr_size)
    canvas.paste(qr, (round(content_cx - qr_size / 2), round(cursor)))
    cursor += qr_size + gaps[2]

    centred_text(draw, (content_cx, cursor + h_note / 2), note_text, note_font, ASH)

    canvas.save(output)
    return canvas


# --------------------------------------------------------------------------- #
# Output + verification
# --------------------------------------------------------------------------- #


def to_transparent(path: Path) -> None:
    """Recolour the white background of a plain QR to full transparency."""
    image = Image.open(path).convert("RGBA")
    pixels = image.getdata()
    transparent = []
    for r, g, b, a in pixels:
        if r > 245 and g > 245 and b > 245:
            transparent.append((255, 255, 255, 0))
        else:
            transparent.append((r, g, b, a))
    image.putdata(transparent)
    image.save(path)


def verify(path: Path, payload: str) -> bool:
    """Decode the QR back out of a rendered file and compare the payload."""
    import zxingcpp  # imported lazily so generation works without the decoder

    results = zxingcpp.read_barcodes(Image.open(path))
    texts = [r.text for r in results]
    ok = payload in texts
    print(f"  {'PASS' if ok else 'FAIL'}  {path.name} -> {texts or 'no QR found'}")
    return ok


def write_plain_svg(payload: str, path: Path) -> None:
    segno.make(payload, error="q", mode="byte").save(
        str(path), scale=12, border=4, dark="#1A1A1A", light="#FFFFFF"
    )


def main() -> None:
    print(f"Play Store deep link : {PLAY_STORE_DEEP_LINK}")
    print(f"Website redirect link: {GET_APP_LINK}\n")

    checks: list[tuple[Path, str]] = []

    print("market:// QR (Play Store app):")
    svg_path = HERE / "play-store-qr.svg"
    write_plain_svg(PLAY_STORE_DEEP_LINK, svg_path)
    print(f"  wrote {svg_path.name}")

    png_path = HERE / "play-store-qr.png"
    plain_qr_image(PLAY_STORE_DEEP_LINK, scale=25, border=4).save(png_path)
    print(f"  wrote {png_path.name}")
    checks.append((png_path, PLAY_STORE_DEEP_LINK))

    transparent_path = HERE / "play-store-qr-transparent.png"
    plain_qr_image(PLAY_STORE_DEEP_LINK, scale=25, border=4).save(transparent_path)
    to_transparent(transparent_path)
    print(f"  wrote {transparent_path.name}")
    checks.append((transparent_path, PLAY_STORE_DEEP_LINK))

    square_path = HERE / "rastasperiq-play-store-qr-square.png"
    build_square(
        square_path,
        PLAY_STORE_DEEP_LINK,
        caption="Scan to install",
        note="Opens the Google Play Store app",
    )
    print(f"  wrote {square_path.name}")
    checks.append((square_path, PLAY_STORE_DEEP_LINK))

    poster_path = HERE / "rastasperiq-play-store-qr-poster.png"
    build_poster(poster_path, PLAY_STORE_DEEP_LINK)
    print(f"  wrote {poster_path.name}")
    checks.append((poster_path, PLAY_STORE_DEEP_LINK))

    print("\n/get-app/ QR (works on every phone, repointable):")
    get_app_svg = HERE / "get-app-qr.svg"
    write_plain_svg(GET_APP_LINK, get_app_svg)
    print(f"  wrote {get_app_svg.name}")

    get_app_square = HERE / "rastasperiq-get-app-qr-square.png"
    build_square(
        get_app_square,
        GET_APP_LINK,
        caption="Scan to get the app",
        note="Android opens the Play Store",
    )
    print(f"  wrote {get_app_square.name}")
    checks.append((get_app_square, GET_APP_LINK))

    print("\nScan verification:")
    results = [verify(path, expected) for path, expected in checks]

    if not all(results):
        raise SystemExit("One or more QR codes failed to decode back to its payload.")

    print("\nEvery QR decodes back to the payload it was generated from.")
    print(f"Play Store web listing: {PLAY_STORE_WEB_LINK}")
    print(f"Redirect page:          {GET_APP_LINK}")


if __name__ == "__main__":
    main()
