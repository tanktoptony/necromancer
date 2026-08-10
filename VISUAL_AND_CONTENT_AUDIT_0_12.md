# Vania Pass 0.12 — Visual & Content Audit, Session Report

Covers the session that took the vertical slice from a 6-room loop with a "frankenstein"
art problem to an 11-room slice with a measured, corrected character roster. Written as a
resume point after a multi-day dev pause — read this before touching anything else.

All work below is committed and pushed to `origin/master` (`ccbbed7..97bb35b`, 9 commits).

## 1. Where visuals actually stand right now

The core problem all session: enemy source art and code-level scale correction were
changing independently and repeatedly, so any "fixed" measurement went stale the next
time art got regenerated. This happened twice — the first scale-correction pass
(`8db4cb5`) was invalidated by a later art redraw, and the *second* pass (`665664f`) had
its own bug on top of that (see §3). The numbers below are the **third** measurement,
taken directly against the art in the current HEAD (`97bb35b`), and are the ones to trust.

Target is the player/guard average: **60.6% canvas-height fill**, measured the same way
for every character (bounding-box height of non-transparent pixels ÷ canvas height).

| Archetype | Folder | Raw art h-fill | Scale now | Effective | Status |
|---|---|---|---|---|---|
| Shield Guard | grave_guard | 91.4% | 0.66 | 60.3% | corrected this session |
| Lantern Tosser / Sentry | lantern_tosser | 87.5% | 0.65–0.66 | 57–58% | already OK, untouched |
| Charger | hook_brute | 90.5% | 0.67 | 60.6% | corrected this session |
| Brute | hook_brute | 90.5% | 0.74 | 67.0% | corrected, intentionally bigger than Charger |
| Bell Wretch | bell_keeper | 92.3% | 0.62 | 57.2% | already OK, untouched |
| Bilge Crawler | bilge_crawler | 72.0% (h) / 91.4% (w) | 0.63 / 0.84 | 60.5% (h) | corrected — was badly undersized after a buggy first fix |
| Hanged Sailor | hanged_sailor | 91.7% (h), 27–94% (w, per-frame) | 0.627 uniform + per-frame X table | 57.5% (h), consistent w | corrected — was the "sometimes big sometimes tiny" bug |
| Bone Crow | bone_crow | 88.6% | 0.68 | 60.2% | corrected this session |
| Coffin Mimic | coffin_mimic | 75.9% | 0.80 | 60.7% | corrected this session |
| Walker | walker | 86.6% | 1.0 (none) | ~87% | **not live** — no spawn uses this archetype, cosmetic only |

Live-verified with actual screenshots (not just arithmetic) after the fix: Shield Guard,
elite Brute, Bilge Crawler, and Bone Crow all read as proportionate next to the player.
Coffin Mimic was corrected with the same formula but not individually screenshotted this
pass — the math checks out (75.9 → 60.7%) but hasn't had eyes on it live.

### Known-good baseline for next time

If art gets regenerated again (very likely, given the pace this session), **do not
compound a new correction onto the existing scale value.** Re-measure `h_fill` for the
new art directly, then set `scale = 0.606 / new_h_fill`. That's the whole formula. The
compounding approach (`new_scale = old_scale * (target/measured)`) is what produced the
bilge_crawler regression — it assumes the existing scale was already correct for a
1:1-with-target baseline, which was never actually true.

Measurement script (run from repo root, needs Pillow):
```python
from PIL import Image
im = Image.open("assets/sprites/enemy_types/<folder>/enemy_4.png").convert("RGBA")
bbox = im.getbbox()
h_fill = (bbox[3]-bbox[1]) / im.size[1]
print(f"scale = {0.606/h_fill:.3f}")
```
Average across a few live-pose frames (idle/walk/attack — skip `enemy_0`/`enemy_1`,
those are dead/hurt poses with different proportions) rather than trusting one frame.

## 2. Bugs found and fixed this session

All of these were found by live-testing through the godot-mcp bridge (frozen game time,
runtime state watches, direct exec calls into the running game), not by reading code and
guessing. Each has a verified-live note because two of the earlier "fixes" in this same
problem area turned out to be wrong on first pass.

- **Walk/idle animation flash (`002e739`).** Player/guard/enemy all picked walk-vs-idle
  off instantaneous `velocity.x`, but patrol/follow movement decelerates smoothly through
  zero on every direction change. That crossed the threshold for 1-2 physics frames and
  flashed the idle pose mid-stride, on *every* patrol turnaround, for every character.
  This is almost certainly most of what read as "occasionally uses an old sprite frame."
  Fixed with a 150ms grace period. Verified live: an enemy that flashed idle every ~570ms
  during patrol showed zero transitions over a clean 5-second watch afterward.

- **Bone crow dive-attack whiff (`002e739`).** Its dive attack triggered from up to 205px
  away but the fixed-velocity dive can only cover ~107px. Every attempt from outside that
  range dove short and recovered without connecting — read as random bouncing, not an
  attack. Tightened `attack_range` to 105px. Verified live: player health dropped 5→1
  across repeated dives after the fix, versus never connecting before it.

- **Bilge crawler oversized, hanged sailor inconsistent, bone crow corpse infinite-fall
  loop (`665664f`, later corrected in `97bb35b` — see below).** hanged_sailor's per-frame
  width varies 27%–94% fill frame-to-frame, which no single fixed scale can ever fix —
  some poses were drawn much wider than others. Added a per-frame `scale.x` override
  table, keyed by the frame's absolute position in the sprite sheet (had a real bug here
  too: `AnimatedSprite2D.frame` is local to whichever animation is playing, not the
  sheet's absolute index — first version of this fix silently looked up the wrong table
  entry for every animation except the one that happens to start at frame 0). Also fixed
  bone crow's corpse getting stuck in an infinite fall-teleport-fall loop in the breach
  room specifically — its `corpse_fall_limit` (tuned for a ground enemy recovering from
  the water hazard) sits mid-height through breach's platform layer, and bone_crow's
  home position is mid-air by nature, so the corpse fell, crossed the limit almost
  immediately, teleported back to that same mid-air spot, and fell again forever. Flying
  corpses now use the room-bottom limit instead.

- **Scale recalibration bug (`97bb35b`).** The `665664f` fix above computed
  `new_scale = old_scale * correction_factor` — compounding onto already-arbitrary
  hardcoded values instead of computing the target directly. Silently produced a wrong
  (too-small) result for bilge_crawler specifically. Recalibrated all 8 live archetypes
  with the direct formula in §1's "known-good baseline."

- **Blocked-door permalock (`ee80cd5`).** `RoomDoor._on_body_entered` latches
  `enabled=false` on any entry attempt, including ones the room manager blocks (locked
  gate, enemies still alive) — nothing ever re-armed it, so a blocked door was a
  permanent dead switch even after the block condition cleared. This affected the
  original deck end-gate, not just the new captain finale. Added `reset_block()`, called
  from both blocked paths.

- **Enemy sprites oversized relative to player (`8db4cb5`, later superseded by the
  measurements in §1).** First discovery that the enemy_types source art was drawn
  filling far more of its canvas than player/guard art. This was the right diagnosis; the
  specific numbers just needed re-measuring twice more as art kept changing underneath.

## 3. Content added this session

Five previously-built-but-unregistered room scenes (`orlop`, `shaft`, `rigging`,
`galley`, `captain`) were sitting on disk, fully populated with art/platforms/enemy
encounters, left over from an earlier, larger level-design pass — never wired into
`ROOM_SCENES`. Registered them and extended the critical path (`ee80cd5`):

```
receiving -> gallery -> gate -> breach -> chain -> (loop back to gate) -> deck
  -> orlop -> rigging -> galley -> captain -> END
```

`shaft` is wired in as an optional one-way hook-climb shortcut from `orlop` back to
`chain`, unchanged from its original self-contained wiring — not part of the required
path. `captain`'s Ossuary (3-enemy gauntlet ending in an elite Brute) is the new finale
trigger, replacing deck's old direct end-of-slice door.

The in-game map (M key) does **not** draw grid cells for these 5 rooms — the parchment
canvas is 600×330 inside a 640-wide viewport, already nearly full at 6 rooms. Extending
it needs an actual map UI redesign (scrolling, or smaller cells), not just more entries
in the existing grid dictionaries. This was a deliberate scope cut, not an oversight —
`_player_map_point()` already falls back gracefully (to `MAP_ORIGIN`) when a room has no
registered rect, so nothing is broken, the new rooms are just invisible on the overlay.

## 4. Art pipeline status

Codex has been running a parallel, largely autonomous art/VFX pass this whole session:

- Full re-draw of every enemy archetype's frame set, plus player and the two new guard
  run frames (`072d7ed`) — this is the "frankenstein" style-consistency problem you
  originally flagged, and this is Codex's attempt at addressing it directly.
- Environment redraw: hull breach parallax, bulkhead door + new frame layer, platform
  module/trim, railing, stairs, rib gate (`ART_HANDOFF/ENVIRONMENT_REDRAW.md` has the
  itemized list).
- New VFX sprite set replacing procedural `Line2D`/`Polygon2D` combat effects (slash,
  impact, raise burst, hook field/beam, ritual ring) with real art, plus a genuine
  physics improvement: thrown lanterns now follow a gravity arc instead of a straight
  line, and projectiles sweep their travel segment via raycast so fast ones can't tunnel
  through thin collision between physics ticks.

This was reviewed (diffs read, textures checked for existence, 11-room smoke test run
with zero errors) before committing, but **not** exhaustively screenshot-verified frame
by frame the way the scale bugs in §1/§2 were. Two known art-content defects are
already flagged and waiting on regen:

- **`player_2.png` / `player_8.png` have a stray creature baked into the art** (a
  gray dog/rat shape at the character's feet, not present in `player_3.png`/
  `player_4.png`). Confirmed by reading the raw PNGs directly, not a rendering bug.
  Fix request already written:
  `ART_HANDOFF/conversion_prompts/11_player_run_frame_creature_fix.txt` — hand this to
  Codex/an art agent directly, it's ready to go as-is.
- Given the pattern this session (art regenerating out from under code corrections
  multiple times), **assume any future art pass invalidates the §1 scale table** until
  re-measured. This is the single biggest process risk right now — see §5.

## 5. Evaluation

**What's working:** the room-building reuse (5 rooms, near-zero new art needed, ~30
minutes of wiring) was high-leverage — there's more unregistered content on disk
(`forecastle`, `lantern`, `pantry` — a receiving/gallery-area side branch) that wasn't
touched this pass and could extend the slice further essentially for free. The
live-verification workflow (godot-mcp frozen-time stepping + runtime state watches)
caught two real bugs (blocked-door permalock, bone crow's fall-loop) that would never
have surfaced from reading code alone, and caught two mistakes in my *own* fixes
(the hanged_sailor frame-index bug, the bilge_crawler compounding bug) before they
shipped wrong.

**What's not working:** art and code correction are racing each other. Every scale fix
this session got at least partially invalidated by the next art regeneration, because
nothing gates "art changed" against "recalibrate scale." This isn't a Codex problem or a
me problem specifically — it's a coordination gap between two agents editing
interdependent state (pixel content vs. the code that scales that content) with no
shared checkpoint. Three iterations of the same fix this session is the direct, visible
cost of that gap.

## 6. Next steps, in order

1. **Regenerate `player_2.png`/`player_8.png`** using the already-written prompt file.
   No code changes needed after — the game already reads whatever's on disk.
2. **Screenshot-verify Coffin Mimic** next to the player (the one archetype corrected by
   formula but not eyeballed live this pass).
3. **Before any further art regeneration**, re-run the §1 measurement script against
   whatever's new and update the scale table in the same commit as the art change —
   don't let them land separately again.
4. **Decide on `forecastle`/`lantern`/`pantry`** — same reuse pattern as this session's
   room work, but they'd need new doors added to `receiving`/`gallery`/`breach` (the
   registered rooms don't currently have return doors to them), which is more invasive
   than what was done this pass since it touches already-tested critical-path scenes.
   Worth doing if you want the slice longer; skip if 11 rooms is enough for the vertical
   slice's purpose.
5. **Map overlay redesign** — only if the new rooms being invisible on the M-key map
   actually bothers you in practice. Low priority; nothing is broken, just incomplete.
6. **`vania_world.gd` cleanup** — confirmed dead code (unreferenced by `main.tscn`)
   since earlier this session, but Codex has been keeping it in sync with
   `barge_room_manager.gd`'s changes anyway (VFX, projectile fixes) out of habit. Either
   delete it or explicitly tell Codex to stop touching it — right now it's wasted effort
   in either direction.
