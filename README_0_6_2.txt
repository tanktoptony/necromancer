NECROMANCER: FIRST DAWN — VANIA PASS 0.6.2
COLLISION & COMBAT INTEGRITY

This package builds directly on the tested 0.6.1 project.
It does not expand the world. It hardens actor/platform behavior and makes combat more deliberate.

COLLISION / TRAVERSAL

- Player receives a small ledge-assist window for near-miss landings on normal platforms.
- Hook-only platforms remain outside the normal route envelope.
- Enemy and follower ledge checks require two supported floor probes rather than accepting a tiny corner.
- Followers no longer leave the army because navigation sent them into the void.
- Stranded followers briefly reform beside the player on a raycast-confirmed floor.
- Hold-position followers remain in place unless they leave the valid world entirely.
- Falling or midair enemies become physical corpses and settle onto world collision before they can be raised.
- F3 now outlines player, enemy, and follower collision bodies in addition to world geometry.

COMBAT

- Player melee now requires the target to be in front and unobstructed by world collision.
- Successful hits produce a small hit-confirm recoil, reducing accidental slide-through.
- Enemies lock their target when a telegraphed attack begins; they do not retarget during the swing.
- Only one melee enemy may actively attack a given target at a time.
- Walkers, Chargers, and Brutes remain on their combat elevation instead of chasing vertically.
- Sentries and Hoppers retain elevation-aware roles.
- Charges validate the entire floor lane before committing.
- Hopper landing checks use three support probes.
- Enemy melee cannot hit behind the attacker or through platforms/walls.
- Brutes, Chargers, and elites retain poise against light hits; the third combo strike interrupts them.
- Raised followers now use visible attack windups and recovery instead of instant contact damage.
- Followers select targets on reachable combat elevations and maintain wider formation spacing.
- The Grave Hook only pulls light enemies on the same combat lane with clear line-of-sight.

CONTROLS

A/D or arrows   Move
SPACE / W / Up  Jump
F / Left Click  Three-hit attack
E               Raise / interact
Q               Grave Hook
C               Army command
M               Map
H               Help
T               Dismiss message
F3              Collision + actor-body overlay
R               Restart at checkpoint

F3 COLORS

Green   Solid floor/wall
Cyan    Normal jumpable one-way platform
Violet  Intentional Grave Hook landing
Red     Hazard/recovery area
White   Player collision body
Red box Enemy collision body
Mint    Friendly collision body
