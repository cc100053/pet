#!/usr/bin/env python3
"""Generate a PetSocketConfig snippet from reviewed Godot socket exports."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

SLOTS = ("head", "body", "back")


def load(path: Path) -> dict:
    return json.loads(path.read_text())


def number(value: float) -> str:
    text = f"{value:.9f}".rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


def socket_line(slot: str, point: dict) -> str:
    return f"PetEquipmentSlot.{slot}: PetSocket(x: {number(point['nx'])}, y: {number(point['ny'])}),"


def motion_block(label: str, data: dict, pet_symbol: str, threshold: float) -> list[str]:
    output: list[str] = []
    tracks: list[tuple[str, list[tuple[float, float]]]] = []
    for slot in SLOTS:
        points = [frame["sockets"][slot] for frame in data["frames"]]
        base = points[0]
        deltas = [(point["nx"] - base["nx"], point["ny"] - base["ny"]) for point in points]
        max_pixels = max(max(abs(dx), abs(dy)) for dx, dy in deltas) * float(data["canvas"][0])
        if max_pixels > threshold:
            tracks.append((slot, deltas))
    if not tracks:
        return output
    output.append(f"      {label}MotionTracksBySlot: {{")
    for slot, deltas in tracks:
        sequence = {"idle": "Idle", "walk": "Walk", "sleep": "Sleep"}[label]
        output.append(f"        PetEquipmentSlot.{slot}: PetMotionTrack.timed(")
        output.append(f"          frameDurationsMs: PetAnimationFrames.{pet_symbol}{sequence}.frameDurationsMs,")
        output.append("          frames: [")
        output.extend(f"            Offset({number(dx)}, {number(dy)})," for dx, dy in deltas)
        output.extend(["          ],", "        ),"])
    output.append("      },")
    return output


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--idle", required=True, type=Path)
    parser.add_argument("--walk", required=True, type=Path)
    parser.add_argument("--sleep", required=True, type=Path)
    parser.add_argument("--track-threshold", type=float, default=10)
    args = parser.parse_args()
    idle, walk, sleep = load(args.idle), load(args.walk), load(args.sleep)
    pet_id = idle["pet"]
    if {walk.get("pet"), sleep.get("pet")} != {pet_id}:
        raise SystemExit("all exports must belong to the same pet")
    symbol = "".join(part.capitalize() if index else part for index, part in enumerate(pet_id.replace("-", "_").split("_")))
    lines = ["    PetSocketConfig(", f"      petId: '{pet_id}',", "      sockets: {"]
    lines.extend(f"        {socket_line(slot, idle['frames'][0]['sockets'][slot])}" for slot in SLOTS)
    lines.extend(["      },", "      walkOverrides: {"])
    lines.extend(f"        {socket_line(slot, walk['frames'][0]['sockets'][slot])}" for slot in SLOTS)
    lines.extend(["      },", "      sleepOverrides: {"])
    lines.extend(f"        {socket_line(slot, sleep['frames'][0]['sockets'][slot])}" for slot in SLOTS)
    lines.append("      },")
    lines.extend(motion_block("idle", idle, symbol, args.track_threshold))
    lines.extend(motion_block("walk", walk, symbol, args.track_threshold))
    lines.extend(motion_block("sleep", sleep, symbol, args.track_threshold))
    lines.extend(["    ),"])
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
