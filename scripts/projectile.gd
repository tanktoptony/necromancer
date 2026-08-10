class_name BoneProjectile
extends Area2D

const LANTERN_TEXTURE: Texture2D = preload("res://assets/vfx/lantern_projectile.png")
const HOSTILE_BOLT_TEXTURE: Texture2D = preload("res://assets/vfx/bone_bolt_hostile.png")
const ALLY_BOLT_TEXTURE: Texture2D = preload("res://assets/vfx/bone_bolt_ally.png")

var velocity: Vector2 = Vector2.ZERO
var damage: int = 1
var lifetime: float = 2.2
var owner_x: float = 0.0
var hostile: bool = true
var visual_kind: String = "bolt"
var gravity_acceleration: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 11 if hostile else 5
	monitoring = true
	body_entered.connect(_on_body_entered)
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 7.0 if visual_kind == "lantern" else 4.0
	collision.shape = shape
	add_child(collision)
	if visual_kind == "lantern":
		gravity_acceleration = 280.0
		var lantern: Sprite2D = Sprite2D.new()
		lantern.texture = LANTERN_TEXTURE
		add_child(lantern)
		var glow: PointLight2D = PointLight2D.new()
		glow.energy = 0.75
		glow.texture_scale = 0.35
		glow.color = Color(1.0, 0.66, 0.32, 1.0)
		add_child(glow)
	else:
		var bolt: Sprite2D = Sprite2D.new()
		bolt.texture = HOSTILE_BOLT_TEXTURE if hostile else ALLY_BOLT_TEXTURE
		add_child(bolt)
		var glow: PointLight2D = PointLight2D.new()
		glow.energy = 0.55
		glow.texture_scale = 0.25
		glow.color = Color(0.72, 0.9, 1.0, 0.95) if hostile else Color(0.72, 1.0, 0.68, 0.95)
		add_child(glow)

func _physics_process(delta: float) -> void:
	var previous_position := global_position
	if visual_kind == "lantern":
		# A thrown lantern follows a ballistic arc but stays upright. Do not
		# rotate or tumble the static lantern artwork during flight.
		velocity.y += gravity_acceleration * delta
		rotation = 0.0
	else:
		rotation = velocity.angle()
	var next_position := previous_position + velocity * delta
	# Sweep the travelled segment so fast projectiles cannot pass through thin
	# deck collision between Area2D overlap samples.
	var query := PhysicsRayQueryParameters2D.create(previous_position, next_position, collision_mask)
	query.exclude = [get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position = hit.position
		var collider: Object = hit.get("collider")
		if collider is Node:
			_apply_hit(collider as Node)
		else:
			queue_free()
		return
	global_position = next_position
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	_apply_hit(body)

func _apply_hit(body: Node) -> void:
	if is_queued_for_deletion():
		return
	if hostile:
		if body is NecromancerPlayer:
			(body as NecromancerPlayer).take_damage(damage, owner_x)
		elif body is RaisedGuard:
			(body as RaisedGuard).take_damage(damage, owner_x)
	else:
		if body is RaggedEnemy:
			(body as RaggedEnemy).take_hit(owner_x, damage, false)
	queue_free()
