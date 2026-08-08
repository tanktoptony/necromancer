class_name BreakableProp
extends Area2D

signal broken(prop, drop_kind: String, amount: int)

@export var prop_kind: String = "urn"
@export var drop_kind: String = "ash"
@export var drop_amount: int = 1
@export var health: int = 1

const CANDLE_TEXTURE: Texture2D = preload("res://assets/vania11/breakable_candle.png")
const URN_TEXTURE: Texture2D = preload("res://assets/vania11/bone_urn.png")

var sprite: Sprite2D
var broken_already: bool = false

func _ready() -> void:
	add_to_group("breakables")
	collision_layer = 16
	collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24.0, 34.0) if prop_kind == "candle" else Vector2(30.0, 34.0)
	collision.shape = shape
	collision.position = Vector2(0.0, -17.0)
	add_child(collision)
	sprite = Sprite2D.new()
	sprite.texture = CANDLE_TEXTURE if prop_kind == "candle" else URN_TEXTURE
	sprite.position = Vector2(0.0, -22.0 if prop_kind == "candle" else -19.0)
	sprite.z_index = 3
	add_child(sprite)

func hit(damage: int = 1) -> void:
	if broken_already:
		return
	health -= damage
	if health > 0:
		return
	broken_already = true
	broken.emit(self, drop_kind, drop_amount)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.35, 0.4), 0.08)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(queue_free)
