class_name RoomHookAnchor
extends Node2D

const LANTERN_TEXTURE: Texture2D = preload("res://assets/vania11/grave_lantern_chunky.png")

@export var anchor_id: String = "anchor"
@export var label: String = "GRAVE LANTERN"
@export var landing_offset: Vector2 = Vector2(0.0, 48.0)
@export var max_range: float = 240.0
@export var tutorial_anchor: bool = false

var available: bool = false
var selected: bool = false
var lantern_sprite: Sprite2D
var base_scale: Vector2 = Vector2(0.76, 0.76)

func _ready() -> void:
	add_to_group("room_hook_anchors")
	lantern_sprite = Sprite2D.new()
	lantern_sprite.texture = LANTERN_TEXTURE
	lantern_sprite.position = Vector2(0.0, -20.0)
	lantern_sprite.scale = base_scale
	lantern_sprite.z_index = 4
	add_child(lantern_sprite)
	queue_redraw()

func _process(_delta: float) -> void:
	if lantern_sprite == null:
		return
	var pulse: float = 1.0
	if available:
		pulse += 0.035 * sin(Time.get_ticks_msec() * 0.007)
	if selected:
		pulse += 0.07
	lantern_sprite.scale = base_scale * pulse
	queue_redraw()

func set_visual_state(is_available: bool, is_selected: bool) -> void:
	available = is_available
	selected = is_selected
	if lantern_sprite != null:
		if selected:
			lantern_sprite.modulate = Color(1.18, 0.86, 1.28, 1.0)
		elif available:
			lantern_sprite.modulate = Color(0.92, 0.76, 1.12, 1.0)
		else:
			lantern_sprite.modulate = Color(0.6, 0.56, 0.64, 0.72)
	queue_redraw()

func landing_position() -> Vector2:
	return global_position + landing_offset

func _draw() -> void:
	# The lantern is the actual artifact. These soft rings only communicate active Grave Field state.
	if not available and not selected:
		return
	var alpha: float = 0.2 if available else 0.0
	var radius: float = 19.0
	if selected:
		alpha = 0.42
		radius = 23.0
	var glow_color: Color = Color(0.72, 0.31, 0.94, alpha)
	draw_circle(Vector2(0.0, -19.0), radius, glow_color)
	if selected:
		draw_arc(Vector2(0.0, -19.0), 27.0, 0.0, TAU, 20, Color(0.88, 0.58, 1.0, 0.85), 1.5)
