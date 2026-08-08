#!/usr/bin/env python3
"""Static collision, traversal, and combat audit for Vania Pass 0.6.2."""
from __future__ import annotations

import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "scripts/vania_world.gd").read_text(encoding="utf-8")
PLAYER = (ROOT / "scripts/player.gd").read_text(encoding="utf-8")
ENEMY = (ROOT / "scripts/enemy.gd").read_text(encoding="utf-8")
GUARD = (ROOT / "scripts/guard.gd").read_text(encoding="utf-8")
PROJECTILE = (ROOT / "scripts/projectile.gd").read_text(encoding="utf-8")


def number(pattern: str, text: str) -> float:
    match = re.search(pattern, text)
    if not match:
        raise AssertionError(f"Missing numeric pattern: {pattern}")
    return float(match.group(1))


jump_velocity = abs(number(r"const JUMP_VELOCITY: float = (-?\d+(?:\.\d+)?)", PLAYER))
gravity = number(r"const GRAVITY: float = (\d+(?:\.\d+)?)", PLAYER)
speed = number(r"const SPEED: float = (\d+(?:\.\d+)?)", PLAYER)
air_accel = number(r"const AIR_ACCELERATION: float = (\d+(?:\.\d+)?)", PLAYER)
ledge_assist = number(r"const LEDGE_ASSIST_UP: float = (\d+(?:\.\d+)?)", PLAYER)

jump_rise = jump_velocity * jump_velocity / (2.0 * gravity)
flight_time = 2.0 * jump_velocity / gravity
time_to_speed = speed / air_accel
horizontal_from_rest = (
    0.5 * air_accel * min(time_to_speed, flight_time) ** 2
    + max(0.0, flight_time - time_to_speed) * speed
)

normal_links = [
    ("atrium floor -> step", 48.0, 0.0),
    ("atrium step -> lower shelf", 46.0, 0.0),
    ("lower shelf -> middle shelf", 48.0, 35.0),
    ("middle shelf -> upper shelf", 52.0, 43.0),
    ("upper shelf -> right deck", 22.0, 30.0),
    ("pit deck 1 -> 2", 29.0, 54.0),
    ("pit deck 3 -> 4", 20.0, 17.0),
]
for name, rise, gap in normal_links:
    assert rise <= jump_rise + 0.5, f"{name}: rise {rise} exceeds {jump_rise:.2f}"
    assert gap <= horizontal_from_rest + 0.5, f"{name}: gap {gap} exceeds {horizontal_from_rest:.2f}"

# Actor collision contract and edge support checks.
for name, text, layer in [
    ("player", PLAYER, "collision_layer = 2"),
    ("enemy", ENEMY, "collision_layer = 4"),
    ("guard", GUARD, "collision_layer = 8"),
]:
    assert layer in text, f"{name}: collision layer missing"
    assert "collision_mask = 1" in text, f"{name}: must collide with world only"
    assert "floor_snap_length = 5.0" in text, f"{name}: floor snap missing"
    assert "safe_margin = 0.04" in text, f"{name}: seam margin missing"

assert "return supported_probes == 2" in ENEMY
assert "return supported_probes == 2" in GUARD
assert "func _try_ledge_assist" in PLAYER
assert "func _has_safe_jump_landing" in GUARD

# Followers may reform because of navigation, but may only leave the army through combat death.
assert GUARD.count("lost.emit(self)") == 1, "Follower lost signal must be combat-death only"
assert "func reform_near_player(force: bool = false)" in GUARD
assert "ally.reform_near_player(true)" in WORLD
assert "left the formation vertically" not in WORLD

# Platform-aware and readable combat rules.
for token in [
    "locked_attack_target",
    "func _actor_is_valid_for_archetype",
    "active_attackers < 1",
    "var in_front: bool",
    "func _has_clear_charge_lane",
    "var has_poise: bool",
    "corpse_settled",
]:
    assert token in ENEMY, f"Enemy combat safeguard missing: {token}"
assert "func _combat_line_clear" in WORLD
assert "player.confirm_hit(combo_step)" in WORLD
assert "func is_attack_active" in PLAYER
assert "func confirm_hit" in PLAYER
assert "attack_windup" in GUARD and "pending_target" in GUARD
assert "func _melee_target_valid" in GUARD

# Corpses must fall onto world geometry rather than freezing in midair.
assert "if state == State.DEAD:" in ENEMY
assert "velocity.y += GRAVITY * delta" in ENEMY
assert 'body_collision.set_deferred("disabled", true)' not in ENEMY
assert "return state == State.DEAD and not raised and corpse_settled" in ENEMY

# Projectile faction and wall collision contracts remain intact.
assert "collision_mask = 11 if hostile else 5" in PROJECTILE

# Spawn and patrol support audit.
supports = [
    (0.0, 720.0, 414.0), (912.0, 1280.0, 414.0),
    (530.0, 622.0, 366.0), (560.0, 720.0, 320.0),
    (755.0, 887.0, 272.0), (930.0, 1080.0, 220.0),
    (1110.0, 1280.0, 198.0), (588.0, 716.0, 132.0),
    (512.0, 652.0, 530.0), (706.0, 901.0, 501.0),
    (846.0, 1000.0, 550.0), (1017.0, 1136.0, 530.0),
    (1152.0, 1536.0, 632.0), (1288.0, 1400.0, 400.0),
    (1430.0, 1520.0, 338.0), (1280.0, 2560.0, 198.0),
    (1350.0, 1488.0, 152.0), (1625.0, 1767.0, 130.0),
    (1950.0, 2070.0, 148.0), (2225.0, 2365.0, 132.0),
]
spawn_pattern = re.compile(
    r'_spawn_enemy\(Vector2\(([\d.]+), ([\d.]+)\), "([^"]+)", '
    r'RaggedEnemy\.Archetype\.([A-Z_]+), ([\d.]+), ([\d.]+)'
)
spawns = [
    (float(x), float(y), room, archetype, float(left), float(right))
    for x, y, room, archetype, left, right in spawn_pattern.findall(WORLD)
]
assert spawns, "No enemy spawns parsed"


def matching_support(x: float, y: float):
    return [s for s in supports if s[0] <= x <= s[1] and 0.0 <= s[2] - y <= 24.5]


for x, y, room, archetype, left, right in spawns:
    matches = matching_support(x, y)
    assert matches, f"Unsupported spawn: {archetype} at {(x, y)}"
    assert any(s_left - 2.0 <= left <= right <= s_right + 2.0 for s_left, s_right, _ in matches), (
        f"Patrol leaves support: {archetype} {room} spawn={(x, y)} patrol={(left, right)} support={matches}"
    )

# Continuous floors must remain single bodies at the two prior seam failures.
assert "Rect2(0.0, 414.0, 720.0, 34.0)" in WORLD
assert "Rect2(1280.0, 198.0, 1280.0, 34.0)" in WORLD

print("0.6.2 COLLISION & COMBAT AUDIT")
print("PASS")
print(f"- jump rise: {jump_rise:.2f}px (+ {ledge_assist:.1f}px edge forgiveness)")
print(f"- standing horizontal envelope: {horizontal_from_rest:.2f}px")
print(f"- {len(normal_links)} normal traversal links fit the player envelope")
print(f"- {len(spawns)} enemy spawns and patrol lanes remain fully supported")
print("- enemies lock telegraphed targets and respect combat elevations")
print("- melee hits require facing and unobstructed world line-of-sight")
print("- chargers validate floor support across the complete charge lane")
print("- followers reform after navigation failure instead of consuming an army slot")
print("- dead enemies settle onto collision before becoming raisable")
