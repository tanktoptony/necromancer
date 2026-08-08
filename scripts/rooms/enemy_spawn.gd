class_name RoomEnemySpawn
extends Marker2D

@export var archetype: int = 0
@export var patrol_left: float = -80.0
@export var patrol_right: float = 80.0
@export var elite: bool = false
@export var phase: float = 0.0

func _ready() -> void:
	add_to_group("room_enemy_spawns")
