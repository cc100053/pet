# Festive furniture (2026-10-11)

The owner supplied finished transparent PNGs in `assets/todo-furniture`;
the task starts at review/normalization, so no composition sketches or new
generation are needed. Original inputs are retained in that folder.

Bundled PNGs: `assets/furniture/{candle,candy_cane,sunflower,gift,christmas_tree}.png`.
Each went through `scripts/normalize_furniture.py` with its default 420 px
object size on a transparent 450 × 450 canvas (10–29 KB).

[Preview](preview.jpg): the top two strips check light/dark backgrounds;
the bottom compares 1×/2×/3× at `RoomCanvas.furnitureBaseWidthFraction`
(`42/360`) on the shipped Bubble Sky wallpaper beside the ghost pet.
White candle/ribbon and tree snow survive; connected parts and silhouettes
read at room size, without background halos. The candle is naturally narrow
at 1×. Real-device acceptance is still required.

Prices, version gate, approved NEW window and deployment status are recorded
in [release status](../../../docs/release_status.md).
