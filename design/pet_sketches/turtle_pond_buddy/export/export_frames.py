"""Export accepted turtle idle (stay) and walk loops as runtime-style transparent PNGs.

Run from design/pet_sketches/turtle_pond_buddy:  python3 export/export_frames.py

Sources (450 x 450 opaque, lowest foot at y=414):
  stay: idle_trial/aligned_frames/frame_01-09 (accepted continuous loop, 1650 ms)
  walk: walk_trial/v4/fix/aligned_frames/frame_01-08 (accepted; frame 9 is closure-only)
Steps: colour-match each sequence to the master, remove the white background,
scale each sequence to one character size (idle height, matched head width), put feet
on BASE_Y, centre the idle and line up the walk's mean head position with it.
Writes export/{stay,walk}/turtle_<state>-NN.png, timing.json and review previews.
"""
import json, os, sys
import cv2
import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, 'walk_trial')
from split_sheet import colours, colour_luts, apply_luts  # noqa: E402

CANVAS, BASE_Y, CENTRE_X, TARGET_H = 450, 432, 225, 390  # tiger-like size and baseline
SEQS = {
    'stay': ([f'idle_trial/aligned_frames/frame_{i:02d}.png' for i in range(1, 10)],
             [200, 200, 250, 200, 120, 160, 120, 200, 200]),
    'walk': ([f'walk_trial/v4/fix/aligned_frames/frame_{i:02d}.png' for i in range(1, 9)],
             [200] * 8),
}


def cut_out(img):
    """White background -> alpha, keeping only the turtle (drops stray specks)."""
    rgb = np.asarray(img.convert('RGB'))
    h, w = rgb.shape[:2]
    ff = (rgb.min(2) > 238).astype(np.uint8)
    mask = np.zeros((h + 2, w + 2), np.uint8)
    for p in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
        if ff[p[1], p[0]]:
            cv2.floodFill(ff, mask, p, 2)
    fg = (ff != 2).astype(np.uint8)
    n, lab, st, _ = cv2.connectedComponentsWithStats(fg)
    big = st[1:, 4].max()
    fg = np.isin(lab, [k for k in range(1, n) if st[k, 4] > 0.02 * big]).astype(np.uint8)
    fg = cv2.morphologyEx(fg, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    edge = (cv2.dilate(fg, np.ones((3, 3))) - cv2.erode(fg, np.ones((3, 3)))) > 0
    a = fg.astype(float)
    whiteness = (765 - rgb.astype(int).sum(2)) / 90.0
    a[edge] = np.clip(whiteness[edge], 0, 1) * cv2.dilate(fg, np.ones((3, 3)))[edge]
    af = a[..., None]
    out = np.where(af > 0.02, (rgb - 255 * (1 - af)) / np.maximum(af, 1e-3), 0).clip(0, 255)
    return Image.fromarray(np.dstack([out, a * 255]).astype(np.uint8), 'RGBA')


def bbox(img):
    ys, xs = np.nonzero(np.asarray(img)[..., 3] > 10)
    return xs.min(), xs.max(), ys.min(), ys.max()


def head_centre_x(img):
    a = np.asarray(img)[..., 3] > 10
    ys = np.nonzero(a.any(1))[0]
    top = a[ys.min(): ys.min() + int(0.3 * (ys.max() - ys.min()))]
    return np.nonzero(top)[1].mean()


def head_width(img):
    """Widest row in the top 30% of the silhouette: stable across poses, unlike height."""
    a = np.asarray(img)[..., 3] > 10
    ys = np.nonzero(a.any(1))[0]
    rows = a[ys.min(): ys.min() + int(0.3 * (ys.max() - ys.min()))]
    return max(np.ptp(np.nonzero(r)[0]) for r in rows if r.any())



def main():
    cut = {}
    for name, (paths, _) in SEQS.items():
        frames = [Image.open(p).convert('RGB') for p in paths]
        luts = colour_luts(colours(Image.fromarray(np.hstack([np.asarray(f) for f in frames]))))
        cut[name] = [cut_out(apply_luts(f, luts)) for f in frames]

    # idle sets the size (TARGET_H tall); the walk sheet was drawn ~10% larger, so each
    # sequence is scaled to the idle's head width to keep the character one size.
    idle_h = np.median([b[3] - b[2] for b in map(bbox, cut['stay'])])
    idle_hw = np.median([head_width(f) for f in cut['stay']])
    scales = {n: TARGET_H / idle_h * idle_hw / np.median([head_width(f) for f in fr]) for n, fr in cut.items()}
    idle_cx = (bbox(cut['stay'][0])[0] + bbox(cut['stay'][0])[1]) / 2
    seq_head = {n: np.mean([head_centre_x(f) for f in fr]) for n, fr in cut.items()}
    # idle bbox centred on CENTRE_X; every sequence's mean head centre lands where the idle's does
    head_out_x = CENTRE_X + (seq_head['stay'] - idle_cx) * scales['stay']

    report = {'canvas': CANVAS, 'baseline_y': BASE_Y,
              'scale': {n: round(float(v), 4) for n, v in scales.items()},
              'sequences': {}}
    os.makedirs('export/review', exist_ok=True)
    for name, (_, durations) in SEQS.items():
        os.makedirs(f'export/{name}', exist_ok=True)
        seq_bottom = max(bbox(f)[3] for f in cut[name])  # lowest foot of the whole sequence
        out = []
        scale = scales[name]
        for i, f in enumerate(cut[name]):
            # premultiplied resize avoids dark fringes
            small = f.convert('RGBa').resize((round(f.width * scale), round(f.height * scale)),
                                             Image.LANCZOS).convert('RGBA')
            x = round(head_out_x - seq_head[name] * scale)
            y = round(BASE_Y - seq_bottom * scale)
            canvas = Image.new('RGBA', (CANVAS, CANVAS), (0, 0, 0, 0))
            canvas.alpha_composite(small, (x, y))
            canvas.save(f'export/{name}/turtle_{name}-{i + 1:02d}.png', optimize=True)
            out.append(canvas)
        bxs = np.array([bbox(c) for c in out])
        assert bxs[:, 0].min() > 4 and bxs[:, 1].max() < CANVAS - 4 and bxs[:, 2].min() > 4, f'{name} clipped'
        assert abs(int(bxs[:, 3].max()) - BASE_Y) <= 2, f'{name} baseline {bxs[:, 3].max()}'
        report['sequences'][name] = {'frames': len(out), 'frame_durations_ms': durations,
                                     'total_ms': sum(durations),
                                     'bounds_x': [int(bxs[:, 0].min()), int(bxs[:, 1].max())],
                                     'bounds_y': [int(bxs[:, 2].min()), int(bxs[:, 3].max())]}
        for label, bg in (('light', (244, 239, 230)), ('dark', (43, 43, 51))):
            flat = [Image.alpha_composite(Image.new('RGBA', c.size, bg + (255,)), c).convert('RGB') for c in out]
            flat[0].save(f'export/review/{name}_{label}.gif', save_all=True, append_images=flat[1:],
                         duration=durations, loop=0)
    json.dump(report, open('export/timing.json', 'w'), indent=2)

    # contact sheet: every frame on dark (fringe check) plus 96/128 px size probes
    rows = [cut for cut in (sorted(os.listdir('export/stay')), sorted(os.listdir('export/walk')))]
    sheet = Image.new('RGB', (9 * 150, 2 * 170 + 150), (43, 43, 51))
    d = ImageDraw.Draw(sheet)
    for r, (name, files) in enumerate(zip(('stay', 'walk'), rows)):
        for k, fn in enumerate(files):
            im = Image.open(f'export/{name}/{fn}').resize((150, 150), Image.LANCZOS)
            sheet.paste(im, (k * 150, r * 170), im)
            d.text((k * 150 + 4, r * 170 + 152), fn, fill=(200, 200, 200))
    x = 0
    for size in (96, 128):
        for name in ('stay', 'walk'):
            im = Image.open(f'export/{name}/turtle_{name}-01.png').resize((size, size), Image.LANCZOS)
            for bg in ((244, 239, 230), (43, 43, 51)):
                tile = Image.new('RGB', (size, size), bg); tile.paste(im, (0, 0), im)
                sheet.paste(tile, (x, 2 * 170 + (150 - size) // 2)); x += size + 8
    sheet.save('export/review/contact_sheet.png')
    print(json.dumps(report, indent=1))


if __name__ == '__main__':
    main()
