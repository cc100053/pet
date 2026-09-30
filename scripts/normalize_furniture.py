#!/usr/bin/env python3
"""Normalize generated furniture art into a shippable assets/furniture PNG.

Gemini (and most image models) cannot output transparency, so art is generated
on a plain white background. This script:
  1. removes that background (auto-detected from the border) by flood-filling from the image border (white
     areas enclosed by an outline, e.g. a bathtub's interior, are kept),
  2. crops to the object, scales its long side to --size (default 420),
  3. centers it on a 450x450 transparent canvas and saves an optimized PNG.

Inputs that already have transparency skip step 1.

    python3 scripts/normalize_furniture.py raw.png assets/furniture/pumpkin_lantern.png
    python3 scripts/normalize_furniture.py --ref-sheet /tmp/style_ref.png   # Gemini style reference
    python3 scripts/normalize_furniture.py --selftest

See docs/art_style.md for the full workflow.
"""

import argparse
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

CANVAS = 450
SENTINEL = (255, 0, 255)  # never survives: it marks background after flood fill


def has_transparency(im):
    return im.mode in ("RGBA", "LA", "P") and im.convert("RGBA").getextrema()[3][0] < 255


def close(a, b, thresh):
    return all(abs(x - y) <= thresh for x, y in zip(a, b))


def remove_background(im, thresh, holes=False):
    rgb = im.convert("RGB")
    w, h = rgb.size
    border = [(x, y) for x in range(0, w, 8) for y in (0, h - 1)]
    border += [(x, y) for y in range(0, h, 8) for x in (0, w - 1)]
    # Background = most common border colour (white by default, dark grey for
    # pale items; see docs/art_style.md).
    colors = [rgb.getpixel(xy) for xy in border]
    bg_color = max(set(colors), key=colors.count)
    # Seed along the whole border so separate background pockets that touch the
    # edge (e.g. between balloon strings) are all reached.
    for xy in border:
        if close(rgb.getpixel(xy), bg_color, thresh):
            ImageDraw.floodfill(rgb, xy, SENTINEL, thresh=thresh)
    if holes:
        # Also clear enclosed pockets of background (gaps between strings).
        # Only safe on a dark-grey background: on white it would punch out
        # white parts of the object itself.
        diff = ImageChops.difference(rgb, Image.new("RGB", rgb.size, bg_color))
        pocket = ImageChops.lighter(ImageChops.lighter(*diff.split()[:2]), diff.split()[2])
        rgb.paste(SENTINEL, mask=pocket.point(lambda v: 255 if v <= thresh else 0))
    bg = ImageChops.difference(rgb, Image.new("RGB", rgb.size, SENTINEL)).convert("L")
    alpha = bg.point(lambda v: 0 if v == 0 else 255)
    # Shave the 1px background-coloured fringe the fill left behind, then soften the
    # edge so it anti-aliases instead of stair-stepping at small room sizes.
    alpha = alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.7))
    out = im.convert("RGBA")
    out.putalpha(alpha)
    return out


def normalize(im, size, thresh, holes=False):
    im = im.convert("RGBA") if has_transparency(im) else remove_background(im, thresh, holes)
    bbox = im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    if not bbox:
        raise SystemExit("error: image is empty after background removal")
    im = im.crop(bbox)
    scale = size / max(im.size)
    im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.LANCZOS)
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.paste(im, ((CANVAS - im.width) // 2, (CANVAS - im.height) // 2), im)
    return canvas


def ref_sheet(out_path, names):
    """Existing furniture on white, so a model sees the art, not black transparency."""
    tiles = [Image.open(f"assets/furniture/{n}.png").convert("RGBA") for n in names]
    sheet = Image.new("RGB", (CANVAS * len(tiles), CANVAS), "white")
    for i, t in enumerate(tiles):
        sheet.paste(t, (i * CANVAS, 0), t)
    sheet.save(out_path)
    print(f"wrote {out_path} ({', '.join(names)})")


def report(im, path):
    a = im.getchannel("A")
    l, t, r, b = a.getbbox()
    print(f"wrote {path}: object {r - l}x{b - t}, margins L{l} T{t} R{CANVAS - r} B{CANVAS - b}, "
          f"{os.path.getsize(path) // 1024} KB")


def selftest():
    # White bg + a ring whose white interior must stay opaque (the bathtub case).
    src = Image.new("RGB", (1024, 1024), "white")
    d = ImageDraw.Draw(src)
    d.ellipse((212, 312, 812, 712), fill=(200, 110, 60))
    d.ellipse((262, 362, 762, 662), fill="white")
    out = normalize(src, 420, 24)
    assert out.size == (CANVAS, CANVAS)
    assert out.getpixel((0, 0))[3] == 0, "corner must be transparent"
    assert out.getpixel((225, 225))[3] == 255, "enclosed white must stay opaque"
    l, t, r, b = out.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    assert abs((r - l) - 420) <= 2 and abs((l + r) / 2 - 225) <= 2, (l, t, r, b)
    # Pale item on dark grey: white parts must survive.
    src = Image.new("RGB", (800, 800), (74, 74, 74))
    d = ImageDraw.Draw(src)
    d.line((400, 100, 400, 700), fill="white", width=12)
    d.ellipse((150, 300, 650, 500), outline="white", width=12)  # encloses a grey pocket
    out = normalize(src, 420, 24, holes=True)
    assert out.getpixel((225, 225))[3] >= 250 and out.getpixel((0, 0))[3] == 0
    assert out.getpixel((120, 225))[3] == 0, "enclosed pocket must be cleared with --holes"
    print("selftest ok")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("input", nargs="?")
    p.add_argument("output", nargs="?")
    p.add_argument("--size", type=int, default=420, help="object long side in px (existing art: 380-444)")
    p.add_argument("--thresh", type=int, default=24, help="background colour tolerance (raise for off-white bg)")
    p.add_argument("--holes", action="store_true", help="also clear enclosed background pockets (dark-grey bg only)")
    p.add_argument("--lossless", action="store_true", help="skip 256-colour quantization")
    p.add_argument("--ref-sheet", metavar="OUT", help="write a style reference sheet and exit")
    p.add_argument("--ref-items", default="cactus,carpet,vinyl", help="comma-separated furniture names for --ref-sheet")
    p.add_argument("--selftest", action="store_true")
    args = p.parse_args()

    if args.selftest:
        return selftest()
    if args.ref_sheet:
        return ref_sheet(args.ref_sheet, args.ref_items.split(","))
    if not (args.input and args.output):
        p.error("input and output are required")
    if not 200 <= args.size <= CANVAS:
        p.error("--size must be 200-450")

    im = normalize(Image.open(args.input), args.size, args.thresh, args.holes)
    if not args.lossless:
        # 256 colours keeps files in the existing 10-150 KB range; the soft
        # painted style survives it. Use --lossless if banding shows up.
        im = im.quantize(256, method=Image.Quantize.FASTOCTREE)
    im.save(args.output, optimize=True)
    report(Image.open(args.output).convert("RGBA"), args.output)


if __name__ == "__main__":
    sys.exit(main())
