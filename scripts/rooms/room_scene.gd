class_name BargeRoomScene
extends Node2D

const PLATFORM_MODULE_TEXTURE: Texture2D = preload("res://assets/vania11/platform_module.png")
const DECK_TRIM_TEXTURE: Texture2D = preload("res://assets/vania11/deck_trim.png")

@export var room_id: String = ""
@export var room_title: String = ""
@export var room_size: Vector2 = Vector2(768.0, 360.0)
@export var camera_offset: Vector2 = Vector2(0.0, -18.0)
@export var camera_zoom: Vector2 = Vector2.ONE
@export var intro_note: String = ""
@export var poi_id: String = ""
@export var poi_trigger_x: float = -1.0
@export var poi_focus_offset: Vector2 = Vector2.ZERO
@export var pit_recovery_y: float = 99999.0


func _ready() -> void:
	_decorate_one_way_platforms()

func _decorate_one_way_platforms() -> void:
	var gameplay: Node = get_node_or_null("Gameplay")
	if gameplay == null:
		return
	var decor_root: Node2D = Node2D.new()
	decor_root.name = "PlatformDecor"
	decor_root.z_index = 2
	gameplay.add_child(decor_root)
	var collision_root: Node = get_node_or_null("Gameplay/Collision")
	if collision_root == null:
		return
	for node: Node in collision_root.find_children("*", "CollisionShape2D", true, false):
		if not node is CollisionShape2D:
			continue
		var collision := node as CollisionShape2D
		if not collision.shape is RectangleShape2D:
			continue
		var rect_shape := collision.shape as RectangleShape2D
		if rect_shape.size.x < 40.0 or rect_shape.size.y > 70.0:
			continue
		var body := collision.get_parent() as Node2D
		if body == null:
			continue
		var platform_art := Sprite2D.new()
		platform_art.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		platform_art.region_enabled = true
		var collision_top: float = -rect_shape.size.y * 0.5
		if collision.one_way_collision:
			platform_art.texture = PLATFORM_MODULE_TEXTURE
			platform_art.region_rect = Rect2(0.0, 0.0, rect_shape.size.x, 80.0)
			# The module's first 50 rows are transparent so the detailed plank face
			# begins exactly at the walkable collision edge and hangs below it.
			platform_art.position = body.position + collision.position + Vector2(0.0, collision_top - 10.0)
		else:
			platform_art.texture = DECK_TRIM_TEXTURE
			platform_art.region_rect = Rect2(0.0, 0.0, rect_shape.size.x, 20.0)
			platform_art.position = body.position + collision.position + Vector2(0.0, collision_top + 10.0)
		platform_art.modulate = Color(1.0, 1.0, 1.0, 1.0)
		decor_root.add_child(platform_art)

func get_spawn(spawn_id: String) -> Marker2D:
	var node: Node = get_node_or_null("SpawnPoints/%s" % spawn_id)
	if node is Marker2D:
		return node as Marker2D
	var fallback: Node = get_node_or_null("SpawnPoints/default")
	if fallback is Marker2D:
		return fallback as Marker2D
	return null

func _owned_group_nodes(group_name: String) -> Array:
	var result: Array = []
	for child: Node in get_tree().get_nodes_in_group(group_name):
		if is_ancestor_of(child):
			result.append(child)
	return result

func get_doors() -> Array:
	return _owned_group_nodes("room_doors")

func get_hook_anchors() -> Array:
	return _owned_group_nodes("room_hook_anchors")

func get_enemy_spawns() -> Array:
	return _owned_group_nodes("room_enemy_spawns")

func get_breakable_spawns() -> Array:
	return _owned_group_nodes("room_breakable_spawns")

func get_hazards() -> Array:
	return _owned_group_nodes("room_hazards")

func get_safe_markers() -> Array[Marker2D]:
	var result: Array[Marker2D] = []
	var safe_root: Node = get_node_or_null("SafePoints")
	if safe_root == null:
		return result
	for child: Node in safe_root.get_children():
		if child is Marker2D:
			result.append(child as Marker2D)
	return result
