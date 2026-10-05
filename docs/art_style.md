# Furniture Art Style & Production Workflow

How new furniture art is made so it matches the existing set. Pricing and
wiring live in `docs/shop_pricing.md`; this doc stops at a finished
`assets/furniture/<name>.png`.

## 1. Target style

The shipped set has three looks. **Cactus, Carpet and Vinyl are the canonical
target** because they fit the Mori UI direction. Bathtub and Toilet (bright,
flat, saturated blue) and Balloon (translucent watercolour) are legacy
outliers. Do not use them as references.

| Trait | Rule |
|---|---|
| Medium | Hand-painted digital gouache: soft visible brush texture, light grain, slightly uneven edges |
| Outlines | A darker shade of the fill it surrounds (dark green on green, dark brown on brown), roughly 3–4 px at 450 px. **Never black**, matching the UI rule in `memory-bank/ui-ux-guidelines.md` |
| Colour | Muted, warm, earthy pastels. Sampled from the canon: pot brown `#624C33`/`#896C48`, cactus green `#4B8138`/`#7FAE55`, sage `#9DB59C`, cream `#E8E5E0`, clay orange `#D2935A`, slate blue `#4F6282` |
| Shading | Flat colour areas, 1–2 tones of simple shading, plus a few thin hatch or highlight strokes. No gradients-for-realism, no glossy 3D |
| Mood | Cute and cozy. Halloween means "friendly", never scary, gory or realistic |
| View | Straight-on front view or a slight ¾ from above. No strong perspective |

**Shop product icons are the exception.** Non-placeable products (currency,
Pet Ticket, candy packs) match the glossy currency icons in
`assets/shop/icon/` instead: soft puffy 3D, gentle gradients, darker-shade
outlines. Use `assets/shop/icon/candy.png` on white as the single style image
(`design/furniture_sketches/shop_products/style_ref_glossy.png`), keep the
§6.2 template's output rules, and swap its style bullets for that look. They
ship as `assets/shop/icon/<name>.png` via the same normalize script, wired
client-side through `ShopItem.bundledIconPath` (no catalog migration). Paint
glass as solid pale colour (the candy jar), never see-through (§4.6).

## 2. Readability at room size

Furniture renders at about **42 pt wide at scale 1.0**
(`RoomCanvas.furnitureBaseWidthFraction`), which is roughly 126 px on a 3× phone.
So:

- The silhouette must read as the object at 40 px. Squint-test it.
- Keep detail sparse: 1–2 focal details (a face, a pattern), not ten.
- Thin lines under ~3 px at 450 disappear. Bold shapes survive.

## 3. File spec

- 450 × 450 PNG with a transparent background. The object is centred and its long side is about **420 px**
  (existing art: 380–444 px, so a ~15 px margin).
- Lowercase snake_case filename, e.g. `pumpkin_lantern.png`.
- Keep it under ~150 KB. `scripts/normalize_furniture.py` handles all of this.

## 4. Known failure modes (check every item)

These came up in real reviews:

1. **Floating parts.** A stem, handle or leg that does not touch the body.
   Every part must physically connect.
2. **Stray lines.** A stroke that continues past its shape, or a dangling
   curl or tendril with no purpose.
3. **Out-of-bounds decoration.** Highlights or patterns spilling past the shape
   they sit on (e.g. a lollipop swirl outside the candy).
4. **Wrong internal outlines.** An outline drawn inside a shape that breaks its
   read (e.g. an arc through a crescent moon).
5. **Unexplained props.** A small element that does not read at room size
   (e.g. a candy corn behind a wrapped candy). If in doubt, delete it.
6. **Translucency and glow.** An image model cannot output alpha, so anything
   see-through gets baked onto the background. Paint glows *inside* the
   object only.

## 5. Workflow

1. **Brief and sketch.** Claude draws an SVG composition sketch (shape, layout,
   palette) to agree the design; it is never uploaded to Gemini. Review and fix
   the composition here, where changes are cheap.
   Example: `design/furniture_sketches/halloween_2026/`. Regenerate the SVGs with
   `python3 gen_sketches.py`, then run `rsvg-convert -w 450 <name>.svg -o <name>.png`.
2. **Generate in Gemini.** Attach one style image and describe the item in text (§6).
   Generate 3–4 variants and pick one.
3. **Targeted edits in Gemini.** Fix issues one at a time with edit prompts (§6.4).
4. **Hand cleanup** (Procreate / Krita), whenever the §4 review finds something
   edit prompts could not fix: stray pixels, a broken outline, a fuzzy edge.
   Skip it only when the output passes §4 as-is.
5. **Normalize.** Run `scripts/normalize_furniture.py` (§7).
6. **In-room review.** Composite it on a room background at 1×/2×/3× (and, once
   a build has it, view it in the app next to the pet). Run the §4 checklist
   and the §2 squint test.
7. **Ship.** Follow `.codex/skills/new-furniture-art/SKILL.md` step 7 (the six
   touch points in `docs/shop_pricing.md`, via the shared-item-rollout skill).

## 6. Gemini prompting

Use a Gemini image model (Gemini app, or Google AI Studio with an image-output
model) and set the aspect ratio to **1:1**.

### 6.1 Method: one style image + text description

**Proven on all three Halloween 2026 pieces (2026-09-30).** Upload **only one style image** and
describe the item in words. Two methods failed:

- **Reference sheet uploaded first:** Gemini treats an uploaded image as *the
  picture to edit*, so it redrew the reference almost unchanged.
- **The word "sticker":** it triggers a die-cut look with a thick white border.
  Never use it; say "item illustration".

The SVG composition sketch (step 1) is for us to agree on the design. Its
decisions go into the `{ITEM}` text; the sketch is not uploaded.

Build the style image (Cactus on white; do not upload raw asset PNGs, their
transparency can show up black):

```bash
python3 scripts/normalize_furniture.py --ref-sheet style_ref.png --ref-items cactus
```

New chat per item, aspect ratio **1:1**, attach `style_ref.png`, then send §6.2.

### 6.2 Base prompt template

Write prompts in English. Fill `{ITEM}` (short phrase), `{THING}` (one word, e.g.
"pumpkin"), `{PARTS}` (bullet list) and the outline colour examples.

```
Draw a NEW picture from scratch: {ITEM}, as a 2D item illustration for a cozy mobile pet game.

The {THING}:
{PARTS}

The attached image is a STYLE REFERENCE ONLY. Do not draw a cactus, a pot, or anything
from that image. Do not edit or redraw that image. Only copy HOW it is painted:
- hand-painted digital gouache, soft visible brush texture, light paper grain
- outlines are a darker shade of each area's own colour (e.g. dark orange around orange,
  dark green around green), slightly uneven like a hand-drawn line, never black
- flat colour areas with 1-2 tones of simple shading and a few thin hatch or highlight strokes
- muted, warm, earthy colours; not 3D, not clay, not glossy, not vector

Output:
- only the {THING}, centred, filling about 90% of a square image
- front view
- pure flat white #FFFFFF background, no floor, no cast shadow, no scenery, no text
- the {THING}'s own coloured outline touches the white background directly:
  no white border, no white outline, no halo around it
- every part connected; nothing floating; no stray lines outside the {THING}
- simple, bold shape that is still recognisable when very small
```

Write `{PARTS}` as a short bullet list (shape, colours, each part and *what it
attaches to*, the face or focal detail, mood). Naming the attachments up front prevents the
floating-part and stray-line failures in §4.

**Pale or white items** (ghosts, white strings, snow): keep the white background but
require a coloured outline all the way round every white part (e.g. `the ghost has a
soft lavender-grey outline all around`). The flood fill stops at outlines, so outlined
white survives. Use `pure flat dark grey #4A4A4A background` + `--holes` (§7) only when
white parts *cannot* be outlined (loose strings, mist) **and** the item has no dark
colours: the script treats anything within ±24 per channel of `#4A4A4A` as background,
so a dark-purple outline like `#3E345E` would be erased with it.

### 6.3 Examples (Halloween 2026, all shipped first try)

First line = `{ITEM}`, bullets = `{PARTS}`.

Pumpkin Lantern (`{THING}` = pumpkin):

```
a cute jack-o'-lantern pumpkin
- soft orange, round and slightly wide, with five rounded vertical lobes
- a short olive-green stem growing straight out of the top centre, touching the pumpkin
- one small green leaf on a short vine that is attached to the stem
- carved rounded eyes and a wide happy smile with one small tooth
- warm yellow light painted inside the carved eyes and mouth only
- soft pink blush on both cheeks
- friendly and cozy, not scary
```

Candy Cauldron (`{THING}` = cauldron; front view slightly from above):

```
a cute witch's candy cauldron
- a round, slightly squat slate-purple cauldron with a thick rolled rim
- three short stubby dark-purple legs attached to the bottom of the cauldron
- a small orange bat shape painted flat on the front of the cauldron
- overflowing with candy piled above the rim: three wrapped candies (butter yellow,
  mint green, lilac); one round pink lollipop with a white swirl on a cream stick that
  goes down into the pile, the swirl staying inside the pink circle; one tiny white
  ghost marshmallow peeking out, with a soft lavender-grey outline all around
- every candy sits in or on the pile; nothing floats above it
- cozy and playful, not scary
```

Bat-Wing Armchair (`{THING}` = armchair):

```
a cute bat-wing armchair
- a cozy, plump plum-purple armchair seen from the front
- a tall rounded backrest with button tufting (small cream buttons)
- two small pointed bat ears growing from the top of the backrest, pink inside
- two darker-purple bat wings attached to the left and right sides of the backrest,
  spreading outward, scalloped lower edge; both clearly connect to the backrest
- two rounded padded armrests; a lighter lilac seat cushion
- a butter-yellow crescent-moon pillow resting on the seat, leaning on the backrest,
  sleeping (one closed curved eye, small pink cheek); one clean crescent with an
  outline only around its edge, no line through its middle
- a wavy pink trim along the front of the seat; four short curved gold legs
- cozy and cute, not scary
```

### 6.4 Edit prompts (same chat, after picking a variant)

Always say what must stay the same. Otherwise the model repaints the whole
image and you lose the good parts.

```
Keep everything exactly the same — style, colours, composition, background — and change ONLY:
{one specific fix}
```

Fix examples, based on §4:

- `the stem must grow out of the top of the pumpkin, touching it; the leaf connects to the stem by the vine`
- `remove the curly line below the leaf`
- `keep the white swirl entirely inside the pink lollipop circle`
- `remove the dark outline running through the middle of the moon pillow`
- `remove the candy corn`
- `make the outlines thinner and a darker orange instead of brown`

### 6.5 When it drifts

| Symptom | Add to the prompt |
|---|---|
| Glossy 3D / clay look | `flat 2D illustration, painted with a brush, no 3D rendering, no specular highlights` |
| Redraws the reference (the cactus comes back) | Make sure the first line is `Draw a NEW picture from scratch`. Add `the output must show a {THING}, not a cactus` |
| White sticker border or halo | Remove any "sticker" wording. Repeat the `no white border` rule |
| Black outlines | `outline colour = darker version of the fill colour, never black or dark grey` |
| Off-white or gradient background | Re-ask for `#FFFFFF`, or raise `--thresh` to 40 when normalizing |
| Too detailed | `simplify: fewer small details, bigger shapes, readable as a small game icon` |
| Style too clean | `visible gouache brush strokes and grain, like the reference` |

## 7. Normalize script

```bash
python3 scripts/normalize_furniture.py raw.png assets/furniture/pumpkin_lantern.png
python3 scripts/normalize_furniture.py --holes raw_on_grey.png assets/furniture/ghost_lamp.png
python3 scripts/normalize_furniture.py --selftest
```

The script:

- Detects the background colour from the border and flood-fills it from the edges.
  White areas enclosed by an outline (e.g. a bathtub interior) are kept. `--holes`
  also clears closed background pockets; use it only with the dark-grey background.
- Crops, scales the long side to `--size` (default 420), centres it on
  450×450, and quantizes to 256 colours (use `--lossless` if you see banding).
- Prints the object size, margins and file size.

It cannot recover translucency (§4.6) or fix drawing mistakes. Those need
the hand-cleanup step.
