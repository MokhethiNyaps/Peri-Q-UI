"""Make plate cut-outs from the restaurant's own menu photos.

The cut-out removes only the wooden table around the plate. Pixels inside the
plate (the food, the plate and its rim) are copied unchanged, with no colour,
sharpness or content edits. The edge gets a 2 px feather so it sits cleanly on
the dark website background.

Usage:
    python3 make_cutouts.py <folder of original photos> <output folder>

The mapping below ties each original photo to the stored menu image it is
identical to (same pixels, re-saved by Supabase with 60 fewer bytes). The
website only uses a cut-out while the menu item still points at that stored
image, so a photo changed in the admin app can never be shown with an old
cut-out.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

# Original file name -> stored file name in the Supabase `menu-images/menu/` folder.
SOURCES = {
    "Chopped Mala Mogodu.jpg": "1791369983681-img-20261007-wa0010.jpg",
    "Pap with Grilled Chicken, Wors and Tomato-Bean Relish.jpg": "1791369258095-img-20261007-wa0006.jpg",
    "Pap with Grilled Pork and Tomato-Bean Relish.jpg": "1791368713288-img-20261007-wa0003.jpg",
    "Pap, Grilled Sheep Liver and Tomato Relish.jpg": "1791369551302-img-20261007-wa0009.jpg",
    "Pork, Beef and Wors.jpg": "1791371149522-img-20261007-wa0008.jpg",
    "Sliced Russian with Cheese and Tomato Relish.jpg": "1791370903846-img-20261007-wa0004.jpg",
    "Pap, Wors, Pork, Beef and Liver.jpg": "1791368389881-img-20261007-wa0005.jpg",
    "Pap with Grilled Chicken, Mogodu and Tomato Relish.jpg": "1791370459978-img-20261007-wa0007.jpg",
    "Pap with Grilled Pork, Wors and Tomato-Bean Relish.jpg": "1791368984770-img-20261007-wa0002.jpg",
}

OUTPUT_SIZE = 900  # px, square, enough for a 450 px plate on 2x screens


def plate_mask(rgb: np.ndarray) -> np.ndarray:
    """Return a 0-255 mask of the plate (rim plus everything inside it)."""
    lab = cv2.cvtColor(rgb, cv2.COLOR_RGB2LAB)
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    lightness = lab[:, :, 0].astype(np.int32)
    saturation = hsv[:, :, 1].astype(np.int32)

    # The cream plate rim is light and low in colour; the wooden table is darker
    # and more saturated.
    rim = ((lightness > 175) & (saturation < 70)).astype(np.uint8) * 255
    rim = cv2.morphologyEx(rim, cv2.MORPH_CLOSE, np.ones((9, 9), np.uint8), iterations=2)

    # Seed GrabCut: the image border is table, the light rim is plate, and the
    # rest is decided by colour statistics.
    seed = np.full(rgb.shape[:2], cv2.GC_PR_BGD, np.uint8)
    seed[saturation < 90] = cv2.GC_PR_FGD
    seed[rim > 0] = cv2.GC_FGD
    border = 6
    seed[:border, :] = cv2.GC_BGD
    seed[-border:, :] = cv2.GC_BGD
    seed[:, :border] = cv2.GC_BGD
    seed[:, -border:] = cv2.GC_BGD
    bgd, fgd = np.zeros((1, 65), np.float64), np.zeros((1, 65), np.float64)
    cv2.grabCut(cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR), seed, None, bgd, fgd, 6, cv2.GC_INIT_WITH_MASK)
    plate = np.where((seed == cv2.GC_FGD) | (seed == cv2.GC_PR_FGD), 255, 0).astype(np.uint8)
    plate = cv2.morphologyEx(plate, cv2.MORPH_OPEN, np.ones((7, 7), np.uint8))

    contours, _ = cv2.findContours(plate, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    if not contours:
        raise ValueError("no plate found")
    largest = max(contours, key=cv2.contourArea)
    if cv2.contourArea(largest) < 0.2 * rgb.shape[0] * rgb.shape[1]:
        raise ValueError("plate outline too small to trust")

    # A plate is convex, so its hull closes any gaps where food spills over the rim.
    hull = cv2.convexHull(largest)
    mask = np.zeros(rgb.shape[:2], np.uint8)
    cv2.fillPoly(mask, [hull], 255)
    # Pull the edge in by 2 px so no wood shows, then feather it.
    mask = cv2.erode(mask, np.ones((5, 5), np.uint8), iterations=1)
    mask = cv2.GaussianBlur(mask, (5, 5), 0)
    return mask


def main(source_dir: Path, out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest: dict[str, dict[str, object]] = {}
    for original, stored in SOURCES.items():
        path = source_dir / original
        if not path.exists():
            print(f"skip (missing): {original}")
            continue
        rgb = np.array(Image.open(path).convert("RGB"))
        try:
            mask = plate_mask(rgb)
        except ValueError as error:
            # The website falls back to the normal photo for this dish.
            print(f"skip ({error}): {original}")
            continue
        rgba = np.dstack([rgb, mask])

        ys, xs = np.where(mask > 0)
        top, bottom, left, right = ys.min(), ys.max(), xs.min(), xs.max()
        side = max(bottom - top, right - left) + 8
        cy, cx = (top + bottom) // 2, (left + right) // 2
        canvas = np.zeros((side, side, 4), np.uint8)
        y0, x0 = cy - side // 2, cx - side // 2
        sy0, sx0 = max(y0, 0), max(x0, 0)
        sy1, sx1 = min(y0 + side, rgb.shape[0]), min(x0 + side, rgb.shape[1])
        canvas[sy0 - y0 : sy1 - y0, sx0 - x0 : sx1 - x0] = rgba[sy0:sy1, sx0:sx1]

        image = Image.fromarray(canvas, "RGBA").resize(
            (OUTPUT_SIZE, OUTPUT_SIZE), Image.Resampling.LANCZOS
        )
        name = Path(stored).stem + ".webp"
        image.save(out_dir / name, "WEBP", quality=86, method=6)
        manifest[stored] = {"file": name, "source": original}
        print(f"ok  {original} -> {name}")

    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(Path(sys.argv[1]), Path(sys.argv[2]))
