"""Sleep loop built from ONE generated sleep frame: dozing nod, breathing and rising z marks.

Run from design/pet_sketches/turtle_pond_buddy:  python3 sleep_trial/animate_sleep.py

Source: sleep_trial/source_sheet.webp (cell 1 = pose without z; cell 4 = three z marks).
The pose is cut once (head / body), so no frame redraws the character. Writes
export/sleep/turtle_sleep-NN.png (450 x 450 RGBA, same size/baseline as stay/walk),
sleep_trial/timing.json and review loops in export/review/.
"""
import json, math, os, sys
import cv2
import numpy as np
from PIL import Image

sys.path.insert(0, 'walk_trial')
sys.path.insert(0, 'export')
from split_sheet import colours, colour_luts, apply_luts  # noqa: E402
from export_frames import cut_out, bbox, head_width, head_centre_x, BASE_Y  # noqa: E402

FRAMES, MS = 16, 160                 # 2560 ms loop
NOD_DROP, NOD_TILT = 9, 4.0          # cell px / degrees at the deepest point of the nod
NOD_SINK_END = 0.62                  # fraction of the cycle spent slowly sinking
BREATH = 0.018                       # body height change at the peak inhale
HEAD = dict(cx=192, cy=170, rx=126, ry=104)   # head ellipse in cell coordinates
NECK_PIVOT = (196, 262)
NECK_BEHIND_Y = 205                  # body exists behind the head only below this row

sheet = Image.open('sleep_trial/source_sheet.webp').convert('RGB')
C = sheet.width // 3
cell = sheet.crop((0, 0, C, C))
luts = colour_luts(colours(cell))
rgba = np.asarray(cut_out(apply_luts(cell, luts))).copy()
alpha = rgba[..., 3]

yy, xx = np.mgrid[:C, :C]
head_m = (((xx - HEAD['cx']) / HEAD['rx']) ** 2 + ((yy - HEAD['cy']) / HEAD['ry']) ** 2) <= 1
head_m &= ~((xx > 292) & (yy > 205))             # leave the shell rim with the body
head_soft = cv2.GaussianBlur(head_m.astype(np.float32), (0, 0), 1.2)

head = rgba.copy()
head[..., 3] = (alpha * head_soft).astype(np.uint8)
# body keeps everything, with the area under the head painted in so a moving head never shows a hole
body = rgba.copy()
under = (head_m & (alpha > 0)).astype(np.uint8)
ring = cv2.dilate(under, np.ones((9, 9), np.uint8)) & ~under & (alpha > 200)
src = np.where(ring[..., None] > 0, rgba[..., :3], 0).astype(np.uint8)
fill = cv2.inpaint(src, (1 - ring).astype(np.uint8), 7, cv2.INPAINT_TELEA)
body[..., :3] = np.where(under[..., None] > 0, fill, rgba[..., :3])
# only the neck/shoulders and shell continue behind the head; the upper head area is empty
behind = cv2.GaussianBlur(((yy > NECK_BEHIND_Y) | ~head_m).astype(np.float32), (0, 0), 2)
body[..., 3] = (alpha * behind).astype(np.uint8)
head_img, body_img = Image.fromarray(head, 'RGBA'), Image.fromarray(body, 'RGBA')

# z glyphs: dark olive-brown strokes in cell 4's top-right corner, split into separate marks
z_cell = np.asarray(apply_luts(sheet.crop((0, C, C, 2 * C)), luts)).astype(int)
zr = (z_cell[..., 0] < 170) & (z_cell[..., 2] < 140) & (z_cell.sum(2) < 420)
zr[:, :300] = False; zr[200:, :] = False
n, lab, st, _ = cv2.connectedComponentsWithStats(zr.astype(np.uint8))
glyphs = sorted([k for k in range(1, n) if st[k, 4] > 40], key=lambda k: -st[k, 4])
z_big = lab == glyphs[0]
x0, y0, w, h = st[glyphs[0], :4]
z_alpha = cv2.GaussianBlur(z_big[y0:y0 + h, x0:x0 + w].astype(np.float32), (0, 0), 0.6)
z_rgb = np.median(z_cell[z_big], 0)
Z = Image.fromarray(np.dstack([np.broadcast_to(z_rgb, (h, w, 3)), z_alpha * 255]).astype(np.uint8), 'RGBA')


def nod(t):
    """0..1 depth: slow sink, quick catch with a small overshoot, settle."""
    if t < NOD_SINK_END:
        u = t / NOD_SINK_END
        return 0.5 - 0.5 * math.cos(math.pi * u)        # ease in-out down
    u = (t - NOD_SINK_END) / (1 - NOD_SINK_END)
    return math.exp(-6 * u) * math.cos(2.2 * math.pi * u)  # snap up, tiny bounce, rest


def frame(i):
    t = i / FRAMES
    out = Image.new('RGBA', (C, C), (0, 0, 0, 0))
    # breathing: stretch the body upward from the ground line
    k = 1 + BREATH * (0.5 - 0.5 * math.cos(2 * math.pi * t))
    ground = bbox(body_img)[3]
    b = body_img.resize((C, round(C * k)), Image.BICUBIC)
    out.alpha_composite(b, (0, round(ground - ground * k)))
    lift = ground - ground * k
    d = nod(t)
    h = head_img.rotate(NOD_TILT * d, resample=Image.BICUBIC, center=NECK_PIVOT)
    out.alpha_composite(h, (0, round(NOD_DROP * d + lift)))
    # three z marks rising up-right in turn, growing then fading
    for j in range(3):
        p = (t + j / 3) % 1
        a = math.sin(math.pi * p) ** 1.5
        s = 0.45 + 0.55 * p
        zi = Z.resize((max(1, round(Z.width * s)), max(1, round(Z.height * s))), Image.LANCZOS)
        zi.putalpha(zi.getchannel('A').point(lambda v: int(v * a)))
        out.alpha_composite(zi, (round(300 + 70 * p), round(150 - 110 * p)))
    return out


def main():
    # same character size and placement as the exported stay frames
    stay = [Image.open(f'export/stay/turtle_stay-{i:02d}.png') for i in range(1, 10)]
    scale = np.median([head_width(f) for f in stay]) / head_width(head_img)
    target_head_x = np.mean([head_centre_x(f) for f in stay])
    ground = bbox(body_img)[3]
    hx = head_centre_x(head_img)
    os.makedirs('export/sleep', exist_ok=True)
    frames = []
    for i in range(FRAMES):
        f = frame(i)
        small = f.convert('RGBa').resize((round(C * scale),) * 2, Image.LANCZOS).convert('RGBA')
        canvas = Image.new('RGBA', (450, 450), (0, 0, 0, 0))
        canvas.alpha_composite(small, (round(target_head_x - hx * scale), round(BASE_Y - ground * scale)))
        canvas.save(f'export/sleep/turtle_sleep-{i + 1:02d}.png', optimize=True)
        frames.append(canvas)
    bxs = np.array([bbox(c) for c in frames])
    assert bxs[:, 0].min() > 4 and bxs[:, 1].max() < 446 and bxs[:, 2].min() > 4, 'clipped'
    for label, bg in (('light', (244, 239, 230)), ('dark', (43, 43, 51))):
        flat = [Image.alpha_composite(Image.new('RGBA', c.size, bg + (255,)), c).convert('RGB') for c in frames]
        flat[0].save(f'export/review/sleep_{label}.gif', save_all=True, append_images=flat[1:],
                     duration=MS, loop=0)
    timing = {'frames': FRAMES, 'frame_durations_ms': [MS] * FRAMES, 'total_ms': MS * FRAMES,
              'scale': round(float(scale), 4), 'bounds_x': [int(bxs[:, 0].min()), int(bxs[:, 1].max())],
              'bounds_y': [int(bxs[:, 2].min()), int(bxs[:, 3].max())]}
    json.dump(timing, open('sleep_trial/timing.json', 'w'), indent=2)
    print(timing)


if __name__ == '__main__':
    main()
