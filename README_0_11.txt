NECROMANCER: FIRST DAWN — VANIA PASS 0.11 CONTENT REBUILD

This pass deliberately shrinks the active prototype from fourteen repetitive compartments to six rooms rebuilt around variety, readable physics and the "kill it because I want it" necromancy fantasy.

ACTIVE SIX-ROOM SLICE
1. Receiving Hold — clean onboarding, first Grave Guard, first Raise.
2. Quarantine Gallery — large optional vertical space, Bell Keeper + Lantern Tosser + Bone Crow, breakables and an ability-gated upper gantry.
3. Rib Gate — progression landmark, Coffin Mimic surprise, broken hatch into the lower ship.
4. Hull Breach — broad broken-hull platforms over seawater, Crawler + Hanged Sailor + Bone Crow.
5. Chain Crypt — Hook Brute encounter, Grave Hook acquisition, two sequential room-local Hook pulls to the crypt lift.
6. Ossuary Deck — wide final combat arena with a mixed six-archetype encounter and elite Brute.

The route is circuitous rather than linear:
Receiving -> Gallery -> Rib Gate -> Hull Breach -> Chain Crypt -> return behind Rib Gate -> Ossuary Deck.
The Rib Gate must be opened before the deck transition is allowed.

ENEMY VISUAL ROSTER
The first-area roster no longer uses one shrouded body tinted into every role. Dedicated eight-frame placeholder/production-swap sheets now exist for:
- Grave Guard
- Lantern Tosser
- Bilge Crawler
- Hook Brute
- Bell Keeper
- Hanged Sailor
- Bone Crow (new flying AI)
- Coffin Mimic (new stationary ambusher)

These are intentionally chunky and modestly detailed so a later sprite artist can replace them cleanly without changing AI or room logic.

RAISE THE DEAD
- Charged Raise remains the signature recruitment action.
- Raised enemies now preserve their source archetype metadata and source silhouette.
- Raised Bone Crows actually fly and provide ranged support.
- Crawlers keep a smaller collision profile.
- Roles still resolve into Guard / Brute / Sentry behavior, but the body you recruited remains visibly recognizable.

COMBAT / REWARDS
- Three-hit ground combo remains.
- Down + Attack on the ground performs a slow heavy cleave (3 damage / armor break).
- Up + Attack remains the temporary rising-cut implementation. The shovel/rock-toss anti-air concept is explicitly parked for a later animation pass.
- Down + Attack in air remains plunge.
- Enemies drop Grave Ash.
- Breakable candles and bone urns drop Ash or Flesh.
- HUD tracks Ash.

MODULAR GAMEPLAY ART
New res://assets/vania11 kit:
- solid deck trim
- one-way platform trim
- chunky stairs
- railings
- breakable candle
- bone urn
- Grave Ash pickup
- Flesh pickup
- chunky purple Grave Lantern
- illustrated Rib Gate
- hanging hook prop

Collision remains authoritative. RoomScene decorates collision surfaces from the gameplay-art kit so legal floors/platforms visibly match physics.

GRAVE HOOK
Chain Crypt now avoids close-anchor ambiguity:
- first anchor is the only anchor in range from the relic floor
- after landing, the second anchor becomes reachable
- both are room-local
- the first required post-relic rise exceeds the player's normal 56.9px jump envelope

CONTROLS
A/D or arrows       Move / Grave Field aim
Space / W / Up      Jump
F / left click      Three-hit combo
Down + F ground     Heavy cleave
Up + F              Rising cut (temporary; shovel toss concept parked)
Down + F in air     Plunge
Hold E              Raise the Dead ritual
Hold Q + direction  Grave Field; release to Hook
C                    Army posture
Direction + C        Assault / Recall / Hold there
M                    Map
H                    Help
T                    Dismiss ordinary note
R                    Restart checkpoint
F3                   Collision overlay

STATIC VALIDATION
Run:
  python tools/audit_gdscript_blocks.py
  python tools/audit_0_11_content_rebuild.py

Godot is not installed in the packaging environment. A local Godot 4.7 launch remains the runtime/parser validation.
