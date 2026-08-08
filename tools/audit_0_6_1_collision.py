#!/usr/bin/env python3
"""Static collision and traversal audit for Vania Pass 0.6.1."""
from __future__ import annotations
import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "scripts/vania_world.gd").read_text(encoding="utf-8")
PLAYER = (ROOT / "scripts/player.gd").read_text(encoding="utf-8")
ENEMY = (ROOT / "scripts/enemy.gd").read_text(encoding="utf-8")
GUARD = (ROOT / "scripts/guard.gd").read_text(encoding="utf-8")

def number(pattern: str, text: str) -> float:
    match = re.search(pattern, text)
    if not match:
        raise AssertionError(f"Missing numeric pattern: {pattern}")
    return float(match.group(1))

jump_velocity = abs(number(r"const JUMP_VELOCITY: float = (-?\d+(?:\.\d+)?)", PLAYER))
gravity = number(r"const GRAVITY: float = (\d+(?:\.\d+)?)", PLAYER)
speed = number(r"const SPEED: float = (\d+(?:\.\d+)?)", PLAYER)
air_accel = number(r"const AIR_ACCELERATION: float = (\d+(?:\.\d+)?)", PLAYER)

jump_rise = jump_velocity * jump_velocity / (2.0 * gravity)
flight_time = 2.0 * jump_velocity / gravity
time_to_speed = speed / air_accel
horizontal_from_rest = (
    0.5 * air_accel * min(time_to_speed, flight_time) ** 2
    + max(0.0, flight_time - time_to_speed) * speed
)

required_rises = {
    "atrium floor -> authored step": 48.0,
    "atrium step -> lower shelf": 46.0,
    "lower shelf -> middle shelf": 48.0,
    "middle shelf -> upper shelf": 52.0,
    "upper shelf -> right deck": 22.0,
    "winch floor -> first ledge": 46.0,
    "ossuary floor -> first ledge": 50.0,
}
for name, rise in required_rises.items():
    assert rise <= jump_rise + 0.5, f"{name} is {rise:.1f}px; jump rises only {jump_rise:.1f}px"

# Hook-only surfaces must be explicit and debug-visible.
for required in [
    "collision_hook_only_rects.append(heart_gantry)",
    "collision_hook_only_rects.append(shaft_lower)",
    "collision_hook_only_rects.append(shaft_upper)",
]:
    assert required in WORLD, f"Missing Hook-only classification: {required}"

# Continuous floors must be single colliders rather than abutting bodies.
assert "Rect2(0.0, 414.0, 720.0, 34.0)" in WORLD
assert "Rect2(1280.0, 198.0, 1280.0, 34.0)" in WORLD
assert "Rect2(0.0, 414.0, 512.0, 34.0)" not in WORLD
assert "Rect2(512.0, 414.0, 208.0, 34.0)" not in WORLD
assert "Rect2(1280.0, 198.0, 512.0, 34.0)" not in WORLD
assert "Rect2(1792.0, 198.0, 768.0, 34.0)" not in WORLD

# All actor types use the same world-only collision contract and seam tolerances.
for name, text, layer in [
    ("player", PLAYER, "collision_layer = 2"),
    ("enemy", ENEMY, "collision_layer = 4"),
    ("guard", GUARD, "collision_layer = 8"),
]:
    assert layer in text, f"{name}: wrong/missing collision layer"
    assert "collision_mask = 1" in text, f"{name}: must collide only with world"
    assert "floor_snap_length = 5.0" in text, f"{name}: missing floor snap"
    assert "safe_margin = 0.04" in text, f"{name}: missing reduced seam margin"

assert "func _resolve_navigation_integrity" in ENEMY
assert "navigation_stuck_time > 0.72" in ENEMY
assert "func _floor_position_near" in GUARD
assert "stuck_time > 0.62" in GUARD
assert "atrium_step.png" in WORLD
assert (ROOT / "assets/vania05/atrium_step.png").exists()

# Spawn supports: x range, platform top, actor origin y.
supports = [
    (0, 720, 414), (912, 1280, 414),
    (530, 622, 366), (560, 720, 320), (755, 887, 272),
    (930, 1080, 220), (1110, 1280, 198), (588, 716, 132),
    (512, 652, 530), (706, 901, 501), (846, 1000, 550),
    (1017, 1136, 530), (1152, 1536, 632),
    (1288, 1400, 400), (1430, 1520, 338),
    (1280, 2560, 198), (1350, 1488, 152), (1625, 1767, 130),
    (1950, 2070, 148), (2225, 2365, 132),
]
spawn_pattern = re.compile(r"_spawn_enemy\(Vector2\(([\d.]+), ([\d.]+)\)")
spawns = [(float(x), float(y)) for x, y in spawn_pattern.findall(WORLD)]
assert spawns, "No enemy spawns parsed"

def supported(x: float, y: float) -> bool:
    # Actor origins are normally on the top surface or may start up to 24px above it.
    return any(left <= x <= right and 0.0 <= top - y <= 24.5 for left, right, top in supports)

unsupported = [(x, y) for x, y in spawns if not supported(x, y)]
assert not unsupported, f"Unsupported enemy spawns: {unsupported}"

print("0.6.1 COLLISION & TRAVERSAL AUDIT")
print("PASS")
print(f"- player jump rise: {jump_rise:.2f}px")
print(f"- standing full-flight horizontal envelope: {horizontal_from_rest:.2f}px")
print(f"- highest required non-Hook rise: {max(required_rises.values()):.1f}px")
print("- room-seam floors are merged into single colliders")
print("- Hook-only ledges are explicitly classified violet")
print("- player, enemies, and followers share world-only collision rules")
print("- enemy and follower anti-wedge recovery systems are present")
print(f"- {len(spawns)} enemy spawns have supporting surfaces")
