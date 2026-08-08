from __future__ import annotations

import re
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"


def require(text: str, needle: str, label: str, errors: list[str]) -> None:
    if needle not in text:
        errors.append(f"missing {label}: {needle}")


def signal_arity(text: str, signal_name: str) -> int | None:
    match = re.search(rf"^signal\s+{re.escape(signal_name)}\s*(?:\(([^)]*)\))?", text, re.M)
    if not match:
        return None
    args = (match.group(1) or "").strip()
    return 0 if not args else len([a for a in args.split(",") if a.strip()])


def function_min_max_arity(text: str, function_name: str) -> tuple[int, int] | None:
    match = re.search(rf"^func\s+{re.escape(function_name)}\s*\(([^)]*)\)", text, re.M)
    if not match:
        return None
    args = [a.strip() for a in match.group(1).split(",") if a.strip()]
    minimum = sum("=" not in a for a in args)
    return minimum, len(args)


def main() -> None:
    errors: list[str] = []
    player = (SCRIPTS / "player.gd").read_text()
    enemy = (SCRIPTS / "enemy.gd").read_text()
    guard = (SCRIPTS / "guard.gd").read_text()
    world = (SCRIPTS / "vania_world.gd").read_text()
    projectile = (SCRIPTS / "projectile.gd").read_text()

    require(player, "signal attacked(origin: Vector2, facing: float, combo_step: int, damage: int, reach: float)", "five-argument combo signal", errors)
    require(player, "signal command_requested", "army command input", errors)
    require(player, "attack_step == 3", "third combo hit", errors)
    require(enemy, "Archetype.BRUTE", "brute archetype", errors)
    require(enemy, "Archetype.BELL_WRETCH", "bell support archetype", errors)
    require(enemy, "func _attack_slot_available()", "attack-slot coordination", errors)
    require(enemy, "func _select_combat_target()", "ally-aware target selection", errors)
    require(guard, "enum CommandMode { FOLLOW, HOLD, ASSAULT }", "army commands", errors)
    require(guard, "enum Role { GUARD, BRUTE, SENTRY }", "raised corpse roles", errors)
    require(projectile, "var hostile: bool = true", "projectile factions", errors)
    require(world, "func _trigger_hitstop", "hit-stop", errors)
    require(world, "func _spawn_slash_effect", "slash effect", errors)
    require(world, "func _on_command_requested", "command handler", errors)
    require(world, "func _find_hook_enemy", "combat Grave Hook", errors)

    attack_signal = signal_arity(player, "attacked")
    callback = function_min_max_arity(world, "_on_player_attacked")
    if attack_signal is None or callback is None or not (callback[0] <= attack_signal <= callback[1]):
        errors.append(f"player attacked signal/callback mismatch: signal={attack_signal}, callback={callback}")

    class_names: dict[str, Path] = {}
    for path in SCRIPTS.glob("*.gd"):
        text = path.read_text()
        match = re.search(r"^class_name\s+(\w+)", text, re.M)
        if not match:
            continue
        name = match.group(1)
        if name in class_names:
            errors.append(f"duplicate class_name {name}: {class_names[name].name}, {path.name}")
        class_names[name] = path

    audio_dir = ROOT / "assets" / "audio"
    expected_audio = {"swing.wav", "hit.wav", "heavy_hit.wav", "raise.wav", "hook.wav", "relic.wav", "command.wav", "alert.wav", "hurt.wav"}
    actual_audio = {p.name for p in audio_dir.glob("*.wav")}
    missing_audio = expected_audio - actual_audio
    if missing_audio:
        errors.append(f"missing audio: {sorted(missing_audio)}")
    for path in audio_dir.glob("*.wav"):
        try:
            with wave.open(str(path), "rb") as wav:
                if wav.getnchannels() != 1 or wav.getsampwidth() != 2 or wav.getframerate() != 22050 or wav.getnframes() <= 0:
                    errors.append(f"invalid wave format: {path.name}")
        except wave.Error as exc:
            errors.append(f"unreadable wave {path.name}: {exc}")

    # Key persistence links.
    state = (SCRIPTS / "game_state.gd").read_text()
    require(state, "var army_roles: Array[int]", "army role persistence", errors)
    require(state, "var army_command_mode: int", "command persistence", errors)
    require(world, "GameState.set_army_roles(roles)", "world-to-state role sync", errors)

    print("0.6 COMBAT & COMMAND AUDIT")
    if errors:
        print("FAIL")
        for error in errors:
            print("-", error)
        raise SystemExit(1)
    print("PASS")
    print("- combo signal and callback arity match")
    print("- combat feedback systems present")
    print("- enemy target/attack coordination present")
    print("- army commands and corpse roles persist")
    print("- hostile/friendly projectiles are separated")
    print("- all synthesized WAV files are valid PCM")


if __name__ == "__main__":
    main()
