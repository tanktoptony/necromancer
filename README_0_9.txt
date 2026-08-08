NECROMANCER: FIRST DAWN — VANIA PASS 0.9 RAISE & COMMAND

This build uses the 0.8 room-scene architecture as the foundation and pushes the game toward its current identity:
  Bloodstained / Order of Ecclesia room traversal
  Rogue Legacy-style readable combat decisions
  chunky expressive sprite work
  spooky graveyard-storybook / Halloween gothic atmosphere
  Raise the Dead as the signature party-building mechanic

MAJOR CHANGES

CHARGED RAISE
E is no longer an instant corpse conversion.
Hold E near a settled corpse to channel a resurrection ritual. The ring must complete before the corpse joins the party. Releasing early, moving too far away, or taking damage interrupts the ritual.
Different corpse classes take different amounts of time to raise.

PLAYER COMBAT VARIANCE
F / left click keeps the three-hit ground chain.
Up + Attack performs a rising anti-air cut.
Down + Attack while airborne performs a plunging strike and bounces on a confirmed hit.

GRAVE FIELD / GRAVE HOOK
Indoor Hook traversal is now a local directional field rather than nearest-anchor roulette.
Hold Q to awaken valid anchors in the current room.
Aim with WASD / arrow input.
Release Q to commit to the selected directional anchor.
If no anchor is selected, the Hook can pull a susceptible light enemy in the aimed direction.
Long cross-stage grapple pulls remain reserved for future outdoor levels.

ARMY COMMANDS
Tap C: cycle FOLLOW / HOLD / ASSAULT.
Up + C: Assault.
Down + C: Recall / reform around the necromancer.
Left or Right + C: Hold There on nearby supported ground.
Followers now score targets differently by role instead of all selecting the same enemy logic.

FOLLOWER ROLES
Guard: protects local player space and favors immediate front-line threats.
Brute: prioritizes heavy targets and controls ground space.
Sentry: seeks firing lanes and prioritizes ranged/support nuisances.

NEW ENEMY TYPES
Shield Guard: blocks ordinary frontal light attacks. Heavy, plunge, or rear attacks break the assumption.
Lantern Tosser: mid-range harassment enemy that repositions and throws slower projectiles.
Both preserve useful resurrection roles after death.

EXPANDED PLAGUE BARGE
The route grows from 8 to 14 authored room scenes:
  I. Receiving Hold
  II. Forecastle Passage
  III. Lantern Chapel
  IV. Quarantine Gallery
  V. Rib Gate
  VI. Hull Breach
  VII. Bone Pantry
  VIII. Chain Crypt
  IX. Winch Shaft
  X. Upper Orlop
  XI. Rigging Walk
  XII. Mourning Galley
  XIII. Captain's Ossuary
  XIV. Ossuary Deck

The Rib Gate shortcut remains the major first-level loop: encounter it before the Grave Hook, descend through the lower route, acquire the Hook, return from the far side, and create the shortcut.

TRAVERSAL RULE
The six new compartments were deliberately built around broad floors, generous landing surfaces, and authored elevation changes within the current jump envelope. Nearby ledges should read as normally jumpable unless their presentation clearly says otherwise.

DOORS
Room boundaries use visible bulkhead / hatch portals. Doors open as the player crosses the threshold and the destination entrance closes behind the party.

MESSAGE PACING
Ordinary flavor text has a deliberate gap and only one waiting slot. Priority progression/tutorial information can still interrupt when necessary. Humor should punctuate play rather than narrate every corpse.

REFERENCE MUSIC
No copyrighted music is bundled.
For private local reference only, place a track in res://assets/music/ named:
  reference_water_level.ogg
  reference_water_level.mp3
  reference_water_level.wav
The first matching file is detected and looped automatically.

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
  python tools/audit_0_9_raise_command.py

Godot itself is not available in the build environment used to assemble this package, so the included audit is static validation. A local Godot 4.x run remains the runtime test.
