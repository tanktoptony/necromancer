NECROMANCER: FIRST DAWN — VANIA PASS 0.11.3 SCENE SERIALIZATION HOTFIX

This is a surgical repair of 0.11.2.

Runtime blocker fixed:
- receiving.tscn line 29 used GDScript-only Vector2.ZERO inside serialized scene text.
- gallery.tscn and chain.tscn contained the same invalid serialized value.
- All three now use valid .tscn syntax: Vector2(0, 0).

Why the earlier audits missed it:
- They validated resource paths, room contracts, and GDScript structure, but did not validate Godot text-scene serialization values.

New release gate:
- tools/audit_scene_serialization.py scans every .tscn file for non-serializable script constants, malformed section headers, unresolved ExtResource/SubResource ids, missing ext_resource paths, and invalid node-parent ordering.

No gameplay, art, encounter, physics, or balance changes are included in this hotfix.
