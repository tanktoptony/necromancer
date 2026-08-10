extends Node2D

const PlayerScript: Script = preload("res://scripts/player.gd")
const EnemyScript: Script = preload("res://scripts/enemy.gd")
const GuardScript: Script = preload("res://scripts/guard.gd")
const ProjectileScript: Script = preload("res://scripts/projectile.gd")
const MapScript: Script = preload("res://scripts/map_overlay.gd")
const VFX_SLASH_1: Texture2D = preload("res://assets/vfx/slash_1.png")
const VFX_SLASH_2: Texture2D = preload("res://assets/vfx/slash_2.png")
const VFX_SLASH_3: Texture2D = preload("res://assets/vfx/slash_3.png")
const VFX_IMPACT_LIGHT: Texture2D = preload("res://assets/vfx/impact_light.png")
const VFX_IMPACT_HEAVY: Texture2D = preload("res://assets/vfx/impact_heavy.png")
const VFX_SUPPORT_PULSE: Texture2D = preload("res://assets/vfx/support_pulse.png")

const WORLD_SIZE: Vector2 = Vector2(4992.0, 972.0)
const VIEWPORT_SIZE: Vector2 = Vector2(640.0, 360.0)
const HOOK_PICKUP_POSITION: Vector2 = Vector2(3000.0, 934.0)
const HEART_SHARD_POSITION: Vector2 = Vector2(1090.0, 272.0)
const BONE_GATE_X: float = 2380.0
const PIT_RECOVERY_Y: float = 850.0
const WORLD_RECOVERY_Y: float = 1002.0

var rooms: Dictionary = {
	"receiving": {"rect": Rect2(0.0, 324.0, 768.0, 324.0), "title": "I. THE RECEIVING HOLD", "safe": Vector2(120.0, 620.0)},
	"gallery": {"rect": Rect2(768.0, 0.0, 1152.0, 648.0), "title": "II. THE QUARANTINE GALLERY", "safe": Vector2(830.0, 620.0)},
	"gate": {"rect": Rect2(1920.0, 324.0, 768.0, 324.0), "title": "III. THE RIB GATE", "safe": Vector2(1985.0, 620.0)},
	"bilge": {"rect": Rect2(1728.0, 648.0, 960.0, 324.0), "title": "IV. THE DROWNED HOLD", "safe": Vector2(2100.0, 754.0)},
	"chain": {"rect": Rect2(2688.0, 648.0, 576.0, 324.0), "title": "V. THE CHAIN CRYPT", "safe": Vector2(2745.0, 944.0)},
	"shaft": {"rect": Rect2(3264.0, 648.0, 384.0, 324.0), "title": "VI. THE WINCH SHAFT", "safe": Vector2(3315.0, 944.0)},
	"orlop": {"rect": Rect2(2688.0, 324.0, 1152.0, 324.0), "title": "VII. THE UPPER ORLOP", "safe": Vector2(2760.0, 620.0)},
	"deck": {"rect": Rect2(3840.0, 324.0, 1152.0, 324.0), "title": "VIII. THE OSSUARY DECK", "safe": Vector2(3910.0, 620.0)}
}

var anchors: Array[Dictionary] = [
	{"position": Vector2(1090.0, 230.0), "target": Vector2(1090.0, 273.0), "range": 300.0, "id": "heart_gantry", "label": "BLACK HEART GANTRY"},
	{"position": Vector2(1288.0, 330.0), "target": Vector2(1288.0, 363.0), "range": 300.0, "id": "gallery_center", "label": "GALLERY CROSSBEAM"},
	{"position": Vector2(1575.0, 238.0), "target": Vector2(1575.0, 273.0), "range": 330.0, "id": "gallery_upper", "label": "UPPER GALLERY"},
	{"position": Vector2(1760.0, 440.0), "target": Vector2(1760.0, 480.0), "range": 280.0, "id": "gallery_right", "label": "QUARANTINE SHELF"},
	{"position": Vector2(2570.0, 715.0), "target": Vector2(2580.0, 773.0), "range": 310.0, "id": "bilge_return", "label": "DROWNED HOLD RETURN"},
	{"position": Vector2(3525.0, 755.0), "target": Vector2(3500.0, 818.0), "range": 300.0, "id": "shaft_upper", "label": "UPPER WINCH"},
	{"position": Vector2(3090.0, 548.0), "target": Vector2(2768.0, 618.0), "range": 560.0, "id": "orlop_return", "label": "UPPER ORLOP"},
	{"position": Vector2(4240.0, 470.0), "target": Vector2(4200.0, 566.0), "range": 260.0, "id": "deck_mast", "label": "OSSUARY MAST"}
]

var player: NecromancerPlayer
var enemies: Array[RaggedEnemy] = []
var allies: Array[RaisedGuard] = []
var dead_guard: RaisedGuard
var nearest_corpse: Node2D
var current_room_id: String = ""
var shown_room_tips: Dictionary = {}
var gate_body: StaticBody2D
var gate_visual: Node2D
var hook_pickup_visual: Node2D
var heart_shard_visual: Node2D
var chain_line: Line2D
var hook_hint_line: Line2D
var chain_line_timer: float = 0.0
var current_anchor: Dictionary = {}
var last_hook_anchor_id: String = ""

var ui_layer: CanvasLayer
var health_label: Label
var army_label: Label
var hook_label: Label
var command_label: Label
var room_label: Label
var toast_panel: ColorRect
var toast_label: Label
var prompt_label: Label
var controls_label: Label
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
var room_title_tween: Tween
var r_was_down: bool = false
var m_was_down: bool = false
var h_was_down: bool = false
var t_was_down: bool = false
var death_note_shown: bool = false
var f3_was_down: bool = false
var collision_debug_visible: bool = false
var collision_solid_rects: Array[Rect2] = []
var collision_one_way_rects: Array[Rect2] = []
var collision_hazard_rects: Array[Rect2] = []
var collision_hook_only_rects: Array[Rect2] = []
var last_safe_position: Vector2 = Vector2(120.0, 620.0)
var safe_record_timer: float = 0.0
var item_fanfare_panel: ColorRect
var item_fanfare_flash: ColorRect
var item_fanfare_title: Label
var item_fanfare_body: Label
var item_fanfare_active: bool = false
var item_fanfare_timer: float = 0.0
var item_fanfare_tween: Tween
var game_camera: Camera2D
var army_command_mode: int = 0
var sfx_players: Dictionary = {}
var hitstop_end_msec: int = 0
var shake_timer: float = 0.0
var shake_strength: float = 0.0
var hook_combat_target: RaggedEnemy
var note_cooldowns: Dictionary = {}
var vista_rooms_shown: Dictionary = {}
var gate_tease_seen: bool = false

func _ready() -> void:
	_build_world_art()
	_build_world_collision()
	_build_gate()
	_build_anchors()
	_build_pickups()
	_build_audio()
	_build_ui()
	_spawn_player()
	_spawn_encounters()
	_spawn_persisted_allies()
	army_command_mode = GameState.army_command_mode
	_apply_army_command(false)
	_update_hud()
	_update_room(true)
	last_safe_position = player.global_position
	queue_redraw()
	_queue_note("The corpse barge is larger than it looked from shore. That is rarely good news for the night shift.", 8.5, false, "opening", 999.0)
	if GameState.has_grave_hook and not GameState.hook_tutorial_complete:
		_show_hook_tutorial()

func _process(delta: float) -> void:
	_update_combat_feedback(delta)
	if collision_debug_visible:
		queue_redraw()
	_update_toasts(delta)
	chain_line_timer = maxf(0.0, chain_line_timer - delta)
	if is_instance_valid(chain_line):
		chain_line.visible = chain_line_timer > 0.0

	if item_fanfare_active:
		_update_item_fanfare(delta)
		return

	var r_down: bool = Input.is_key_pressed(KEY_R)
	if r_down and not r_was_down:
		GameState.restart_room()
		get_tree().reload_current_scene()
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
	if t_down and not t_was_down and not active_toast.is_empty() and toast_timer < 900.0:
		toast_timer = 0.0
	t_was_down = t_down

	var f3_down: bool = Input.is_key_pressed(KEY_F3)
	if f3_down and not f3_was_down:
		collision_debug_visible = not collision_debug_visible
		queue_redraw()
		_queue_note("Collision overlay %s. Green world, cyan jumpable, violet Hook-only, red hazard; white/player, red/enemy, mint/ally." % ("ON" if collision_debug_visible else "OFF"), 4.0)
	f3_was_down = f3_down

	if not is_instance_valid(player):
		return

	_refresh_allies()
	_update_room(false)
	_update_pickups()
	_update_anchor_guidance()
	_update_interaction_prompt()
	_update_map()
	_update_last_safe_position(delta)

	if (current_room_id == "bilge" and player.global_position.y > PIT_RECOVERY_Y) or player.global_position.y > WORLD_RECOVERY_Y:
		_recover_from_pit()

	if player.health <= 0:
		if not death_note_shown:
			death_note_shown = true
			_queue_note("Death is temporary. The paperwork is not. Press R.", 999.0, true)
		return
	death_note_shown = false

	player.global_position.x = clampf(player.global_position.x, 8.0, WORLD_SIZE.x - 8.0)
	if player.global_position.x > WORLD_SIZE.x - 18.0:
		if _active_enemies_in_room("deck") == 0:
			GameState.slice_complete = true
			player.global_position.x = WORLD_SIZE.x - 24.0
			_queue_note("FIRST DAWN SETPIECE PASS COMPLETE — the shore is now someone else's problem.", 7.0)
		else:
			player.global_position.x = WORLD_SIZE.x - 26.0
			_queue_note("The exit remains professionally occupied.", 6.0)

func _build_world_art() -> void:
	var darkness: Polygon2D = Polygon2D.new()
	darkness.polygon = PackedVector2Array([Vector2.ZERO, Vector2(WORLD_SIZE.x, 0.0), WORLD_SIZE, Vector2(0.0, WORLD_SIZE.y)])
	darkness.color = Color(0.004, 0.004, 0.007, 1.0)
	darkness.z_index = -40
	add_child(darkness)

	_add_background("res://assets/vania07/receiving_hold.png", Vector2(384.0, 486.0))
	_add_background("res://assets/vania07/quarantine_gallery.png", Vector2(1344.0, 324.0))
	_add_background("res://assets/vania07/bone_gate_landing.png", Vector2(2304.0, 486.0))
	_add_background("res://assets/vania07/drowned_hold.png", Vector2(2208.0, 810.0))
	_add_background("res://assets/vania07/chain_crypt.png", Vector2(2976.0, 810.0))
	_add_background("res://assets/vania07/winch_shaft_tall.png", Vector2(3456.0, 648.0))
	_add_background("res://assets/vania07/upper_orlop.png", Vector2(3264.0, 486.0))
	_add_background("res://assets/vania07/storm_deck.png", Vector2(4416.0, 486.0))
	_add_prop_sprite("res://assets/vania07/gallery_step.png", Vector2(835.0, 615.0), 3)
	_add_prop_sprite("res://assets/vania07/gallery_step.png", Vector2(915.0, 563.0), 3)
	_add_prop_sprite("res://assets/vania07/gallery_step.png", Vector2(995.0, 513.0), 3)

	# Unbuilt negative space is deliberately black so a room reads as a place, not a tiled wallpaper.
	_add_dark_filler(Rect2(0.0, 0.0, 768.0, 324.0))
	_add_dark_filler(Rect2(0.0, 648.0, 1728.0, 324.0))
	_add_dark_filler(Rect2(3840.0, 648.0, 1152.0, 324.0))

	# Thick foreground timbers sell depth and divide the large spaces without creating collision.
	for timber_x: float in [760.0, 1912.0, 2680.0, 3832.0]:
		var timber: Line2D = Line2D.new()
		timber.width = 10.0
		timber.default_color = Color(0.025, 0.018, 0.016, 0.72)
		timber.points = PackedVector2Array([Vector2(timber_x, 300.0), Vector2(timber_x, 660.0)])
		timber.z_index = 12
		add_child(timber)

func _add_background(path: String, position_value: Vector2) -> void:
	var sprite_node: Sprite2D = Sprite2D.new()
	sprite_node.texture = load(path) as Texture2D
	sprite_node.position = position_value
	sprite_node.z_index = -20
	add_child(sprite_node)

func _add_prop_sprite(path: String, position_value: Vector2, z_value: int = 2) -> void:
	var sprite_node: Sprite2D = Sprite2D.new()
	sprite_node.texture = load(path) as Texture2D
	sprite_node.position = position_value
	sprite_node.z_index = z_value
	add_child(sprite_node)

func _add_dark_filler(rect: Rect2) -> void:
	var polygon: Polygon2D = Polygon2D.new()
	polygon.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	polygon.color = Color(0.006, 0.006, 0.009, 1.0)
	polygon.z_index = -19
	add_child(polygon)

func _build_world_collision() -> void:
	_add_static_rect(Rect2(-18.0, 0.0, 18.0, WORLD_SIZE.y), false)
	_add_static_rect(Rect2(WORLD_SIZE.x, 0.0, 18.0, WORLD_SIZE.y), false)

	# Main deck: long continuous runs remove room-seam snags. The only break is the authored hatch.
	_add_static_rect(Rect2(0.0, 620.0, 2080.0, 40.0), false)
	_add_static_rect(Rect2(2170.0, 620.0, 545.0, 40.0), false)
	var orlop_hatch: Rect2 = Rect2(2708.0, 620.0, 144.0, 12.0)
	_add_static_rect(orlop_hatch, true)
	collision_hook_only_rects.append(orlop_hatch)
	_add_static_rect(Rect2(2845.0, 620.0, 2147.0, 40.0), false)

	# Quarantine Gallery: visible cargo steps form the normal route to the first shelf.
	_add_static_rect(Rect2(766.0, 572.0, 138.0, 12.0), true)
	_add_static_rect(Rect2(846.0, 520.0, 138.0, 12.0), true)
	_add_static_rect(Rect2(926.0, 470.0, 138.0, 12.0), true)
	_add_static_rect(Rect2(873.0, 448.0, 265.0, 12.0), true)
	# Higher existing shelves are intentionally Hook-gated and align with the artwork.
	var gallery_center: Rect2 = Rect2(1184.0, 365.0, 204.0, 12.0)
	var gallery_upper_left: Rect2 = Rect2(1038.0, 275.0, 100.0, 12.0)
	var gallery_upper_right: Rect2 = Rect2(1476.0, 275.0, 214.0, 12.0)
	var gallery_right: Rect2 = Rect2(1681.0, 482.0, 172.0, 12.0)
	for gallery_platform: Rect2 in [gallery_center, gallery_upper_left, gallery_upper_right, gallery_right]:
		_add_static_rect(gallery_platform, true)
		collision_hook_only_rects.append(gallery_platform)

	# The Rib Gate landing has an obvious hatch. Falling is the intended route before the Hook.

	# Drowned Hold collision traces the four visible wooden decks exactly enough to read at a glance.
	_add_static_rect(Rect2(1750.0, 803.0, 192.0, 12.0), true)
	_add_static_rect(Rect2(2018.0, 756.0, 187.0, 12.0), true)
	_add_static_rect(Rect2(2229.0, 826.0, 179.0, 12.0), true)
	_add_static_rect(Rect2(2493.0, 775.0, 170.0, 12.0), true)
	_add_hazard_rect(Rect2(1728.0, 850.0, 960.0, 122.0))

	# Chain Crypt is a safe acquisition chamber, intentionally calmer than the Hold.
	_add_static_rect(Rect2(2688.0, 944.0, 576.0, 28.0), false)

	# Winch Shaft: the first visible shelf is a normal staging ledge; the second requires the Hook.
	_add_static_rect(Rect2(3290.0, 910.0, 125.0, 12.0), true)
	var shaft_upper: Rect2 = Rect2(3498.0, 820.0, 124.0, 12.0)
	_add_static_rect(shaft_upper, true)
	collision_hook_only_rects.append(shaft_upper)

	# Upper Orlop and Ossuary Deck ride the continuous main-deck collider above.
	_add_static_rect(Rect2(3060.0, 565.0, 190.0, 12.0), true)
	_add_static_rect(Rect2(3380.0, 520.0, 180.0, 12.0), true)
	_add_static_rect(Rect2(4090.0, 565.0, 180.0, 12.0), true)
	_add_static_rect(Rect2(4380.0, 520.0, 210.0, 12.0), true)

func _add_static_rect(rect: Rect2, one_way: bool) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.position = rect.position + rect.size * 0.5
	collision.one_way_collision = one_way
	collision.one_way_collision_margin = 7.0
	body.add_child(collision)
	add_child(body)
	if one_way:
		collision_one_way_rects.append(rect)
	else:
		collision_solid_rects.append(rect)
	return body

func _add_hazard_rect(rect: Rect2) -> void:
	collision_hazard_rects.append(rect)

func _build_gate() -> void:
	gate_body = StaticBody2D.new()
	gate_body.collision_layer = 1
	gate_body.collision_mask = 0
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(22.0, 220.0)
	collision.shape = shape
	collision.position = Vector2(BONE_GATE_X, 510.0)
	gate_body.add_child(collision)
	add_child(gate_body)

	gate_visual = Node2D.new()
	gate_visual.position = Vector2(BONE_GATE_X, 400.0)
	gate_visual.z_index = 6
	for offset: float in [-8.0, 0.0, 8.0]:
		var rib: Line2D = Line2D.new()
		rib.width = 5.0
		rib.default_color = Color(0.72, 0.67, 0.54, 1.0)
		rib.points = PackedVector2Array([Vector2(offset, 0.0), Vector2(offset + sin(offset) * 3.0, 220.0)])
		gate_visual.add_child(rib)
	for y: float in [28.0, 78.0, 128.0, 178.0]:
		var cross: Line2D = Line2D.new()
		cross.width = 4.0
		cross.default_color = Color(0.48, 0.39, 0.3, 1.0)
		cross.points = PackedVector2Array([Vector2(-16.0, y), Vector2(16.0, y + 5.0)])
		gate_visual.add_child(cross)
	add_child(gate_visual)
	if GameState.bone_gate_open:
		gate_body.queue_free()
		gate_visual.visible = false

func _build_anchors() -> void:
	for anchor_data: Dictionary in anchors:
		var anchor: Node2D = Node2D.new()
		anchor.position = anchor_data["position"]
		anchor.z_index = 6
		var ring: Line2D = Line2D.new()
		ring.width = 2.0
		ring.default_color = Color(0.56, 0.37, 0.68, 0.68)
		var points: PackedVector2Array = PackedVector2Array()
		for index: int in range(17):
			var angle: float = TAU * float(index) / 16.0
			points.append(Vector2(cos(angle), sin(angle)) * 7.0)
		ring.points = points
		anchor.add_child(ring)
		var chain: Line2D = Line2D.new()
		chain.width = 2.0
		chain.default_color = Color(0.23, 0.2, 0.24, 0.78)
		chain.points = PackedVector2Array([Vector2(0.0, -38.0), Vector2.ZERO])
		anchor.add_child(chain)
		add_child(anchor)
		anchor_data["visual"] = anchor

	chain_line = Line2D.new()
	chain_line.width = 3.0
	chain_line.default_color = Color(0.78, 0.48, 0.9, 0.95)
	chain_line.z_index = 9
	chain_line.visible = false
	add_child(chain_line)

	hook_hint_line = Line2D.new()
	hook_hint_line.width = 1.0
	hook_hint_line.default_color = Color(0.67, 0.42, 0.8, 0.42)
	hook_hint_line.z_index = 8
	hook_hint_line.visible = false
	add_child(hook_hint_line)

func _build_pickups() -> void:
	hook_pickup_visual = Node2D.new()
	hook_pickup_visual.position = HOOK_PICKUP_POSITION
	hook_pickup_visual.z_index = 7
	var hook: Line2D = Line2D.new()
	hook.width = 3.0
	hook.default_color = Color(0.88, 0.62, 0.96, 1.0)
	hook.points = PackedVector2Array([Vector2(0.0, -22.0), Vector2(0.0, -6.0), Vector2(9.0, 1.0), Vector2(6.0, 11.0), Vector2(-3.0, 13.0)])
	hook_pickup_visual.add_child(hook)
	var glow: Polygon2D = Polygon2D.new()
	glow.polygon = PackedVector2Array([Vector2(-15.0, -10.0), Vector2(0.0, -30.0), Vector2(15.0, -10.0), Vector2(12.0, 14.0), Vector2(-12.0, 14.0)])
	glow.color = Color(0.5, 0.14, 0.68, 0.3)
	hook_pickup_visual.add_child(glow)
	add_child(hook_pickup_visual)
	hook_pickup_visual.visible = not GameState.has_grave_hook

	heart_shard_visual = Node2D.new()
	heart_shard_visual.position = HEART_SHARD_POSITION
	heart_shard_visual.z_index = 7
	var heart: Polygon2D = Polygon2D.new()
	heart.polygon = PackedVector2Array([Vector2(0.0, 8.0), Vector2(-9.0, -2.0), Vector2(-6.0, -9.0), Vector2(0.0, -6.0), Vector2(6.0, -9.0), Vector2(9.0, -2.0)])
	heart.color = Color(0.78, 0.14, 0.32, 0.95)
	heart_shard_visual.add_child(heart)
	add_child(heart_shard_visual)
	heart_shard_visual.visible = not GameState.heart_shard_collected

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 30
	add_child(ui_layer)

	var top_bar: ColorRect = ColorRect.new()
	top_bar.position = Vector2(8.0, 8.0)
	top_bar.size = Vector2(624.0, 30.0)
	top_bar.color = Color(0.01, 0.01, 0.018, 0.9)
	ui_layer.add_child(top_bar)

	health_label = Label.new()
	health_label.position = Vector2(18.0, 13.0)
	health_label.add_theme_font_size_override("font_size", 12)
	ui_layer.add_child(health_label)

	army_label = Label.new()
	army_label.position = Vector2(150.0, 13.0)
	army_label.add_theme_font_size_override("font_size", 12)
	army_label.add_theme_color_override("font_color", Color("#8fc5a5"))
	ui_layer.add_child(army_label)

	hook_label = Label.new()
	hook_label.position = Vector2(270.0, 13.0)
	hook_label.add_theme_font_size_override("font_size", 12)
	hook_label.add_theme_color_override("font_color", Color("#c889df"))
	ui_layer.add_child(hook_label)

	command_label = Label.new()
	command_label.position = Vector2(362.0, 14.0)
	command_label.add_theme_font_size_override("font_size", 9)
	command_label.add_theme_color_override("font_color", Color("#a7d8b6"))
	ui_layer.add_child(command_label)

	controls_label = Label.new()
	controls_label.text = "C CMD  M MAP  H HELP"
	controls_label.position = Vector2(490.0, 14.0)
	controls_label.add_theme_font_size_override("font_size", 8)
	controls_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.76, 0.9))
	ui_layer.add_child(controls_label)

	room_label = Label.new()
	room_label.position = Vector2(110.0, 44.0)
	room_label.size = Vector2(420.0, 28.0)
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_label.add_theme_font_size_override("font_size", 15)
	room_label.add_theme_color_override("font_color", Color("#e2b45c"))
	room_label.add_theme_constant_override("outline_size", 4)
	room_label.add_theme_color_override("font_outline_color", Color(0.01, 0.01, 0.015, 0.95))
	ui_layer.add_child(room_label)

	# Notes live in a dedicated lower strip. The camera keeps actors above it.
	toast_panel = ColorRect.new()
	toast_panel.position = Vector2(8.0, 310.0)
	toast_panel.size = Vector2(624.0, 42.0)
	toast_panel.color = Color(0.01, 0.01, 0.018, 0.94)
	toast_panel.visible = false
	ui_layer.add_child(toast_panel)

	toast_label = Label.new()
	toast_label.position = Vector2(12.0, 4.0)
	toast_label.size = Vector2(600.0, 32.0)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_font_size_override("font_size", 11)
	toast_panel.add_child(toast_label)

	prompt_label = Label.new()
	prompt_label.position = Vector2(120.0, 275.0)
	prompt_label.size = Vector2(400.0, 28.0)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 13)
	prompt_label.add_theme_color_override("font_color", Color("#f0ba55"))
	prompt_label.add_theme_constant_override("outline_size", 5)
	prompt_label.add_theme_color_override("font_outline_color", Color(0.01, 0.01, 0.015, 0.98))
	prompt_label.visible = false
	ui_layer.add_child(prompt_label)

	# Persistent mechanics tips stay in the upper-right rather than across the player.
	tutorial_panel = ColorRect.new()
	tutorial_panel.position = Vector2(405.0, 48.0)
	tutorial_panel.size = Vector2(225.0, 104.0)
	tutorial_panel.color = Color(0.05, 0.025, 0.065, 0.94)
	tutorial_panel.visible = false
	ui_layer.add_child(tutorial_panel)

	tutorial_title = Label.new()
	tutorial_title.position = Vector2(10.0, 7.0)
	tutorial_title.size = Vector2(205.0, 20.0)
	tutorial_title.add_theme_font_size_override("font_size", 12)
	tutorial_title.add_theme_color_override("font_color", Color("#d99ced"))
	tutorial_panel.add_child(tutorial_title)

	tutorial_body = Label.new()
	tutorial_body.position = Vector2(10.0, 29.0)
	tutorial_body.size = Vector2(205.0, 67.0)
	tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_body.add_theme_font_size_override("font_size", 9)
	tutorial_panel.add_child(tutorial_body)

	help_panel = ColorRect.new()
	help_panel.position = Vector2(120.0, 48.0)
	help_panel.size = Vector2(400.0, 264.0)
	help_panel.color = Color(0.012, 0.012, 0.022, 0.98)
	help_panel.visible = false
	ui_layer.add_child(help_panel)
	var help_text: Label = Label.new()
	help_text.position = Vector2(18.0, 16.0)
	help_text.size = Vector2(364.0, 236.0)
	help_text.text = "CONTROLS\nA/D or arrows  Move\nSPACE / W / Up  Jump\nF / left click  Three-hit attack combo\nE  Raise corpse / claim item\nQ  Grave Hook to violet ring—or pull a light enemy\nC  Cycle army command: FOLLOW / HOLD / ASSAULT\nM  Castlevania map\nT  Dismiss current note\nR  Restart at checkpoint\nF3  Collision overlay\nH  Close this help\n\nYellow flash = windup. Dark enemy = recovery. Bell Wretches buff nearby enemies. Brutes punish crowding. Raised Brutes and Sentries keep their combat role."
	help_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_text.add_theme_font_size_override("font_size", 11)
	help_panel.add_child(help_text)

	map_overlay = MapScript.new() as BargeMapOverlay
	map_overlay.position = Vector2(40.0, 20.0)
	map_overlay.visible = false
	ui_layer.add_child(map_overlay)

	# Item acquisition pauses combat and gets a full presentation beat.
	item_fanfare_flash = ColorRect.new()
	item_fanfare_flash.position = Vector2.ZERO
	item_fanfare_flash.size = VIEWPORT_SIZE
	item_fanfare_flash.color = Color(0.56, 0.18, 0.7, 0.0)
	item_fanfare_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_fanfare_flash.visible = false
	ui_layer.add_child(item_fanfare_flash)

	item_fanfare_panel = ColorRect.new()
	item_fanfare_panel.position = Vector2(80.0, 76.0)
	item_fanfare_panel.size = Vector2(480.0, 205.0)
	item_fanfare_panel.pivot_offset = item_fanfare_panel.size * 0.5
	item_fanfare_panel.color = Color(0.025, 0.012, 0.04, 0.98)
	item_fanfare_panel.visible = false
	ui_layer.add_child(item_fanfare_panel)

	var fanfare_border: ColorRect = ColorRect.new()
	fanfare_border.position = Vector2(6.0, 6.0)
	fanfare_border.size = Vector2(468.0, 193.0)
	fanfare_border.color = Color(0.28, 0.08, 0.36, 0.65)
	item_fanfare_panel.add_child(fanfare_border)

	item_fanfare_title = Label.new()
	item_fanfare_title.position = Vector2(20.0, 28.0)
	item_fanfare_title.size = Vector2(440.0, 48.0)
	item_fanfare_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_fanfare_title.add_theme_font_size_override("font_size", 25)
	item_fanfare_title.add_theme_color_override("font_color", Color("#e6a8ff"))
	item_fanfare_title.add_theme_constant_override("outline_size", 5)
	item_fanfare_title.add_theme_color_override("font_outline_color", Color(0.02, 0.0, 0.03, 1.0))
	item_fanfare_panel.add_child(item_fanfare_title)

	item_fanfare_body = Label.new()
	item_fanfare_body.position = Vector2(40.0, 88.0)
	item_fanfare_body.size = Vector2(400.0, 92.0)
	item_fanfare_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_fanfare_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_fanfare_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_fanfare_body.add_theme_font_size_override("font_size", 13)
	item_fanfare_panel.add_child(item_fanfare_body)
func _spawn_player() -> void:
	player = PlayerScript.new() as NecromancerPlayer
	player.health = clampi(GameState.player_health, 0, GameState.max_health)
	player.position = GameState.checkpoint_position if GameState.checkpoint_valid else Vector2(120.0, 620.0)
	player.attacked.connect(_on_player_attacked)
	player.interact_requested.connect(_on_interact)
	player.hook_requested.connect(_on_hook_requested)
	player.command_requested.connect(_on_command_requested)
	player.health_changed.connect(_on_health_changed)
	player.hurt_received.connect(_on_player_hurt)
	player.hook_completed.connect(_on_hook_completed)
	add_child(player)

	game_camera = Camera2D.new()
	game_camera.position = Vector2(0.0, -28.0)
	game_camera.position_smoothing_enabled = true
	game_camera.position_smoothing_speed = 7.5
	game_camera.limit_left = 0
	game_camera.limit_top = 0
	game_camera.limit_right = int(WORLD_SIZE.x)
	game_camera.limit_bottom = int(WORLD_SIZE.y + 90.0)
	game_camera.limit_smoothed = true
	player.add_child(game_camera)
	game_camera.make_current()

func _spawn_encounters() -> void:
	if not GameState.starting_guard_raised:
		dead_guard = GuardScript.new() as RaisedGuard
		dead_guard.position = Vector2(300.0, 620.0)
		dead_guard.player = player
		dead_guard.lost.connect(_on_ally_lost)
		dead_guard.damaged.connect(_on_ally_damaged)
		add_child(dead_guard)

	# The opening intentionally breathes: one readable enemy, then a larger gallery encounter.
	_spawn_enemy(Vector2(520.0, 620.0), "receiving", RaggedEnemy.Archetype.WALKER, 420.0, 680.0, false, 0.0)

	_spawn_enemy(Vector2(930.0, 620.0), "gallery", RaggedEnemy.Archetype.CHARGER, 840.0, 1120.0, false, 0.25)
	_spawn_enemy(Vector2(1050.0, 446.0), "gallery", RaggedEnemy.Archetype.SENTRY, 900.0, 1120.0, false, 0.72)
	_spawn_enemy(Vector2(1760.0, 620.0), "gallery", RaggedEnemy.Archetype.BELL_WRETCH, 1640.0, 1865.0, false, 0.48)

	# The gate room is intentionally quiet. The bone gate itself is the encounter.

	_spawn_enemy(Vector2(1850.0, 801.0), "bilge", RaggedEnemy.Archetype.HOPPER, 1760.0, 1930.0, false, 0.15)
	_spawn_enemy(Vector2(2100.0, 754.0), "bilge", RaggedEnemy.Archetype.SENTRY, 2030.0, 2195.0, false, 0.7)
	_spawn_enemy(Vector2(2335.0, 824.0), "bilge", RaggedEnemy.Archetype.WALKER, 2240.0, 2398.0, false, 0.4)

	_spawn_enemy(Vector2(2815.0, 944.0), "chain", RaggedEnemy.Archetype.WALKER, 2740.0, 2880.0, false, 0.2)
	_spawn_enemy(Vector2(3170.0, 944.0), "chain", RaggedEnemy.Archetype.BRUTE, 3090.0, 3235.0, false, 0.65)

	_spawn_enemy(Vector2(3540.0, 818.0), "shaft", RaggedEnemy.Archetype.HOPPER, 3505.0, 3610.0, false, 0.35)

	_spawn_enemy(Vector2(3070.0, 620.0), "orlop", RaggedEnemy.Archetype.WALKER, 2920.0, 3220.0, false, 0.05)
	_spawn_enemy(Vector2(3460.0, 620.0), "orlop", RaggedEnemy.Archetype.SENTRY, 3360.0, 3620.0, false, 0.72)

	# Final deck is a broad set-piece formation, not a crowded corridor.
	_spawn_enemy(Vector2(4050.0, 620.0), "deck", RaggedEnemy.Archetype.WALKER, 3920.0, 4200.0, false, 0.0)
	_spawn_enemy(Vector2(4380.0, 620.0), "deck", RaggedEnemy.Archetype.BELL_WRETCH, 4250.0, 4520.0, false, 0.55)
	_spawn_enemy(Vector2(4660.0, 620.0), "deck", RaggedEnemy.Archetype.BRUTE, 4525.0, 4780.0, false, 0.82)
	_spawn_enemy(Vector2(4860.0, 620.0), "deck", RaggedEnemy.Archetype.CHARGER, 4770.0, 4960.0, true, 0.28)

func _spawn_enemy(position_value: Vector2, room_id_value: String, archetype_value: int, left: float, right: float, elite: bool = false, phase: float = 0.0) -> void:
	var enemy: RaggedEnemy = EnemyScript.new() as RaggedEnemy
	enemy.position = position_value
	enemy.target = player
	enemy.archetype = archetype_value
	enemy.room_id = room_id_value
	enemy.room_bounds = rooms[room_id_value]["rect"]
	enemy.patrol_left = left
	enemy.patrol_right = right
	enemy.is_elite = elite
	enemy.attack_phase_offset = phase
	var slot_offsets: Array[float] = [-64.0, -28.0, 28.0, 64.0]
	enemy.combat_slot_offset = slot_offsets[enemies.size() % slot_offsets.size()]
	enemy.died.connect(_on_enemy_died)
	enemy.projectile_requested.connect(_on_projectile_requested)
	enemy.alerted.connect(_on_enemy_alerted)
	enemy.damaged.connect(_on_enemy_damaged)
	enemy.support_pulsed.connect(_on_support_pulsed)
	add_child(enemy)
	enemies.append(enemy)

func _spawn_persisted_allies() -> void:
	for index: int in range(GameState.army_size):
		var saved_role: int = GameState.army_roles[index] if index < GameState.army_roles.size() else RaisedGuard.Role.GUARD
		_spawn_raised_ally(player.position + Vector2(-24.0 - float(index) * 18.0, -4.0), false, index, saved_role)

func _on_player_attacked(origin: Vector2, facing_value: float, combo_step: int, damage: int, reach: float) -> void:
	_spawn_slash_effect(origin, facing_value, combo_step)
	_play_sfx("swing", 0.94 + float(combo_step) * 0.06)
	var confirmed_hit: bool = false
	for enemy: RaggedEnemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_hostile_active():
			continue
		var difference: Vector2 = enemy.global_position - origin
		var in_front: bool = absf(difference.x) <= 4.0 or signf(difference.x) == signf(facing_value)
		if absf(difference.x) < reach and in_front and absf(difference.y) < 40.0 and _combat_line_clear(origin, enemy.global_position):
			confirmed_hit = enemy.take_hit(origin.x, damage, combo_step == 3) or confirmed_hit
	if confirmed_hit and is_instance_valid(player):
		player.confirm_hit(combo_step)

func _combat_line_clear(origin: Vector2, target_position: Vector2) -> bool:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		origin + Vector2(0.0, -23.0),
		target_position + Vector2(0.0, -22.0),
		1
	)
	if is_instance_valid(player):
		query.exclude = [player.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _on_interact() -> void:
	if not is_instance_valid(player):
		return
	if not GameState.has_grave_hook and player.global_position.distance_to(HOOK_PICKUP_POSITION) < 48.0:
		GameState.has_grave_hook = true
		GameState.hook_tutorial_complete = false
		GameState.checkpoint_position = Vector2(2940.0, 944.0)
		GameState.checkpoint_valid = true
		player.heal_to_full()
		hook_pickup_visual.visible = false
		_update_hud()
		_start_grave_hook_fanfare()
		return

	if is_instance_valid(nearest_corpse):
		if allies.size() >= GameState.MAX_ARMY_SIZE:
			_queue_note("Your grave-command is full. Management refuses a fourth direct report.", 6.0)
			return
		if nearest_corpse == dead_guard:
			dead_guard.resurrect(true)
			dead_guard.follow_slot = allies.size()
			dead_guard.set_command(army_command_mode)
			allies.append(dead_guard)
			GameState.starting_guard_raised = true
			_play_sfx("raise")
			_queue_note("Guard: I was off duty. This feels contractual.", 5.8)
		elif nearest_corpse is RaggedEnemy:
			var corpse: RaggedEnemy = nearest_corpse as RaggedEnemy
			var corpse_position: Vector2 = corpse.global_position
			var raised_role: int = _role_for_corpse(corpse)
			corpse.mark_raised()
			_spawn_raised_ally(corpse_position, true, allies.size(), raised_role)
			_play_sfx("raise")
			_queue_note("A hostile corpse changes employers. Its old job skills remain disturbingly transferable.", 6.4)
		_sync_army_state()
		nearest_corpse = null

func _on_hook_requested() -> void:
	if not GameState.has_grave_hook:
		if absf(player.global_position.x - BONE_GATE_X) < 110.0 and player.global_position.y > 360.0 and player.global_position.y < 650.0:
			_queue_note("The ribs flex. Your hands do not. Something made for pulling would change the argument.", 8.5, true, "gate_no_hook", 12.0)
		else:
			_queue_note("Q currently performs a convincing gesture of intent.", 6.5, false, "no_hook", 14.0)
		return
	if not GameState.bone_gate_open and absf(player.global_position.x - BONE_GATE_X) < 110.0 and player.global_position.y > 360.0 and player.global_position.y < 650.0:
		_open_bone_gate()
		return
	if current_anchor.is_empty():
		var pull_target: RaggedEnemy = _find_hook_enemy()
		if is_instance_valid(pull_target) and pull_target.apply_hook_pull(player.global_position):
			chain_line.points = PackedVector2Array([player.global_position + Vector2(0.0, -24.0), pull_target.global_position + Vector2(0.0, -22.0)])
			chain_line_timer = 0.5
			_play_sfx("hook")
			_queue_note("The Grave Hook also negotiates shorter enemy commutes.", 5.8, false, "hook_enemy", 16.0)
			return
		_queue_note("No violet ring or light enemy is in range.", 5.5, false, "hook_no_target", 8.0)
		return
	var target_position: Vector2 = current_anchor["target"]
	chain_line.points = PackedVector2Array([player.global_position + Vector2(0.0, -24.0), current_anchor["position"]])
	chain_line_timer = 0.85
	last_hook_anchor_id = str(current_anchor["id"])
	_play_sfx("hook")
	player.start_hook(target_position)
	if not GameState.hook_tutorial_complete:
		GameState.hook_tutorial_complete = true
		_hide_persistent_tip()
		_queue_note("Hook understood. Violet rings move you; bone gates can be ripped apart; light enemies can be dragged into reach.", 9.5, true, "hook_understood", 999.0)

func _open_bone_gate() -> void:
	GameState.bone_gate_open = true
	if is_instance_valid(gate_body):
		gate_body.queue_free()
	if is_instance_valid(gate_visual):
		var tween: Tween = create_tween()
		tween.tween_property(gate_visual, "modulate:a", 0.0, 0.35)
		tween.tween_callback(Callable(gate_visual, "queue_free"))
	_play_sfx("heavy_hit", 0.82)
	_queue_note("The bone gate revises its position on collective bargaining.", 6.0)

func _on_projectile_requested(origin: Vector2, direction: Vector2, speed: float, damage: int, visual_kind: String = "bolt") -> void:
	var projectile: BoneProjectile = ProjectileScript.new() as BoneProjectile
	projectile.position = origin
	projectile.velocity = _projectile_launch_velocity(direction, speed, visual_kind)
	projectile.damage = damage
	projectile.owner_x = origin.x
	projectile.hostile = true
	projectile.visual_kind = visual_kind
	add_child(projectile)

func _on_enemy_alerted(source: RaggedEnemy) -> void:
	_play_sfx("alert", 0.94 + randf() * 0.08)
	for enemy: RaggedEnemy in enemies:
		if not is_instance_valid(enemy) or enemy == source or not enemy.is_hostile_active():
			continue
		if enemy.room_id == source.room_id and enemy.global_position.distance_to(source.global_position) < 260.0:
			enemy.receive_alert(3.2)

func _on_enemy_died(_enemy: RaggedEnemy) -> void:
	_queue_note("Corpse available. Previous qualifications include trying to kill you.", 7.0, false, "corpse_available", 14.0)

func _spawn_raised_ally(position_value: Vector2, play_rise: bool, slot: int, role_value: int = RaisedGuard.Role.GUARD) -> void:
	var ally: RaisedGuard = GuardScript.new() as RaisedGuard
	ally.position = position_value
	ally.player = player
	ally.follow_slot = slot
	ally.role = role_value
	ally.command_mode = army_command_mode
	ally.lost.connect(_on_ally_lost)
	ally.projectile_requested.connect(_on_ally_projectile_requested)
	ally.damaged.connect(_on_ally_damaged)
	add_child(ally)
	ally.resurrect(play_rise)
	ally.set_command(army_command_mode)
	allies.append(ally)

func _update_pickups() -> void:
	if is_instance_valid(hook_pickup_visual) and hook_pickup_visual.visible:
		var hook_pulse: float = 1.0 + 0.08 * absf(sin(Time.get_ticks_msec() * 0.006))
		hook_pickup_visual.scale = Vector2.ONE * hook_pulse
		hook_pickup_visual.rotation = sin(Time.get_ticks_msec() * 0.0025) * 0.08
	if is_instance_valid(heart_shard_visual) and heart_shard_visual.visible:
		heart_shard_visual.position.y = HEART_SHARD_POSITION.y + sin(Time.get_ticks_msec() * 0.004) * 3.0
	if not GameState.heart_shard_collected and player.global_position.distance_to(HEART_SHARD_POSITION) < 21.0:
		GameState.collect_heart_shard()
		player.heal_to_full()
		heart_shard_visual.visible = false
		_queue_note("BLACK HEART SHARD: maximum flesh increased. Morale remains unchanged.", 6.8)
		_update_hud()

func _update_anchor_guidance() -> void:
	current_anchor = {}
	var candidates: Array[Dictionary] = []
	var upward_candidate_exists: bool = false
	for anchor_data: Dictionary in anchors:
		var anchor_position: Vector2 = anchor_data["position"]
		var target_position: Vector2 = anchor_data["target"]
		var distance: float = player.global_position.distance_to(anchor_position)
		var target_distance: float = player.global_position.distance_to(target_position)
		var visual: Node2D = anchor_data["visual"]
		var available: bool = GameState.has_grave_hook and distance <= float(anchor_data["range"])
		var pulse: float = 1.0 + 0.08 * absf(sin(Time.get_ticks_msec() * 0.008))
		visual.scale = Vector2.ONE * (pulse if available else 1.0)
		visual.modulate = Color(1.0, 0.86, 1.0, 1.0) if available else Color(0.55, 0.45, 0.6, 0.6)
		if not available or target_distance < 48.0:
			continue
		var candidate: Dictionary = {"data": anchor_data, "distance": distance, "target_distance": target_distance}
		candidates.append(candidate)
		if target_position.y < player.global_position.y - 24.0:
			upward_candidate_exists = true

	var best_score: float = INF
	for candidate: Dictionary in candidates:
		var anchor_data: Dictionary = candidate["data"]
		var target_position: Vector2 = anchor_data["target"]
		var is_upward: bool = target_position.y < player.global_position.y - 24.0
		if upward_candidate_exists and not is_upward:
			continue
		var score: float = float(candidate["distance"])
		if str(anchor_data["id"]) == last_hook_anchor_id and float(candidate["target_distance"]) < 120.0:
			score += 260.0
		if score < best_score:
			current_anchor = anchor_data
			best_score = score

	if GameState.has_grave_hook and not current_anchor.is_empty():
		hook_hint_line.visible = true
		hook_hint_line.points = PackedVector2Array([player.global_position + Vector2(0.0, -24.0), current_anchor["position"]])
	else:
		hook_hint_line.visible = false

func _update_interaction_prompt() -> void:
	nearest_corpse = null
	var nearest_distance: float = 52.0
	if is_instance_valid(dead_guard) and dead_guard.can_be_raised():
		var distance_to_guard: float = player.global_position.distance_to(dead_guard.global_position)
		if distance_to_guard < nearest_distance:
			nearest_corpse = dead_guard
			nearest_distance = distance_to_guard
	for enemy: RaggedEnemy in enemies:
		if not is_instance_valid(enemy) or not enemy.can_be_raised():
			continue
		var corpse_distance: float = player.global_position.distance_to(enemy.global_position)
		if corpse_distance < nearest_distance:
			nearest_corpse = enemy
			nearest_distance = corpse_distance

	prompt_label.visible = false
	if not GameState.has_grave_hook and player.global_position.distance_to(HOOK_PICKUP_POSITION) < 50.0:
		prompt_label.text = "[E] CLAIM THE GRAVE HOOK"
		prompt_label.visible = true
	elif is_instance_valid(nearest_corpse):
		prompt_label.text = "[E] ARMY FULL" if allies.size() >= GameState.MAX_ARMY_SIZE else "[E] RAISE THE DEAD"
		prompt_label.visible = true
	elif not GameState.has_grave_hook and not GameState.bone_gate_open and absf(player.global_position.x - BONE_GATE_X) < 110.0 and player.global_position.y > 360.0 and player.global_position.y < 650.0:
		prompt_label.text = "[Q] TEST THE RIB GATE"
		prompt_label.visible = true
	elif GameState.has_grave_hook and not GameState.bone_gate_open and absf(player.global_position.x - BONE_GATE_X) < 110.0 and player.global_position.y > 360.0 and player.global_position.y < 650.0:
		prompt_label.text = "[Q] RIP OPEN BONE GATE"
		prompt_label.visible = true
	elif GameState.has_grave_hook and not current_anchor.is_empty():
		prompt_label.text = "[Q] GRAVE HOOK — %s" % str(current_anchor.get("label", "VIOLET RING"))
		prompt_label.visible = true
	elif GameState.has_grave_hook:
		hook_combat_target = _find_hook_enemy()
		if is_instance_valid(hook_combat_target):
			prompt_label.text = "[Q] PULL LIGHT ENEMY"
			prompt_label.visible = true

func _update_room(force: bool) -> void:
	var next_room: String = _room_at_position(player.global_position)
	if not force and next_room == current_room_id:
		return
	current_room_id = next_room
	GameState.discover_room(current_room_id)
	if rooms.has(current_room_id):
		last_safe_position = rooms[current_room_id]["safe"]
	room_label.text = str(rooms[current_room_id]["title"])
	if is_instance_valid(room_title_tween):
		room_title_tween.kill()
	room_label.modulate.a = 1.0
	room_title_tween = create_tween()
	room_title_tween.tween_interval(3.4)
	room_title_tween.tween_property(room_label, "modulate:a", 0.0, 0.65)

	if not bool(vista_rooms_shown.get(current_room_id, false)) and current_room_id in ["gallery", "gate", "deck"]:
		vista_rooms_shown[current_room_id] = true
		_start_vista_sweep(150.0 if current_room_id != "deck" else 210.0)

	if bool(shown_room_tips.get(current_room_id, false)):
		return
	shown_room_tips[current_room_id] = true
	match current_room_id:
		"gallery":
			_queue_note("The quarantine gallery opens up above you. The high red gantry is not a normal jump.", 8.0, false, "gallery_intro", 20.0)
		"gate":
			gate_tease_seen = true
			_queue_note("BONE GATE — the ribs are fused into the bulkhead. They flex, but you have no leverage. The broken hatch is the only way forward.", 10.5, true, "gate_tease", 999.0)
		"bilge":
			_queue_note("The Drowned Hold is a drop, not a detour. Cross the visible decks and look for a way back up.", 8.0, false, "bilge_intro", 30.0)
		"chain":
			_queue_note("Something in the Chain Crypt is still attached to the ship. That usually means it is either useful or angry.", 8.0, false, "chain_intro", 30.0)
		"shaft":
			_queue_note("Now the Hook has a job: follow the violet rings up the winch shaft.", 8.5, true, "shaft_intro", 999.0)
		"orlop":
			_queue_note("You have come up behind the Rib Gate. Tear it open before heading for the weather deck.", 9.0, true, "orlop_gate", 999.0)
		"deck":
			_queue_note("The Ossuary Deck. Open sky, bad footing, and enough room for everyone to make regrettable decisions.", 9.0, true, "deck_intro", 999.0)

func _start_vista_sweep(horizontal_offset: float) -> void:
	if not is_instance_valid(game_camera):
		return
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(game_camera, "position:x", horizontal_offset, 1.1)
	tween.tween_interval(0.55)
	tween.tween_property(game_camera, "position:x", 0.0, 1.0)

func _room_at_position(position_value: Vector2) -> String:
	for room_id_value: String in rooms.keys():
		var room_rect: Rect2 = rooms[room_id_value]["rect"]
		if room_rect.has_point(position_value):
			return room_id_value
	return current_room_id if not current_room_id.is_empty() else "receiving"

func _active_enemies_in_room(room_id_value: String) -> int:
	var count: int = 0
	for enemy: RaggedEnemy in enemies:
		if is_instance_valid(enemy) and enemy.is_hostile_active() and enemy.room_id == room_id_value:
			count += 1
	return count

func _recover_from_pit() -> void:
	var safe_position: Vector2 = last_safe_position
	if safe_position == Vector2.ZERO:
		safe_position = rooms[current_room_id]["safe"] if rooms.has(current_room_id) else Vector2(120.0, 620.0)
	player.recover_from_pit(safe_position)
	for ally: RaisedGuard in allies:
		if is_instance_valid(ally):
			ally.snap_near_player()
	_queue_note("The water returns you one flesh lighter. It has standards, apparently.", 6.5, false, "pit_recovery", 14.0)

func _update_last_safe_position(delta: float) -> void:
	safe_record_timer = maxf(0.0, safe_record_timer - delta)
	if safe_record_timer > 0.0 or not player.is_on_floor() or absf(player.velocity.y) > 8.0:
		return
	if current_room_id == "bilge":
		var pit_safe_points: Array[Vector2] = [
			Vector2(1845.0, 801.0), Vector2(2100.0, 754.0), Vector2(2335.0, 824.0), Vector2(2575.0, 773.0)
		]
		var closest_point: Vector2 = pit_safe_points[0]
		var closest_distance: float = INF
		for point: Vector2 in pit_safe_points:
			var distance: float = player.global_position.distance_to(point)
			if distance < closest_distance:
				closest_distance = distance
				closest_point = point
		if closest_distance < 120.0:
			last_safe_position = closest_point
	else:
		last_safe_position = player.global_position
	safe_record_timer = 0.15

func _draw() -> void:
	if not collision_debug_visible:
		return
	for rect: Rect2 in collision_solid_rects:
		draw_rect(rect, Color(0.22, 1.0, 0.28, 0.32), true)
		draw_rect(rect, Color(0.45, 1.0, 0.5, 0.9), false, 1.0)
	for rect: Rect2 in collision_one_way_rects:
		draw_rect(rect, Color(0.15, 0.85, 1.0, 0.34), true)
		draw_rect(rect, Color(0.4, 0.95, 1.0, 0.95), false, 1.0)
	for rect: Rect2 in collision_hook_only_rects:
		draw_rect(rect, Color(0.72, 0.24, 0.95, 0.4), true)
		draw_rect(rect, Color(0.9, 0.55, 1.0, 0.98), false, 2.0)
	for rect: Rect2 in collision_hazard_rects:
		draw_rect(rect, Color(1.0, 0.12, 0.12, 0.38), true)
		draw_rect(rect, Color(1.0, 0.35, 0.35, 0.95), false, 1.0)
	if is_instance_valid(player):
		draw_rect(Rect2(player.global_position + Vector2(-7.0, -38.0), Vector2(14.0, 38.0)), Color(1.0, 1.0, 1.0, 0.95), false, 1.5)
	for enemy: RaggedEnemy in enemies:
		if is_instance_valid(enemy) and enemy.is_hostile_active():
			draw_rect(Rect2(enemy.global_position + Vector2(-7.0, -37.0), Vector2(14.0, 37.0)), Color(1.0, 0.35, 0.28, 0.95), false, 1.2)
	for ally: RaisedGuard in allies:
		if is_instance_valid(ally) and ally.resurrected:
			var half_width: float = 9.0 if ally.role == RaisedGuard.Role.BRUTE else 7.0
			var height: float = 42.0 if ally.role == RaisedGuard.Role.BRUTE else 38.0
			draw_rect(Rect2(ally.global_position + Vector2(-half_width, -height), Vector2(half_width * 2.0, height)), Color(0.35, 1.0, 0.62, 0.95), false, 1.2)

func _refresh_allies() -> void:
	var changed: bool = false
	for index: int in range(allies.size() - 1, -1, -1):
		var ally: RaisedGuard = allies[index]
		if not is_instance_valid(ally):
			allies.remove_at(index)
			changed = true
			continue
		var ally_in_bilge: bool = ally.global_position.x >= 1728.0 and ally.global_position.x < 2688.0
		if (ally_in_bilge and ally.global_position.y > PIT_RECOVERY_Y) or ally.global_position.y > WORLD_RECOVERY_Y:
			ally.reform_near_player(true)
		elif ally.global_position.distance_to(player.global_position) > 260.0 and ally.command_mode != RaisedGuard.CommandMode.HOLD:
			ally.reform_near_player()
	if changed:
		_refresh_ally_slots()
		_sync_army_state()

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
	_queue_note("A servant has been destroyed in combat. The vacancy is regrettably literal.", 6.0)

func _sync_army_state() -> void:
	var roles: Array[int] = []
	for ally: RaisedGuard in allies:
		if is_instance_valid(ally):
			roles.append(int(ally.role))
	GameState.set_army_roles(roles)
	GameState.army_command_mode = army_command_mode
	_update_hud()

func _on_health_changed(value: int) -> void:
	GameState.player_health = maxi(value, 0)
	_update_hud()

func _update_hud() -> void:
	if not is_instance_valid(health_label):
		return
	health_label.text = "FLESH %d/%d" % [maxi(player.health, 0) if is_instance_valid(player) else GameState.player_health, GameState.max_health]
	army_label.text = "DEAD %d/%d" % [allies.size(), GameState.MAX_ARMY_SIZE]
	hook_label.text = "HOOK Q" if GameState.has_grave_hook else "HOOK —"
	var command_names: Array[String] = ["FOLLOW", "HOLD", "ASSAULT"]
	command_label.text = "C %s" % command_names[clampi(army_command_mode, 0, 2)]

func _update_map() -> void:
	if is_instance_valid(map_overlay):
		map_overlay.update_map(player.global_position, current_room_id, GameState.discovered_rooms, GameState.has_grave_hook, GameState.bone_gate_open, GameState.heart_shard_collected)

func _queue_note(message: String, duration: float = -1.0, priority: bool = false, key: String = "", cooldown: float = 0.0) -> void:
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	var note_key: String = key if not key.is_empty() else message
	if cooldown > 0.0 and note_cooldowns.has(note_key) and now - float(note_cooldowns[note_key]) < cooldown:
		return
	note_cooldowns[note_key] = now
	if not active_toast.is_empty() and str(active_toast.get("message", "")) == message:
		return
	for queued_note: Dictionary in toast_queue:
		if str(queued_note.get("message", "")) == message:
			return
	var calculated_duration: float = duration
	if calculated_duration < 0.0:
		var word_count: int = message.split(" ", false).size()
		calculated_duration = clampf(6.5 + float(word_count) * 0.22, 7.0, 12.0)
	var item: Dictionary = {"message": message, "duration": calculated_duration}
	if priority:
		toast_queue.clear()
		active_toast = {}
		toast_timer = 0.0
		toast_queue.push_front(item)
	else:
		# Ordinary jokes never become an endless subtitle backlog. Keep at most one waiting.
		if toast_queue.size() >= 1:
			return
		toast_queue.append(item)
	if active_toast.is_empty():
		_show_next_toast()

func _update_toasts(delta: float) -> void:
	if active_toast.is_empty():
		if not toast_queue.is_empty():
			_show_next_toast()
		return
	if toast_timer >= 900.0:
		return
	toast_timer = maxf(0.0, toast_timer - delta)
	if toast_timer <= 0.0:
		active_toast = {}
		toast_panel.visible = false
		_show_next_toast()

func _show_next_toast() -> void:
	if toast_queue.is_empty():
		toast_panel.visible = false
		return
	active_toast = toast_queue.pop_front()
	toast_label.text = str(active_toast["message"])
	toast_timer = float(active_toast["duration"])
	toast_panel.visible = true

func _start_grave_hook_fanfare() -> void:
	_play_sfx("relic")
	item_fanfare_active = true
	item_fanfare_timer = 3.2
	player.can_control = false
	player.set_physics_process(false)
	for enemy: RaggedEnemy in enemies:
		if is_instance_valid(enemy):
			enemy.set_physics_process(false)
	for ally: RaisedGuard in allies:
		if is_instance_valid(ally):
			ally.set_physics_process(false)
	if is_instance_valid(dead_guard):
		dead_guard.set_physics_process(false)

	tutorial_panel.visible = false
	prompt_label.visible = false
	toast_panel.visible = false
	item_fanfare_title.text = "GRAVE HOOK"
	item_fanfare_body.text = "TRAVERSAL RELIC ACQUIRED\n\nQ: pull to violet rings\nQ near bone gates: tear them open\nQ facing light enemies: drag them into reach"
	item_fanfare_panel.visible = true
	item_fanfare_panel.modulate.a = 0.0
	item_fanfare_panel.scale = Vector2(0.82, 0.82)
	item_fanfare_flash.visible = true
	item_fanfare_flash.modulate.a = 0.0
	if is_instance_valid(item_fanfare_tween):
		item_fanfare_tween.kill()
	item_fanfare_tween = create_tween()
	item_fanfare_tween.set_parallel(true)
	item_fanfare_tween.tween_property(item_fanfare_panel, "modulate:a", 1.0, 0.28)
	item_fanfare_tween.tween_property(item_fanfare_panel, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	item_fanfare_tween.tween_property(item_fanfare_flash, "modulate:a", 0.38, 0.16)
	var flash_fade: Tween = create_tween()
	flash_fade.tween_interval(0.18)
	flash_fade.tween_property(item_fanfare_flash, "modulate:a", 0.0, 0.75)

func _update_item_fanfare(delta: float) -> void:
	item_fanfare_timer = maxf(0.0, item_fanfare_timer - delta)
	if is_instance_valid(item_fanfare_panel) and item_fanfare_timer < 2.72:
		var pulse: float = 1.0 + 0.012 * sin(Time.get_ticks_msec() * 0.01)
		item_fanfare_panel.scale = Vector2.ONE * pulse
	if item_fanfare_timer <= 0.0:
		_finish_grave_hook_fanfare()

func _finish_grave_hook_fanfare() -> void:
	item_fanfare_active = false
	item_fanfare_panel.visible = false
	item_fanfare_flash.visible = false
	player.set_physics_process(true)
	player.can_control = true
	for enemy: RaggedEnemy in enemies:
		if is_instance_valid(enemy):
			enemy.set_physics_process(true)
	for ally: RaisedGuard in allies:
		if is_instance_valid(ally):
			ally.set_physics_process(true)
	if is_instance_valid(dead_guard):
		dead_guard.set_physics_process(true)
	_show_hook_tutorial()
	_queue_note("The Grave Hook is ready. Violet rings move you. Bone gates can be torn open. Press Q when the guide-line appears.", 8.0, true)

func _show_hook_tutorial() -> void:
	tutorial_title.text = "GRAVE HOOK — CURRENT OBJECTIVE"
	tutorial_body.text = "Q follows violet rings. Bone gates can be ripped open. Light enemies can be dragged into melee range."
	tutorial_panel.visible = true

func _hide_persistent_tip() -> void:
	tutorial_panel.visible = false



func _build_audio() -> void:
	var paths: Dictionary = {
		"swing": "res://assets/audio/swing.wav",
		"hit": "res://assets/audio/hit.wav",
		"heavy_hit": "res://assets/audio/heavy_hit.wav",
		"raise": "res://assets/audio/raise.wav",
		"hook": "res://assets/audio/hook.wav",
		"relic": "res://assets/audio/relic.wav",
		"command": "res://assets/audio/command.wav",
		"alert": "res://assets/audio/alert.wav",
		"hurt": "res://assets/audio/hurt.wav"
	}
	for key: String in paths.keys():
		var audio: AudioStreamPlayer = AudioStreamPlayer.new()
		audio.stream = load(str(paths[key])) as AudioStream
		audio.volume_db = -5.0
		add_child(audio)
		sfx_players[key] = audio

func _play_sfx(key: String, pitch: float = 1.0) -> void:
	if not sfx_players.has(key):
		return
	var player_node: AudioStreamPlayer = sfx_players[key] as AudioStreamPlayer
	player_node.pitch_scale = pitch
	player_node.play()

func _on_command_requested() -> void:
	army_command_mode = (army_command_mode + 1) % 3
	GameState.army_command_mode = army_command_mode
	_apply_army_command(true)

func _apply_army_command(show_note: bool) -> void:
	for ally: RaisedGuard in allies:
		if is_instance_valid(ally):
			ally.set_command(army_command_mode)
	_update_hud()
	if not show_note:
		return
	_play_sfx("command", 0.92 + float(army_command_mode) * 0.08)
	match army_command_mode:
		RaisedGuard.CommandMode.FOLLOW:
			_queue_note("ARMY: FOLLOW. The dead resume standing near the person with the benefits package.", 5.5, true)
		RaisedGuard.CommandMode.HOLD:
			_queue_note("ARMY: HOLD. They will defend this ground with the confidence of people who cannot die correctly.", 6.0, true)
		RaisedGuard.CommandMode.ASSAULT:
			_queue_note("ARMY: ASSAULT. Professional boundaries have been suspended.", 5.2, true)

func _role_for_corpse(corpse: RaggedEnemy) -> int:
	match corpse.archetype:
		RaggedEnemy.Archetype.CHARGER, RaggedEnemy.Archetype.BRUTE:
			return RaisedGuard.Role.BRUTE
		RaggedEnemy.Archetype.SENTRY, RaggedEnemy.Archetype.BELL_WRETCH:
			return RaisedGuard.Role.SENTRY
		_:
			return RaisedGuard.Role.GUARD

func _on_ally_projectile_requested(origin: Vector2, direction: Vector2, speed: float, damage: int, visual_kind: String = "bolt") -> void:
	var projectile: BoneProjectile = ProjectileScript.new() as BoneProjectile
	projectile.position = origin
	projectile.velocity = _projectile_launch_velocity(direction, speed, visual_kind)
	projectile.damage = damage
	projectile.owner_x = origin.x
	projectile.hostile = false
	projectile.visual_kind = visual_kind
	add_child(projectile)

func _projectile_launch_velocity(direction: Vector2, speed: float, visual_kind: String) -> Vector2:
	var aim := direction.normalized()
	if visual_kind != "lantern":
		return aim * speed
	var horizontal_sign := signf(aim.x) if absf(aim.x) > 0.05 else 1.0
	return Vector2(horizontal_sign * maxf(absf(aim.x) * speed, speed * 0.82), clampf(aim.y * speed - 200.0, -250.0, -140.0))

func _on_enemy_damaged(position_value: Vector2, amount: int, heavy: bool) -> void:
	_spawn_impact_effect(position_value, heavy)
	_play_sfx("heavy_hit" if heavy else "hit", 0.94 + randf() * 0.12)
	_trigger_hitstop(72 if heavy else 42, 0.12 if heavy else 0.2)
	shake_timer = maxf(shake_timer, 0.18 if heavy else 0.08)
	shake_strength = maxf(shake_strength, 5.0 if heavy else 2.2)

func _on_ally_damaged(position_value: Vector2, amount: int, heavy: bool) -> void:
	_spawn_impact_effect(position_value, heavy)
	_play_sfx("hurt", 0.86)
	shake_timer = maxf(shake_timer, 0.08)
	shake_strength = maxf(shake_strength, 1.8)

func _on_player_hurt(position_value: Vector2) -> void:
	_spawn_impact_effect(position_value, true)
	_play_sfx("hurt")
	_trigger_hitstop(58, 0.16)
	shake_timer = maxf(shake_timer, 0.2)
	shake_strength = maxf(shake_strength, 5.5)

func _on_hook_completed(_position_value: Vector2) -> void:
	_play_sfx("hook", 0.72)
	shake_timer = maxf(shake_timer, 0.08)
	shake_strength = maxf(shake_strength, 1.4)

func _on_support_pulsed(position_value: Vector2) -> void:
	_spawn_support_pulse(position_value)
	_play_sfx("alert", 0.82)

func _find_hook_enemy() -> RaggedEnemy:
	if not is_instance_valid(player):
		return null
	var closest: RaggedEnemy = null
	var best_distance: float = 172.0
	for enemy: RaggedEnemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_hostile_active():
			continue
		if enemy.is_elite or enemy.archetype == RaggedEnemy.Archetype.BRUTE or enemy.archetype == RaggedEnemy.Archetype.CHARGER:
			continue
		var difference: Vector2 = enemy.global_position - player.global_position
		if signf(difference.x) != signf(player.facing) or absf(difference.y) > 48.0:
			continue
		if not _combat_line_clear(player.global_position, enemy.global_position):
			continue
		var distance: float = difference.length()
		if distance < best_distance:
			closest = enemy
			best_distance = distance
	return closest

func _trigger_hitstop(milliseconds: int, scale: float) -> void:
	hitstop_end_msec = maxi(hitstop_end_msec, Time.get_ticks_msec() + milliseconds)
	Engine.time_scale = minf(Engine.time_scale, scale)

func _update_combat_feedback(delta: float) -> void:
	if hitstop_end_msec > 0 and Time.get_ticks_msec() >= hitstop_end_msec:
		hitstop_end_msec = 0
		Engine.time_scale = 1.0
	shake_timer = maxf(0.0, shake_timer - delta)
	if is_instance_valid(game_camera):
		if shake_timer > 0.0:
			game_camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		else:
			game_camera.offset = Vector2.ZERO

func _spawn_slash_effect(origin: Vector2, facing_value: float, combo_step: int) -> void:
	var textures: Array[Texture2D] = [VFX_SLASH_1, VFX_SLASH_2, VFX_SLASH_3]
	var effect := _spawn_world_vfx(textures[clampi(combo_step - 1, 0, 2)], origin + Vector2(facing_value * 26.0, -24.0), Vector2(1.15, 1.15), 0.16)
	effect.flip_h = facing_value < 0.0

func _spawn_impact_effect(position_value: Vector2, heavy: bool) -> void:
	_spawn_world_vfx(VFX_IMPACT_HEAVY if heavy else VFX_IMPACT_LIGHT, position_value + Vector2(0.0, -24.0), Vector2(1.4, 1.4), 0.2)

func _spawn_support_pulse(position_value: Vector2) -> void:
	_spawn_world_vfx(VFX_SUPPORT_PULSE, position_value + Vector2(0.0, -24.0), Vector2(1.8, 1.8), 0.4)

func _spawn_world_vfx(texture: Texture2D, position_value: Vector2, end_scale: Vector2, duration: float) -> Sprite2D:
	var effect := Sprite2D.new()
	effect.texture = texture
	effect.position = position_value
	effect.z_index = 16
	add_child(effect)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(effect, "scale", end_scale, duration)
	tween.tween_property(effect, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(effect.queue_free)
	return effect
