"""Split a 3 x 3 walk sheet, baseline-align, preview and measure colour drift.

    python3 split_sheet.py v4/source_sheet.webp v4

Writes raw_frames/, aligned_frames/ (450 x 450; lowest foot moved to y=414, generated
horizontal placement kept so any lean survives), raw/aligned GIFs (frames 1-8, 200 ms),
aligned_contact_sheet.png and alignment_report.json with median skin/shell/belly colours.
"""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw

MASTER = {'skin': (181, 202, 149), 'shell': (116, 123, 69), 'belly': (253, 236, 197)}
BASE_Y, W, DX = 414, 450, 16


def colours(img):
    a = np.asarray(img.convert('RGB')).reshape(-1, 3)
    hsv = np.asarray(img.convert('RGB').convert('HSV')).reshape(-1, 3).astype(float) / 255
    h, s, v = hsv.T
    fg = ~((s < .08) & (v > .9))
    masks = {'skin': fg & (h > .2) & (h < .35) & (v > .5) & (s > .25),
             'shell': fg & (h > .15) & (h < .3) & (v < .5) & (s > .3),
             'belly': fg & (h > .08) & (h < .16) & (s > .15) & (s < .5) & (v > .85)}
    return {k: [int(x) for x in np.median(a[m], 0)] for k, m in masks.items()}


src, out = sys.argv[1], sys.argv[2]
sheet = Image.open(src).convert('RGB')
c = sheet.width // 3
for d in ('raw_frames', 'aligned_frames'):
    os.makedirs(f'{out}/{d}', exist_ok=True)
raw, aligned, rep = [], [], []
for i in range(9):
    f = sheet.crop(((i % 3) * c, (i // 3) * c, (i % 3 + 1) * c, (i // 3 + 1) * c))
    f.save(f'{out}/raw_frames/frame_{i + 1:02d}.png')
    fg = np.asarray(f).astype(int).min(2) < 235
    ys, xs = np.nonzero(fg)
    base = int(ys.max())
    canvas = Image.new('RGB', (W, W), 'white')
    canvas.paste(f, (DX, BASE_Y - base))
    canvas.save(f'{out}/aligned_frames/frame_{i + 1:02d}.png')
    raw.append(f); aligned.append(canvas)
    rep.append({'frame': i + 1, 'baseline_y': base, 'top_y': int(ys.min()),
                'head_centre_x': round(float(np.nonzero(fg[:int(c * .4)])[1].mean()), 1),
                'dy': BASE_Y - base})
for name, fr in (('raw', raw), ('aligned', aligned)):
    fr[0].save(f'{out}/{name}_preview.gif', save_all=True, append_images=fr[1:8], duration=200, loop=0)
cs = Image.new('RGB', (W * 3, W * 3), 'white'); d = ImageDraw.Draw(cs)
for k, f in enumerate(aligned):
    x, y = (k % 3) * W, (k // 3) * W
    cs.paste(f, (x, y)); d.line([(x, y + BASE_Y), (x + W, y + BASE_Y)], fill=(170, 140, 110))
    d.text((x + 8, y + 425), f'{k + 1:02d}' + (' / 200 ms' if k < 8 else ' closure ref'), fill=(90, 70, 50))
cs.save(f'{out}/aligned_contact_sheet.png')
report = {'source_size': list(sheet.size), 'cell': c,
          'registration': 'integer translation; lowest foot to y=414, generated horizontal placement kept',
          'frame_durations_ms': [200] * 8, 'closure_reference_frame': 9,
          'master_colours': MASTER, 'sheet_colours': colours(sheet), 'frames': rep}
json.dump(report, open(f'{out}/alignment_report.json', 'w'), indent=2)
print(json.dumps({k: report[k] for k in ('source_size', 'sheet_colours', 'master_colours')}))
for r in rep: print(r)
