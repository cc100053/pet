"""Level-1 socket estimates for the turtle + Godot authoring scenes.

Run from the repository root:  python3 design/pet_sketches/turtle_pond_buddy/sockets/estimate_sockets.py

Frame-0 sockets are hand-placed (FRAME0, canvas px) following the shipped pets' semantics:
head = top-centre of the head where hats sit, body = upper chest just under the chin,
back = on the shell at shoulder height. Every later frame is tracked by template matching
the patch around each socket against the previous frame (search window SEARCH px), which
follows walk sway and the sleep nod without redrawing anything by hand.

Writes into the Godot project (/Users/fatboy/pet-tomo/pet/turtle/):
  turtle_<anim>/<frames>.png, turtle_<anim>.tscn, turtle_<anim>_sockets.json
and a review sheet design/pet_sketches/turtle_pond_buddy/sockets/review_<anim>.png.
These are review level 1: human Godot review with equipment is required before Flutter sync.
"""
import json, os, shutil
import cv2
import numpy as np
from PIL import Image, ImageDraw

GODOT = '/Users/fatboy/pet-tomo/pet/turtle'
HERE = 'design/pet_sketches/turtle_pond_buddy/sockets'
CANVAS = 450
PATCH, SEARCH = 36, 18   # half-size of the tracked patch, max px moved per frame
ANIMS = {  # Godot action name: (asset state folder, durations ms, frame-0 sockets)
    'stay': ('stay', [200, 200, 250, 200, 120, 160, 120, 200, 200],
             {'head': (170, 72), 'body': (172, 228), 'back': (275, 255)}),
    'moving': ('walk', [200] * 8,
               {'head': (168, 88), 'body': (172, 250), 'back': (272, 272)}),
    'sleep': ('sleep', [160] * 16,
              {'head': (162, 168), 'body': (165, 318), 'back': (280, 315)}),
}
COLOURS = {'head': (230, 40, 40), 'body': (40, 90, 230), 'back': (40, 170, 60)}


def grey(path):
    """Alpha-composite on mid grey so the silhouette edge is part of the matched texture."""
    im = Image.open(path).convert('RGBA')
    bg = Image.new('RGBA', im.size, (128, 128, 128, 255))
    bg.alpha_composite(im)
    return np.asarray(bg.convert('L')).astype(np.float32)


def track(images, start):
    pts = [np.array(start, float)]
    for prev, cur in zip(images, images[1:]):
        x, y = np.round(pts[-1]).astype(int)
        tpl = prev[y - PATCH:y + PATCH, x - PATCH:x + PATCH]
        win = cur[y - PATCH - SEARCH:y + PATCH + SEARCH, x - PATCH - SEARCH:x + PATCH + SEARCH]
        res = cv2.matchTemplate(win, tpl, cv2.TM_CCOEFF_NORMED)
        _, _, _, (mx, my) = cv2.minMaxLoc(res)
        pts.append(pts[-1] + (mx - SEARCH, my - SEARCH))
    return pts


def scene(anim, files, durations):
    ext = ''.join(f'[ext_resource type="Texture2D" path="res://pet/turtle/turtle_{anim}/{f}" id="{i + 1}"]\n'
                  for i, f in enumerate(files))
    frames = ', '.join(f'{{"duration": {d / 100:g}, "texture": ExtResource("{i + 1}")}}'
                       for i, d in enumerate(durations))
    s0 = ANIMS[anim][2]
    name = 'Turtle' + anim.capitalize()
    return f"""[gd_scene load_steps={len(files) + 2} format=3]

{ext}
[sub_resource type="SpriteFrames" id="SpriteFrames_turtle_{anim}"]
animations = [{{
"frames": [{frames}],
"loop": true,
"name": &"{anim}",
"speed": 10.0
}}]

[node name="{name}" type="Node2D"]

[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]
sprite_frames = SubResource("SpriteFrames_turtle_{anim}")
animation = &"{anim}"
autoplay = "{anim}"
centered = false

[node name="HeadSocket" type="Marker2D" parent="."]
position = Vector2({s0['head'][0]}, {s0['head'][1]})

[node name="BodySocket" type="Marker2D" parent="."]
position = Vector2({s0['body'][0]}, {s0['body'][1]})

[node name="BackSocket" type="Marker2D" parent="."]
position = Vector2({s0['back'][0]}, {s0['back'][1]})
"""


os.makedirs(HERE, exist_ok=True)
for anim, (state, durations, frame0) in ANIMS.items():
    src = f'assets/pet_sequences/turtle/{state}'
    files = sorted(os.listdir(src))
    assert len(files) == len(durations)
    dst = f'{GODOT}/turtle_{anim}'
    os.makedirs(dst, exist_ok=True)
    for f in files:
        shutil.copyfile(f'{src}/{f}', f'{dst}/{f}')
    imgs = [grey(f'{src}/{f}') for f in files]
    tracks = {slot: track(imgs, xy) for slot, xy in frame0.items()}
    frames = []
    for i, f in enumerate(files):
        socks = {}
        for slot in ('head', 'body', 'back'):
            x, y = (round(float(v), 1) for v in tracks[slot][i])
            socks[slot] = {'x': x, 'y': y, 'nx': round(x / CANVAS, 9), 'ny': round(y / CANVAS, 9)}
        frames.append({'index': i, 'durationMs': durations[i],
                       'image': f'res://pet/turtle/turtle_{anim}/{f}', 'sockets': socks})
    data = {'pet': 'turtle', 'animation': anim, 'canvas': [450.0, 450.0], 'frameCount': len(files),
            'frameHold': 1, 'frameDurationsMs': durations, 'frames': frames,
            'equipmentSettings': {}, 'sockets': {}}
    json.dump(data, open(f'{GODOT}/turtle_{anim}_sockets.json', 'w'), indent=2)
    open(f'{GODOT}/turtle_{anim}.tscn', 'w').write(scene(anim, files, durations))
    # review sheet: every frame with its sockets and the frame-0 position as a faint cross
    n = len(files); cols = min(n, 8); rows = (n + cols - 1) // cols
    sheet = Image.new('RGB', (cols * 225, rows * 235), 'white')
    for i, f in enumerate(files):
        im = Image.open(f'{src}/{f}').convert('RGBA')
        bg = Image.new('RGBA', im.size, 'white'); bg.alpha_composite(im)
        d = ImageDraw.Draw(bg)
        for slot, c in COLOURS.items():
            x0, y0 = frame0[slot]
            d.line([(x0 - 6, y0), (x0 + 6, y0)], fill=(200, 200, 200)); d.line([(x0, y0 - 6), (x0, y0 + 6)], fill=(200, 200, 200))
            x, y = tracks[slot][i]
            d.ellipse((x - 8, y - 8, x + 8, y + 8), outline=c, width=4)
        sheet.paste(bg.convert('RGB').resize((225, 225)), ((i % cols) * 225, (i // cols) * 235))
    sheet.save(f'{HERE}/review_{anim}.png')
    rng = {s: np.ptp(np.array(t), 0).round(1).tolist() for s, t in tracks.items()}
    print(anim, 'range px (x,y):', rng)
