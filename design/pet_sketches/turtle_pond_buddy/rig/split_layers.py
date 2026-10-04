"""Cut the selected master into rig layers (1254 x 1254 RGBA, master coordinates).

Run from design/pet_sketches/turtle_pond_buddy:  python3 rig/split_layers.py
Polygons are hand-placed on the master; hidden areas are filled with cv2.inpaint.
"""
import cv2, numpy as np, json

rgba = cv2.imread('rig/master_rgba.png', cv2.IMREAD_UNCHANGED)
rgb, alpha = rgba[..., :3], rgba[..., 3]
H, W = alpha.shape
hsv = cv2.cvtColor(rgb, cv2.COLOR_BGR2HSV)
cream = (hsv[..., 0] >= 12) & (hsv[..., 0] <= 28) & (hsv[..., 2] > 215) & (hsv[..., 1] < 130)

def poly(pts):
    m = np.zeros((H, W), np.uint8)
    cv2.fillPoly(m, [np.array(pts, np.int32)], 1)
    return m.astype(bool)

# Visible part of each piece (master coordinates).
LEG_A = poly([(350, 900), (402, 900), (412, 940), (430, 958), (575, 958), (575, 1105), (350, 1105)])
LEG_B = poly([(590, 965), (625, 935), (665, 925), (720, 935), (768, 958), (782, 968), (790, 1110), (590, 1110)])
ARM_A = poly([(300, 700), (335, 668), (395, 655), (428, 675), (436, 740), (425, 795), (380, 820), (310, 810), (296, 760)])
ARM_B = poly([(536, 712), (560, 676), (620, 660), (680, 668), (700, 700), (700, 770), (668, 806), (600, 812), (548, 800), (534, 760)])
TAIL = poly([(762, 985), (775, 930), (800, 900), (808, 850), (1000, 745), (1000, 1000), (800, 1010)])
# Hidden extensions painted behind the body so moved parts never show a gap.
LEG_A_HIDDEN = poly([(400, 900), (545, 900), (560, 960), (398, 960)])
LEG_B_HIDDEN = poly([(608, 880), (755, 880), (772, 955), (602, 965)])
TAIL_HIDDEN = poly([(745, 935), (785, 905), (800, 890), (800, 960), (772, 978), (748, 970)])
# Torso silhouette behind ARM_A (the arm is the body's outer edge there).
TORSO_A = poly([(348, 650), (334, 700), (330, 750), (342, 800), (362, 835), (700, 835), (700, 650)])
ARM_HOLE_DILATE = 7

fg = alpha > 8

def layer(visible, hidden=None, drop_cream=False):
    vis = visible & fg
    if drop_cream:
        vis &= ~cream
    a = np.where(vis, alpha, 0).astype(np.uint8)
    out = rgb.copy()
    if hidden is not None:
        fill = hidden & ~vis
        # inpaint the hidden extension from this layer's own pixels only
        src = np.where(vis[..., None], rgb, 0).astype(np.uint8)
        holes = (~vis).astype(np.uint8)
        out = cv2.inpaint(src, holes, 9, cv2.INPAINT_TELEA)
        a = np.where(fill, 255, a).astype(np.uint8)
        a = cv2.GaussianBlur(a, (3, 3), 0) if False else a
    out = np.where(a[..., None] > 0, out, 0).astype(np.uint8)
    return np.dstack([out, a]), vis

leg_a, va = layer(LEG_A, LEG_A_HIDDEN, drop_cream=True)
leg_b, vb = layer(LEG_B, LEG_B_HIDDEN, drop_cream=True)
arm_a, vaa = layer(ARM_A, drop_cream=True)
arm_b, vab = layer(ARM_B, drop_cream=True)
tail, vt = layer(TAIL, TAIL_HIDDEN, drop_cream=True)

# Body = everything else; fill what the arms covered so a swung arm reveals torso/belly.
removed = va | vb | vt | (vaa & ~TORSO_A)
body_a = np.where(removed, 0, alpha).astype(np.uint8)
# feather the hip cuts so the body edge blends over the leg tops instead of a hard line
hip = cv2.GaussianBlur((va | vb).astype(np.float32), (0, 0), 3)
body_a = (body_a * (1 - hip)).astype(np.uint8)
# torso pixels revealed behind ARM_A get full opacity
body_a = np.where(vaa & TORSO_A, 255, body_a).astype(np.uint8)
holes = cv2.dilate((vaa | vab).astype(np.uint8), np.ones((ARM_HOLE_DILATE,) * 2, np.uint8))
holes &= fg.astype(np.uint8)
# bleed colour outward first so edge holes never sample the black background
# (from pixels at least 8 px inside the silhouette, skipping the pale anti-aliased rim)
core = cv2.erode(fg.astype(np.uint8), np.ones((17, 17), np.uint8)).astype(bool) & ~holes.astype(bool)
_, lbl = cv2.distanceTransformWithLabels((~core).astype(np.uint8), cv2.DIST_L2, 5, labelType=cv2.DIST_LABEL_PIXEL)
ys, xs = np.nonzero(core)
lut = np.zeros((lbl.max() + 1, 3), np.uint8)
lut[lbl[ys, xs]] = rgb[ys, xs]
bled = np.where(core[..., None], rgb, lut[lbl]).astype(np.uint8)
body_rgb = cv2.inpaint(bled, holes, 15, cv2.INPAINT_TELEA).astype(np.int16)
# inpaint is smooth; add brush grain borrowed from a plain stretch of the head
donor = rgb[222:282, 450:600].astype(np.int16)  # plain forehead
grain = donor - cv2.GaussianBlur(donor, (0, 0), 3).astype(np.int16)
grain = np.tile(grain, (H // 60 + 1, W // 150 + 1, 1))[:H, :W]
# torso rim behind ARM_A is sage skin, not belly: blend toward skin left of x~372
skin = np.median(rgb[222:282, 450:600].reshape(-1, 3), 0)
wx = np.clip((380 - np.arange(W)) / 20.0, 0, 1)[None, :, None]
body_rgb = np.where(holes[..., None] > 0, body_rgb * (1 - wx) + skin * wx, body_rgb).astype(np.int16)
body_rgb = np.where(holes[..., None] > 0, body_rgb + grain, body_rgb).clip(0, 255).astype(np.uint8)
body = np.dstack([np.where(body_a[..., None] > 0, body_rgb, 0).astype(np.uint8), body_a])

# Underside: a shaded sage belly-bottom drawn BEHIND the legs, so a stepping leg never
# reveals background between the belly and the shell rim.
UNDER = poly([(410, 905), (780, 900), (790, 945), (765, 968), (700, 972), (560, 972),
              (450, 968), (412, 955)])
skin_dark = np.median(rgb[(hsv[..., 0] > 30) & (hsv[..., 0] < 50) & fg & ~cream].reshape(-1, 3), 0) * 0.86
under_rgb = np.clip(skin_dark + grain, 0, 255).astype(np.uint8)
under_a = cv2.GaussianBlur(UNDER.astype(np.float32), (0, 0), 1.5)
under = np.dstack([under_rgb, (under_a * 255).astype(np.uint8)])

pivots = {  # master coordinates
    'leg_a': [462, 935], 'leg_b': [668, 915], 'arm_a': [390, 680], 'arm_b': [600, 680],
    'tail': [785, 950], 'ground_y': 1100,
}
for name, img in [('underside', under), ('body', body), ('leg_a', leg_a), ('leg_b', leg_b),
                  ('arm_a', arm_a), ('arm_b', arm_b), ('tail', tail)]:
    cv2.imwrite(f'rig/layers/{name}.png', img)
json.dump(pivots, open('rig/layers/pivots.json', 'w'), indent=2)
