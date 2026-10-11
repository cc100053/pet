"""Prepare Gingerbread Man Godot scenes and Level-1 socket estimates.

Run once from the repo root with python3. Reuses the turtle template tracker.
Outputs stay/moving/sleep scenes under ../godot/pet/gingerbread_man, plus review
sheets here. Never re-run over reviewed exports; human equipment review and
Export Sockets are required before Flutter sync. Runtime art is copied unchanged.
"""
import json, os, shutil
import cv2
import numpy as np
from PIL import Image, ImageDraw

GODOT = 'design/pet_sketches/gingerbread_man/godot/pet/gingerbread_man'
HERE = 'design/pet_sketches/gingerbread_man/sockets'
CANVAS = 450
PATCH, SEARCH = 36, 18   # half-size of the tracked patch, max px moved per frame
ANIMS = {
    'stay': ('stay', [200, 100, 250, 400, 200, 400, 100],
             {'head': (225, 40), 'body': (225, 185), 'back': (270, 190)}),
    'moving': ('walk', [200, 200, 200, 200, 200, 200, 300, 200],
               {'head': (225, 28), 'body': (225, 175), 'back': (270, 180)}),
    'sleep': ('sleep', [200, 100, 200, 100, 100, 100],
              {'head': (225, 28), 'body': (225, 182), 'back': (265, 195)}),
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
        x0, y0 = max(0, x - PATCH), max(0, y - PATCH)
        x1, y1 = min(CANVAS, x + PATCH), min(CANVAS, y + PATCH)
        wx, wy = max(0, x0 - SEARCH), max(0, y0 - SEARCH)
        win = cur[wy:min(CANVAS, y1 + SEARCH), wx:min(CANVAS, x1 + SEARCH)]
        tpl = prev[y0:y1, x0:x1]
        assert tpl.size and win.shape[0] >= tpl.shape[0] and win.shape[1] >= tpl.shape[1]
        res = cv2.matchTemplate(win, tpl, cv2.TM_CCOEFF_NORMED)
        _, _, _, (mx, my) = cv2.minMaxLoc(res)
        pts.append(pts[-1] + (mx + wx - x0, my + wy - y0))
    return pts


def scene(anim, files, durations):
    ext = ''.join(f'[ext_resource type="Texture2D" path="res://pet/gingerbread_man/gingerbread_man_{anim}/{f}" id="{i + 1}"]\n'
                  for i, f in enumerate(files))
    frames = ', '.join(f'{{"duration": {d / 100:g}, "texture": ExtResource("{i + 1}")}}'
                       for i, d in enumerate(durations))
    s0 = ANIMS[anim][2]
    name = 'GingerbreadMan' + anim.capitalize()
    return f"""[gd_scene load_steps={len(files) + 2} format=3]

{ext}
[sub_resource type="SpriteFrames" id="SpriteFrames_gingerbread_man_{anim}"]
animations = [{{
"frames": [{frames}],
"loop": true,
"name": &"{anim}",
"speed": 10.0
}}]

[node name="{name}" type="Node2D"]

[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]
sprite_frames = SubResource("SpriteFrames_gingerbread_man_{anim}")
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


assert not any(os.path.exists(f'{GODOT}/gingerbread_man_{a}_sockets.json') for a in ANIMS), 'Refusing to overwrite existing socket captures'
os.makedirs(HERE, exist_ok=True)
for anim, (state, durations, frame0) in ANIMS.items():
    src = f'assets/pet_sequences/gingerbread_man/{state}'
    files = sorted(f for f in os.listdir(src) if f.endswith('.png'))
    assert len(files) == len(durations)
    dst = f'{GODOT}/gingerbread_man_{anim}'
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
                       'image': f'res://pet/gingerbread_man/gingerbread_man_{anim}/{f}', 'sockets': socks})
    data = {'pet': 'gingerbread_man', 'animation': anim, 'canvas': [450.0, 450.0], 'frameCount': len(files),
            'frameHold': 1, 'frameDurationsMs': durations, 'frames': frames,
            'equipmentSettings': {}, 'sockets': {}}
    export_path = f'{GODOT}/gingerbread_man_{anim}_sockets.json'
    assert not os.path.exists(export_path), 'Refusing to overwrite existing socket captures'
    json.dump(data, open(f'{GODOT}/gingerbread_man_{anim}_sockets.json', 'w'), indent=2)
    open(f'{GODOT}/gingerbread_man_{anim}.tscn', 'w').write(scene(anim, files, durations))
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
