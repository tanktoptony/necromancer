NECROMANCER: FIRST DAWN — VANIA PASS 0.8 ROOM SCENE REFACTOR

This build replaces the giant continuous 0.7 world with individual Godot room scenes.

PRIMARY CHANGE
Each barge compartment is now its own .tscn under res://scenes/barge/:
  receiving.tscn
  gallery.tscn
  gate.tscn
  breach.tscn
  chain.tscn
  shaft.tscn
  orlop.tscn
  deck.tscn

Room traversal now happens through authored door/hatch portals. Crossing a portal performs a short directional threshold wipe and loads the adjacent room. Player health, army roles, army command, Grave Hook state, gate state, map discovery, and heart upgrade persist.

GRAVE HOOK
Hook anchors are room-local. Q can never target an anchor in another room.
Indoor Hook ranges are intentionally short. The Winch Shaft is the tutorial/combat-scale example. Future outdoor stages can support much longer Ghosts 'n Goblins-style pulls without changing the barge rule set.

RIB GATE LOOP
Receiving Hold -> Quarantine Gallery -> Rib Gate.
The Rib Gate is encountered before the Hook and cannot be opened.
Drop through the broken hatch -> Hull Breach -> Chain Crypt.
Claim the Grave Hook -> Winch Shaft -> Upper Orlop.
Return through the right side of the Rib Gate and tear it open, creating the shortcut.
Continue through the Upper Orlop -> Ossuary Deck.

HULL BREACH
The old Drowned Hold has been replaced by a three-layer Hull Breach room:
  far exterior / shoreline + sea
  damaged hull gameplay layer
  foreground broken ribs / chains
The water is a hazard below the visible broken decking, not an abstract swimming-pool room.

CAMERA
No automatic room-entry sightseeing sweeps.
Each room owns a restrained camera profile.
Only explicit POI beats can temporarily bias the camera, and player control remains active.

REFERENCE MUSIC SLOT
No copyrighted music is bundled.
For private local reference only, place your track in res://assets/music/ as one of:
  reference_water_level.ogg
  reference_water_level.mp3
  reference_water_level.wav
The prototype auto-plays and loops the first matching file it finds.

CONTROLS
A/D or arrows  Move
Space / W / Up  Jump
F / left click  Attack combo
E  Raise / claim item
Q  Grave Hook / Rib Gate / pull light enemy
C  Cycle FOLLOW / HOLD / ASSAULT
M  Map
H  Help
T  Dismiss note
R  Restart checkpoint
F3 Collision overlay
