class_name PickupDrop
extends Area2D

signal collected(kind: String, amount: int)

const ASH_TEXTURE: Texture2D = preload("res://assets/vania11/grave_ash.png")
const FLESH_TEXTURE: Texture2D = preload("res://assets/vania11/flesh_pickup.png")

var kind: String = "ash"
var amount: int = 1
var sprite: Sprite2D
var age: float = 0.0
var base_y: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 11.0
	collision.shape = shape
	add_child(collision)
	sprite = Sprite2D.new()
	sprite.texture = FLESH_TEXTURE if kind == "flesh" else ASH_TEXTURE
	sprite.z_index = 8
	add_child(sprite)
	base_y = position.y

func _process(delta: float) -> void:
	age += delta
	sprite.position.y = -5.0 + sin(age * 5.0) * 3.0
	sprite.rotation = sin(age * 2.7) * 0.08

func _on_body_entered(body: Node2D) -> void:
	if body is NecromancerPlayer:
		collected.emit(kind, amount)
		queue_free()
