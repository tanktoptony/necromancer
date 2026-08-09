extends Node2D

const PlayerScript: Script = preload("res://scripts/player.gd")
const EnemyScript: Script = preload("res://scripts/enemy.gd")
const GuardScript: Script = preload("res://scripts/guard.gd")
const ProjectileScript: Script = preload("res://scripts/projectile.gd")
const MapScript: Script = preload("res://scripts/map_overlay.gd")
const BreakableScript: Script = preload("res://scripts/rooms/breakable_prop.gd")
const PickupScript: Script = preload("res://scripts/pickup_drop.gd")

const VIEWPORT_SIZE: Vector2 = Vector2(640.0, 360.0)
const ROOM_SCENES: Dictionary = {
	"receiving": "res://scenes/barge/receiving.tscn",
	"gallery": "res://scenes/barge/gallery.tscn",
	"gate": "res://scenes/barge/gate.tscn",
	"breach": "res://scenes/barge/breach.tscn",
	"chain": "res://scenes/barge/chain.tscn",
	"deck": "res://scenes/barge/deck.tscn"
}

var room_holder: Node2D
var actor_holder: Node2D
var effects_holder: Node2D
var current_room: Node2D
var current_room_id: String = ""
var player: NecromancerPlayer
var game_camera: Camera2D
var enemies: Array[RaggedEnemy] = []
var breakables: Array = []
var allies: Array[RaisedGuard] = []
var dead_guard: RaisedGuard
var nearest_corpse: Node2D
var current_anchor: Node2D
var hook_combat_target: RaggedEnemy
var raise_target: Node2D
var raise_progress: float = 0.0
var raise_required: float = 0.9
var raise_active: bool = false
var hook_field_active: bool = false
const HOOK_FIELD_RADIUS: float = 245.0
var command_hold_target: Vector2 = Vector2.ZERO
var last_safe_position: Vector2 = Vector2.ZERO
var safe_record_timer: float = 0.0
var army_command_mode: int = 0
var transitioning: bool = false
var pending_room: String = ""
var pending_door: String = "default"
var shown_room_notes: Dictionary = {}
var shown_pois: Dictionary = {}
var note_cooldowns: Dictionary = {}
var corpse_note_rooms: Dictionary = {}
var collision_debug_visible: bool = false
var death_note_shown: bool = false
var f3_was_down: bool = false
var r_was_down: bool = false
var m_was_down: bool = false
var h_was_down: bool = false
var t_was_down: bool = false

var ui_layer: CanvasLayer
var health_label: Label
var army_label: Label
var hook_label: Label
var command_label: Label
var ash_label: Label
var room_label: Label
var prompt_label: Label
var toast_panel: ColorRect
var toast_label: Label
var tutorial_panel: ColorRect
var tutorial_title: Label
var tutorial_body: Label
var help_panel: ColorRect
var map_overlay: BargeMapOverlay
var map_visible: bool = false
var help_visible: bool = false
var toast_queue: Array[Dictionary] = []
var active_toast: Dictionary = {}
var toast_timer: float = 0.0
var toast_gap_timer: float = 0.0
var room_title_tween: Tween
var transition_rect: ColorRect
var transition_slit: ColorRect
var item_fanfare_panel: ColorRect
var item_fanfare_flash: ColorRect
var item_fanfare_title: Label
var item_fanfare_body: Label
var item_fanfare_active: bool = false
var item_fanfare_timer: float = 0.0
var hook_hint_line: Line2D
var chain_line: Line2D
var chain_line_timer: float = 0.0
var sfx_players: Dictionary = {}
var music_player: AudioStreamPlayer
var hitstop_end_msec: int = 0
var shake_timer: float = 0.0
var shake_strength: float = 0.0
var startup_error_label: Label

func _ready() -> void:
	room_holder = Node2D.new()
	room_holder.name = "RoomHolder"
	add_child(room_holder)
	actor_holder = Node2D.new()
	actor_holder.name = "Actors"
	add_child(actor_holder)
	effects_holder = Node2D.new()
	effects_holder.name = "Effects"
	add_child(effects_holder)
	_build_audio()
	_build_ui()
	_spawn_player()
	_spawn_persisted_allies()
	army_command_mode = GameState.army_command_mode
	_apply_army_command(false)
	var start_room: String = GameState.current_room_id if ROOM_SCENES.has(GameState.current_room_id) else "receiving"
	var start_door: String = "default"
	var override_position: Variant = null
	if GameState.checkpoint_valid:
		start_room = GameState.checkpoint_room
		override_position = GameState.checkpoint_local_position
	_load_room(start_room, start_door, true, override_position)

func _process(delta: float) -> void:
	_update_combat_feedback(delta)
	_update_toasts(delta)
	if collision_debug_visible:
		queue_redraw()
	chain_line_timer = maxf(0.0, chain_line_timer - delta)
	if is_instance_valid(chain_line):
		chain_line.visible = chain_line_timer > 0.0
	if item_fanfare_active:
		_update_item_fanfare(delta)
		return
	_handle_global_inputs()
	if not is_instance_valid(player) or transitioning or current_room == null:
		return
	if player.health <= 0:
		if not death_note_shown:
			death_note_shown = true
			_queue_note("Death is temporary. The paperwork is not. Press R to restart at your checkpoint.", 999.0, true)
		return
	death_note_shown = false
	_refresh_allies()
	_update_pickups()
	_update_raise_ritual(delta)
	_update_anchor_guidance()
	_update_interaction_prompt()
	_update_last_safe_position(delta)
	_check_world_bounds()
	_update_poi_camera()
	_update_map()
	_update_hud()

func _check_world_bounds() -> void:
	# Rooms only stop lateral travel via door trigger areas, not real walls, so any
	# edge without a door (or any height above/below a door's narrow trigger band)
	# is otherwise open air. This is the generic catch the old world-scene build had
	# (WORLD_RECOVERY_Y) that never carried over into the per-room refactor.
	var margin: float = 140.0
	var out_of_bounds: bool = (
		player.global_position.x < -margin
		or player.global_position.x > current_room.room_size.x + margin
		or player.global_position.y > current_room.room_size.y + margin
		or player.global_position.y < -margin
	)
	if not out_of_bounds:
		return
	player.take_damage(1, player.global_position.x)
	player.global_position = last_safe_position
	player.velocity = Vector2.ZERO
	for ally: RaisedGuard in allies:
		if is_instance_valid(ally):
			ally.snap_near_player()
	_queue_note("The barge does not extend that far. Something drags you back aboard.", 6.0, false, "bounds_recovery", 10.0)

func _handle_global_inputs() -> void:
	var r_down: bool = Input.is_key_pressed(KEY_R)
	if r_down and not r_was_down:
		_restart_from_checkpoint()
	r_was_down = r_down
	var m_down: bool = Input.is_key_pressed(KEY_M)
	if m_down and not m_was_down:
		map_visible = not map_visible
		map_overlay.visible = map_visible
	m_was_down = m_down
	var h_down: bool = Input.is_key_pressed(KEY_H)
	if h_down and not h_was_down:
		help_visible = not help_visible
		help_panel.visible = help_visible
	h_was_down = h_down
	var t_down: bool = Input.is_key_pressed(KEY_T)
	if t_down and not t_was_down and not active_toast.is_empty():
		toast_timer = 0.0
	t_was_down = t_down
	var f3_down: bool = Input.is_key_pressed(KEY_F3)
	if f3_down and not f3_was_down:
		collision_debug_visible = not collision_debug_visible
		queue_redraw()
		_queue_note("Collision overlay %s." % ("ON" if collision_debug_visible else "OFF"), 3.0, false, "collision_toggle", 1.0)
	f3_was_down = f3_down

func _spawn_player() -> void:
	player = PlayerScript.new() as NecromancerPlayer
	player.health = clampi(GameState.player_health, 0, GameState.max_health)
	player.attacked.connect(_on_player_attacked)
	player.interact_requested.connect(_on_interact)
	player.interact_released.connect(_on_interact_released)
	player.hook_requested.connect(_on_hook_requested)
	player.hook_aim_released.connect(_on_hook_aim_released)
	player.command_requested.connect(_on_command_requested)
	player.health_changed.connect(_on_health_changed)
	player.hurt_received.connect(_on_player_hurt)
	player.hook_completed.connect(_on_hook_completed)
	actor_holder.add_child(player)
	game_camera = Camera2D.new()
	game_camera.position_smoothing_enabled = true
	game_camera.position_smoothing_speed = 8.0
	game_camera.limit_smoothed = true
	player.add_child(game_camera)
	game_camera.make_current()

func _spawn_persisted_allies() -> void:
	for index: int in range(GameState.army_size):
		var saved_role: int = GameState.army_roles[index] if index < GameState.army_roles.size() else RaisedGuard.Role.GUARD
		var saved_archetype: int = GameState.army_archetypes[index] if index < GameState.army_archetypes.size() else -1
		_spawn_raised_ally(Vector2(-200.0 - float(index) * 20.0, -200.0), false, index, saved_role, saved_archetype)

func _load_room(room_id_value: String, spawn_id: String, first_load: bool = false, override_position: Variant = null) -> void:
	if not ROOM_SCENES.has(room_id_value):
		_show_startup_error("Unknown room id: %s" % room_id_value)
		return
	_clear_room_runtime()
	var packed: PackedScene = load(str(ROOM_SCENES[room_id_value])) as PackedScene
	if packed == null:
		_show_startup_error("Unable to load barge room resource: %s" % room_id_value)
		return
	var instance: Node = packed.instantiate()
	if not instance is Node2D:
		_show_startup_error("Room scene did not instantiate as Node2D: %s" % room_id_value)
		return
	current_room = instance as Node2D
	var required_methods: Array[String] = ["get_spawn", "get_doors", "get_hook_anchors", "get_enemy_spawns", "get_breakable_spawns", "get_hazards", "get_safe_markers"]
	for method_name: String in required_methods:
		if not current_room.has_method(method_name):
			_show_startup_error("Room %s is missing runtime contract: %s" % [room_id_value, method_name])
			current_room.queue_free()
			current_room = null
			return
	room_holder.add_child(current_room)
	current_room_id = room_id_value
	GameState.current_room_id = current_room_id
	GameState.discover_room(current_room_id)
	_connect_room_nodes()
	_apply_room_persistence()
	_spawn_room_encounters()
	var spawn_marker: Marker2D = current_room.get_spawn(spawn_id)
	var spawn_position: Vector2 = spawn_marker.position if spawn_marker != null else Vector2(80.0, current_room.room_size.y - 40.0)
	if typeof(override_position) == TYPE_VECTOR2:
		spawn_position = override_position
	player.enter_room(spawn_position)
	_reform_party_at_entry()
	last_safe_position = spawn_position
	_configure_camera_for_room()
	_setup_room_pickups()
	_update_room_title()
	if not bool(shown_room_notes.get(current_room_id, false)):
		shown_room_notes[current_room_id] = true
		if not current_room.intro_note.is_empty():
			_queue_note(current_room.intro_note, 8.0, false, "room_%s" % current_room_id, 999.0)
	for door: Node in current_room.get_doors():
		door.arm_delay(0.42 if not first_load else 0.65)
		if not first_load and door.door_id == spawn_id:
			door.show_arrival_open(0.46)
	queue_redraw()

func _clear_room_runtime() -> void:
	_cancel_raise_ritual(false)
	hook_field_active = false
	if is_instance_valid(player):
		player.cancel_hook_aim()
	current_anchor = null
	hook_combat_target = null
	nearest_corpse = null
	enemies.clear()
	breakables.clear()
	dead_guard = null
	for child: Node in room_holder.get_children():
		room_holder.remove_child(child)
		child.queue_free()
	for child: Node in effects_holder.get_children():
		child.queue_free()

func _connect_room_nodes() -> void:
	for door: Node in current_room.get_doors():
		door.entered.connect(_on_door_entered)
	for hazard: Node in current_room.get_hazards():
		hazard.entered_hazard.connect(_on_hazard_entered)

func _apply_room_persistence() -> void:
	if current_room_id == "gate" and GameState.bone_gate_open:
		var gate: Node = current_room.get_node_or_null("Gameplay/BoneGate")
		if gate != null:
			gate.queue_free()
	if current_room_id == "gallery" and GameState.heart_shard_collected:
		var heart: Node = current_room.get_node_or_null("Gameplay/HeartShard")
		if heart != null:
			heart.visible = false
	if current_room_id == "chain" and GameState.has_grave_hook:
		var hook_pickup: Node = current_room.get_node_or_null("Gameplay/HookPickup")
		if hook_pickup != null:
			hook_pickup.visible = false

func _spawn_room_encounters() -> void:
	if current_room_id == "receiving" and not GameState.starting_guard_raised:
		dead_guard = GuardScript.new() as RaisedGuard
		dead_guard.position = Vector2(300.0, 300.0)
		dead_guard.player = player
		dead_guard.lost.connect(_on_ally_lost)
		dead_guard.damaged.connect(_on_ally_damaged)
		current_room.add_child(dead_guard)
	for spawn: Node in current_room.get_enemy_spawns():
		_spawn_enemy_from_marker(spawn)
	for spawn: Node in current_room.get_breakable_spawns():
		_spawn_breakable_from_marker(spawn)

func _spawn_enemy_from_marker(spawn: Node) -> void:
	var spawn_key: String = spawn.name
	var clear_status: String = GameState.enemy_clear_status(current_room_id, spawn_key)
	if clear_status == "raised":
		# Already living as an ally elsewhere; this spawn point stays empty for good.
		return
	var enemy: RaggedEnemy = EnemyScript.new() as RaggedEnemy
	enemy.position = spawn.position
	enemy.target = player
	enemy.archetype = spawn.archetype
	enemy.room_id = current_room_id
	enemy.room_bounds = Rect2(Vector2.ZERO, current_room.room_size)
	enemy.patrol_left = spawn.patrol_left
	enemy.patrol_right = spawn.patrol_right
	enemy.is_elite = spawn.elite
	enemy.attack_phase_offset = spawn.phase
	enemy.spawn_key = spawn_key
	var slot_offsets: Array[float] = [-64.0, -28.0, 28.0, 64.0]
	enemy.combat_slot_offset = slot_offsets[enemies.size() % slot_offsets.size()]
	enemy.died.connect(_on_enemy_died)
	enemy.projectile_requested.connect(_on_projectile_requested)
	enemy.alerted.connect(_on_enemy_alerted)
	enemy.damaged.connect(_on_enemy_damaged)
	enemy.support_pulsed.connect(_on_support_pulsed)
	current_room.add_child(enemy)
	if clear_status == "killed":
		enemy.mark_pre_dead()
	enemies.append(enemy)

func _spawn_breakable_from_marker(spawn: Node) -> void:
	var prop = BreakableScript.new()
	prop.position = spawn.position
	prop.prop_kind = spawn.prop_kind
	prop.drop_kind = spawn.drop_kind
	prop.drop_amount = spawn.drop_amount
	prop.health = spawn.health
	prop.broken.connect(_on_breakable_broken)
	current_room.add_child(prop)
	breakables.append(prop)

func _on_breakable_broken(prop, kind: String, amount: int) -> void:
	if not is_instance_valid(prop):
		return
	_spawn_pickup(prop.global_position + Vector2(0.0, -12.0), kind, amount)

func _spawn_pickup(position_value: Vector2, kind: String, amount: int) -> void:
	var pickup = PickupScript.new()
	pickup.position = position_value
	pickup.kind = kind
	pickup.amount = amount
	pickup.collected.connect(_on_pickup_collected)
	current_room.add_child(pickup)

func _on_pickup_collected(kind: String, amount: int) -> void:
	if kind == "flesh":
		player.heal(amount)
		_queue_note("A questionable red morsel restores flesh. Culinary standards remain wartime.", 5.4, false, "flesh_pickup", 12.0)
	else:
		GameState.add_grave_ash(amount)
		_queue_note("Grave ash pocketed. The dead continue to produce excellent loyalty points.", 5.4, false, "ash_pickup", 12.0)
	_update_hud()

func _configure_camera_for_room() -> void:
	if current_room == null or not is_instance_valid(game_camera):
		return
	game_camera.position = current_room.camera_offset
	game_camera.zoom = current_room.camera_zoom
	game_camera.limit_left = 0
	game_camera.limit_top = 0
	game_camera.limit_right = int(current_room.room_size.x)
	game_camera.limit_bottom = int(current_room.room_size.y + 38.0)

func _on_door_entered(door: Node) -> void:
	if transitioning or item_fanfare_active:
		return
	if current_room_id == "gate" and door.door_id == "right" and not GameState.bone_gate_open:
		_queue_note("The Rib Gate remains between you and the deck. Q has opinions about this now.", 6.8, true, "gate_exit_locked", 8.0)
		return
	if door.target_room == "END":
		if _active_enemy_count() > 0:
			_queue_note("The gangplank remains professionally occupied.", 5.0, false, "exit_blocked", 7.0)
			return
		GameState.slice_complete = true
		_queue_note("FIRST DAWN ROOM-SCENE PASS COMPLETE — shore leave remains aspirational.", 8.0, true, "slice_complete", 999.0)
		return
	_begin_room_transition(door.target_room, door.target_door, door.direction)

func _begin_room_transition(target_room: String, target_door: String, direction: String) -> void:
	if transitioning:
		return
	transitioning = true
	pending_room = target_room
	pending_door = target_door
	player.can_control = false
	_sync_army_state()
	_play_sfx("door", 0.96)
	transition_slit.visible = true
	transition_slit.position = Vector2.ZERO
	transition_slit.size = VIEWPORT_SIZE
	transition_slit.modulate.a = 1.0
	transition_slit.scale = Vector2.ONE
	if direction == "left":
		transition_slit.pivot_offset = Vector2(0.0, VIEWPORT_SIZE.y * 0.5)
		transition_slit.scale.x = 0.02
	elif direction == "right":
		transition_slit.pivot_offset = Vector2(VIEWPORT_SIZE.x, VIEWPORT_SIZE.y * 0.5)
		transition_slit.scale.x = 0.02
	elif direction == "up":
		transition_slit.pivot_offset = Vector2(VIEWPORT_SIZE.x * 0.5, 0.0)
		transition_slit.scale.y = 0.02
	else:
		transition_slit.pivot_offset = Vector2(VIEWPORT_SIZE.x * 0.5, VIEWPORT_SIZE.y)
		transition_slit.scale.y = 0.02
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(transition_slit, "scale", Vector2.ONE, 0.13)
	tween.tween_callback(_complete_room_transition.bind(direction))

func _complete_room_transition(_direction: String) -> void:
	_load_room(pending_room, pending_door, false)
	transition_slit.scale = Vector2.ONE
	transition_slit.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(transition_slit, "modulate:a", 0.0, 0.12)
	tween.tween_callback(_finish_room_transition)

func _finish_room_transition() -> void:
	transition_slit.visible = false
	transitioning = false
	player.can_control = true

func _reform_party_at_entry() -> void:
	for index: int in range(allies.size()):
		var ally: RaisedGuard = allies[index]
		if not is_instance_valid(ally):
			continue
		ally.global_position = player.global_position + Vector2(-28.0 - float(index) * 24.0, -2.0)
		ally.velocity = Vector2.ZERO
		ally.player = player
		ally.follow_slot = index
		ally.set_command(army_command_mode)

func _setup_room_pickups() -> void:
	if current_room_id == "gallery" and GameState.heart_shard_collected:
		var heart: Node = current_room.get_node_or_null("Gameplay/HeartShard")
		if heart != null:
			heart.visible = false

func _update_pickups() -> void:
	if current_room_id == "gallery" and not GameState.heart_shard_collected:
		var heart: Marker2D = current_room.get_node_or_null("Gameplay/HeartShard") as Marker2D
		if heart != null and player.global_position.distance_to(heart.global_position) < 22.0:
			GameState.collect_heart_shard()
			player.heal_to_full()
			heart.visible = false
			_queue_note("BLACK HEART SHARD: maximum flesh increased. Morale remains structurally unchanged.", 7.5, true, "heart_shard", 999.0)
	if current_room_id == "chain" and not GameState.has_grave_hook:
		var hook_pickup: Marker2D = current_room.get_node_or_null("Gameplay/HookPickup") as Marker2D
		if hook_pickup != null:
			hook_pickup.position.y = 306.0 + sin(Time.get_ticks_msec() * 0.004) * 3.0

func _on_interact() -> void:
	if not is_instance_valid(player):
		return
	if current_room_id == "chain" and not GameState.has_grave_hook:
		var hook_pickup: Marker2D = current_room.get_node_or_null("Gameplay/HookPickup") as Marker2D
		if hook_pickup != null and player.global_position.distance_to(hook_pickup.global_position) < 52.0:
			GameState.has_grave_hook = true
			GameState.hook_tutorial_complete = false
			GameState.checkpoint_valid = true
			GameState.checkpoint_room = "chain"
			GameState.checkpoint_local_position = Vector2(288.0, 318.0)
			player.heal_to_full()
			hook_pickup.visible = false
			_update_hud()
			_start_grave_hook_fanfare()
			return
	if not is_instance_valid(nearest_corpse):
		return
	if allies.size() >= GameState.MAX_ARMY_SIZE:
		_queue_note("Your grave-command is full. Management refuses a fourth direct report.", 6.5, false, "army_full", 8.0)
		return
	_start_raise_ritual(nearest_corpse)

func _on_interact_released() -> void:
	if raise_active and raise_progress < raise_required:
		_cancel_raise_ritual(false)

func _start_raise_ritual(target_value: Node2D) -> void:
	if raise_active or not is_instance_valid(target_value):
		return
	raise_target = target_value
	raise_progress = 0.0
	raise_required = 0.78
	if target_value is RaggedEnemy:
		var corpse := target_value as RaggedEnemy
		if corpse.archetype in [RaggedEnemy.Archetype.BRUTE, RaggedEnemy.Archetype.CHARGER]:
			raise_required = 1.18
		elif corpse.archetype == RaggedEnemy.Archetype.BILGE_CRAWLER:
			raise_required = 0.62
		elif corpse.archetype in [RaggedEnemy.Archetype.SENTRY, RaggedEnemy.Archetype.BELL_WRETCH, RaggedEnemy.Archetype.HANGED_SAILOR, RaggedEnemy.Archetype.BONE_CROW]:
			raise_required = 0.92
		elif corpse.archetype == RaggedEnemy.Archetype.COFFIN_MIMIC:
			raise_required = 1.08
	raise_active = true
	player.begin_ritual()
	queue_redraw()

func _update_raise_ritual(delta: float) -> void:
	if not raise_active:
		return
	if not is_instance_valid(raise_target) or not Input.is_key_pressed(KEY_E):
		_cancel_raise_ritual(false)
		return
	if player.global_position.distance_to(raise_target.global_position) > 66.0:
		_cancel_raise_ritual(false)
		return
	raise_progress += delta
	prompt_label.text = "RAISING  %d%%" % int(clampf(raise_progress / maxf(raise_required, 0.01), 0.0, 1.0) * 100.0)
	prompt_label.visible = true
	queue_redraw()
	if raise_progress >= raise_required:
		_complete_raise_ritual()

func _cancel_raise_ritual(show_note: bool = false) -> void:
	if not raise_active:
		return
	raise_active = false
	raise_progress = 0.0
	raise_target = null
	if is_instance_valid(player):
		player.end_ritual()
	if show_note:
		_queue_note("The ritual breaks. Death remains temporarily unionized.", 4.8, false, "raise_cancel", 8.0)
	queue_redraw()

func _complete_raise_ritual() -> void:
	if not raise_active or not is_instance_valid(raise_target):
		_cancel_raise_ritual(false)
		return
	var completed_target: Node2D = raise_target
	raise_active = false
	raise_progress = 0.0
	raise_target = null
	player.end_ritual()
	_spawn_raise_burst(completed_target.global_position)
	if completed_target == dead_guard:
		dead_guard.resurrect(true)
		dead_guard.reparent(actor_holder)
		dead_guard.player = player
		dead_guard.follow_slot = allies.size()
		dead_guard.set_command(army_command_mode)
		allies.append(dead_guard)
		GameState.starting_guard_raised = true
		_play_sfx("raise")
		_queue_note("Guard: I was off duty. This feels contractual.", 7.2, false, "first_guard", 999.0)
	elif completed_target is RaggedEnemy:
		var corpse: RaggedEnemy = completed_target as RaggedEnemy
		var corpse_position: Vector2 = corpse.global_position
		var raised_role: int = _role_for_corpse(corpse)
		GameState.mark_enemy_raised(current_room_id, corpse.spawn_key)
		corpse.mark_raised()
		_spawn_raised_ally(corpse_position, true, allies.size(), raised_role, int(corpse.archetype))
		_play_sfx("raise")
		_queue_note(_raise_role_note(raised_role), 7.2, false, "raise_role_%d" % raised_role, 12.0)
	_sync_army_state()
	nearest_corpse = null
	queue_redraw()

func _raise_role_note(role_value: int) -> String:
	match role_value:
		RaisedGuard.Role.BRUTE:
			return "The large one clocks back in. Benefits remain terrible; leverage improves."
		RaisedGuard.Role.SENTRY:
			return "Ranged support acquired. Previous performance review: attempted murder."
		_:
			return "A hostile corpse changes employers. The résumé is mostly transferable."


func _update_interaction_prompt() -> void:
	if raise_active:
		return
	nearest_corpse = null
	prompt_label.visible = false
	var nearest_distance: float = 52.0
	if is_instance_valid(dead_guard) and dead_guard.can_be_raised():
		var guard_distance: float = player.global_position.distance_to(dead_guard.global_position)
		if guard_distance < nearest_distance:
			nearest_corpse = dead_guard
			nearest_distance = guard_distance
	for enemy: RaggedEnemy in enemies:
		if not is_instance_valid(enemy) or not enemy.can_be_raised():
			continue
		var corpse_distance: float = player.global_position.distance_to(enemy.global_position)
		if corpse_distance < nearest_distance:
			nearest_corpse = enemy
			nearest_distance = corpse_distance
	if current_room_id == "chain" and not GameState.has_grave_hook:
		var hook_pickup: Marker2D = current_room.get_node_or_null("Gameplay/HookPickup") as Marker2D
		if hook_pickup != null and player.global_position.distance_to(hook_pickup.global_position) < 54.0:
			prompt_label.text = "[E] CLAIM THE GRAVE HOOK"
			prompt_label.visible = true
			return
	if is_instance_valid(nearest_corpse):
		prompt_label.text = "[E] ARMY FULL" if allies.size() >= GameState.MAX_ARMY_SIZE else "[HOLD E] RAISE THE DEAD"
		prompt_label.visible = true
		return
	if current_room_id == "gate" and not GameState.bone_gate_open and absf(player.global_position.x - 530.0) < 105.0:
		prompt_label.text = "[Q] TEST THE RIB GATE" if not GameState.has_grave_hook else "[Q] RIP OPEN THE RIB GATE"
		prompt_label.visible = true
		return
	if hook_field_active:
		prompt_label.text = "RELEASE Q — %s" % current_anchor.label if is_instance_valid(current_anchor) else "GRAVE FIELD — AIM WITH WASD / ARROWS"
		prompt_label.visible = true
		return
	if GameState.has_grave_hook and current_room.get_hook_anchors().size() > 0:
		prompt_label.text = "[HOLD Q] OPEN GRAVE FIELD"
		prompt_label.visible = true

func _update_anchor_guidance() -> void:
	current_anchor = null
	if current_room == null:
		return
	var anchors: Array = current_room.get_hook_anchors()
	if not GameState.has_grave_hook:
		for anchor: Node2D in anchors:
			anchor.set_visual_state(false, false)
		hook_hint_line.visible = false
		return

	var aim_direction: Vector2 = player.hook_aim_direction if player.hook_aiming else Vector2(player.facing, 0.0)
	var best_score: float = INF
	var available_count: int = 0
	for anchor: Node2D in anchors:
		var to_anchor: Vector2 = anchor.global_position - player.global_position
		var distance: float = to_anchor.length()
		var available: bool = distance <= minf(anchor.max_range, HOOK_FIELD_RADIUS) and player.global_position.distance_to(anchor.landing_position()) > 30.0
		if available:
			available_count += 1
		if player.hook_aiming and available:
			var direction_dot: float = aim_direction.normalized().dot(to_anchor.normalized())
			# Direction matters more than proximity; this prevents adjacent rings from stealing selection.
			if direction_dot > 0.12:
				var angular_penalty: float = (1.0 - direction_dot) * 420.0
				var score: float = angular_penalty + distance * 0.28
				if score < best_score:
					best_score = score
					current_anchor = anchor

	# With only one viable anchor, don't make the player fight an eight-way keyboard cone.
	if player.hook_aiming and current_anchor == null and available_count == 1:
		for anchor: Node2D in anchors:
			var distance: float = player.global_position.distance_to(anchor.global_position)
			if distance <= minf(anchor.max_range, HOOK_FIELD_RADIUS) and player.global_position.distance_to(anchor.landing_position()) > 30.0:
				current_anchor = anchor
				break

	for anchor: Node2D in anchors:
		var distance: float = player.global_position.distance_to(anchor.global_position)
		var available: bool = distance <= minf(anchor.max_range, HOOK_FIELD_RADIUS)
		anchor.set_visual_state(available, anchor == current_anchor)

	var show_line: bool = player.hook_aiming and is_instance_valid(current_anchor)
	hook_hint_line.visible = show_line
	if show_line:
		hook_hint_line.points = PackedVector2Array([player.global_position + Vector2(0.0, -24.0), current_anchor.global_position])
	queue_redraw()

func _on_hook_requested() -> void:
	if current_room_id == "gate" and not GameState.bone_gate_open and absf(player.global_position.x - 530.0) < 108.0:
		if not GameState.has_grave_hook:
			_queue_note("The ribs flex. You do not. Something made for pulling would change the argument.", 9.0, true, "gate_no_hook", 14.0)
			return
		_open_bone_gate()
		return
	if not GameState.has_grave_hook:
		_queue_note("Q currently performs a convincing gesture of intent.", 6.5, false, "no_hook", 16.0)
		return
	hook_field_active = true
	player.begin_hook_aim()
	prompt_label.text = "GRAVE FIELD — AIM WITH WASD / ARROWS, RELEASE Q"
	prompt_label.visible = true
	queue_redraw()

func _on_hook_aim_released(direction: Vector2) -> void:
	if not hook_field_active:
		return
	hook_field_active = false
	if is_instance_valid(current_anchor):
		var target_position: Vector2 = current_anchor.landing_position()
		chain_line.points = PackedVector2Array([player.global_position + Vector2(0.0, -24.0), current_anchor.global_position])
		chain_line_timer = 0.65
		_play_sfx("hook")
		player.start_hook(target_position)
		if not GameState.hook_tutorial_complete:
			GameState.hook_tutorial_complete = true
			_hide_persistent_tip()
			_queue_note("Grave Hook understood: hold Q, aim the grave field, release to commit.", 9.0, true, "hook_understood", 999.0)
		queue_redraw()
		return
	var pull_target: RaggedEnemy = _find_hook_enemy(direction)
	if is_instance_valid(pull_target) and pull_target.apply_hook_pull(player.global_position):
		chain_line.points = PackedVector2Array([player.global_position + Vector2(0.0, -24.0), pull_target.global_position + Vector2(0.0, -22.0)])
		chain_line_timer = 0.45
		_play_sfx("hook")
		queue_redraw()
		return
	queue_redraw()


func _open_bone_gate() -> void:
	GameState.bone_gate_open = true
	var gate: Node = current_room.get_node_or_null("Gameplay/BoneGate")
	if gate != null:
		gate.open_gate()
	_play_sfx("heavy_hit", 0.82)
	_queue_note("The Rib Gate finally loses the argument. Shortcut opened.", 7.2, true, "gate_open", 999.0)

func _update_poi_camera() -> void:
	if current_room == null or current_room.poi_id.is_empty() or current_room.poi_trigger_x < 0.0:
		return
	if bool(shown_pois.get(current_room.poi_id, false)):
		return
	if player.global_position.x < current_room.poi_trigger_x:
		return
	shown_pois[current_room.poi_id] = true
	var base_offset: Vector2 = current_room.camera_offset
	var focus_offset: Vector2 = base_offset + current_room.poi_focus_offset
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(game_camera, "position", focus_offset, 0.45)
	tween.tween_interval(0.45)
	tween.tween_property(game_camera, "position", base_offset, 0.6)
	if current_room.poi_id == "rib_gate":
		_queue_note("A sealed Rib Gate blocks the upper route. The broken hatch beneath it is less selective.", 9.5, true, "rib_gate_poi", 999.0)

func _on_hazard_entered(hazard: Node, body: Node) -> void:
	if transitioning:
		return
	if body is NecromancerPlayer:
		if not is_instance_valid(player):
			return
		player.take_damage(hazard.damage, player.global_position.x)
		player.global_position = last_safe_position
		player.velocity = Vector2.ZERO
		for ally: RaisedGuard in allies:
			if is_instance_valid(ally):
				ally.snap_near_player()
		_queue_note("Cold water, immediate regret, one flesh lighter.", 6.2, false, "water_recovery", 14.0)
	elif body is RaisedGuard:
		var ally: RaisedGuard = body as RaisedGuard
		if not is_instance_valid(ally):
			return
		ally.take_damage(hazard.damage, ally.global_position.x)
		if is_instance_valid(ally):
			ally.global_position = last_safe_position
			ally.velocity = Vector2.ZERO

func _update_last_safe_position(delta: float) -> void:
	safe_record_timer = maxf(0.0, safe_record_timer - delta)
	if safe_record_timer > 0.0 or not player.is_on_floor() or absf(player.velocity.y) > 8.0:
		return
	var best: Vector2 = player.global_position
	var best_distance: float = 100.0
	for marker: Marker2D in current_room.get_safe_markers():
		var distance: float = player.global_position.distance_to(marker.global_position)
		if distance < best_distance:
			best_distance = distance
			best = marker.global_position
	last_safe_position = best if best_distance < 100.0 else player.global_position
	safe_record_timer = 0.18

func _on_player_attacked(origin: Vector2, facing_value: float, attack_kind: String, combo_step: int, damage: int, reach: float) -> void:
	_spawn_slash_effect(origin, facing_value, combo_step)
	_play_sfx("swing", 0.94 + float(mini(combo_step, 3)) * 0.06)
	var confirmed_hit: bool = false
	for enemy: RaggedEnemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_hostile_active():
			continue
		var difference: Vector2 = enemy.global_position - origin
		var valid: bool = false
		match attack_kind:
			"anti_air":
				valid = absf(difference.x) < 38.0 and difference.y < 14.0 and difference.y > -92.0
			"plunge":
				valid = absf(difference.x) < 34.0 and difference.y > -8.0 and difference.y < 78.0
			_:
				var in_front: bool = absf(difference.x) <= 4.0 or signf(difference.x) == signf(facing_value)
				valid = absf(difference.x) < reach and in_front and absf(difference.y) < 40.0
		if valid and _combat_line_clear(origin, enemy.global_position):
			var heavy: bool = combo_step == 3 or combo_step == 6 or attack_kind == "plunge"
			confirmed_hit = enemy.take_hit(origin.x, damage, heavy) or confirmed_hit
	for prop in breakables:
		if not is_instance_valid(prop):
			continue
		var difference: Vector2 = prop.global_position - origin
		var in_front: bool = absf(difference.x) <= 5.0 or signf(difference.x) == signf(facing_value)
		if absf(difference.x) <= reach + 8.0 and absf(difference.y) <= 48.0 and in_front and _combat_line_clear(origin, prop.global_position):
			prop.hit(damage)
			confirmed_hit = true
	if confirmed_hit:
		player.confirm_hit(combo_step)

func _combat_line_clear(origin: Vector2, target_position: Vector2) -> bool:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(origin + Vector2(0.0, -23.0), target_position + Vector2(0.0, -22.0), 1)
	query.exclude = [player.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _on_projectile_requested(origin: Vector2, direction: Vector2, speed: float, damage: int, visual_kind: String = "bolt") -> void:
	var projectile: BoneProjectile = ProjectileScript.new() as BoneProjectile
	projectile.position = origin
	projectile.velocity = direction.normalized() * speed
	projectile.damage = damage
	projectile.owner_x = origin.x
	projectile.hostile = true
	projectile.visual_kind = visual_kind
	current_room.add_child(projectile)

func _on_ally_projectile_requested(origin: Vector2, direction: Vector2, speed: float, damage: int, visual_kind: String = "bolt") -> void:
	var projectile: BoneProjectile = ProjectileScript.new() as BoneProjectile
	projectile.position = origin
	projectile.velocity = direction.normalized() * speed
	projectile.damage = damage
	projectile.owner_x = origin.x
	projectile.hostile = false
	projectile.visual_kind = visual_kind
	current_room.add_child(projectile)

func _on_enemy_alerted(source: RaggedEnemy) -> void:
	_play_sfx("alert", 0.95)
	for enemy: RaggedEnemy in enemies:
		if is_instance_valid(enemy) and enemy != source and enemy.is_hostile_active() and enemy.global_position.distance_to(source.global_position) < 280.0:
			enemy.receive_alert(3.2)

func _on_enemy_died(_enemy: RaggedEnemy) -> void:
	if is_instance_valid(_enemy):
		var ash_amount: int = 2 if _enemy.archetype in [RaggedEnemy.Archetype.BRUTE, RaggedEnemy.Archetype.BELL_WRETCH, RaggedEnemy.Archetype.COFFIN_MIMIC] else 1
		_spawn_pickup(_enemy.global_position + Vector2(0.0, -14.0), "ash", ash_amount)
		GameState.mark_enemy_killed(current_room_id, _enemy.spawn_key)
	if not bool(corpse_note_rooms.get(current_room_id, false)):
		corpse_note_rooms[current_room_id] = true
		_queue_note("Corpse available. Previous qualifications include trying to kill you.", 8.0, false, "corpse_%s" % current_room_id, 999.0)

func _spawn_raised_ally(position_value: Vector2, play_rise: bool, slot: int, role_value: int = RaisedGuard.Role.GUARD, source_archetype: int = -1) -> void:
	var ally: RaisedGuard = GuardScript.new() as RaisedGuard
	ally.position = position_value
	ally.player = player
	ally.follow_slot = slot
	ally.role = role_value
	ally.source_archetype = source_archetype
	ally.command_mode = army_command_mode
	ally.lost.connect(_on_ally_lost)
	ally.projectile_requested.connect(_on_ally_projectile_requested)
	ally.damaged.connect(_on_ally_damaged)
	actor_holder.add_child(ally)
	ally.resurrect(play_rise)
	ally.set_command(army_command_mode)
	allies.append(ally)

func _refresh_allies() -> void:
	var changed: bool = false
	for index: int in range(allies.size() - 1, -1, -1):
		var ally: RaisedGuard = allies[index]
		if not is_instance_valid(ally):
			allies.remove_at(index)
			changed = true
			continue
		if ally.global_position.y > current_room.room_size.y + 100.0 or ally.global_position.distance_to(player.global_position) > 420.0:
			ally.global_position = _supported_party_position(index)
			ally.velocity = Vector2.ZERO
	if changed:
		_refresh_ally_slots()
		_sync_army_state()

func _supported_party_position(index: int) -> Vector2:
	var candidate: Vector2 = player.global_position + Vector2(-28.0 - float(index) * 22.0, -2.0)
	var ray_start: Vector2 = candidate + Vector2(0.0, -60.0)
	var ray_end: Vector2 = candidate + Vector2(0.0, 90.0)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(ray_start, ray_end, 1)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var hit_position: Vector2 = hit["position"]
		return Vector2(candidate.x, hit_position.y)
	return player.global_position

func _refresh_ally_slots() -> void:
	for index: int in range(allies.size()):
		if is_instance_valid(allies[index]):
			allies[index].follow_slot = index

func _on_ally_lost(ally: RaisedGuard) -> void:
	for index: int in range(allies.size() - 1, -1, -1):
		if allies[index] == ally:
			allies.remove_at(index)
	_refresh_ally_slots()
	_sync_army_state()
	_queue_note("A servant has become properly dead. Vacancy posted internally.", 7.0, false, "ally_lost", 12.0)

func _sync_army_state() -> void:
	var roles: Array[int] = []
	var archetypes: Array[int] = []
	for ally: RaisedGuard in allies:
		if is_instance_valid(ally):
			roles.append(int(ally.role))
			archetypes.append(int(ally.source_archetype))
	GameState.set_army_roster(roles, archetypes)
	_update_hud()

func _on_health_changed(value: int) -> void:
	GameState.player_health = maxi(value, 0)
	_update_hud()

func _on_command_requested() -> void:
	var direct := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direct.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direct.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direct.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direct.y += 1.0
	if direct.y < -0.5:
		army_command_mode = RaisedGuard.CommandMode.ASSAULT
		GameState.army_command_mode = army_command_mode
		_apply_army_command(false)
		_queue_note("ASSAULT: the department advances with deeply questionable enthusiasm.", 5.8, false, "cmd_assault", 4.0)
		_play_sfx("command")
		return
	if direct.y > 0.5:
		army_command_mode = RaisedGuard.CommandMode.FOLLOW
		GameState.army_command_mode = army_command_mode
		_apply_army_command(false)
		for ally: RaisedGuard in allies:
			if is_instance_valid(ally):
				ally.reform_near_player(true)
		_queue_note("RECALL: everybody back to the necromancer. Yes, even you.", 5.6, false, "cmd_recall", 4.0)
		_play_sfx("command")
		return
	if absf(direct.x) > 0.5:
		army_command_mode = RaisedGuard.CommandMode.HOLD
		GameState.army_command_mode = army_command_mode
		var target_x: float = clampf(player.global_position.x + signf(direct.x) * 118.0, 28.0, current_room.room_size.x - 28.0)
		var target := _floor_point_for_command(Vector2(target_x, player.global_position.y))
		for index: int in range(allies.size()):
			var ally: RaisedGuard = allies[index]
			if is_instance_valid(ally):
				ally.set_hold_position(target + Vector2(float(index) * 22.0 * -signf(direct.x), 0.0))
		_queue_note("HOLD THERE: a surprisingly literal interpretation of middle management.", 5.8, false, "cmd_hold_point", 4.0)
		_play_sfx("command")
		return
	army_command_mode = (army_command_mode + 1) % 3
	GameState.army_command_mode = army_command_mode
	_apply_army_command(true)

func _floor_point_for_command(preferred: Vector2) -> Vector2:
	var start: Vector2 = preferred + Vector2(0.0, -90.0)
	var finish: Vector2 = preferred + Vector2(0.0, 120.0)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, finish, 1)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		return hit["position"]
	return player.global_position

func _apply_army_command(show_note: bool) -> void:
	for ally: RaisedGuard in allies:
		if is_instance_valid(ally):
			ally.set_command(army_command_mode)
	if show_note:
		var names: Array[String] = ["FOLLOW", "HOLD", "ASSAULT"]
		_queue_note("Army order: %s." % names[army_command_mode], 3.8, false, "command", 1.0)
	_update_hud()

func _role_for_corpse(corpse: RaggedEnemy) -> int:
	if corpse.archetype in [RaggedEnemy.Archetype.BRUTE, RaggedEnemy.Archetype.CHARGER]:
		return RaisedGuard.Role.BRUTE
	if corpse.archetype in [RaggedEnemy.Archetype.SENTRY, RaggedEnemy.Archetype.BELL_WRETCH, RaggedEnemy.Archetype.LANTERN_TOSSER, RaggedEnemy.Archetype.BONE_CROW]:
		return RaisedGuard.Role.SENTRY
	if corpse.archetype == RaggedEnemy.Archetype.COFFIN_MIMIC:
		return RaisedGuard.Role.BRUTE
	if corpse.archetype == RaggedEnemy.Archetype.SHIELD_GUARD:
		return RaisedGuard.Role.GUARD
	return RaisedGuard.Role.GUARD

func _find_hook_enemy(direction: Vector2 = Vector2.ZERO) -> RaggedEnemy:
	var closest: RaggedEnemy = null
	var closest_score: float = INF
	var aim: Vector2 = direction.normalized() if direction.length() > 0.1 else Vector2(player.facing, 0.0)
	for enemy: RaggedEnemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_hostile_active():
			continue
		if enemy.archetype in [RaggedEnemy.Archetype.BRUTE, RaggedEnemy.Archetype.CHARGER, RaggedEnemy.Archetype.COFFIN_MIMIC] or enemy.is_elite:
			continue
		var difference: Vector2 = enemy.global_position - player.global_position
		var distance: float = difference.length()
		if distance > 180.0 or distance < 18.0:
			continue
		var dot: float = aim.dot(difference.normalized())
		if dot < 0.3:
			continue
		if not _combat_line_clear(player.global_position, enemy.global_position):
			continue
		var score: float = (1.0 - dot) * 240.0 + distance * 0.25
		if score < closest_score:
			closest = enemy
			closest_score = score
	return closest

func _active_enemy_count() -> int:
	var count: int = 0
	for enemy: RaggedEnemy in enemies:
		if is_instance_valid(enemy) and enemy.is_hostile_active():
			count += 1
	return count

func _restart_from_checkpoint() -> void:
	GameState.restart_room()
	player.health = GameState.player_health
	if GameState.checkpoint_valid:
		_load_room(GameState.checkpoint_room, "default", false, GameState.checkpoint_local_position)
	else:
		_load_room(current_room_id if not current_room_id.is_empty() else "receiving", "default", false)

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 30
	add_child(ui_layer)
	var top_bar: ColorRect = ColorRect.new()
	top_bar.position = Vector2(8.0, 8.0)
	top_bar.size = Vector2(624.0, 27.0)
	top_bar.color = Color(0.008, 0.008, 0.014, 0.9)
	ui_layer.add_child(top_bar)
	startup_error_label = Label.new()
	startup_error_label.position = Vector2(54.0, 126.0)
	startup_error_label.size = Vector2(532.0, 110.0)
	startup_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	startup_error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	startup_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	startup_error_label.add_theme_font_size_override("font_size", 13)
	startup_error_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.48, 1.0))
	startup_error_label.add_theme_constant_override("outline_size", 5)
	startup_error_label.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.01, 1.0))
	startup_error_label.visible = false
	ui_layer.add_child(startup_error_label)
	health_label = _hud_label(Vector2(18, 12), 12, Color.WHITE)
	army_label = _hud_label(Vector2(150, 12), 12, Color("#8fc5a5"))
	hook_label = _hud_label(Vector2(270, 12), 12, Color("#c889df"))
	command_label = _hud_label(Vector2(350, 13), 9, Color("#a7d8b6"))
	ash_label = _hud_label(Vector2(445, 13), 9, Color("#d6a5df"))
	var help_hint: Label = _hud_label(Vector2(540, 13), 8, Color(0.75, 0.72, 0.68, 0.9))
	help_hint.text = "M MAP  H"
	room_label = Label.new()
	room_label.position = Vector2(110.0, 42.0)
	room_label.size = Vector2(420.0, 28.0)
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_label.add_theme_font_size_override("font_size", 14)
	room_label.add_theme_color_override("font_color", Color("#e2b45c"))
	room_label.add_theme_constant_override("outline_size", 4)
	room_label.add_theme_color_override("font_outline_color", Color(0.01, 0.01, 0.015, 0.95))
	ui_layer.add_child(room_label)
	toast_panel = ColorRect.new()
	toast_panel.position = Vector2(42.0, 314.0)
	toast_panel.size = Vector2(556.0, 38.0)
	toast_panel.color = Color(0.008, 0.008, 0.014, 0.94)
	toast_panel.visible = false
	ui_layer.add_child(toast_panel)
	toast_label = Label.new()
	toast_label.position = Vector2(12.0, 3.0)
	toast_label.size = Vector2(532.0, 31.0)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_font_size_override("font_size", 10)
	toast_panel.add_child(toast_label)
	prompt_label = Label.new()
	prompt_label.position = Vector2(110.0, 278.0)
	prompt_label.size = Vector2(420.0, 26.0)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 12)
	prompt_label.add_theme_color_override("font_color", Color("#f0ba55"))
	prompt_label.add_theme_constant_override("outline_size", 4)
	prompt_label.add_theme_color_override("font_outline_color", Color(0.01, 0.01, 0.015, 0.98))
	ui_layer.add_child(prompt_label)
	tutorial_panel = ColorRect.new()
	tutorial_panel.position = Vector2(420.0, 46.0)
	tutorial_panel.size = Vector2(205.0, 88.0)
	tutorial_panel.color = Color(0.045, 0.02, 0.06, 0.94)
	tutorial_panel.visible = false
	ui_layer.add_child(tutorial_panel)
	tutorial_title = Label.new()
	tutorial_title.position = Vector2(9.0, 6.0)
	tutorial_title.size = Vector2(188.0, 20.0)
	tutorial_title.add_theme_font_size_override("font_size", 11)
	tutorial_title.add_theme_color_override("font_color", Color("#d99ced"))
	tutorial_panel.add_child(tutorial_title)
	tutorial_body = Label.new()
	tutorial_body.position = Vector2(9.0, 27.0)
	tutorial_body.size = Vector2(188.0, 54.0)
	tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_body.add_theme_font_size_override("font_size", 8)
	tutorial_panel.add_child(tutorial_body)
	help_panel = ColorRect.new()
	help_panel.position = Vector2(130.0, 50.0)
	help_panel.size = Vector2(380.0, 250.0)
	help_panel.color = Color(0.012, 0.012, 0.022, 0.98)
	help_panel.visible = false
	ui_layer.add_child(help_panel)
	var help_text: Label = Label.new()
	help_text.position = Vector2(18, 14)
	help_text.size = Vector2(344, 222)
	help_text.text = "CONTROLS\nA/D or arrows  Move\nSPACE / W / Up  Jump\nF / click  Three-hit combo\nUP + F  Rising cut\nDOWN + F in air  Plunge\nHOLD E near corpse  Raise ritual\nHOLD Q  Grave field; aim with WASD/arrows; release to Hook\nC  Cycle army posture\nDirection + C  Assault / Recall / Hold there\nM  Map\nT  Dismiss note\nR  Restart checkpoint\nF3  Collision overlay\nH  Close\n\nRooms own their doors, enemies, collisions and Hook anchors. The barge is a chain of authored compartments, not one open-world canvas."
	help_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_text.add_theme_font_size_override("font_size", 10)
	help_panel.add_child(help_text)
	map_overlay = MapScript.new() as BargeMapOverlay
	map_overlay.position = Vector2(40.0, 20.0)
	map_overlay.visible = false
	ui_layer.add_child(map_overlay)
	transition_slit = ColorRect.new()
	transition_slit.position = Vector2.ZERO
	transition_slit.size = VIEWPORT_SIZE
	transition_slit.color = Color(0.005, 0.005, 0.008, 1.0)
	transition_slit.modulate.a = 0.0
	transition_slit.visible = false
	transition_slit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(transition_slit)
	_build_item_fanfare_ui()
	hook_hint_line = Line2D.new()
	hook_hint_line.width = 1.2
	hook_hint_line.default_color = Color(0.72, 0.35, 0.88, 0.62)
	hook_hint_line.visible = false
	add_child(hook_hint_line)
	chain_line = Line2D.new()
	chain_line.width = 2.2
	chain_line.default_color = Color(0.76, 0.42, 0.9, 0.85)
	chain_line.visible = false
	add_child(chain_line)

func _show_startup_error(message: String) -> void:
	push_error(message)
	if is_instance_valid(startup_error_label):
		startup_error_label.text = "ROOM LOAD ERROR\n" + message + "\n\nSend this message back with the debugger's first error."
		startup_error_label.visible = true

func _hud_label(position_value: Vector2, size_value: int, color_value: Color) -> Label:
	var label: Label = Label.new()
	label.position = position_value
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color_value)
	ui_layer.add_child(label)
	return label

func _build_item_fanfare_ui() -> void:
	item_fanfare_flash = ColorRect.new()
	item_fanfare_flash.position = Vector2.ZERO
	item_fanfare_flash.size = VIEWPORT_SIZE
	item_fanfare_flash.color = Color(0.56, 0.18, 0.7, 0.0)
	item_fanfare_flash.visible = false
	item_fanfare_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(item_fanfare_flash)
	item_fanfare_panel = ColorRect.new()
	item_fanfare_panel.position = Vector2(88.0, 82.0)
	item_fanfare_panel.size = Vector2(464.0, 190.0)
	item_fanfare_panel.color = Color(0.025, 0.012, 0.04, 0.98)
	item_fanfare_panel.visible = false
	ui_layer.add_child(item_fanfare_panel)
	item_fanfare_title = Label.new()
	item_fanfare_title.position = Vector2(20, 25)
	item_fanfare_title.size = Vector2(424, 44)
	item_fanfare_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_fanfare_title.add_theme_font_size_override("font_size", 24)
	item_fanfare_title.add_theme_color_override("font_color", Color("#e6a8ff"))
	item_fanfare_panel.add_child(item_fanfare_title)
	item_fanfare_body = Label.new()
	item_fanfare_body.position = Vector2(38, 82)
	item_fanfare_body.size = Vector2(388, 78)
	item_fanfare_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_fanfare_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_fanfare_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_fanfare_body.add_theme_font_size_override("font_size", 12)
	item_fanfare_panel.add_child(item_fanfare_body)

func _update_room_title() -> void:
	room_label.text = current_room.room_title
	if is_instance_valid(room_title_tween):
		room_title_tween.kill()
	room_label.modulate.a = 1.0
	room_title_tween = create_tween()
	room_title_tween.tween_interval(2.7)
	room_title_tween.tween_property(room_label, "modulate:a", 0.0, 0.6)

func _update_hud() -> void:
	if not is_instance_valid(player):
		return
	health_label.text = "FLESH %d/%d" % [maxi(player.health, 0), GameState.max_health]
	army_label.text = "DEAD %d/%d" % [allies.size(), GameState.MAX_ARMY_SIZE]
	hook_label.text = "HOOK Q" if GameState.has_grave_hook else "HOOK —"
	var command_names: Array[String] = ["FOLLOW", "HOLD", "ASSAULT"]
	command_label.text = "C %s" % command_names[army_command_mode]
	ash_label.text = "ASH %d" % GameState.grave_ash

func _update_map() -> void:
	map_overlay.update_map(current_room_id, player.global_position, GameState.discovered_rooms, GameState.has_grave_hook, GameState.bone_gate_open, GameState.heart_shard_collected)

func _queue_note(message: String, duration: float = -1.0, priority: bool = false, key: String = "", cooldown: float = 0.0) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if not key.is_empty() and float(note_cooldowns.get(key, -9999.0)) > now:
		return
	if not key.is_empty():
		note_cooldowns[key] = now + cooldown
	var actual_duration: float = duration
	if actual_duration < 0.0:
		actual_duration = clampf(4.8 + float(message.length()) * 0.055, 6.0, 10.5)
	var note: Dictionary = {"message": message, "duration": actual_duration, "priority": priority}
	if priority:
		toast_queue.clear()
		active_toast = note
		toast_timer = actual_duration
		toast_panel.visible = true
		toast_label.text = message
		return
	if active_toast.is_empty() and toast_gap_timer <= 0.0:
		active_toast = note
		toast_timer = actual_duration
		toast_panel.visible = true
		toast_label.text = message
	elif toast_queue.is_empty():
		toast_queue.append(note)

func _update_toasts(delta: float) -> void:
	toast_gap_timer = maxf(0.0, toast_gap_timer - delta)
	if active_toast.is_empty():
		if toast_gap_timer <= 0.0 and not toast_queue.is_empty():
			_show_next_toast()
		return
	toast_timer -= delta
	if toast_timer <= 0.0:
		active_toast = {}
		toast_panel.visible = false
		toast_gap_timer = 1.15

func _show_next_toast() -> void:
	if toast_queue.is_empty():
		return
	active_toast = toast_queue.pop_front()
	toast_timer = float(active_toast["duration"])
	toast_label.text = str(active_toast["message"])
	toast_panel.visible = true

func _start_grave_hook_fanfare() -> void:
	item_fanfare_active = true
	item_fanfare_timer = 2.9
	player.can_control = false
	for enemy: RaggedEnemy in enemies:
		if is_instance_valid(enemy):
			enemy.set_physics_process(false)
	for ally: RaisedGuard in allies:
		if is_instance_valid(ally):
			ally.set_physics_process(false)
	item_fanfare_flash.visible = true
	item_fanfare_flash.color = Color(0.56, 0.18, 0.7, 0.34)
	item_fanfare_panel.visible = true
	item_fanfare_title.text = "GRAVE HOOK"
	item_fanfare_body.text = "A grave-iron chain that answers directional intent.\nHold Q: open the grave field. Aim with WASD / arrows. Release: commit.\nAlso tears the Rib Gate and drags light enemies."
	_play_sfx("relic")

func _update_item_fanfare(delta: float) -> void:
	item_fanfare_timer -= delta
	item_fanfare_flash.color.a = maxf(0.0, item_fanfare_flash.color.a - delta * 0.18)
	if item_fanfare_timer <= 0.0:
		_finish_grave_hook_fanfare()

func _finish_grave_hook_fanfare() -> void:
	item_fanfare_active = false
	item_fanfare_panel.visible = false
	item_fanfare_flash.visible = false
	player.can_control = true
	for enemy: RaggedEnemy in enemies:
		if is_instance_valid(enemy):
			enemy.set_physics_process(true)
	for ally: RaisedGuard in allies:
		if is_instance_valid(ally):
			ally.set_physics_process(true)
	_show_hook_tutorial()

func _show_hook_tutorial() -> void:
	tutorial_panel.visible = true
	tutorial_title.text = "GRAVE HOOK — Q"
	tutorial_body.text = "Hold Q to open the grave field. Aim with WASD / arrows; release Q to commit to the highlighted violet anchor. Indoor pulls stay local to this room."

func _hide_persistent_tip() -> void:
	tutorial_panel.visible = false

func _build_audio() -> void:
	var sounds: Dictionary = {
		"swing": "res://assets/audio/swing.wav", "hit": "res://assets/audio/hit.wav", "heavy_hit": "res://assets/audio/heavy_hit.wav",
		"raise": "res://assets/audio/raise.wav", "hook": "res://assets/audio/hook.wav", "relic": "res://assets/audio/relic.wav",
		"command": "res://assets/audio/command.wav", "alert": "res://assets/audio/alert.wav", "hurt": "res://assets/audio/hurt.wav", "door": "res://assets/audio/door.wav"
	}
	for key: String in sounds.keys():
		var audio: AudioStreamPlayer = AudioStreamPlayer.new()
		audio.stream = load(str(sounds[key])) as AudioStream
		audio.volume_db = -5.0
		add_child(audio)
		sfx_players[key] = audio
	# A slot for the user's temporary Castlevania reference track. Nothing copyrighted ships here.
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -12.0
	add_child(music_player)
	for candidate: String in ["res://assets/music/reference_water_level.ogg", "res://assets/music/reference_water_level.mp3", "res://assets/music/reference_water_level.wav"]:
		if ResourceLoader.exists(candidate):
			music_player.stream = load(candidate) as AudioStream
			music_player.finished.connect(music_player.play)
			music_player.play()
			break

func _play_sfx(key: String, pitch: float = 1.0) -> void:
	if not sfx_players.has(key):
		return
	var audio: AudioStreamPlayer = sfx_players[key] as AudioStreamPlayer
	audio.pitch_scale = pitch
	audio.play()

func _on_enemy_damaged(position_value: Vector2, _amount: int, heavy: bool) -> void:
	_spawn_impact_effect(position_value, heavy)
	_play_sfx("heavy_hit" if heavy else "hit", 0.94)
	_trigger_hitstop(48 if heavy else 28, 0.2 if heavy else 0.32)
	shake_timer = 0.12 if heavy else 0.07
	shake_strength = 3.4 if heavy else 1.7

func _on_ally_damaged(position_value: Vector2, _amount: int, heavy: bool) -> void:
	_spawn_impact_effect(position_value, heavy)
	_play_sfx("hurt", 0.9)

func _on_player_hurt(position_value: Vector2) -> void:
	_cancel_raise_ritual(false)
	hook_field_active = false
	if is_instance_valid(player):
		player.cancel_hook_aim()
	_play_sfx("hurt")
	_spawn_impact_effect(position_value, false)
	shake_timer = 0.12
	shake_strength = 2.5

func _on_hook_completed(_position_value: Vector2) -> void:
	_play_sfx("hook", 1.08)
	for ally: RaisedGuard in allies:
		if is_instance_valid(ally) and ally.global_position.distance_to(player.global_position) > 180.0:
			ally.global_position = _supported_party_position(ally.follow_slot)
			ally.velocity = Vector2.ZERO

func _on_support_pulsed(position_value: Vector2) -> void:
	_spawn_support_pulse(position_value)
	_play_sfx("alert", 0.75)

func _trigger_hitstop(milliseconds: int, scale: float) -> void:
	hitstop_end_msec = maxi(hitstop_end_msec, Time.get_ticks_msec() + milliseconds)
	Engine.time_scale = scale

func _update_combat_feedback(delta: float) -> void:
	if hitstop_end_msec > 0 and Time.get_ticks_msec() >= hitstop_end_msec:
		Engine.time_scale = 1.0
		hitstop_end_msec = 0
	if shake_timer > 0.0 and is_instance_valid(game_camera):
		shake_timer = maxf(0.0, shake_timer - delta)
		game_camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	else:
		if is_instance_valid(game_camera):
			game_camera.offset = Vector2.ZERO

func _spawn_raise_burst(position_value: Vector2) -> void:
	var ring := Line2D.new()
	var points := PackedVector2Array()
	for index: int in range(33):
		var angle: float = TAU * float(index) / 32.0
		points.append(position_value + Vector2(cos(angle), sin(angle)) * 18.0)
	ring.points = points
	ring.width = 2.6
	ring.default_color = Color(0.68, 0.25, 0.88, 0.92)
	effects_holder.add_child(ring)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(2.6, 2.6), 0.34)
	tween.tween_property(ring, "modulate:a", 0.0, 0.34)
	tween.chain().tween_callback(ring.queue_free)

func _spawn_slash_effect(origin: Vector2, facing_value: float, combo_step: int) -> void:
	var slash: Line2D = Line2D.new()
	slash.width = 2.2 + float(combo_step) * 0.8
	slash.default_color = Color(0.76, 0.52, 0.92, 0.82)
	var reach: float = 28.0 + float(combo_step) * 5.0
	slash.points = PackedVector2Array([origin + Vector2(facing_value * 8.0, -30.0), origin + Vector2(facing_value * reach, -22.0), origin + Vector2(facing_value * (reach + 7.0), -10.0)])
	effects_holder.add_child(slash)
	var tween: Tween = create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.16)
	tween.tween_callback(slash.queue_free)

func _spawn_impact_effect(position_value: Vector2, heavy: bool) -> void:
	var impact: Polygon2D = Polygon2D.new()
	impact.position = position_value + Vector2(0.0, -24.0)
	var radius: float = 11.0 if heavy else 7.0
	impact.polygon = PackedVector2Array([Vector2(0,-radius),Vector2(radius,0),Vector2(0,radius),Vector2(-radius,0)])
	impact.color = Color(0.9, 0.68, 0.35, 0.9) if heavy else Color(0.82, 0.45, 0.72, 0.84)
	effects_holder.add_child(impact)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(impact, "scale", Vector2(1.8,1.8), 0.14)
	tween.tween_property(impact, "modulate:a", 0.0, 0.14)
	tween.chain().tween_callback(impact.queue_free)

func _spawn_support_pulse(position_value: Vector2) -> void:
	var ring: Line2D = Line2D.new()
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(25):
		var angle: float = TAU * float(index) / 24.0
		points.append(position_value + Vector2(cos(angle), sin(angle)) * 26.0)
	ring.points = points
	ring.width = 2.0
	ring.default_color = Color(0.95, 0.74, 0.3, 0.75)
	effects_holder.add_child(ring)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(1.8,1.8), 0.28)
	tween.tween_property(ring, "modulate:a", 0.0, 0.28)
	tween.chain().tween_callback(ring.queue_free)

func _draw() -> void:
	if is_instance_valid(player) and hook_field_active:
		draw_arc(player.global_position + Vector2(0.0, -20.0), HOOK_FIELD_RADIUS, 0.0, TAU, 72, Color(0.55, 0.22, 0.72, 0.22), 2.0)
		var aim_end: Vector2 = player.global_position + Vector2(0.0, -20.0) + player.hook_aim_direction * 78.0
		draw_line(player.global_position + Vector2(0.0, -20.0), aim_end, Color(0.74, 0.4, 0.9, 0.7), 2.0)
	if raise_active and is_instance_valid(raise_target):
		var ratio: float = clampf(raise_progress / maxf(raise_required, 0.01), 0.0, 1.0)
		var center: Vector2 = raise_target.global_position + Vector2(0.0, -18.0)
		draw_circle(center, 23.0, Color(0.24, 0.05, 0.34, 0.28))
		draw_arc(center, 25.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 36, Color(0.78, 0.35, 0.94, 0.96), 3.0)
	if not collision_debug_visible or current_room == null:
		return
	for node: Node in current_room.get_node("Gameplay/Collision").get_children():
		if node is StaticBody2D:
			for child: Node in node.get_children():
				if child is CollisionShape2D and (child as CollisionShape2D).shape is RectangleShape2D:
					var cs: CollisionShape2D = child as CollisionShape2D
					var shape: RectangleShape2D = cs.shape as RectangleShape2D
					var rect: Rect2 = Rect2((node as Node2D).position - shape.size * 0.5, shape.size)
					var color: Color = Color(0.2,0.9,1.0,0.3) if cs.one_way_collision else Color(0.25,1.0,0.3,0.3)
					draw_rect(rect, color, true)
					draw_rect(rect, Color(color.r,color.g,color.b,0.9), false, 1.0)
	if is_instance_valid(player):
		draw_rect(Rect2(player.global_position + Vector2(-7,-38),Vector2(14,38)),Color.WHITE,false,1.3)
	for enemy: RaggedEnemy in enemies:
		if is_instance_valid(enemy) and enemy.is_hostile_active():
			draw_rect(Rect2(enemy.global_position + Vector2(-7,-37),Vector2(14,37)),Color(1,0.3,0.25,0.95),false,1.2)
	for ally: RaisedGuard in allies:
		if is_instance_valid(ally):
			draw_rect(Rect2(ally.global_position + Vector2(-7,-38),Vector2(14,38)),Color(0.55,1,0.72,0.95),false,1.2)
