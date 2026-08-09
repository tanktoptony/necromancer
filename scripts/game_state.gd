extends Node

const BASE_MAX_HEALTH: int = 5
const MAX_ARMY_SIZE: int = 3

var max_health: int = BASE_MAX_HEALTH
var player_health: int = BASE_MAX_HEALTH
var army_size: int = 0
var army_roles: Array[int] = []
var army_archetypes: Array[int] = []
var grave_ash: int = 0
var army_command_mode: int = 0
var starting_guard_raised: bool = false
var has_grave_hook: bool = false
var hook_tutorial_complete: bool = false
var bone_gate_open: bool = false
var heart_shard_collected: bool = false
var checkpoint_valid: bool = false
var checkpoint_room: String = "chain"
var checkpoint_local_position: Vector2 = Vector2(288.0, 318.0)
var current_room_id: String = "receiving"
var slice_complete: bool = false
var discovered_rooms: Dictionary = {"receiving": true}
var enemy_clear_state: Dictionary = {}

func mark_enemy_killed(room_id: String, spawn_key: String) -> void:
	if spawn_key.is_empty():
		return
	var key: String = "%s/%s" % [room_id, spawn_key]
	if enemy_clear_state.get(key, "") != "raised":
		enemy_clear_state[key] = "killed"

func mark_enemy_raised(room_id: String, spawn_key: String) -> void:
	if spawn_key.is_empty():
		return
	enemy_clear_state["%s/%s" % [room_id, spawn_key]] = "raised"

func enemy_clear_status(room_id: String, spawn_key: String) -> String:
	if spawn_key.is_empty():
		return ""
	return str(enemy_clear_state.get("%s/%s" % [room_id, spawn_key], ""))

func reset_run() -> void:
	max_health = BASE_MAX_HEALTH
	player_health = max_health
	army_size = 0
	army_roles.clear()
	army_archetypes.clear()
	grave_ash = 0
	army_command_mode = 0
	starting_guard_raised = false
	has_grave_hook = false
	hook_tutorial_complete = false
	bone_gate_open = false
	heart_shard_collected = false
	checkpoint_valid = false
	checkpoint_room = "chain"
	checkpoint_local_position = Vector2(288.0, 318.0)
	current_room_id = "receiving"
	slice_complete = false
	discovered_rooms = {"receiving": true}
	enemy_clear_state.clear()

func restart_room() -> void:
	player_health = max_health

func set_army_size(value: int) -> void:
	army_size = clampi(value, 0, MAX_ARMY_SIZE)
	while army_roles.size() > army_size:
		army_roles.pop_back()
	while army_roles.size() < army_size:
		army_roles.append(0)
	while army_archetypes.size() > army_size:
		army_archetypes.pop_back()
	while army_archetypes.size() < army_size:
		army_archetypes.append(-1)

func set_army_roles(roles: Array[int]) -> void:
	army_roles = roles.duplicate()
	if army_roles.size() > MAX_ARMY_SIZE:
		army_roles.resize(MAX_ARMY_SIZE)
	army_size = army_roles.size()

func set_army_roster(roles: Array[int], archetypes: Array[int]) -> void:
	army_roles = roles.duplicate()
	army_archetypes = archetypes.duplicate()
	if army_roles.size() > MAX_ARMY_SIZE:
		army_roles.resize(MAX_ARMY_SIZE)
	if army_archetypes.size() > MAX_ARMY_SIZE:
		army_archetypes.resize(MAX_ARMY_SIZE)
	while army_archetypes.size() < army_roles.size():
		army_archetypes.append(-1)
	army_size = army_roles.size()

func add_grave_ash(amount: int) -> void:
	grave_ash = maxi(0, grave_ash + amount)

func discover_room(room_id: String) -> void:
	discovered_rooms[room_id] = true

func collect_heart_shard() -> void:
	if heart_shard_collected:
		return
	heart_shard_collected = true
	max_health += 1
	player_health = max_health
