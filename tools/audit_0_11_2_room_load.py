from pathlib import Path
import re, sys
ROOT=Path(__file__).resolve().parents[1]
manager=(ROOT/'scripts/barge_room_manager.gd').read_text()
room=(ROOT/'scripts/rooms/room_scene.gd').read_text()
errors=[]
for name in ['BargeRoomScene','RoomDoor','RoomHookAnchor','RoomEnemySpawn','RoomBreakableSpawn','RoomHazard','BoneGate','BreakableProp','PickupDrop']:
    # Detect actual GDScript type usage, not node names inside quoted paths.
    patterns = [rf':\s*{re.escape(name)}\b', rf'\bas\s+{re.escape(name)}\b', rf'Array\[{re.escape(name)}\]']
    if any(re.search(pattern, manager) for pattern in patterns):
        errors.append(f'startup manager still uses custom room type {name}')
for token in ['_show_startup_error','required_methods','packed.instantiate()','current_room.has_method(method_name)']:
    if token not in manager: errors.append(f'missing room-load hardening token: {token}')
for token in ['_owned_group_nodes("room_doors")','_owned_group_nodes("room_hook_anchors")','_owned_group_nodes("room_enemy_spawns")','_owned_group_nodes("room_breakable_spawns")','_owned_group_nodes("room_hazards")']:
    if token not in room: errors.append(f'room scene missing group contract: {token}')
if errors:
    print('VANIA PASS 0.11.2 ROOM LOAD AUDIT')
    [print('ERROR:',e) for e in errors]
    sys.exit(1)
print('VANIA PASS 0.11.2 ROOM LOAD AUDIT')
print('PASS: startup room manager has no global room-helper type dependency')
print('PASS: room instance API is validated before gameplay')
print('PASS: room helper discovery uses room-owned group contracts')
print('PASS: visible startup error fallback is present')
