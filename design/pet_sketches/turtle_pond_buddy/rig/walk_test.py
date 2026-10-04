"""Rough procedural walk from the rig layers, to judge motion (not final timing or art).

3/4 view heading image-left: a forward foot moves image-left; planted feet slide back.
Writes rig/walk_test/frame_XX.png (450 x 450) and walk_test.gif.
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from compose import compose
from PIL import Image

FRAMES, MS = 8, 200
STRIDE, LIFT, LEG_TILT = 55, 24, 10      # master px, master px, degrees
BOB, ARM_SWING, TAIL_SWAY = 9, 6, 5
SCALE, BASE_Y, CENTRE_X = 0.40, 414, 210  # output placement (450 canvas)


def leg(phi):
    s = -math.cos(phi)                    # -1 forward (image-left) .. +1 back
    lift = max(0.0, -math.sin(phi)) * LIFT  # only while swinging forward
    return s, (s * LEG_TILT, s * STRIDE, -lift)


def pose_at(i):
    """(pose, body_dy) for frame i of the cycle."""
    phi = 2 * math.pi * i / FRAMES
    sa, pa = leg(phi)
    sb, pb = leg(phi + math.pi)
    lag = 2 * math.pi * (i - 1) / FRAMES
    pose = {
        'leg_a': pa, 'leg_b': pb,
        'arm_a': (-sb * ARM_SWING, 0, 0), 'arm_b': (-sa * ARM_SWING, 0, 0),
        'tail': (math.cos(lag) * TAIL_SWAY, 0, 0),
    }
    return pose, -BOB * abs(math.sin(phi))


def place(full):
    """Scale a 1254 master-space frame onto the 450 canvas, foot baseline at BASE_Y."""
    small = full.resize((round(full.width * SCALE), round(full.height * SCALE)), Image.LANCZOS)
    canvas = Image.new('RGBA', (450, 450), (0, 0, 0, 0))
    canvas.alpha_composite(small, (round(CENTRE_X - 636 * SCALE), round(BASE_Y - 1100 * SCALE)))
    return canvas


if __name__ == '__main__':
    os.makedirs('rig/walk_test', exist_ok=True)
    frames = []
    for i in range(FRAMES):
        pose, body_dy = pose_at(i)
        canvas = place(compose(pose, body_dy=body_dy))
        canvas.save(f'rig/walk_test/frame_{i + 1:02d}.png')
        frames.append(canvas)
    white = [Image.alpha_composite(Image.new('RGBA', f.size, 'white'), f).convert('RGB') for f in frames]
    white[0].save('rig/walk_test.gif', save_all=True, append_images=white[1:], duration=MS, loop=0)
