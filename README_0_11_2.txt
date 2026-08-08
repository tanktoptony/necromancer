NECROMANCER: FIRST DAWN — VANIA PASS 0.11.2 ROOM LOAD HOTFIX

This hotfix addresses the gray-screen startup failure seen in 0.11.1.

ROOT CAUSE / HARDENING
- Startup-critical room loading no longer depends on Godot's global custom-class registry resolving BargeRoomScene, RoomDoor, RoomHookAnchor, RoomEnemySpawn, RoomBreakableSpawn, RoomHazard, BoneGate, BreakableProp, or PickupDrop in a particular order.
- Room-scene helper queries now use room-owned group membership and untyped runtime contracts.
- Breakable/door/hazard signals no longer self-reference global custom class names.
- Room instantiation now validates its required API before gameplay begins.
- Any future room-load failure displays a visible ROOM LOAD ERROR message instead of silently showing the engine clear color.

No gameplay balance/content changes are intended in this hotfix.
