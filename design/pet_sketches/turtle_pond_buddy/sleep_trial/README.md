# Turtle sleep loop

The generated [sleep sheet](source_sheet.webp) was received on 2026-10-05. It is
preserved unchanged: 1254 × 1254 WebP. It came from the [sleep prompt](../sleep_prompt.txt).
The pose is good, but the owner wanted visible movement: the prompt had asked
for "extremely small" breathing, so only the z marks changed between frames.

[`animate_sleep.py`](animate_sleep.py) builds the loop from cell 1 (the pose
without z marks) and the largest z mark in cell 4. The character is never
redrawn, so detail and colour do not change between frames:

- The pose is colour-matched to the master and its background removed, as in
  the stay and walk exports. It is cut once into the head (an ellipse) and the
  body. Only the neck, shoulders and shell continue behind the head, and that
  area is filled in.
- Dozing nod: for 62% of the cycle the head slowly sinks 9 px and tilts 4°
  forward around the neck. It then snaps back up with a small bounce and settles.
- Breathing: the body stretches 1.8% taller from the ground line, once per cycle.
- Z marks: three copies of the generated z rise toward image-right in turn,
  growing as they rise and fading in and out.
- 16 frames at 160 ms each, 2560 ms per loop (`timing.json`). The tunables are at
  the top of the script.

Running `python3 sleep_trial/animate_sleep.py` writes
`export/sleep/turtle_sleep-01..16.png`. These are 450 × 450 RGBA, with feet on
y=432 and the head at the stay frames' position. Scaling compares full head
widths: the widest row of the stay head band (the top 40%, above the shell)
against the widest row of the isolated sleep head. Measured heads after export:
stay 205 px, walk 205 px, sleep 207 px. The first export used a top-30% band
of the sleep head, which missed its widest row and drew the head about 20% too large. It also writes
`export/review/sleep_{light,dark}.gif`.

## Review

- At the deepest nod (frames 10-11), a tiny dark mark shows where the head
  meets the shell rim. Check it at room size.
- The owner accepted the motion on 2026-10-05, after the head-size fix.
