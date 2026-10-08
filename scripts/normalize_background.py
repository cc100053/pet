#!/usr/bin/env python3
"""Normalize a generated room background into a shippable assets/bg JPG.

Room backgrounds ship at 1206x2622 (a 3x iPhone screen, ~9:19.5). Image models
top out at 9:16, so this script:
  1. scales the image to 1206 px wide,
  2. if it is too short, stretches only the calm middle band (--band, as
     fractions of the height) to reach 2622, leaving the decorated top and
     bottom edges untouched; if it is too tall, centre-crops the height,
  3. saves an optimized JPG.

The stretch is invisible only because backgrounds keep the middle empty
(docs/art_style.md, "Room backgrounds"). Check the band against the art: no
decoration may sit inside it.

    python3 scripts/normalize_background.py raw.png assets/bg/paid/background-paid-03.jpg
    python3 scripts/normalize_background.py --band 0.3 0.68 raw.png out.jpg
    python3 scripts/normalize_background.py --preview /tmp/p.jpg assets/bg/paid/background-paid-03.jpg
    python3 scripts/normalize_background.py --selftest
"""

import argparse
import glob
import sys

from PIL import Image

WIDTH, HEIGHT = 1206, 2622


def normalize(im, band=(0.3, 0.7)):
    im = im.convert("RGB")
    h = round(im.height * WIDTH / im.width)
    im = im.resize((WIDTH, h), Image.LANCZOS)
    if h >= HEIGHT:
        top = (h - HEIGHT) // 2
        return im.crop((0, top, WIDTH, top + HEIGHT))
    y0, y1 = round(h * band[0]), round(h * band[1])
    middle = im.crop((0, y0, WIDTH, y1)).resize(
        (WIDTH, (y1 - y0) + (HEIGHT - h)), Image.LANCZOS
    )
    out = Image.new("RGB", (WIDTH, HEIGHT))
    out.paste(im.crop((0, 0, WIDTH, y0)), (0, 0))
    out.paste(middle, (0, y0))
    out.paste(im.crop((0, y1, WIDTH, h)), (0, y0 + middle.height))
    return out


def preview(bg_path, dst):
    """Shipped furniture at 1x-3x plus the ghost pet, for the squint test."""
    bg = Image.open(bg_path).convert("RGBA")
    base = (bg.width - 96) * 42 / 360  # RoomCanvas.furnitureBaseWidthFraction
    pet = sorted(glob.glob("assets/pet_sequences/ghost/stay/*.png"))[0]
    for path, scale, cx, cy in [
        ("assets/furniture/carpet.png", 3, 640, 1640),
        ("assets/furniture/bat_armchair.png", 2, 330, 1250),
        ("assets/furniture/candy_cauldron.png", 1.5, 880, 1200),
        ("assets/furniture/cactus.png", 1, 1000, 1500),
        (pet, 3.2, 620, 1450),
    ]:
        im = Image.open(path).convert("RGBA")
        w = round(base * scale)
        im = im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
        bg.alpha_composite(im, (round(cx - im.width / 2), round(cy - im.height / 2)))
    bg.convert("RGB").resize((603, 1311), Image.LANCZOS).save(dst, quality=90)
    print(f"wrote {dst}")


def selftest():
    # 9:16 input with red top/bottom edge bands and a plain middle.
    src = Image.new("RGB", (900, 1600), (200, 190, 240))
    src.paste((255, 0, 0), (0, 0, 900, 100))
    src.paste((255, 0, 0), (0, 1500, 900, 1600))
    out = normalize(src)
    assert out.size == (WIDTH, HEIGHT), out.size
    edge = round(100 * WIDTH / 900)
    assert out.getpixel((600, edge // 2)) == (255, 0, 0)  # top edge kept
    assert out.getpixel((600, HEIGHT - edge // 2)) == (255, 0, 0)  # bottom kept
    assert out.getpixel((600, HEIGHT // 2)) == (200, 190, 240)  # middle plain
    # Too-tall input is centre-cropped, not squashed.
    tall = normalize(Image.new("RGB", (1206, 3000), (1, 2, 3)))
    assert tall.size == (WIDTH, HEIGHT)
    print("selftest ok")


def main():
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("src", nargs="?")
    p.add_argument("dst", nargs="?")
    p.add_argument("--band", nargs=2, type=float, default=(0.3, 0.7),
                   metavar=("TOP", "BOTTOM"),
                   help="calm middle band to stretch, as height fractions")
    p.add_argument("--quality", type=int, default=88)
    p.add_argument("--preview", metavar="OUT",
                   help="composite furniture + pet on SRC (a normalized JPG)")
    p.add_argument("--selftest", action="store_true")
    a = p.parse_args()
    if a.selftest:
        return selftest()
    if a.preview and a.src:
        return preview(a.src, a.preview)
    if not (a.src and a.dst):
        p.error("src and dst are required")
    if not 0 < a.band[0] < a.band[1] < 1:
        p.error("--band needs 0 < TOP < BOTTOM < 1")
    normalize(Image.open(a.src), tuple(a.band)).save(
        a.dst, "JPEG", quality=a.quality, optimize=True, progressive=True
    )
    print(f"wrote {a.dst} ({WIDTH}x{HEIGHT})")


if __name__ == "__main__":
    sys.exit(main())
