class_name RoomDoor
extends Area2D

signal entered(door)

const DOOR_TEXTURE: Texture2D = preload("res://assets/vania10/bulkhead_door.png")

@export var door_id: String = "door"
@export var target_room: String = ""
@export var target_door: String = "default"
@export var direction: String = "right"
@export var locked_by_gate: bool = false
@export var gate_id: String = ""
@export var transition_label: String = ""

var enabled: bool = true
var _cooldown: float = 0.0
var open_amount: float = 0.0
var _transition_pending: bool = false
var door_sprite: Sprite2D
var closed_sprite_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("room_doors")
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	_build_visual()
	queue_redraw()

func _build_visual() -> void:
	door_sprite = Sprite2D.new()
	door_sprite.texture = DOOR_TEXTURE
	door_sprite.z_index = 5
	if direction == "down" or direction == "up":
		door_sprite.rotation = PI * 0.5
		door_sprite.scale = Vector2(1.15, 1.15)
		closed_sprite_position = Vector2(0.0, -3.0)
	else:
		door_sprite.scale = Vector2(0.9, 0.9)
		closed_sprite_position = Vector2(0.0, -31.0)
	door_sprite.position = closed_sprite_position
	add_child(door_sprite)
	_update_visual()

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)

func arm_delay(seconds: float = 0.35) -> void:
	_cooldown = seconds
	enabled = true

func show_arrival_open(seconds: float = 0.42) -> void:
	open_amount = 1.0
	_update_visual()
	var tween: Tween = create_tween()
	tween.tween_interval(seconds)
	tween.tween_method(_set_open_amount, 1.0, 0.0, 0.2)

func _on_body_entered(body: Node2D) -> void:
	if not enabled or _cooldown > 0.0 or _transition_pending:
		return
	if body is NecromancerPlayer:
		_transition_pending = true
		enabled = false
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_method(_set_open_amount, open_amount, 1.0, 0.18)
		tween.tween_callback(_emit_entered)

func _emit_entered() -> void:
	entered.emit(self)

func _set_open_amount(value: float) -> void:
	open_amount = clampf(value, 0.0, 1.0)
	_update_visual()
	queue_redraw()

func _update_visual() -> void:
	if door_sprite == null:
		return
	if direction == "down" or direction == "up":
		var travel_x: float = 54.0 * open_amount
		if direction == "up":
			travel_x *= -1.0
		door_sprite.position = closed_sprite_position + Vector2(travel_x, 0.0)
	else:
		door_sprite.position = closed_sprite_position + Vector2(0.0, -50.0 * open_amount)
	door_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0 - open_amount * 0.15)

func _draw() -> void:
	# The opening is deliberately simple and dark; the illustrated bulkhead is the dominant visual.
	if direction == "down" or direction == "up":
		draw_rect(Rect2(Vector2(-34.0, -8.0), Vector2(68.0, 16.0)), Color(0.012, 0.008, 0.016, 0.88), true)
	else:
		draw_rect(Rect2(Vector2(-13.0, -55.0), Vector2(26.0, 55.0)), Color(0.012, 0.008, 0.016, 0.88), true)
