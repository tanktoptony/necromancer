class_name RoomHazard
extends Area2D

signal entered_hazard(hazard)

@export var hazard_id: String = "pit"
@export var damage: int = 1

func _ready() -> void:
	add_to_group("room_hazards")
	collision_layer = 0
	collision_mask = 2 | 4 | 8
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is NecromancerPlayer:
		entered_hazard.emit(self)
