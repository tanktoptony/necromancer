class_name RoomBreakableSpawn
extends Marker2D

@export var prop_kind: String = "urn"
@export var drop_kind: String = "ash"
@export var drop_amount: int = 1
@export var health: int = 1

func _ready() -> void:
	add_to_group("room_breakable_spawns")
