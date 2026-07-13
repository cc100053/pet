#!/usr/bin/env python3
"""Validate Godot socket export structure and normalized coordinate math."""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

SLOTS = ("head", "body", "back")


def validate(path: Path) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    try:
        data = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read JSON: {error}"], warnings
    canvas = data.get("canvas", [])
    frames = data.get("frames", [])
    durations = data.get("frameDurationsMs", [])
    count = data.get("frameCount")
    if not isinstance(canvas, list) or len(canvas) != 2 or not all(isinstance(value, (int, float)) and value > 0 for value in canvas):
        errors.append("canvas must contain two positive numbers")
        return errors, warnings
    if count != len(frames):
        errors.append(f"frameCount={count} but frames has {len(frames)} entries")
    if len(durations) != len(frames):
        errors.append(f"frameDurationsMs has {len(durations)} entries; expected {len(frames)}")
    expected_indices = list(range(len(frames)))
    actual_indices = [frame.get("index") for frame in frames if isinstance(frame, dict)]
    if actual_indices != expected_indices:
        errors.append(f"frame indices are not sequential: {actual_indices}")
    for index, frame in enumerate(frames):
        if not isinstance(frame, dict):
            errors.append(f"frame {index} is not an object")
            continue
        duration = frame.get("durationMs")
        if not isinstance(duration, (int, float)) or duration <= 0:
            errors.append(f"frame {index} durationMs must be positive")
        elif index < len(durations) and int(duration) != int(durations[index]):
            errors.append(f"frame {index} duration differs from frameDurationsMs")
        sockets = frame.get("sockets", {})
        for slot in SLOTS:
            point = sockets.get(slot) if isinstance(sockets, dict) else None
            if not isinstance(point, dict):
                errors.append(f"frame {index} missing {slot} socket")
                continue
            for key in ("x", "y", "nx", "ny"):
                if not isinstance(point.get(key), (int, float)) or not math.isfinite(point[key]):
                    errors.append(f"frame {index} {slot}.{key} must be finite")
            if any(not isinstance(point.get(key), (int, float)) for key in ("x", "y", "nx", "ny")):
                continue
            if not (0 <= point["x"] <= canvas[0] and 0 <= point["y"] <= canvas[1]):
                errors.append(f"frame {index} {slot} pixel coordinate is outside canvas")
            if not (0 <= point["nx"] <= 1 and 0 <= point["ny"] <= 1):
                errors.append(f"frame {index} {slot} normalized coordinate is outside 0..1")
            if abs(point["x"] / canvas[0] - point["nx"]) > 0.001 or abs(point["y"] / canvas[1] - point["ny"]) > 0.001:
                errors.append(f"frame {index} {slot} normalized coordinate does not match pixel coordinate")
    if not data.get("pet"):
        warnings.append("pet id is empty")
    if not data.get("animation"):
        warnings.append("animation id is empty")
    return errors, warnings


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", type=Path)
    args = parser.parse_args()
    failed = False
    for path in args.files:
        errors, warnings = validate(path)
        print(f"{path}: {'FAIL' if errors else 'PASS'}")
        for error in errors:
            print(f"  ERROR: {error}")
        for warning in warnings:
            print(f"  WARN: {warning}")
        failed |= bool(errors)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
