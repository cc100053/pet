"""Copy the reviewed turtle exports into the app's asset folders and build fallback GIFs.

Run from the repository root:  python3 design/pet_sketches/turtle_pond_buddy/export/install_assets.py

PNG frames -> assets/pet_sequences/turtle/{stay,walk,sleep}/turtle_<state>-NN.png
GIFs (stable sourceAsset identifiers / fallback, like tiger) -> assets/pet/turtle/
  turtle_stay.gif, turtle_moving.gif, turtle_sleep.gif
Frame durations come from export/timing.json and sleep_trial/timing.json.
"""
import json, os, shutil
from PIL import Image

SRC = 'design/pet_sketches/turtle_pond_buddy'
timing = json.load(open(f'{SRC}/export/timing.json'))['sequences']
timing['sleep'] = json.load(open(f'{SRC}/sleep_trial/timing.json'))
GIF_NAME = {'stay': 'turtle_stay.gif', 'walk': 'turtle_moving.gif', 'sleep': 'turtle_sleep.gif'}

os.makedirs('assets/pet/turtle', exist_ok=True)
for state, gif_name in GIF_NAME.items():
    src_dir, dst_dir = f'{SRC}/export/{state}', f'assets/pet_sequences/turtle/{state}'
    os.makedirs(dst_dir, exist_ok=True)
    names = sorted(n for n in os.listdir(src_dir) if n.endswith('.png'))
    assert len(names) == timing[state]['frames'], (state, len(names))
    frames = []
    for n in names:
        shutil.copyfile(f'{src_dir}/{n}', f'{dst_dir}/{n}')
        rgba = Image.open(f'{src_dir}/{n}').convert('RGBA')
        # 1-bit GIF transparency: palette from opaque pixels, index 255 reserved for clear
        p = rgba.convert('RGB').quantize(255, method=Image.Quantize.MEDIANCUT)
        p.paste(255, mask=rgba.getchannel('A').point(lambda v: 255 if v < 128 else 0))
        frames.append(p)
    frames[0].save(f'assets/pet/turtle/{gif_name}', save_all=True, append_images=frames[1:],
                   duration=timing[state]['frame_durations_ms'], loop=0, transparency=255, disposal=2)
    print(state, len(names), 'frames', sum(timing[state]['frame_durations_ms']), 'ms')
