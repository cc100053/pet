"""Snap the Level-1 head socket to the centre of the forehead icing loop.

Run from the repo root with python3. The cream icing loop encloses exactly one
small dough-coloured hole per frame; its centroid is a drawn landmark, so it
replaces the drifting template-tracked head estimate. Body/back stay as seeded.
Pass Godot project dirs as arguments (default: the repo seed copy). Refuses to
run over captures carrying equipmentSettings (a human export).
"""
import json, os, re, sys
import cv2
import numpy as np
from PIL import Image

DIRS = sys.argv[1:] or ['design/pet_sketches/gingerbread_man/godot/pet/gingerbread_man']
STATES = {'stay': 'stay', 'moving': 'walk', 'sleep': 'sleep'}
HEAD_BAND = 130  # px from the top that contains the head; icing below (smile) is ignored


def loop_centre(path):
    a = np.asarray(Image.open(path).convert('RGBA')).astype(int)
    icing = (a[..., :3].sum(-1) > 620) & (a[..., 3] > 128)
    icing[HEAD_BAND:] = False
    n, _, st, cen = cv2.connectedComponentsWithStats((~icing).astype(np.uint8), connectivity=4)
    holes = [cen[k] for k in range(1, n)
             if 15 < st[k, cv2.CC_STAT_AREA] < 600 and st[k, cv2.CC_STAT_TOP] > 0
             and st[k, cv2.CC_STAT_TOP] + st[k, cv2.CC_STAT_HEIGHT] < HEAD_BAND]
    assert len(holes) == 1, f'{path}: expected one enclosed loop hole, found {len(holes)}'
    return [round(float(v), 1) for v in holes[0]]


for anim, state in STATES.items():
    src = f'assets/pet_sequences/gingerbread_man/{state}'
    centres = [loop_centre(f'{src}/{f}') for f in sorted(os.listdir(src)) if f.endswith('.png')]
    for d in DIRS:
        path = f'{d}/gingerbread_man_{anim}_sockets.json'
        data = json.load(open(path))
        assert not data['equipmentSettings'], f'{path} looks human-exported; compare by hand instead'
        assert len(data['frames']) == len(centres)
        for frame, (x, y) in zip(data['frames'], centres):
            frame['sockets']['head'] = {'x': x, 'y': y, 'nx': round(x / 450, 9), 'ny': round(y / 450, 9)}
        json.dump(data, open(path, 'w'), indent=2)
        tscn = f'{d}/gingerbread_man_{anim}.tscn'
        text = open(tscn).read()
        text = re.sub(r'(\[node name="HeadSocket"[^\n]*\]\nposition = )Vector2\([^)]*\)',
                      rf'\g<1>Vector2({centres[0][0]:g}, {centres[0][1]:g})', text)
        open(tscn, 'w').write(text)
    print(anim, centres)
