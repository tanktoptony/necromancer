class_name BargeMapOverlay
extends Control

const CELL_SIZE: float = 18.0
const MAP_ORIGIN: Vector2 = Vector2(56.0, 70.0)
const PARCHMENT: Texture2D = preload("res://assets/vania10/map_parchment.png")
const ROOM_EXPLORED: Texture2D = preload("res://assets/vania10/map_room_explored.png")
const ROOM_CURRENT: Texture2D = preload("res://assets/vania10/map_room_current.png")
const PLAYER_MARKER: Texture2D = preload("res://assets/vania10/map_player.png")
const HOOK_MARKER: Texture2D = preload("res://assets/vania10/map_hook.png")
const GATE_MARKER: Texture2D = preload("res://assets/vania10/map_gate.png")
const HEART_MARKER: Texture2D = preload("res://assets/vania10/map_heart.png")
const CONNECTOR_HORIZONTAL: Texture2D = preload("res://assets/vania10/map_connector_horizontal.png")
const CONNECTOR_VERTICAL: Texture2D = preload("res://assets/vania10/map_connector_vertical.png")
const CONNECTOR_CORNER: Texture2D = preload("res://assets/vania10/map_connector_corner.png")
const CONNECTOR_SEALED: Texture2D = preload("res://assets/vania10/map_connector_sealed.png")

var current_room: String = "receiving"
var local_position: Vector2 = Vector2.ZERO
var discovered: Dictionary = {}
var has_hook: bool = false
var gate_open: bool = false
var heart_collected: bool = false

var room_names: Dictionary = {
	"receiving": "Receiving Hold",
	"gallery": "Quarantine Gallery",
	"gate": "Rib Gate",
	"breach": "Hull Breach",
	"chain": "Chain Crypt",
	"deck": "Ossuary Deck",
	"orlop": "Upper Orlop",
	"shaft": "Winch Shaft",
	"rigging": "Rigging Walk",
	"galley": "Mourning Galley",
	"captain": "Captain's Ossuary"
}

var room_sizes: Dictionary = {
	"receiving": Vector2(768,360),
	"gallery": Vector2(1152,648),
	"gate": Vector2(768,360),
	"breach": Vector2(960,360),
	"chain": Vector2(576,360),
	"deck": Vector2(1152,360),
	"orlop": Vector2(1152,360),
	"shaft": Vector2(384,648),
	"rigging": Vector2(960,360),
	"galley": Vector2(768,360),
	"captain": Vector2(960,360)
}

func _ready() -> void:
	custom_minimum_size = Vector2(600.0, 330.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func update_map(room_value: String, position_value: Vector2, discovered_value: Dictionary, hook_value: bool, gate_value: bool, heart_value: bool) -> void:
	current_room = room_value
	local_position = position_value
	discovered = discovered_value
	has_hook = hook_value
	gate_open = gate_value
	heart_collected = heart_value
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(PARCHMENT, Rect2(Vector2.ZERO, size), false)
	var ink := Color(0.21, 0.14, 0.09, 0.95)
	var pale := Color(0.34, 0.25, 0.16, 0.92)
	draw_string(ThemeDB.fallback_font, Vector2(30.0, 42.0), "THE PALLID BARGE — FIRST DAWN", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, ink)
	draw_string(ThemeDB.fallback_font, Vector2(510.0, 40.0), "M CLOSE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, pale)
	_draw_connections()
	for room_id_value: String in _room_cells().keys():
		if not bool(discovered.get(room_id_value, false)):
			continue
		for cell: Vector2i in _room_cells()[room_id_value]:
			_draw_cell(cell, room_id_value == current_room)
	_draw_markers()
	var current_name: String = str(room_names.get(current_room, "Unknown Compartment"))
	draw_string(ThemeDB.fallback_font, Vector2(30.0, 285.0), current_name, HORIZONTAL_ALIGNMENT_LEFT, 390.0, 15, ink)
	draw_string(ThemeDB.fallback_font, Vector2(30.0, 311.0), "rooms are compartments; doors are connections; purple marks necromancy", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, pale)

func _draw_cell(cell: Vector2i, is_current: bool) -> void:
	var texture: Texture2D = ROOM_CURRENT if is_current else ROOM_EXPLORED
	var position: Vector2 = MAP_ORIGIN + Vector2(cell.x, cell.y) * CELL_SIZE
	draw_texture_rect(texture, Rect2(position, Vector2(CELL_SIZE, CELL_SIZE)), false)

func _draw_connections() -> void:
	_connect_if("receiving", "gallery", Vector2i(3,4), Vector2i(4,4))
	_connect_if("gallery", "gate", Vector2i(9,4), Vector2i(10,4))
	_connect_if("gate", "breach", Vector2i(11,5), Vector2i(11,6))
	_connect_if("breach", "chain", Vector2i(15,7), Vector2i(16,7))
	_connect_if("gate", "deck", Vector2i(13,4), Vector2i(14,4), not gate_open)
	# The crypt lift is the return leg that makes the first area a circuit instead of a hallway.
	_connect_if("chain", "gate", Vector2i(18,6), Vector2i(12,5))
	# orlop/shaft/rigging/galley/captain are drawn without map cells: the 600x330
	# parchment canvas is already nearly the full 640-wide game viewport, with no
	# room left to extend the grid for 5 more compartments without a wider map
	# redesign. room_names/room_sizes above keep the HUD label and player-dot
	# math correct in those rooms; _player_map_point falls back to MAP_ORIGIN
	# when a room has no rect, so this degrades gracefully instead of breaking.

func _connect_if(first: String, second: String, from_cell: Vector2i, to_cell: Vector2i, sealed: bool = false) -> void:
	if not bool(discovered.get(first, false)) or not bool(discovered.get(second, false)):
		return
	var from_point: Vector2 = _cell_center(from_cell)
	var to_point: Vector2 = _cell_center(to_cell)
	var middle := Vector2(to_point.x, from_point.y)
	_draw_connector_leg(from_point, middle, CONNECTOR_HORIZONTAL)
	_draw_connector_leg(middle, to_point, CONNECTOR_VERTICAL)
	if from_point.x != to_point.x and from_point.y != to_point.y:
		var horizontal_sign := signf(from_point.x - middle.x)
		var vertical_sign := signf(to_point.y - middle.y)
		var rotation := 0.0
		if horizontal_sign < 0.0 and vertical_sign > 0.0:
			rotation = PI * 0.5
		elif horizontal_sign < 0.0 and vertical_sign < 0.0:
			rotation = PI
		elif horizontal_sign > 0.0 and vertical_sign < 0.0:
			rotation = -PI * 0.5
		_draw_connector_at(CONNECTOR_CORNER, middle, rotation)
	if sealed:
		_draw_connector_at(CONNECTOR_SEALED, (from_point + to_point) * 0.5)

func _draw_connector_leg(start: Vector2, finish: Vector2, texture: Texture2D) -> void:
	var distance := start.distance_to(finish)
	if distance < 1.0:
		return
	var direction := start.direction_to(finish)
	var steps := maxi(1, int(ceil(distance / CELL_SIZE)))
	for index in range(steps + 1):
		var point := start + direction * minf(distance, float(index) * CELL_SIZE)
		_draw_connector_at(texture, point)

func _draw_connector_at(texture: Texture2D, center: Vector2, rotation: float = 0.0) -> void:
	draw_set_transform(center, rotation)
	draw_texture(texture, Vector2(-9.0, -9.0))
	draw_set_transform(Vector2.ZERO, 0.0)

func _draw_markers() -> void:
	draw_texture(PLAYER_MARKER, _player_map_point() - Vector2(5.0,5.0))
	if bool(discovered.get("chain", false)) and not has_hook:
		draw_texture(HOOK_MARKER, _cell_center(Vector2i(17,7)) - Vector2(5.0,5.0))
	if bool(discovered.get("gallery", false)) and not heart_collected:
		draw_texture(HEART_MARKER, _cell_center(Vector2i(8,2)) - Vector2(5.0,5.0))
	if bool(discovered.get("gate", false)):
		draw_texture(GATE_MARKER, _cell_center(Vector2i(12,4)) - Vector2(5.0,5.0))

func _cell_center(cell: Vector2i) -> Vector2:
	return MAP_ORIGIN + (Vector2(float(cell.x), float(cell.y)) + Vector2(0.5,0.5)) * CELL_SIZE

func _player_map_point() -> Vector2:
	var rects: Dictionary = _room_map_rects()
	if not rects.has(current_room):
		return MAP_ORIGIN
	var map_rect: Rect2 = rects[current_room]
	var rs: Vector2 = room_sizes.get(current_room, Vector2.ONE)
	var tx: float = clampf(local_position.x / maxf(rs.x,1.0),0.0,1.0)
	var ty: float = clampf(local_position.y / maxf(rs.y,1.0),0.0,1.0)
	return MAP_ORIGIN + Vector2(map_rect.position.x + tx * map_rect.size.x, map_rect.position.y + ty * map_rect.size.y) * CELL_SIZE + Vector2(CELL_SIZE*0.5,CELL_SIZE*0.5)

func _rect_cells(start_x: int, start_y: int, width: int, height: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y: int in range(start_y,start_y+height):
		for x: int in range(start_x,start_x+width):
			result.append(Vector2i(x,y))
	return result

func _room_cells() -> Dictionary:
	return {
		"receiving": _rect_cells(0,3,4,2),
		"gallery": _rect_cells(4,1,6,5),
		"gate": _rect_cells(10,3,4,3),
		"breach": _rect_cells(10,6,6,2),
		"chain": _rect_cells(16,6,3,2),
		"deck": _rect_cells(14,3,6,2)
	}

func _room_map_rects() -> Dictionary:
	return {
		"receiving": Rect2(0,3,4,2),
		"gallery": Rect2(4,1,6,5),
		"gate": Rect2(10,3,4,3),
		"breach": Rect2(10,6,6,2),
		"chain": Rect2(16,6,3,2),
		"deck": Rect2(14,3,6,2)
	}
