# Vania Pass 0.7 — Setpiece Circuit Audit

## Goal
Move the opening away from a dense stack of prototype chambers and toward an authored first-level arc: spacious rooms, scenic composition, deliberate encounter pacing, an ability gate shown before the ability, a committed detour, a relic payoff, a shortcut loop, and an exterior finale.

## Critical progression
`Receiving Hold -> Quarantine Gallery -> Rib Gate -> Drowned Hold -> Chain Crypt -> Winch Shaft -> Upper Orlop -> Rib Gate shortcut -> Ossuary Deck`

The Rib Gate can be physically reached and tested before the Grave Hook. The nearby broken hatch is 90px wide, within the player's ideal horizontal jump envelope, so inspecting the gate does not force an accidental fall. The player must eventually take the hatch because the gate cannot be opened by hand.

The Grave Hook is acquired in the Chain Crypt. Its acquisition text explicitly teaches three uses: traversal rings, bone gates, and light-enemy pulls. The Winch Shaft immediately requires the traversal use. The final shaft pull lands the player on a one-way hatch in the Upper Orlop, on the opposite side of the Rib Gate. Returning left produces the shortcut-opening payoff.

## Collision / traversal
- Long main-deck floor runs are continuous except at authored hatches.
- Gallery normal steps rise by at most 52px; player jump height is about 56.9px.
- Higher Gallery shelves are marked Hook-only in F3.
- Drowned Hold collision tracks the visible platforms; the only required upward rise is 51px.
- Drowned Hold recovery begins at the visible waterline instead of far below it.
- The first Winch Shaft shelf is normal staging ground; the upper shelf is Hook-only.
- The Upper Orlop return uses a one-way hatch so the Hook does not collide with a solid ceiling.

## Message pacing
- Ordinary flavor messages can have only one queued successor.
- Corpse-available jokes have a 14-second cooldown.
- Repeated pit, no-target Hook, and no-Hook messages have cooldowns.
- Progression beats such as the Rib Gate, Grave Hook, Winch Shaft, and Ossuary Deck are priority notes.

## Encounter pacing
- Receiving Hold: 1 enemy.
- Quarantine Gallery: 3 enemies spread across a large room and two elevations.
- Rib Gate: deliberately quiet; the environment is the encounter.
- Drowned Hold: 3 enemies distributed across platforms.
- Chain Crypt: 2 enemies before the relic.
- Winch Shaft: 1 enemy.
- Upper Orlop: 2 enemies.
- Ossuary Deck: 4-enemy wide formation ending in an elite charger.

## Static audit
Run:
`python tools/audit_0_7_setpiece.py`

The audit checks resource references, structural delimiters, duplicate functions, required jump envelopes, the pre-Hook gate inspection, Hook ranges, the Upper Orlop one-way exit hatch, obsolete room IDs, and the new room-art assets.
