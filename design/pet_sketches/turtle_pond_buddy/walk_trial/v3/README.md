# Turtle walk trial v3

Received on 2026-10-05 from the [v3 prompt](../v3_prompt.txt), a march-in-place
waddle. The [original sheet](source_sheet.webp) is preserved unchanged: a
1254 × 1254 WebP. This is the best result so far, but it is not accepted yet.

- [Raw loop](raw_preview.gif), [aligned loop](aligned_preview.gif) and
  [aligned contact sheet](aligned_contact_sheet.png).
- [Alignment measurements](alignment_report.json).
- [Loop without frame 6](preview_without_frame6.gif): frames 1-5, 7 and 8, with
  frame 7 held for 400 ms. This is a stopgap comparison, not a production timing.
- [Targeted frame 6 fix prompt](frame6_fix_prompt.txt).

Registration uses integer translation only. Each frame's lowest foot is moved
to y=414. The generated horizontal placement is kept, because centring each
frame would remove the side-to-side lean. The source's bottom row sits about
19 px higher and its character is drawn about 3% larger. No scaling or
repainting was applied.

## Review

- Fixed compared with v2: frames 2-4 lift the image-right foot straight up with
  the sole flat. Frame 2 leans toward image-left and frame 6 shifts toward
  image-right, so the waddle reads. Frames 1, 5 and 9 have both feet planted.
- The blink is preserved: half-closed eyes on frame 3, closed eyes on frame 4.
- Frame 6 is still a sideways kick with splayed toes on the near (image-left)
  leg, and it peaks too early. Frame 7 is the correct vertical lift. The
  image-left step therefore looks unlike the image-right step and causes a hitch.
- The scale and texture vary slightly between rows.
- Next, fix frame 6 in the same Gemini chat using the targeted prompt, then
  split and review the result again.
