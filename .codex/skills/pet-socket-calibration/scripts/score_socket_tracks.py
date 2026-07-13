#!/usr/bin/env python3
"""Report motion ranges, isolated steps, loop closure, and review readiness."""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

SLOTS = ("head", "body", "back")


def distance(a: dict, b: dict) -> float:
    return math.hypot(float(b["x"]) - float(a["x"]), float(b["y"]) - float(a["y"]))


def score(path: Path, step_warning: float, loop_warning: float, track_threshold: float) -> dict[str, object]:
    data = json.loads(path.read_text())
    frames = data["frames"]
    slots: dict[str, object] = {}
    for slot in SLOTS:
        points = [frame["sockets"][slot] for frame in frames]
        steps = [distance(points[index - 1], points[index]) for index in range(1, len(points))]
        # Report destination frames using the 1-based numbering shown to authors.
        suspicious = [index for index, value in enumerate(steps, start=2) if value > step_warning]
        x_range = max(point["x"] for point in points) - min(point["x"] for point in points)
        y_range = max(point["y"] for point in points) - min(point["y"] for point in points)
        loop_delta = distance(points[-1], points[0]) if len(points) > 1 else 0
        slots[slot] = {
            "x_range_px": round(x_range, 3),
            "y_range_px": round(y_range, 3),
            "max_step_px": round(max(steps, default=0), 3),
            "suspicious_frames": suspicious,
            "loop_delta_px": round(loop_delta, 3),
            "loop_warning": loop_delta > loop_warning,
            "motion_track_recommended": max(x_range, y_range) > track_threshold,
        }
    return {"file": str(path), "pet": data.get("pet"), "animation": data.get("animation"), "slots": slots}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", type=Path)
    parser.add_argument("--review-level", type=int, choices=range(4), default=0)
    parser.add_argument("--step-warning", type=float, default=12)
    parser.add_argument("--loop-warning", type=float, default=10)
    parser.add_argument("--track-threshold", type=float, default=10)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    reports = [score(path, args.step_warning, args.loop_warning, args.track_threshold) for path in args.files]
    if args.json:
        print(json.dumps({"review_level": args.review_level, "reports": reports}, indent=2))
    else:
        print(f"Declared review level: {args.review_level}/3")
        for report in reports:
            print(f"{report['pet']} / {report['animation']}")
            for slot, metrics in report["slots"].items():
                print(f"  {slot}: range=({metrics['x_range_px']}, {metrics['y_range_px']})px max-step={metrics['max_step_px']}px loop={metrics['loop_delta_px']}px track={metrics['motion_track_recommended']} suspicious={metrics['suspicious_frames']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
