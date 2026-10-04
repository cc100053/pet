"""Flat-colour 3 x 3 pose guide for an AI walk sheet, posed by the rig walk (walk_test.pose_at).

Body grey, image-left leg blue, image-right leg orange (drawn in front where they overlap),
shell dark grey, arms light grey, tail green, ground line. Frame 9 repeats frame 1.
Writes walk_trial/v4/pose_guide.png (1350 x 1350).
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from compose import ORDER, PIVOTS
import walk_test
from walk_test import pose_at, place, BASE_Y

walk_test.LIFT = 48  # exaggerate foot lift so the guide reads clearly at sheet size

COLOURS = {'body': (170, 170, 170), 'underside': (150, 150, 150), 'leg_a': (70, 120, 220),
           'leg_b': (240, 140, 50), 'arm_a': (215, 215, 215), 'arm_b': (215, 215, 215),
           'tail': (110, 175, 90)}
_layers = {n: Image.open(f'rig/layers/{n}.png') for n in ORDER}
_alpha = {n: im.getchannel('A').point(lambda v: 255 if v > 100 else 0)
          .filter(ImageFilter.MinFilter(5)).filter(ImageFilter.MaxFilter(5)) for n, im in _layers.items()}
# shell drawn darker inside the body silhouette so the guide keeps it readable
_shell = _layers['body'].convert('L').point(lambda v: 255 if v < 125 else 0).filter(ImageFilter.MedianFilter(5))


def flat(pose, body_dy):
    out = Image.new('RGBA', (1254, 1254), (0, 0, 0, 0))
    for n in ORDER:
        ang, dx, dy = pose.get(n, (0, 0, 0))
        a = _alpha[n]
        if ang:
            a = a.rotate(ang, resample=Image.NEAREST, center=tuple(PIVOTS[n]))
        solid = Image.new('RGBA', a.size, COLOURS[n] + (255,))
        solid.putalpha(a)
        off_y = dy + (0 if n.startswith('leg') else body_dy)
        if n == 'body':
            shell = Image.new('RGBA', a.size, (105, 105, 105, 255))
            shell.putalpha(Image.fromarray(np.minimum(np.asarray(_shell), np.asarray(a))))
            solid.alpha_composite(shell)
        out.alpha_composite(solid, (int(round(dx)), int(round(off_y))))
    return out


sheet = Image.new('RGB', (1350, 1350), 'white')
d = ImageDraw.Draw(sheet)
for k in range(9):
    pose, body_dy = pose_at(k % 8)
    cell = place(flat(pose, body_dy))
    x, y = (k % 3) * 450, (k // 3) * 450
    sheet.paste(cell, (x, y), cell)
    d.line([(x + 30, y + BASE_Y + 1), (x + 420, y + BASE_Y + 1)], fill=(200, 200, 200), width=2)
sheet.save('walk_trial/v4/pose_guide.png')
