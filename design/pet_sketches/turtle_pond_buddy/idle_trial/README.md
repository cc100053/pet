# Turtle idle trial

Received on 2026-10-05. The owner accepted the continuous-loop preview's motion
and timing on 2026-10-05. Production transparency, room-size review and runtime
integration are still pending.
The supplied [source sheet](source_sheet.png) is preserved byte-for-byte:
1254 × 1254 RGB, nine 418 × 418 cells, opaque white background.

## Review outputs

- [Continuous loop for seam review](continuous_loop.gif): first and last holds
  reduced to 200 ms each, preserving the slower blink and all original frames.
- [Continuous-loop timing](continuous_loop_timing.json).
- [Slower-blink preview](aligned_preview_slower_blink.gif): revised timing for
  owner review; the same nine visual frames as the aligned preview.
- [Slower-blink timing](slower_blink_timing.json).
- [Raw looping preview](raw_preview.gif): exact cell crops padded to 450 × 450.
- [Aligned looping preview](aligned_preview.gif): integer translation only.
- [Aligned frame contact sheet](aligned_contact_sheet.png).
- [Frame measurements and assigned timing](alignment_report.json).

The source cells show approximately 33.5 px of horizontal foot-centre range
and 26 px of baseline range. Measurements use coloured foreground in the bottom
27 rows of each character; they are technical alignment estimates, not manual
socket captures. Alignment places the estimated foot centre at x=212 and the
baseline at y=414 on the review canvas. It does not resize, warp, redraw or
independently centre the silhouette. No measured foreground is clipped.

All nine exact crops live in `raw_frames/`; nine translated 450 × 450 PNGs live
in `aligned_frames/`. Both remain opaque. The GIFs share one review palette;
the PNGs retain their RGB pixels without GIF quantization.

Assigned trial timing: 600, 200, 250, 200, 80, 80, 80, 200, 350 ms (2040 ms total).
Both GIFs were decoded to verify nine frames, those durations and infinite loop.
Timing is a review choice; it was not embedded in the AI sheet.

The owner found the blink noticeably faster on 2026-10-05. A timing-only
alternative holds frames 5–7 for 120, 160 and 120 ms instead of 80 ms each:
400 ms for the blink section and 2200 ms for the full loop. All other holds
are unchanged. Decoded RGB pixels were compared with the original aligned
GIF to verify identical artwork, nine frames, the new timing and infinite loop.
Review this timing before adding in-between drawings; extra frames would address
stepped eyelid movement, while longer holds address the perceived speed.

The continuous-loop alternative runs for 1650 ms with infinite repeat. It removes
the extra rest holds at the loop boundary (600 → 200 ms on frame 1; 350 → 200 ms
on frame 9) so the owner can assess the actual 9 → 1 transition. No transition
frames, fades or artwork corrections were added. Decoding verified the nine
unchanged RGB frames, all durations and infinite loop setting.

## Visual assessment and pending work

- The intended open → half-closed → closed → half-open → open blink is present.
- The leaf tail rises and returns while the standing pose stays recognizable.
- Translation corrects the large sheet-placement differences. Minor differences
  in foot shape, shell markings and painted texture remain and are not repaired.
- Frame 9 resembles frame 1 but is not identical. The owner accepted the preview
  transition; verify remaining variations at actual room size during production.
- Transparency, background-edge review, room-size acceptance, equipment calibration,
  runtime catalog integration and release gates remain pending.

The selected [character master](../selected_master.png) remains the identity
reference. Do not treat the normalized furniture workflow as a per-frame crop
and recenter operation.
