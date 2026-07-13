#!/usr/bin/env python3
"""Inspect pet GIF/PNG sequences for structural authoring problems."""

from __future__ import annotations

import argparse
import json
import statistics
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError as error:
    raise SystemExit("Pillow is required: python3 -m pip install Pillow") from error


def alpha_count(path: Path) -> tuple[int, tuple[int, int, int, int] | None]:
    with Image.open(path) as image:
        alpha = image.convert("RGBA").getchannel("A")
        return (
            sum(1 for value in alpha.get_flattened_data() if value),
            alpha.getbbox(),
        )


def inspect_action(directory: Path) -> dict[str, object]:
    gifs = sorted(directory.glob("*.gif"))
    pngs = sorted(path for path in directory.glob("*.png") if "time" not in path.stem.lower())
    errors: list[str] = []
    warnings: list[str] = []
    sizes: list[tuple[int, int]] = []
    coverages: list[int] = []
    bboxes: list[tuple[int, int, int, int] | None] = []

    for path in pngs:
        with Image.open(path) as image:
            sizes.append(image.size)
        coverage, bbox = alpha_count(path)
        coverages.append(coverage)
        bboxes.append(bbox)

    if not pngs:
        errors.append("no animation PNG frames")
    if len(set(sizes)) > 1:
        errors.append(f"mixed PNG canvas sizes: {sorted(set(sizes))}")
    if coverages:
        median = statistics.median(coverages)
        for index, coverage in enumerate(coverages):
            ratio = coverage / median if median else 0
            if ratio < 0.75 or ratio > 1.25:
                warnings.append(f"frame {index + 1} alpha coverage is {ratio:.2f}x median")

    gif_report: dict[str, object] | None = None
    if len(gifs) > 1:
        errors.append(f"multiple GIF files: {[path.name for path in gifs]}")
    if gifs:
        with Image.open(gifs[0]) as gif:
            durations = []
            for frame in range(gif.n_frames):
                gif.seek(frame)
                durations.append(int(gif.info.get("duration", 0)))
            gif_report = {
                "file": gifs[0].name,
                "canvas": list(gif.size),
                "frame_count": gif.n_frames,
                "durations_ms": durations,
            }
            if gif.n_frames != len(pngs):
                errors.append(f"GIF has {gif.n_frames} frames but PNG sequence has {len(pngs)}")
            if sizes and gif.size != sizes[0]:
                errors.append(f"GIF canvas {gif.size} differs from PNG canvas {sizes[0]}")
    else:
        warnings.append("no GIF fallback found")

    return {
        "action": directory.name,
        "png_count": len(pngs),
        "canvas": list(sizes[0]) if sizes else None,
        "alpha_counts": coverages,
        "alpha_bboxes": bboxes,
        "gif": gif_report,
        "errors": errors,
        "warnings": warnings,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    action_dirs = sorted({path.parent for path in args.root.rglob("*.png") if "time" not in path.stem.lower()})
    if not action_dirs:
        print(f"ERROR: no animation PNG frames found under {args.root}", file=sys.stderr)
        return 1
    reports = [inspect_action(directory) for directory in action_dirs]
    if args.json:
        print(json.dumps(reports, indent=2))
    else:
        for report in reports:
            gif = report["gif"] or {}
            print(f"{report['action']}: {report['png_count']} PNG, canvas={report['canvas']}, durations={gif.get('durations_ms')}")
            for error in report["errors"]:
                print(f"  ERROR: {error}")
            for warning in report["warnings"]:
                print(f"  WARN: {warning}")
    return 1 if any(report["errors"] for report in reports) else 0


if __name__ == "__main__":
    sys.exit(main())
