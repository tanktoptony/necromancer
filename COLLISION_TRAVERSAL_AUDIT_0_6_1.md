# Necromancer: First Dawn — Collision & Traversal Audit 0.6.1

## Scope

This pass audits the exact 0.6 Combat & Command package for:

- player/world collision
- enemy/world collision
- raised follower/world collision
- room seams
- ledge reachability
- intentional Hook-only routes
- encounter spawn support
- actor recovery from wedges and falls

## Confirmed defects in 0.6

### 1. Receiving Hold / Corpse Atrium seam

The Receiving Hold floor ended at `x = 512` and a second StaticBody began at the exact same coordinate. Even with matching heights, adjacent bodies can catch a CharacterBody capsule at the join.

**Fix:** the two floor pieces are now one collider from `x = 0` through `x = 720`.

The Winch Loft / Ossuary Deck floor had the same construction at `x = 1792` and is also merged.

### 2. Atrium ledge was visually close but mathematically unreachable

The original floor was at `y = 414`; the first ledge was at `y = 320`, a required rise of 94 pixels. The 0.6 player jump rose approximately 52 pixels.

**Fixes:**

- player jump now rises approximately 56.9 pixels
- an authored wooden step was added at `y = 366`
- the required non-Hook route is now 48px, 46px, 48px, 52px, and 22px rises
- every required rise falls within the measured jump envelope

### 3. Hook-only routes were not classified separately

A nearby ledge could look broken when it was actually intended for the Grave Hook.

**Fix:** F3 collision debug now distinguishes:

- green — solid
- cyan — normal jumpable one-way platform
- violet — intentionally Hook-only landing
- red — hazard

The Black Heart gantry and two Winch Shaft landings are explicitly Hook-only.

### 4. Enemy room-edge jitter

Enemies were clamped to room bounds after movement but retained behavior that could immediately push them back into the same edge.

**Fix:** room-bound contact now cancels horizontal velocity, turns patrol direction inward, and returns non-attacking enemies to patrol.

### 5. Enemy and follower ledge probes were too optimistic

One short ray could detect a tiny corner and treat it as a complete floor.

**Fix:** enemies and followers use two forward support probes. They stop before unsupported edges instead of trusting one pixel of contact.

### 6. Anti-wedge recovery missed nearby actors

Followers only considered themselves stuck when they were already far from the player. An ally could remain wedged nearby indefinitely.

**Fixes:**

- requested movement is recorded before `move_and_slide()`
- enemies recover after 0.72 seconds of genuine blocked motion
- followers recover after 0.68 seconds of genuine blocked motion
- follower recovery raycasts to a real floor before repositioning
- prolonged airborne followers recover instead of falling forever

### 7. Character seam tolerance differed implicitly

**Fix:** player, enemies, and followers now share:

- `collision_mask = 1` — world only
- `floor_snap_length = 5`
- `safe_margin = 0.04`
- pass-through relationships with friendlies and hostiles remain intact

## Static validation

The package passes:

- resource reference audit
- script structure audit
- original 0.6 combat/command audit
- collision topology audit
- required jump-height audit
- Hook route audit
- all 17 enemy spawn support checks

Measured values:

- player jump rise: **56.89px**
- standing full-flight horizontal envelope: **105.71px**
- highest required non-Hook rise: **52px**

## Runtime validation requested

Godot runtime execution is not available in the build environment. During playtesting, press **F3** and inspect:

1. the x=512 room seam
2. the new first atrium step
3. the central atrium drop
4. the Drowned Pit decks
5. the two violet Winch Shaft landings
6. the x=1792 Winch/Ossuary seam

Any colored collider that does not match the visible architecture remains a bug.
