NECROMANCER: FIRST DAWN — VANIA PASS 0.6.1
COLLISION & TRAVERSAL INTEGRITY

This package builds directly on 0.6 Combat & Command.

KEY CHANGES

- Merged floor colliders at the Receiving/Atrium and Winch/Ossuary seams.
- Added a visible wooden step to make the lower Atrium platform route jumpable.
- Slightly increased jump height and added jump input buffering.
- F3 now marks intentional Hook-only ledges in violet.
- Enemy room-edge behavior cancels outward motion instead of jittering.
- Enemy and follower ledge checks now use two support probes.
- Enemies recover from genuine collision wedges.
- Followers recover from nearby wedges and snap only to raycast-confirmed floors.
- The first Corpse Atrium charger patrols farther from the room threshold.

CONTROLS

A/D or arrows  Move
Space/W/Up     Jump
F / Left Click Attack
E              Raise / interact
Q              Grave Hook
C              Army command
M              Map
H              Help
T              Dismiss message
F3             Collision overlay
R              Restart

F3 COLORS

Green   Solid floor/wall
Cyan    Normal jumpable one-way platform
Violet  Intentional Grave Hook landing
Red     Hazard/recovery area
