"""Compose rig layers into one frame.  pose = {layer: (angle_deg, dx, dy)}; angles rotate about pivots."""
import json
from PIL import Image

ORDER = ['tail', 'underside', 'leg_a', 'leg_b', 'body', 'arm_a', 'arm_b']
_layers = {n: Image.open(f'rig/layers/{n}.png').convert('RGBA') for n in ORDER}
PIVOTS = json.load(open('rig/layers/pivots.json'))


def compose(pose=None, body_dy=0):
    pose = pose or {}
    out = Image.new('RGBA', _layers['body'].size, (0, 0, 0, 0))
    for n in ORDER:
        ang, dx, dy = pose.get(n, (0, 0, 0))
        im = _layers[n]
        if ang:
            im = im.rotate(ang, resample=Image.BICUBIC, center=tuple(PIVOTS[n]))
        # everything but the legs rides the body bob
        off_y = dy + (0 if n.startswith('leg') else body_dy)  # underside bobs with the body
        out.alpha_composite(im, (int(round(dx)), int(round(off_y))))
    return out
