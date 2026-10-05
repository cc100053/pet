# Turtle walk trial

Superseded: the accepted walk is the [v4 fix](v4/README.md). The
[corrected v2 trial](v2/README.md) was rejected. The files and findings below describe the original v1.

Received on 2026-10-05. This candidate has the requested blink but does not
complete the alternating gait. It is not accepted production animation.

- [Original sheet](source_sheet.png), preserved unchanged: 1254 × 1254 RGB.
- [Raw loop](raw_preview.gif).
- [Aligned loop](aligned_preview.gif).
- [Aligned contact sheet](aligned_contact_sheet.png).
- [Alignment measurements](alignment_report.json).
- [Targeted gait correction prompt](gait_fix_prompt.txt).

Nine exact 418 × 418 crops are in `raw_frames/`; translated 450 × 450 copies
are in `aligned_frames/`. Review alignment uses the leftmost substantial foot
region in the bottom 21 foreground rows, placing its approximate centre at
x=162 and baseline at y=414. This is a diagnostic placement correction for
this candidate, not a valid support-foot rule for future alternating gait.
The next result must preserve actual planted-foot and body motion.

No scaling, warping, pose corrections or background removal were applied.
Both previews play frames 1–8 at 200 ms each (1600 ms per cycle), looping
indefinitely. Frame 9 is only a closure comparison. Decoding verified eight
frames, durations and infinite loop; all measured foreground remains in bounds.

## Review

- Half-closed eyes on frame 3 and closed eyes on frame 4 are present, followed
  by reopening on frame 5. Gait timing stays uniform through the blink.
- The image-left foot remains grounded while the image-right foot is lifted
  through much of the sequence, including the intended opposite-step frames
  5–7. It reads as a one-foot lift rather than a full alternating walk.
- Body/face/paint details vary somewhat between drawings. Frame 9 also is not
  an exact copy of frame 1. Translation does not repair these differences.
- Correct the second half-cycle and closure frame before acceptance. Generated
  corrections require another split-frame and continuous-loop review.

Attach the received source sheet to the correction prompt in the same Gemini
chat; preserve the character and blink while fixing the specified gait phases.
