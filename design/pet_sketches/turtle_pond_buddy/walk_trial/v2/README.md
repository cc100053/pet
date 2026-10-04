# Turtle walk trial v2

Received on 2026-10-05 after the targeted gait correction. The second half now
lifts the image-left foot while the image-right foot supports the body, completing
the alternating steps. Continuous-loop motion and timing await owner review.

- [Original sheet](source_sheet.png), preserved unchanged: 1254 × 1254 RGB.
- [Raw loop](raw_preview.gif).
- [Aligned loop](aligned_preview.gif).
- [Aligned contact sheet](aligned_contact_sheet.png).
- [Alignment measurements](alignment_report.json).

Nine exact 418 × 418 crops are saved in `raw_frames/`; translated 450 × 450
copies are in `aligned_frames/`. Registration uses the head's horizontal centre
and the lowest grounded-foot baseline, targeting x=190.5 and y=414 from the
accepted idle's first frame. It does not centre each foot independently, so the
alternating leg motion remains intact. Only integer translation was applied;
there is no scaling, warping, repainting or background removal.

Both previews play frames 1–8 at 200 ms each, looping indefinitely with a
1600 ms cycle. Frame 9 is a closure comparison only. GIF decoding verified
eight frames, uniform durations and infinite looping; measured foreground
remains within the canvas.

## Review

- Frames 2–4 lift the image-right foot; frames 5–8 lift and lower the image-left
  foot. The one-foot-only motion in [v1](../README.md) has been corrected.
- The half-close on frame 3, closed eyes on frame 4 and reopening on frame 5
  remain present. Playback cadence stays constant through the blink.
- Head shape, shell markings and paint texture still vary slightly. Frame 9
  is not an exact duplicate of frame 1. Translation cannot repair these details.
- Review the actual frame 8 → frame 1 transition and support-foot changes in
  the aligned loop before accepting the motion. White backgrounds remain opaque;
  transparency, runtime exports and equipment calibration are pending.
