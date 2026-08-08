NECROMANCER: FIRST DAWN — VANIA PASS 0.10 VISUAL IDENTITY & ROSTER

This pass resumes development from the stable 0.9.1 room-scene build and focuses on making the game read as an authored Halloween-gothic action Metroidvania instead of a prototype full of debug-shaped artifacts.

VISUAL IDENTITY
- Grave Hook anchors are now illustrated purple Grave Lanterns built from the existing orange lantern language.
- The Chain Crypt Grave Hook pickup now has dedicated relic art rather than Polygon2D diamonds.
- Room portals use illustrated wooden/iron bulkhead door sprites instead of mostly runtime-drawn rectangles.
- Every one-way gameplay platform receives a tiled plank/iron lip derived from the existing prop art, so legal landing surfaces are much easier to read.
- The goal remains chunky, expressive, slightly cartoony gothic pixel art -- not the ultra-polished mockup look.

MAP PASS
- The map now renders on a worn parchment / timber frame.
- Explored/current rooms use textured map tiles rather than flat CSS-like color rectangles.
- Player, Grave Hook, Rib Gate and Heart Shard use small illustrated markers.
- The underlying Castlevania-style room graph remains unchanged.

ENEMY ROSTER
Two additional early-game archetypes are active:

BILGE CRAWLER
- Smaller, lower silhouette.
- Fast scuttling approach.
- Short readable windup into a quick lunge.
- Low health and short recovery: dangerous when ignored, easy to punish when read correctly.
- First appears in the Hull Breach and later Mourning Galley.

HANGED SAILOR
- Tall, violet-gray silhouette.
- Uses a committed arcing leap similar to a nastier traversal-aware Hopper.
- Checks landing support before committing.
- First appears on the Rigging Walk.

Lantern Tossers now visibly carry an orange lantern accessory, giving the orange mundane / violet necromantic lantern language a clearer contrast.

RAISE THE DEAD
- Charged Raise remains intact.
- Bilge Crawlers have a deliberately faster ritual time.
- Hanged Sailors take a standard specialist ritual time.
- New corpse types currently map into existing Guard / Sentry / Brute follower roles; deeper role specialization remains planned.

CONTROLS
A/D or arrows     Move / directional aim
Space / W / Up    Jump
F / left click    Attack
Up + Attack       Rising cut
Down + Attack air Plunge
Hold E            Raise the Dead
Hold Q + direction, release   Grave Field / Hook
C                  Cycle army posture
Direction + C      Direct army command
M                  Map
H                  Help
T                  Dismiss ordinary note
R                  Restart checkpoint
F3                 Collision overlay

AUDIT
Run:
  python tools/audit_0_10_visual_identity.py
  python tools/audit_gdscript_blocks.py
  python tools/audit_0_9_raise_command.py

Godot itself is not available in the packaging environment, so a local Godot 4.7 run remains the runtime validation.
