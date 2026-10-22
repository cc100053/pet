#!/usr/bin/env python3
"""Compose the Ghost Sky shop thumbnail from the shipped background.

The full art keeps its ghosts and clouds at the far edges (docs/art_style.md
§8.1), so a centre crop shows only plain sky. This keeps the top band (clouds
+ right ghost), lifts the bottom-left ghost up beside it, and crossfades the
bottom clouds on underneath, giving a ~4:3 image that card crops never cut
at the sides.

    python3 design/backgrounds/halloween_2026/ghost_sky_thumb.py
"""

from PIL import Image, ImageChops, ImageFilter

SRC = "assets/bg/paid/background-paid-03.jpg"
DST = "assets/bg/paid/background-paid-03-thumb.jpg"
TOP_END = 660  # below the right ghost (rows ~340-620)
BOTTOM_START = 2330  # plain sky just above the bottom clouds (~2380)
FADE = 60
GHOST_BOX = (0, 1930, 200, 2250)  # left ghost peeking in near the bottom
GHOST_Y = 330
OUT_WIDTH = 600


def ghost_mask(patch):
    """Alpha for the ghost only: pixels off the patch's plain-sky colour."""
    grey = patch.convert("L")
    sky = grey.resize((1, 1), Image.BOX).resize(grey.size)
    diff = ImageChops.difference(grey, sky).point(lambda v: 255 if v > 14 else 0)
    return diff.filter(ImageFilter.MaxFilter(15)).filter(ImageFilter.GaussianBlur(6))


def main():
    src = Image.open(SRC).convert("RGB")
    w, h = src.size
    top = src.crop((0, 0, w, TOP_END))
    patch = src.crop(GHOST_BOX)
    top.paste(patch, (0, GHOST_Y), ghost_mask(patch))

    bottom = src.crop((0, BOTTOM_START, w, h))
    out = Image.new("RGB", (w, TOP_END + bottom.height - FADE))
    out.paste(top, (0, 0))
    fade = Image.linear_gradient("L").resize((w, FADE))
    seam = Image.composite(
        bottom.crop((0, 0, w, FADE)), top.crop((0, TOP_END - FADE, w, TOP_END)), fade
    )
    out.paste(bottom, (0, TOP_END - FADE))
    out.paste(seam, (0, TOP_END - FADE))

    out = out.resize((OUT_WIDTH, round(out.height * OUT_WIDTH / w)), Image.LANCZOS)
    out.save(DST, "JPEG", quality=88, optimize=True, progressive=True)
    print(f"wrote {DST} ({out.width}x{out.height})")


if __name__ == "__main__":
    main()
