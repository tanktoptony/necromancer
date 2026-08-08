# Vania Pass 0.9 - Raise & Command Audit

## Build intent

0.9 keeps the independent-room architecture introduced in 0.8 and makes necromancy the signature loop rather than a side interaction. It also expands the Plague Barge from eight to fourteen compartments without returning to the old giant-world coordinate model.

## Static audit result

`tools/audit_0_9_raise_command.py` currently passes the following checks:

- All `.tscn` resource references resolve.
- Fourteen room scenes exist and expose the expected room-layer structure.
- Every authored door target resolves to a valid destination room and spawn marker.
- The main route resolves as:
  `receiving -> forecastle -> lantern -> gallery -> gate -> breach -> pantry -> chain -> shaft -> orlop -> rigging -> galley -> captain -> deck`.
- The Rib Gate shortcut still connects the Gate and Upper Orlop after the Grave Hook progression beat.
- The six new rooms use broad ground geometry and authored vertical rises no greater than the generous normal-jump rule used by the audit.
- Charged Raise contracts exist in the manager/player integration.
- Grave Hook targeting is room-local and uses directional aim/release state.
- Follower Guard, Brute and Sentry roles plus directed hold-position behavior are present.
- Shield Guard and Lantern Tosser enemy archetypes are present.
- GDScript delimiter counts and function-name uniqueness pass the basic structural scan.
- No private reference music file is bundled.

## Design contracts introduced in 0.9

### Charged Raise
Raise is intentionally vulnerable. The player must hold E near a settled corpse while the ritual completes. Larger or more specialized bodies take longer. Releasing the input, moving out of range, or taking damage cancels the channel.

### Directional Grave Field
Indoor Hook use no longer asks a global nearest-anchor query. Holding Q opens a room-local field; directional input biases anchor selection; release commits the pull. This is intended to feel occult and deliberate rather than like a grapple gun.

### Direct army intent
The player can still cycle Follow / Hold / Assault, while directional C commands supply immediate intent without requiring individual follower micromanagement.

### Enemy-to-party continuity
Shield Guard and Lantern Tosser expand combat variety while also expanding recruitment decisions: their combat jobs remain legible in the roles they contribute when raised.

## Known limitations / runtime validation priorities

The static audit cannot replace execution in Godot. The first local run should prioritize:

1. Hold-to-Raise interruption and completion timing in live combat.
2. Hook directional selection when two anchors are close together.
3. Whether anti-air and plunge inputs conflict with jump / aim behavior.
4. Door transition spawn safety with three followers in each posture.
5. Follower directed Hold positions on platforms and near room exits.
6. Shield Guard frontal block readability.
7. Lantern Tosser projectile lanes and platform safety.
8. Normal jump accessibility in all six new rooms.
9. Rib Gate progression and shortcut return route.
10. Message density during corpse-heavy encounters.

## Audit command

```text
python tools/audit_0_9_raise_command.py
```
