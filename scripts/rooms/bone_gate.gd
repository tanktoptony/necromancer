class_name BoneGate
extends StaticBody2D

const RIB_GATE_TEXTURE: Texture2D = preload("res://assets/vania11/rib_gate.png")

@export var gate_id: String = "rib_gate"
var gate_sprite: Sprite2D

func _ready() -> void:
	add_to_group("bone_gates")
	collision_layer = 1
	collision_mask = 0
	gate_sprite = Sprite2D.new()
	gate_sprite.texture = RIB_GATE_TEXTURE
	gate_sprite.position = Vector2(0.0, -4.0)
	gate_sprite.scale = Vector2(0.72, 0.72)
	gate_sprite.z_index = 6
	add_child(gate_sprite)

func open_gate() -> void:
	for child: Node in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", true)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.32)
	tween.tween_property(self, "position:y", position.y - 22.0, 0.32)
	tween.chain().tween_callback(queue_free)
