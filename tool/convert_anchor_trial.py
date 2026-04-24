#!/usr/bin/env python3

import argparse
import json
from pathlib import Path
from statistics import mean
from typing import Any


def _load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text())


def _collect_frames(data: dict[str, Any], slot: str) -> list[dict[str, Any]]:
    frames = []
    for entry in data.get("frames", []):
        sockets = entry.get("sockets", {})
        point = sockets.get(slot, {})
        x = point.get("x")
        y = point.get("y")
        if x is None or y is None:
            continue
        frames.append(
            {
                "frame": entry["frame"],
                "file": entry["file"],
                "x": float(x),
                "y": float(y),
            }
        )
    return frames


def _format_float(value: float) -> str:
    text = f"{value:.9f}"
    return text.rstrip("0").rstrip(".") if "." in text else text


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Convert manual anchor trial JSON into normalized socket and motion-track snippets."
    )
    parser.add_argument("input", type=Path, help="Path to the trial JSON file.")
    parser.add_argument(
        "--slot",
        default="head",
        choices=("head", "body", "back"),
        help="Socket slot to extract.",
    )
    args = parser.parse_args()

    data = _load(args.input)
    canvas = data["canvas"]
    width = float(canvas["width"])
    height = float(canvas["height"])
    pet_id = data["pet_id"]
    state = data["state"]

    frames = _collect_frames(data, args.slot)
    if not frames:
        raise SystemExit(f"No completed points found for slot '{args.slot}'.")

    base_x = mean(frame["x"] for frame in frames)
    base_y = mean(frame["y"] for frame in frames)
    base_norm_x = base_x / width
    base_norm_y = base_y / height

    print(f"pet_id: {pet_id}")
    print(f"state: {state}")
    print(f"slot: {args.slot}")
    print(f"frames: {len(frames)}")
    print()
    print("Normalized base socket:")
    print(
        f"{args.slot}: PetSocket(x: {_format_float(base_norm_x)}, y: {_format_float(base_norm_y)}),"
    )
    print()
    print("Motion track deltas:")
    print("PetMotionTrack(")
    print("  frames: [")
    for frame in frames:
        dx = (frame["x"] - base_x) / width
        dy = (frame["y"] - base_y) / height
        print(
            f"    Offset({_format_float(dx)}, {_format_float(dy)}),"
            f" // frame {frame['frame']} {frame['file']}"
        )
    print("  ],")
    print(")")
    print()
    print("Per-frame normalized points:")
    for frame in frames:
        nx = frame["x"] / width
        ny = frame["y"] / height
        print(
            f"- frame {frame['frame']:>2} {frame['file']}: "
            f"x={_format_float(nx)} y={_format_float(ny)}"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
