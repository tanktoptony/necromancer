extends Node2D

const PlayerScript: Script = preload("res://scripts/player.gd")
const EnemyScript: Script = preload("res://scripts/enemy.gd")
const GuardScript: Script = preload("res://scripts/guard.gd")

@export var room_key: String = "cargo_hold"

var room_data: Dictionary
var player: NecromancerPlayer
var enemies: Array[RaggedEnemy] = []
var allies: Array[RaisedGuard] = []
var dead_guard: RaisedGuard
var status_label: Label
var health_label: Label
var army_label: Label
var prompt_label: Label
var room_label: Label
var fade_rect: ColorRect
var transitioning: bool = false
var r_was_down: bool = false
var nearest_corpse: Node2D
var status_timer: float = 0.0

func _ready() -> void:
	room_data = _room_database()[room_key]
	GameState.current_room = room_key
	_build_background()
	_build_collision()
	_build_ui()
	_spawn_actors()
	_begin_fade_in()
	_show_note(str(room_data.get("intro", "")), 3.6)

func _process(delta: float) -> void:
	status_timer = maxf(0.0, status_timer - delta)
	if status_timer <= 0.0 and is_instance_valid(status_label) and player != null and player.health > 0 and not GameState.slice_complete:
		status_label.text = str(room_data.get("intro", ""))

	var r_down: bool = Input.is_key_pressed(KEY_R)
	if r_down and not r_was_down:
		GameState.restart_room()
		get_tree().reload_current_scene()
	r_was_down = r_down

	if not is_instance_valid(player):
		return

	_refresh_allies()
	_update_corpse_prompt()
	if player.health <= 0:
		status_label.text = "Death is temporary. Press R to restart this room."
		return
	if transitioning:
		return

	if player.global_position.x > 390.0:
		var next_scene: String = str(room_data.get("next_scene", ""))
		if next_scene.is_empty():
			player.global_position.x = 376.0
			if _active_enemy_count() == 0:
				GameState.slice_complete = true
				_show_note("THE OSSUARY GATE OPENS — FIRST DAWN VERTICAL SLICE COMPLETE", 5.0)
			else:
				_show_note("The ossuary gate is sealed while the dead still walk.", 2.5)
		else:
			_begin_transition(next_scene, "left")
	elif player.global_position.x < -6.0:
		var previous_scene: String = str(room_data.get("previous_scene", ""))
		if previous_scene.is_empty():
			player.global_position.x = 8.0
		else:
			_begin_transition(previous_scene, "right")

func _room_database() -> Dictionary:
	return {
		"cargo_hold": {
			"title": "I. THE RECEIVING HOLD",
			"background": "res://assets/backgrounds/cargo_hold.png",
			"previous_scene": "",
			"next_scene": "res://scenes/rooms/storehouse.tscn",
			"start_position": Vector2(58.0, 166.0),
			"enemy_positions": [Vector2(302.0, 166.0)],
			"enemy_health": [3],
			"elite_indices": [],
			"dead_guard_position": Vector2(198.0, 166.0),
			"platforms": [],
			"intro": "The guard is dead. The shrouded thing is not."
		},
		"storehouse": {
			"title": "II. THE CORPSE STOREHOUSE",
			"background": "res://assets/backgrounds/storehouse.png",
			"previous_scene": "res://main.tscn",
			"next_scene": "res://scenes/rooms/graveyard_gate.tscn",
			"start_position": Vector2(28.0, 166.0),
			"enemy_positions": [Vector2(210.0, 166.0), Vector2(318.0, 166.0)],
			"enemy_health": [3, 3],
			"elite_indices": [],
			"dead_guard_position": Vector2(-999.0, -999.0),
			"platforms": [Rect2(88.0, 150.0, 92.0, 8.0), Rect2(250.0, 132.0, 70.0, 8.0)],
			"intro": "Anything you kill can become another pair of hands. Army limit: three."
		},
		"graveyard_gate": {
			"title": "III. THE OSSUARY GATE",
			"background": "res://assets/backgrounds/graveyard_gate.png",
			"previous_scene": "res://scenes/rooms/storehouse.tscn",
			"next_scene": "",
			"start_position": Vector2(28.0, 166.0),
			"enemy_positions": [Vector2(212.0, 166.0), Vector2(302.0, 166.0)],
			"enemy_health": [3, 7],
			"elite_indices": [1],
			"dead_guard_position": Vector2(-999.0, -999.0),
			"platforms": [],
			"intro": "Break the gatekeeper and carry your dead into the dawn."
		}
	}

func _build_background() -> void:
	var texture: Texture2D = load(str(room_data["background"])) as Texture2D
	if texture != null:
		var sprite_node: Sprite2D = Sprite2D.new()
		sprite_node.texture = texture
		sprite_node.position = Vector2(192.0, 108.0)
		sprite_node.z_index = -20
		add_child(sprite_node)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.01, 0.015, 0.025, 0.14)
	shade.size = Vector2(384.0, 216.0)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.z_index = -19
	add_child(shade)
	_build_exit_markers()

func _build_exit_markers() -> void:
	var left_marker: ColorRect = ColorRect.new()
	left_marker.position = Vector2(0.0, 78.0)
	left_marker.size = Vector2(7.0, 120.0)
	left_marker.color = Color(0.08, 0.06, 0.05, 0.45)
	left_marker.z_index = 2
	add_child(left_marker)
	var right_marker: ColorRect = ColorRect.new()
	right_marker.position = Vector2(377.0, 78.0)
	right_marker.size = Vector2(7.0, 120.0)
	right_marker.color = Color(0.08, 0.06, 0.05, 0.45)
	right_marker.z_index = 2
	add_child(right_marker)

func _build_collision() -> void:
	var floor_body: StaticBody2D = StaticBody2D.new()
	var floor_collision: CollisionShape2D = CollisionShape2D.new()
	var floor_shape: RectangleShape2D = RectangleShape2D.new()
	floor_shape.size = Vector2(384.0, 36.0)
	floor_collision.shape = floor_shape
	floor_collision.position = Vector2(192.0, 216.0)
	floor_body.add_child(floor_collision)
	add_child(floor_body)

	var platforms: Array = room_data.get("platforms", [])
	for platform_value: Variant in platforms:
		var platform_rect: Rect2 = platform_value
		var platform_body: StaticBody2D = StaticBody2D.new()
		var platform_collision: CollisionShape2D = CollisionShape2D.new()
		var platform_shape: RectangleShape2D = RectangleShape2D.new()
		platform_shape.size = platform_rect.size
		platform_collision.shape = platform_shape
		platform_collision.position = platform_rect.position + platform_rect.size * 0.5
		platform_collision.one_way_collision = true
		platform_collision.one_way_collision_margin = 6.0
		platform_body.add_child(platform_collision)
		add_child(platform_body)
		var platform_art: ColorRect = ColorRect.new()
		platform_art.position = platform_rect.position
		platform_art.size = platform_rect.size
		platform_art.color = Color(0.16, 0.11, 0.09, 0.62)
		platform_art.z_index = 1
		add_child(platform_art)

func _build_ui() -> void:
	var ui_layer: CanvasLayer = CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)
	var panel: ColorRect = ColorRect.new()
	panel.color = Color(0.015, 0.015, 0.02, 0.84)
	panel.position = Vector2(5.0, 5.0)
	panel.size = Vector2(374.0, 40.0)
	ui_layer.add_child(panel)

	room_label = Label.new()
	room_label.text = str(room_data["title"])
	room_label.position = Vector2(10.0, 7.0)
	room_label.add_theme_font_size_override("font_size", 10)
	room_label.add_theme_color_override("font_color", Color("#e2b45c"))
	ui_layer.add_child(room_label)

	var controls: Label = Label.new()
	controls.text = "A/D move   SPACE jump   F/click attack   E raise   R restart"
	controls.position = Vector2(137.0, 7.0)
	controls.add_theme_font_size_override("font_size", 8)
	ui_layer.add_child(controls)

	health_label = Label.new()
	health_label.position = Vector2(10.0, 23.0)
	health_label.add_theme_font_size_override("font_size", 9)
	ui_layer.add_child(health_label)

	army_label = Label.new()
	army_label.position = Vector2(77.0, 23.0)
	army_label.add_theme_font_size_override("font_size", 9)
	army_label.add_theme_color_override("font_color", Color("#8fc5a5"))
	ui_layer.add_child(army_label)

	status_label = Label.new()
	status_label.text = str(room_data["intro"])
	status_label.position = Vector2(143.0, 23.0)
	status_label.add_theme_font_size_override("font_size", 8)
	ui_layer.add_child(status_label)

	prompt_label = Label.new()
	prompt_label.position = Vector2(111.0, 145.0)
	prompt_label.add_theme_font_size_override("font_size", 11)
	prompt_label.add_theme_color_override("font_color", Color("#f0ba55"))
	prompt_label.visible = false
	ui_layer.add_child(prompt_label)

	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.position = Vector2.ZERO
	fade_rect.size = Vector2(384.0, 216.0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.modulate.a = 0.0
	ui_layer.add_child(fade_rect)

func _spawn_actors() -> void:
	player = PlayerScript.new() as NecromancerPlayer
	player.health = clampi(GameState.player_health, 0, GameState.MAX_HEALTH)
	player.position = _entry_position()
	player.attacked.connect(_on_player_attacked)
	player.interact_requested.connect(_on_interact)
	player.health_changed.connect(_on_health_changed)
	add_child(player)

	var enemy_positions: Array = room_data.get("enemy_positions", [])
	var enemy_health_values: Array = room_data.get("enemy_health", [])
	var elite_indices: Array = room_data.get("elite_indices", [])
	for index: int in range(enemy_positions.size()):
		var enemy: RaggedEnemy = EnemyScript.new() as RaggedEnemy
		enemy.position = enemy_positions[index]
		enemy.target = player
		enemy.max_health = int(enemy_health_values[index])
		enemy.is_elite = elite_indices.has(index)
		if enemy.is_elite:
			enemy.move_speed = 57.0
		enemy.died.connect(_on_enemy_died)
		add_child(enemy)
		enemies.append(enemy)

	var dead_guard_position: Vector2 = room_data.get("dead_guard_position", Vector2(-999.0, -999.0))
	if dead_guard_position.x > -500.0 and GameState.army_size == 0:
		dead_guard = GuardScript.new() as RaisedGuard
		dead_guard.position = dead_guard_position
		dead_guard.player = player
		dead_guard.lost.connect(_on_ally_lost)
		add_child(dead_guard)

	for ally_index: int in range(GameState.army_size):
		var offset: Vector2 = Vector2(-22.0 - float(ally_index) * 16.0, -4.0)
		_spawn_raised_ally(player.position + offset, false, ally_index)

	_on_health_changed(player.health)
	_update_army_label()

func _entry_position() -> Vector2:
	if GameState.entry_side == "left":
		return Vector2(24.0, 166.0)
	if GameState.entry_side == "right":
		return Vector2(360.0, 166.0)
	return room_data.get("start_position", Vector2(58.0, 166.0))

func _on_player_attacked(origin: Vector2, facing: float, _combo_step: int = 1, damage: int = 1, reach: float = 39.0) -> void:
	for enemy_value: Variant in enemies:
		if not is_instance_valid(enemy_value):
			continue
		var enemy: RaggedEnemy = enemy_value as RaggedEnemy
		if not enemy.is_hostile_active():
			continue
		var delta_x: float = enemy.global_position.x - origin.x
		if absf(delta_x) < reach and signf(delta_x) == signf(facing) and absf(enemy.global_position.y - origin.y) < 34.0:
			enemy.take_hit(origin.x, damage, _combo_step == 3)

func _on_interact() -> void:
	if not is_instance_valid(nearest_corpse):
		return
	if allies.size() >= GameState.MAX_ARMY_SIZE:
		_show_note("Your grave-command is full. Three servants answer you.", 2.3)
		return

	if nearest_corpse == dead_guard:
		dead_guard.resurrect(true)
		dead_guard.follow_slot = allies.size()
		allies.append(dead_guard)
		_show_note("Guard: Am I under arrest? He follows and attacks automatically.", 3.2)
	elif nearest_corpse is RaggedEnemy:
		var corpse_enemy: RaggedEnemy = nearest_corpse as RaggedEnemy
		var corpse_position: Vector2 = corpse_enemy.global_position
		corpse_enemy.mark_raised()
		_spawn_raised_ally(corpse_position, true, allies.size())
		_show_note("A hostile corpse changes employers.", 2.2)
	_sync_army_state()
	nearest_corpse = null
	prompt_label.visible = false

func _spawn_raised_ally(spawn_position: Vector2, play_rise: bool, slot: int) -> void:
	var ally: RaisedGuard = GuardScript.new() as RaisedGuard
	ally.position = spawn_position
	ally.player = player
	ally.follow_slot = slot
	ally.lost.connect(_on_ally_lost)
	add_child(ally)
	ally.resurrect(play_rise)
	allies.append(ally)

func _update_corpse_prompt() -> void:
	nearest_corpse = null
	var nearest_distance: float = 48.0
	if is_instance_valid(dead_guard) and dead_guard.can_be_raised():
		var guard_distance: float = player.global_position.distance_to(dead_guard.global_position)
		if guard_distance < nearest_distance:
			nearest_corpse = dead_guard
			nearest_distance = guard_distance

	for enemy_value: Variant in enemies:
		if not is_instance_valid(enemy_value):
			continue
		var enemy: RaggedEnemy = enemy_value as RaggedEnemy
		if enemy.can_be_raised():
			var enemy_distance: float = player.global_position.distance_to(enemy.global_position)
			if enemy_distance < nearest_distance:
				nearest_corpse = enemy
				nearest_distance = enemy_distance

	prompt_label.visible = is_instance_valid(nearest_corpse)
	if prompt_label.visible:
		prompt_label.text = "[E] ARMY FULL" if allies.size() >= GameState.MAX_ARMY_SIZE else "[E] RAISE THE DEAD"

func _on_enemy_died(_enemy: RaggedEnemy) -> void:
	if _active_enemy_count() == 0:
		if room_key == "graveyard_gate":
			_show_note("The gatekeeper falls. Raise what remains, then cross the right edge.", 4.0)
		else:
			_show_note("The room is quiet. Corpses remain useful.", 2.6)
	else:
		_show_note("One corpse felled. Press E nearby to recruit it.", 2.4)

func _active_enemy_count() -> int:
	var count: int = 0
	for enemy_value: Variant in enemies:
		if is_instance_valid(enemy_value) and enemy_value.is_hostile_active():
			count += 1
	return count

func _on_health_changed(value: int) -> void:
	GameState.player_health = maxi(value, 0)
	health_label.text = "FLESH: %d/%d" % [maxi(value, 0), GameState.MAX_HEALTH]

func _update_army_label() -> void:
	army_label.text = "DEAD: %d/%d" % [allies.size(), GameState.MAX_ARMY_SIZE]

func _begin_transition(scene_path: String, new_entry_side: String) -> void:
	if transitioning:
		return
	transitioning = true
	player.can_control = false
	_sync_army_state()
	GameState.entry_side = new_entry_side
	GameState.just_transitioned = true
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.18)
	tween.tween_callback(_change_scene.bind(scene_path))

func _change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

func _begin_fade_in() -> void:
	if GameState.just_transitioned:
		fade_rect.modulate.a = 1.0
		var tween: Tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 0.0, 0.22)
		GameState.just_transitioned = false
	else:
		fade_rect.modulate.a = 0.0

func _refresh_allies() -> void:
	var changed: bool = false
	for index: int in range(allies.size() - 1, -1, -1):
		var ally: RaisedGuard = allies[index]
		if not is_instance_valid(ally):
			allies.remove_at(index)
			changed = true
			continue
		if ally.global_position.y > 260.0:
			ally.queue_free()
			allies.remove_at(index)
			changed = true
		elif ally.global_position.distance_to(player.global_position) > 220.0:
			ally.snap_near_player()
	if changed:
		_refresh_ally_slots()
		_sync_army_state()

func _refresh_ally_slots() -> void:
	for index: int in range(allies.size()):
		if is_instance_valid(allies[index]):
			allies[index].follow_slot = index

func _sync_army_state() -> void:
	GameState.set_army_size(allies.size())
	_update_army_label()

func _on_ally_lost(ally: RaisedGuard) -> void:
	for index: int in range(allies.size() - 1, -1, -1):
		if allies[index] == ally:
			allies.remove_at(index)
	_refresh_ally_slots()
	_sync_army_state()
	_show_note("One servant drops out of formation. The dead are not known for balance.", 3.0)

func _show_note(message: String, duration: float = 2.5) -> void:
	status_label.text = message
	status_timer = duration
