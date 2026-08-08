class_name BoneProjectile
extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 1
var lifetime: float = 2.2
var owner_x: float = 0.0
var hostile: bool = true

func _ready() -> void:
	collision_layer = 0
	collision_mask = 11 if hostile else 5
	monitoring = true
	body_entered.connect(_on_body_entered)
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 4.0
	collision.shape = shape
	add_child(collision)
	var diamond: Polygon2D = Polygon2D.new()
	diamond.polygon = PackedVector2Array([
		Vector2(0.0, -5.0), Vector2(5.0, 0.0), Vector2(0.0, 5.0), Vector2(-5.0, 0.0)
	])
	diamond.color = Color(0.72, 0.9, 1.0, 0.95) if hostile else Color(0.72, 1.0, 0.68, 0.95)
	add_child(diamond)
	var glow: PointLight2D = PointLight2D.new()
	glow.energy = 0.55
	glow.texture_scale = 0.25
	glow.color = diamond.color
	add_child(glow)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	rotation += delta * 7.0
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if hostile:
		if body is NecromancerPlayer:
			(body as NecromancerPlayer).take_damage(damage, owner_x)
		elif body is RaisedGuard:
			(body as RaisedGuard).take_damage(damage, owner_x)
	else:
		if body is RaggedEnemy:
			(body as RaggedEnemy).take_hit(owner_x, damage, false)
	queue_free()
