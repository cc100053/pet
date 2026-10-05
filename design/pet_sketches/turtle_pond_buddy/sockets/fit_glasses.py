"""Fit the sunglasses to the turtle's tilted eyes, per state, from the current socket JSON.

Run from the repository root after any head-socket change:
    python3 design/pet_sketches/turtle_pond_buddy/sockets/fit_glasses.py

Measures both eyes in every frame (dark pupils, or closed-lid lines in sleep) and takes,
per state, the median eye tilt, spacing and eye-midpoint offset from the head socket. It
then solves the face-slot override so the lens centres land on the eyes: one shared width
from the median spacing, an anchor per state, and a rotation about the item centre (the
lens midpoint). Prints the Dart override and writes review_glasses.png, a mock of the
Flutter placement (socket - anchor * size, then rotated) on every frame.
"""
import json, math
import cv2
import numpy as np
from PIL import Image, ImageDraw

G = '/Users/fatboy/pet-tomo/pet/turtle'
OUT = 'design/pet_sketches/turtle_pond_buddy/sockets/review_glasses.png'
GLASSES = 'assets/equipment/sunglasses.png'
LENS_L, LENS_R = (140, 222), (312, 222)   # lens centres in the 450 px glasses image
CANVAS = 450
STATES = {'stay': 'idle', 'moving': 'walk', 'sleep': 'sleep'}


def eyes(rgba, hx, hy):
    """Left/right eye centres: the two highest dark-brown blobs below the head socket."""
    y0, x0 = int(hy + 20), int(hx - 110)
    sub = rgba[y0:int(hy + 110), x0:int(hx + 110)].astype(int)
    dark = (sub[..., 3] > 200) & (sub[..., :3].sum(2) < 300) & (sub[..., 0] > sub[..., 2])
    n, _, st, cen = cv2.connectedComponentsWithStats(dark.astype(np.uint8))
    comps = sorted([k for k in range(1, n) if st[k, 4] > 25], key=lambda k: -st[k, 4])[:3]
    comps = sorted(sorted(comps, key=lambda k: cen[k][1])[:2], key=lambda k: cen[k][0])
    return [(cen[k][0] + x0, cen[k][1] + y0) for k in comps]


data, fits = {}, {}
for anim in STATES:
    d = json.load(open(f'{G}/turtle_{anim}_sockets.json'))
    rows = []
    for fr in d['frames']:
        img = np.asarray(Image.open(fr['image'].replace('res://pet/turtle', G)).convert('RGBA'))
        h = fr['sockets']['head']
        (lx, ly), (rx, ry) = eyes(img, h['x'], h['y'])
        rows.append((lx, ly, rx, ry, h['x'], h['y']))
    r = np.array(rows)
    data[anim] = (d, r)
    fits[anim] = {
        'angle': float(np.median(np.degrees(np.arctan2(r[:, 3] - r[:, 1], r[:, 2] - r[:, 0])))),
        'spacing': float(np.median(np.hypot(r[:, 2] - r[:, 0], r[:, 3] - r[:, 1]))),
        'dx': float(np.median((r[:, 0] + r[:, 2]) / 2 - r[:, 4])),
        'dy': float(np.median((r[:, 1] + r[:, 3]) / 2 - r[:, 5])),
    }

lens_mid = ((LENS_L[0] + LENS_R[0]) / 2 / CANVAS, (LENS_L[1] + LENS_R[1]) / 2 / CANVAS)
lens_gap = (LENS_R[0] - LENS_L[0]) / CANVAS
spacing = np.median([f['spacing'] for f in fits.values()])
width_ratio = round(spacing / CANVAS / lens_gap, 2)   # one size for every state
item = width_ratio * CANVAS
for f in fits.values():
    f['anchor'] = (round(lens_mid[0] - f['dx'] / item, 3), round(lens_mid[1] - f['dy'] / item, 3))
    f['rotation'] = round(f['angle'], 1)

print(json.dumps({'widthRatio': width_ratio, 'fits': fits}, indent=1))
print("\nDart (petOverrides + petStateOverrides for 'turtle'):")
for anim, state in STATES.items():
    f = fits[anim]
    print(f"  {state}: anchor ({f['anchor'][0]}, {f['anchor'][1]}), widthRatio {width_ratio}, "
          f"rotationDegrees {f['rotation']}")

# mock Flutter placement on every frame
glasses = Image.open(GLASSES).convert('RGBA').resize((round(item),) * 2, Image.LANCZOS)
tiles = []
for anim in STATES:
    d, _ = data[anim]
    f = fits[anim]
    g = glasses.rotate(-f['rotation'], resample=Image.BICUBIC)  # PIL: positive = CCW
    for fr in d['frames']:
        im = Image.open(fr['image'].replace('res://pet/turtle', G)).convert('RGBA')
        bg = Image.new('RGBA', im.size, 'white'); bg.alpha_composite(im)
        h = fr['sockets']['head']
        bg.alpha_composite(g, (round(h['x'] - f['anchor'][0] * item), round(h['y'] - f['anchor'][1] * item)))
        tiles.append(bg.convert('RGB').resize((180, 180)))
cols = 11
sheet = Image.new('RGB', (cols * 180, -(-len(tiles) // cols) * 180), 'white')
for i, t in enumerate(tiles):
    sheet.paste(t, ((i % cols) * 180, (i // cols) * 180))
sheet.save(OUT)
