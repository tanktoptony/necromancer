from __future__ import annotations

import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"


def check_resource_references() -> list[str]:
    missing: list[str] = []
    pattern = re.compile(r"res://[^\"')\s]+")
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix not in {".gd", ".tscn", ".godot"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for ref in pattern.findall(text):
            target = ROOT / ref.removeprefix("res://")
            if not target.exists():
                missing.append(f"{path.relative_to(ROOT)} -> {ref}")
    return missing


def check_script_structure() -> list[str]:
    errors: list[str] = []
    pairs = {")": "(", "]": "[", "}": "{"}
    for path in sorted(SCRIPTS.glob("*.gd")):
        text = path.read_text(encoding="utf-8")
        function_lines: dict[str, list[int]] = {}
        for line_number, line in enumerate(text.splitlines(), 1):
            if line.startswith("func "):
                name = line[5:].split("(", 1)[0]
                function_lines.setdefault(name, []).append(line_number)
            quote_count = 0
            escaped = False
            for char in line:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == '"':
                    quote_count += 1
            if quote_count % 2:
                errors.append(f"{path.name}:{line_number}: unbalanced quote")

        for name, lines in function_lines.items():
            if len(lines) > 1:
                errors.append(f"{path.name}: duplicate function {name} at {lines}")

        stack: list[tuple[str, int]] = []
        in_string = False
        escaped = False
        line_number = 1
        for char in text:
            if char == "\n":
                line_number += 1
            if in_string:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == '"':
                    in_string = False
                continue
            if char == '"':
                in_string = True
            elif char in "([{":
                stack.append((char, line_number))
            elif char in ")]}" :
                if not stack or stack[-1][0] != pairs[char]:
                    errors.append(f"{path.name}:{line_number}: mismatched {char}")
                else:
                    stack.pop()
        if stack:
            errors.append(f"{path.name}: unclosed delimiters {stack[-3:]}")
    return errors


def movement_and_route_report() -> list[str]:
    jump_velocity = 320.0
    gravity = 900.0
    speed = 174.0
    jump_height = jump_velocity**2 / (2.0 * gravity)
    flat_range = speed * (2.0 * jump_velocity / gravity)
    lines = [
        f"Maximum jump height: {jump_height:.1f}px",
        f"Flat-ground jump range: {flat_range:.1f}px",
    ]
    pit_steps = [
        ("Pit deck 1 -> 2", 54.0, 29.0),
        ("Pit deck 2 -> 3", 0.0, -49.0),
        ("Pit deck 3 -> 4", 17.0, 20.0),
    ]
    for name, gap, rise in pit_steps:
        reachable = rise <= jump_height and gap <= flat_range
        lines.append(f"{name}: gap {gap:.0f}px, rise {rise:.0f}px, reachable={reachable}")

    hook_steps = [
        ("Chain Locker -> Lower Shaft", (1432.0, 622.0), (1430.0, 372.0), 300.0),
        ("Lower Shaft -> Upper Shaft", (1360.0, 388.0), (1492.0, 238.0), 220.0),
        ("Upper Shaft -> Winch Loft", (1475.0, 326.0), (1580.0, 104.0), 310.0),
    ]
    for name, start, ring, maximum in hook_steps:
        distance = math.dist(start, ring)
        lines.append(f"{name}: ring distance {distance:.1f}px / range {maximum:.1f}px, reachable={distance <= maximum}")
    return lines


def main() -> None:
    resource_errors = check_resource_references()
    script_errors = check_script_structure()
    print("RESOURCE REFERENCES")
    print("PASS" if not resource_errors else "\n".join(resource_errors))
    print("\nSCRIPT STRUCTURE")
    print("PASS" if not script_errors else "\n".join(script_errors))
    print("\nMOVEMENT / CRITICAL ROUTE")
    print("\n".join(movement_and_route_report()))
    if resource_errors or script_errors:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
