class_name RaisedGuard
extends CharacterBody2D

signal lost(guard)
signal projectile_requested(origin: Vector2, direction: Vector2, speed: float, damage: int, visual_kind: String)
signal damaged(position: Vector2, amount: int, heavy: bool)

enum Role { GUARD, BRUTE, SENTRY }
enum CommandMode { FOLLOW, HOLD, ASSAULT }

const GRAVITY: float = 820.0
const JUMP_VELOCITY: float = -276.0
const REFORM_DELAY: float = 0.2
# Same per-frame width fix as RaggedEnemy - see enemy.gd's
# HANGED_SAILOR_FRAME_SCALE_X for the measurement this comes from. Keyed by
# absolute enemy_N.png index; HANGED_SAILOR_ANIM_FRAMES maps AnimatedSprite2D's
# per-animation-local sprite.frame to that absolute index.
const HANGED_SAILOR_FRAME_SCALE_X: Dictionary = {
	0: 0.400, 1: 0.554, 2: 1.384, 3: 0.899, 4: 0.765,
	5: 0.899, 6: 0.400, 7: 0.545, 8: 0.856, 9: 0.783
}
const HANGED_SAILOR_ANIM_FRAMES: Dictionary = {
	"dead": [0], "rise": [0, 1, 2], "idle": [2, 3], "run": [4, 5, 8, 9], "attack": [6, 7]
}

var player: NecromancerPlayer
var resurrected: bool = false
var role: Role = Role.GUARD
var source_archetype: int = -1
var command_mode: CommandMode = CommandMode.FOLLOW
var hold_position: Vector2 = Vector2.ZERO
var health: int = 3
var max_health: int = 3
var attack_cooldown: float = 0.0
var attack_windup: float = 0.0
var attack_recovery: float = 0.0
var pending_target: RaggedEnemy
var rise_time: float = 0.0
var hurt_time: float = 0.0
var follow_slot: int = 0
var body_collision: CollisionShape2D
var sprite: AnimatedSprite2D
var sprite_base_position: Vector2 = Vector2.ZERO
var sprite_base_scale: Vector2 = Vector2.ONE
var walk_cycle_phase: float = 0.0
var run_anim_grace: float = 0.0
var stuck_time: float = 0.0
var last_position: Vector2 = Vector2.ZERO
var jump_cooldown: float = 0.0
var formation_side: float = 1.0
var ledge_wait_time: float = 0.0
var facing: float = 1.0
var target_memory: RaggedEnemy
var target_memory_timer: float = 0.0
var airborne_time: float = 0.0
var vertical_separation_time: float = 0.0
var reforming: bool = false
var reform_timer: float = 0.0
var reform_destination: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("allies")
	collision_layer = 8
	collision_mask = 1
	floor_snap_length = 5.0
	floor_stop_on_slope = true
	safe_margin = 0.04
	_configure_role()
	body_collision = CollisionShape2D.new()
	var shape: CapsuleShape2D = CapsuleShape2D.new()
	shape.radius = 7.0 if role != Role.BRUTE else 9.0
	shape.height = 38.0 if role != Role.BRUTE else 42.0
	var collision_y: float = -19.0 if role != Role.BRUTE else -21.0
	if source_archetype == RaggedEnemy.Archetype.BILGE_CRAWLER:
		shape.radius = 6.0
		shape.height = 24.0
		collision_y = -12.0
	elif source_archetype == RaggedEnemy.Archetype.BONE_CROW:
		shape.radius = 5.0
		shape.height = 15.0
		collision_y = -12.0
	body_collision.shape = shape
	body_collision.position = Vector2(0.0, collision_y)
	add_child(body_collision)
	body_collision.disabled = not resurrected
	_build_sprite()
	last_position = global_position
	hold_position = global_position

func _configure_role() -> void:
	match role:
		Role.GUARD:
			max_health = 3
		Role.BRUTE:
			max_health = 5
		Role.SENTRY:
			max_health = 2
	health = max_health

func _build_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.position = Vector2(0.0, -34.0)
	var animations: Dictionary
	var folder: String = "res://assets/sprites/guard"
	if source_archetype >= 0:
		folder = _source_sprite_folder()
		animations = {
			"dead": {"frames": [0], "fps": 1.0, "loop": false},
			"rise": {"frames": [0, 1, 2], "fps": 6.0, "loop": false},
			"idle": {"frames": [2, 3], "fps": 2.5, "loop": true},
			"run": {"frames": [4, 5, 8, 9], "fps": 8.0, "loop": true},
			"attack": {"frames": [6, 7], "fps": 7.0, "loop": false}
		}
	else:
		animations = {
			"dead": {"frames": [0], "fps": 1.0, "loop": false},
			"rise": {"frames": [1, 2], "fps": 5.0, "loop": false},
			"idle": {"frames": [3, 4], "fps": 2.5, "loop": true},
			"run": {"frames": [5, 6, 8, 9], "fps": 8.0, "loop": true},
			"attack": {"frames": [7], "fps": 1.0, "loop": false}
		}
	sprite.sprite_frames = FrameLibrary.build_frames(folder, "enemy" if source_archetype >= 0 else "guard", animations)
	match role:
		Role.BRUTE:
			sprite.scale = Vector2(1.15, 1.15)
		Role.SENTRY:
			sprite.scale = Vector2(0.94, 0.94)
	if source_archetype >= 0:
		# Same oversized-source-art correction as RaggedEnemy._build_sprite;
		# without it a raised ally renders at full (too-large) enemy scale.
		var correction: float = _source_scale_correction()
		sprite.scale *= correction
		sprite.position *= correction
		# Raised enemies keep their old silhouette; necromancy is communicated by corpse-light, not replacement art.
		sprite.modulate = Color(0.66, 1.0, 0.82, 1.0)
	else:
		sprite.modulate = Color(0.78, 0.93, 0.84, 1.0)
	sprite_base_position = sprite.position
	sprite_base_scale = sprite.scale
	add_child(sprite)
	sprite.play("idle" if resurrected else "dead")

func _source_scale_correction() -> float:
	# Kept in sync with RaggedEnemy._build_sprite's per-archetype scale -
	# see that function's comment for the measurement methodology.
	match source_archetype:
		RaggedEnemy.Archetype.SHIELD_GUARD:
			return 0.66
		RaggedEnemy.Archetype.LANTERN_TOSSER, RaggedEnemy.Archetype.SENTRY:
			return 0.69
		RaggedEnemy.Archetype.BRUTE, RaggedEnemy.Archetype.CHARGER:
			return 0.67
		RaggedEnemy.Archetype.BELL_WRETCH:
			return 0.62
		RaggedEnemy.Archetype.HANGED_SAILOR:
			return 0.627
		RaggedEnemy.Archetype.BILGE_CRAWLER:
			return 0.84
		RaggedEnemy.Archetype.BONE_CROW:
			return 0.68
		RaggedEnemy.Archetype.COFFIN_MIMIC:
			return 0.8
		_:
			return 1.0

func _source_sprite_folder() -> String:
	match source_archetype:
		RaggedEnemy.Archetype.SHIELD_GUARD:
			return "res://assets/sprites/enemy_types/grave_guard"
		RaggedEnemy.Archetype.LANTERN_TOSSER, RaggedEnemy.Archetype.SENTRY:
			return "res://assets/sprites/enemy_types/lantern_tosser"
		RaggedEnemy.Archetype.BILGE_CRAWLER, RaggedEnemy.Archetype.HOPPER:
			return "res://assets/sprites/enemy_types/bilge_crawler"
		RaggedEnemy.Archetype.BRUTE, RaggedEnemy.Archetype.CHARGER:
			return "res://assets/sprites/enemy_types/hook_brute"
		RaggedEnemy.Archetype.BELL_WRETCH:
			return "res://assets/sprites/enemy_types/bell_keeper"
		RaggedEnemy.Archetype.HANGED_SAILOR:
			return "res://assets/sprites/enemy_types/hanged_sailor"
		RaggedEnemy.Archetype.BONE_CROW:
			return "res://assets/sprites/enemy_types/bone_crow"
		RaggedEnemy.Archetype.COFFIN_MIMIC:
			return "res://assets/sprites/enemy_types/coffin_mimic"
		_:
			return "res://assets/sprites/enemy_types/walker"

func resurrect(play_rise_animation: bool = true) -> void:
	if resurrected:
		return
	resurrected = true
	body_collision.set_deferred("disabled", false)
	if play_rise_animation:
		rise_time = 0.48
		if sprite != null:
			sprite.play("rise")
	else:
		rise_time = 0.0
		if sprite != null:
			sprite.play("idle")

func set_command(mode: int) -> void:
	command_mode = mode
	if command_mode == CommandMode.HOLD:
		hold_position = global_position
	target_memory = null
	target_memory_timer = 0.0
	pending_target = null
	attack_windup = 0.0

func set_hold_position(position_value: Vector2) -> void:
	command_mode = CommandMode.HOLD
	hold_position = position_value
	target_memory = null
	target_memory_timer = 0.0
	pending_target = null
	attack_windup = 0.0


func _physics_process(delta: float) -> void:
	if not resurrected or health <= 0 or not is_instance_valid(player):
		return
	if reforming:
		_update_reform(delta)
		return

	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	attack_windup = maxf(0.0, attack_windup - delta)
	attack_recovery = maxf(0.0, attack_recovery - delta)
	rise_time = maxf(0.0, rise_time - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	jump_cooldown = maxf(0.0, jump_cooldown - delta)
	target_memory_timer = maxf(0.0, target_memory_timer - delta)
	run_anim_grace = maxf(0.0, run_anim_grace - delta)
	if source_archetype == RaggedEnemy.Archetype.BONE_CROW:
		_physics_process_crow_follower(delta)
		return
	if not is_on_floor():
		airborne_time += delta
		velocity.y += GRAVITY * delta
	else:
		airborne_time = 0.0

	formation_side = move_toward(formation_side, player.facing, 3.4 * delta)
	var target_enemy: RaggedEnemy = _find_combat_target()
	var desired_position: Vector2 = _command_position()
	var speed_limit: float = _follow_speed()

	if is_instance_valid(target_enemy):
		desired_position = _combat_position(target_enemy)
		speed_limit = _combat_speed()

	if attack_windup > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, _braking() * delta)
		if attack_windup <= delta:
			_commit_pending_attack()
	elif attack_recovery > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, _braking() * delta)
	elif is_instance_valid(target_enemy) and _can_start_attack(target_enemy):
		_begin_attack(target_enemy)
	else:
		desired_position.x += _ally_separation_offset()
		_update_horizontal_motion(delta, desired_position.x, speed_limit)
		_update_vertical_navigation(desired_position)

	var requested_horizontal_motion: float = velocity.x
	move_and_slide()
	_update_stuck_state(delta, requested_horizontal_motion, desired_position)
	_update_animation(target_enemy)

func _physics_process_crow_follower(delta: float) -> void:
	var target_enemy: RaggedEnemy = _find_combat_target()
	var desired: Vector2 = player.global_position + Vector2(-player.facing * (64.0 + float(follow_slot) * 18.0), -72.0 - float(follow_slot % 2) * 12.0)
	if is_instance_valid(target_enemy):
		var enemy_side: float = signf(target_enemy.global_position.x - player.global_position.x)
		if enemy_side == 0.0:
			enemy_side = player.facing
		desired = target_enemy.global_position - Vector2(enemy_side * 118.0, 62.0)
		var difference: Vector2 = target_enemy.global_position - global_position
		if attack_cooldown <= 0.0 and difference.length() <= 205.0 and _has_line_of_sight(target_enemy.global_position):
			var aim: Vector2 = (target_enemy.global_position + target_enemy.velocity * 0.12 - global_position).normalized()
			projectile_requested.emit(global_position, aim, 215.0, 1, "bolt")
			attack_cooldown = 1.2 + float(follow_slot) * 0.08
	var desired_velocity: Vector2 = (desired - global_position).limit_length(105.0) * 1.25
	velocity = velocity.move_toward(desired_velocity, 420.0 * delta)
	if absf(velocity.x) > 6.0:
		facing = signf(velocity.x)
	move_and_slide()
	if global_position.distance_to(player.global_position) > 360.0:
		reform_near_player(true)
	_update_animation(target_enemy)

func _follow_speed() -> float:
	return 82.0 if role == Role.BRUTE else (96.0 if role == Role.GUARD else 100.0)

func _combat_speed() -> float:
	return 90.0 if role == Role.BRUTE else (108.0 if role == Role.GUARD else 98.0)

func _acceleration() -> float:
	return 620.0 if role == Role.BRUTE else 790.0

func _braking() -> float:
	return 1700.0 if role == Role.BRUTE else 2200.0

func _command_position() -> Vector2:
	match command_mode:
		CommandMode.HOLD:
			return hold_position + Vector2(float(follow_slot % 2) * 15.0, 0.0)
		CommandMode.ASSAULT:
			return player.global_position + Vector2(-formation_side * (52.0 + float(follow_slot) * 24.0), 0.0)
		_:
			var row: int = int(follow_slot / 2)
			var side_index: float = -1.0 if follow_slot % 2 == 0 else 1.0
			var behind_distance: float = 42.0 + float(row) * 32.0
			var lateral_spread: float = side_index * 17.0
			return player.global_position + Vector2(-formation_side * behind_distance + lateral_spread, 0.0)

func _combat_position(enemy: RaggedEnemy) -> Vector2:
	var enemy_side: float = signf(enemy.global_position.x - player.global_position.x)
	if enemy_side == 0.0:
		enemy_side = player.facing
	match role:
		Role.SENTRY:
			return enemy.global_position - Vector2(enemy_side * (112.0 + float(follow_slot) * 10.0), 0.0)
		Role.BRUTE:
			return enemy.global_position - Vector2(enemy_side * 34.0, 0.0)
		_:
			return enemy.global_position - Vector2(enemy_side * (29.0 + float(follow_slot) * 6.0), 0.0)

func _can_start_attack(enemy: RaggedEnemy) -> bool:
	if attack_cooldown > 0.0 or attack_recovery > 0.0 or not is_instance_valid(enemy):
		return false
	var difference: Vector2 = enemy.global_position - global_position
	var horizontal: float = absf(difference.x)
	var vertical: float = absf(difference.y)
	if role == Role.SENTRY:
		return horizontal >= 78.0 and horizontal <= 178.0 and vertical <= 82.0 and _has_line_of_sight(enemy.global_position)
	var attack_range: float = 38.0 if role == Role.BRUTE else 32.0
	return horizontal <= attack_range and vertical <= 42.0 and _has_line_of_sight(enemy.global_position)

func _begin_attack(enemy: RaggedEnemy) -> void:
	pending_target = enemy
	facing = signf(enemy.global_position.x - global_position.x) if absf(enemy.global_position.x - global_position.x) > 1.0 else facing
	attack_windup = 0.38 if role == Role.BRUTE else (0.3 if role == Role.SENTRY else 0.2)
	velocity.x = move_toward(velocity.x, 0.0, _braking() * 0.08)

func _commit_pending_attack() -> void:
	var enemy: RaggedEnemy = pending_target
	pending_target = null
	if not is_instance_valid(enemy) or not enemy.is_hostile_active():
		attack_recovery = 0.18
		return
	var difference: Vector2 = enemy.global_position - global_position
	facing = signf(difference.x) if absf(difference.x) > 1.0 else facing
	match role:
		Role.SENTRY:
			if absf(difference.x) >= 70.0 and absf(difference.x) <= 190.0 and absf(difference.y) <= 90.0 and _has_line_of_sight(enemy.global_position):
				var aim: Vector2 = (enemy.global_position + enemy.velocity * 0.16 - global_position).normalized()
				var kind: String = "lantern" if source_archetype == RaggedEnemy.Archetype.LANTERN_TOSSER else "bolt"
				projectile_requested.emit(global_position + Vector2(facing * 10.0, -25.0), aim, 205.0, 1, kind)
			attack_cooldown = 1.45 + float(follow_slot) * 0.08
			attack_recovery = 0.34
		Role.BRUTE:
			if _melee_target_valid(enemy, 42.0, 45.0):
				enemy.take_hit(global_position.x, 2, true)
			attack_cooldown = 1.25
			attack_recovery = 0.46
		_:
			if _melee_target_valid(enemy, 35.0, 40.0):
				enemy.take_hit(global_position.x, 1, false)
			attack_cooldown = 0.92 + float(follow_slot) * 0.09
			attack_recovery = 0.28

func _melee_target_valid(enemy: RaggedEnemy, horizontal_range: float, vertical_range: float) -> bool:
	if not is_instance_valid(enemy) or not enemy.is_hostile_active():
		return false
	var difference: Vector2 = enemy.global_position - global_position
	if absf(difference.x) > horizontal_range or absf(difference.y) > vertical_range:
		return false
	if signf(difference.x) != signf(facing) and absf(difference.x) > 5.0:
		return false
	return _has_line_of_sight(enemy.global_position)

func _update_horizontal_motion(delta: float, desired_x: float, speed_limit: float) -> void:
	var difference: float = desired_x - global_position.x
	var stop_radius: float = 17.0 if command_mode != CommandMode.HOLD else 11.0
	if absf(difference) <= stop_radius:
		velocity.x = move_toward(velocity.x, 0.0, _braking() * delta)
		ledge_wait_time = 0.0
		return
	var direction: float = signf(difference)
	if is_on_floor() and not _has_floor_ahead(direction):
		velocity.x = move_toward(velocity.x, 0.0, _braking() * delta)
		ledge_wait_time += delta
		if ledge_wait_time > 0.6 and command_mode != CommandMode.HOLD:
			reform_near_player()
		return
	ledge_wait_time = 0.0
	var proportional_speed: float = minf(absf(difference) * 1.7, speed_limit)
	var desired_velocity: float = direction * proportional_speed
	velocity.x = move_toward(velocity.x, desired_velocity, _acceleration() * delta)
	if absf(velocity.x) > 7.0:
		facing = signf(velocity.x)

func _update_vertical_navigation(desired_position: Vector2) -> void:
	if not is_on_floor() or jump_cooldown > 0.0:
		return
	var vertical_difference: float = desired_position.y - global_position.y
	var horizontal_difference: float = absf(desired_position.x - global_position.x)
	if vertical_difference < -30.0 and vertical_difference >= -62.0 and horizontal_difference < 112.0 and _has_safe_jump_landing(desired_position):
		velocity.y = JUMP_VELOCITY if role != Role.BRUTE else -252.0
		jump_cooldown = 0.9

func _has_safe_jump_landing(desired_position: Vector2) -> bool:
	var start: Vector2 = Vector2(desired_position.x, desired_position.y - 18.0)
	var finish: Vector2 = Vector2(desired_position.x, desired_position.y + 32.0)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, finish, 1)
	query.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _has_floor_ahead(direction: float) -> bool:
	if not is_on_floor() or absf(direction) < 0.01:
		return true
	var supported_probes: int = 0
	for horizontal_offset: float in [14.0, 23.0]:
		var start: Vector2 = global_position + Vector2(direction * horizontal_offset, -2.0)
		var finish: Vector2 = start + Vector2(0.0, 44.0)
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, finish, 1)
		query.exclude = [get_rid()]
		if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			supported_probes += 1
	return supported_probes == 2

func _has_line_of_sight(target_position: Vector2) -> bool:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0.0, -24.0),
		target_position + Vector2(0.0, -22.0),
		1
	)
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _find_combat_target() -> RaggedEnemy:
	if target_memory_timer > 0.0 and is_instance_valid(target_memory) and _target_is_reachable(target_memory):
		return target_memory
	var best: RaggedEnemy = null
	var leash: float = 150.0
	match command_mode:
		CommandMode.HOLD:
			leash = 135.0
		CommandMode.ASSAULT:
			leash = 300.0
		_:
			leash = 190.0
	var origin: Vector2 = hold_position if command_mode == CommandMode.HOLD else player.global_position
	var best_score: float = INF
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if not node is RaggedEnemy:
			continue
		var candidate: RaggedEnemy = node as RaggedEnemy
		if not _target_is_reachable(candidate):
			continue
		var distance: float = origin.distance_to(candidate.global_position)
		if distance > leash:
			continue
		var score: float = distance
		match role:
			Role.GUARD:
				# Guards protect the necromancer first, rather than chasing the nearest random body.
				score += candidate.global_position.distance_to(player.global_position) * 0.45
				if candidate.archetype in [RaggedEnemy.Archetype.CHARGER, RaggedEnemy.Archetype.SHIELD_GUARD]:
					score -= 26.0
			Role.BRUTE:
				# Brutes prefer the enemy most likely to clog the frontline.
				if candidate.archetype in [RaggedEnemy.Archetype.BRUTE, RaggedEnemy.Archetype.CHARGER, RaggedEnemy.Archetype.SHIELD_GUARD]:
					score -= 62.0
				score -= float(candidate.health) * 3.0
			Role.SENTRY:
				# Sentries prioritize support/ranged nuisances and avoid wasting shots on the nearest tank.
				if candidate.archetype in [RaggedEnemy.Archetype.SENTRY, RaggedEnemy.Archetype.BELL_WRETCH, RaggedEnemy.Archetype.LANTERN_TOSSER, RaggedEnemy.Archetype.HOPPER]:
					score -= 54.0
				if candidate.archetype == RaggedEnemy.Archetype.BRUTE:
					score += 34.0
		if score < best_score:
			best = candidate
			best_score = score
	target_memory = best
	target_memory_timer = 0.34
	return best

func _target_is_reachable(candidate: RaggedEnemy) -> bool:
	if not is_instance_valid(candidate) or not candidate.is_hostile_active() or not candidate.is_engaged_with(player):
		return false
	var vertical: float = absf(candidate.global_position.y - global_position.y)
	if role == Role.SENTRY:
		return vertical <= 105.0 and _has_line_of_sight(candidate.global_position)
	return vertical <= 48.0 and _has_line_of_sight(candidate.global_position)

func _ally_separation_offset() -> float:
	var offset: float = 0.0
	for node: Node in get_tree().get_nodes_in_group("allies"):
		if node == self or not node is RaisedGuard:
			continue
		var other: RaisedGuard = node as RaisedGuard
		if not other.resurrected or other.health <= 0 or absf(other.global_position.y - global_position.y) > 34.0:
			continue
		var difference: float = global_position.x - other.global_position.x
		if absf(difference) < 24.0:
			offset += signf(difference if absf(difference) > 0.5 else (1.0 if follow_slot > other.follow_slot else -1.0)) * (24.0 - absf(difference)) * 0.55
	return clampf(offset, -18.0, 18.0)

func _update_stuck_state(delta: float, requested_horizontal_motion: float, desired_position: Vector2) -> void:
	var moved_distance: float = global_position.distance_to(last_position)
	var intends_to_move: bool = absf(requested_horizontal_motion) > 9.0
	if intends_to_move and moved_distance < 0.28 and is_on_floor() and command_mode != CommandMode.HOLD:
		stuck_time += delta
	else:
		stuck_time = maxf(0.0, stuck_time - delta * 2.0)

	var vertical_separation: float = absf(desired_position.y - global_position.y)
	if vertical_separation > 88.0 and command_mode != CommandMode.HOLD:
		vertical_separation_time += delta
	else:
		vertical_separation_time = maxf(0.0, vertical_separation_time - delta * 2.0)

	if stuck_time > 0.62 or airborne_time > 1.05 or vertical_separation_time > 0.85:
		reform_near_player()
	last_position = global_position

func reform_near_player(force: bool = false) -> void:
	if reforming or not is_instance_valid(player) or (command_mode == CommandMode.HOLD and not force):
		return
	reforming = true
	reform_timer = REFORM_DELAY
	reform_destination = _floor_position_near(player.global_position + Vector2(-player.facing * (38.0 + float(follow_slot) * 24.0), -4.0))
	velocity = Vector2.ZERO
	body_collision.set_deferred("disabled", true)
	if sprite != null:
		sprite.modulate.a = 0.35

func _update_reform(delta: float) -> void:
	reform_timer -= delta
	if reform_timer > 0.0:
		return
	global_position = reform_destination
	velocity = Vector2.ZERO
	reforming = false
	stuck_time = 0.0
	airborne_time = 0.0
	vertical_separation_time = 0.0
	ledge_wait_time = 0.0
	body_collision.set_deferred("disabled", false)
	if sprite != null:
		sprite.modulate.a = 1.0

func snap_near_player() -> void:
	if command_mode == CommandMode.HOLD:
		return
	global_position = _floor_position_near(player.global_position + Vector2(-player.facing * (38.0 + float(follow_slot) * 24.0), -4.0))
	velocity = Vector2.ZERO
	ledge_wait_time = 0.0
	stuck_time = 0.0
	airborne_time = 0.0
	vertical_separation_time = 0.0

func _floor_position_near(preferred: Vector2) -> Vector2:
	var candidate_offsets: Array[float] = [0.0, -28.0, 28.0, -54.0, 54.0, -82.0, 82.0]
	for x_offset: float in candidate_offsets:
		var ray_start: Vector2 = preferred + Vector2(x_offset, -58.0)
		var ray_end: Vector2 = ray_start + Vector2(0.0, 178.0)
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(ray_start, ray_end, 1)
		query.exclude = [get_rid()]
		var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var hit_position: Vector2 = hit["position"]
			return Vector2(ray_start.x, hit_position.y - 1.0)
	return player.global_position

func take_damage(amount: int, from_x: float) -> void:
	if hurt_time > 0.0 or health <= 0 or reforming:
		return
	health -= amount
	hurt_time = 0.45
	attack_windup = 0.0
	pending_target = null
	velocity = Vector2(signf(global_position.x - from_x) * 95.0, -78.0)
	damaged.emit(global_position, amount, amount >= 2)
	if health <= 0:
		resurrected = false
		body_collision.set_deferred("disabled", true)
		if sprite != null:
			sprite.play("dead")
		lost.emit(self)
		queue_free()

func _update_animation(target_enemy: RaggedEnemy) -> void:
	if sprite == null or rise_time > 0.0 or reforming:
		return
	var role_color: Color = Color(0.72, 0.98, 0.82, 1.0) if source_archetype >= 0 else Color.WHITE
	if role == Role.BRUTE:
		role_color = Color(0.82, 0.82, 0.57, 1.0) if source_archetype >= 0 else Color(0.92, 0.72, 0.58, 1.0)
	elif role == Role.SENTRY:
		role_color = Color(0.62, 0.95, 0.9, 1.0) if source_archetype >= 0 else Color(0.68, 0.88, 1.0, 1.0)
	if hurt_time > 0.0 and int(hurt_time * 26.0) % 2 == 0:
		sprite.modulate = Color(1.0, 0.4, 0.4, 0.45)
	elif attack_windup > 0.0:
		sprite.modulate = role_color.lerp(Color(1.0, 0.9, 0.42, 1.0), 0.55)
	elif attack_recovery > 0.0:
		sprite.modulate = role_color.darkened(0.25)
	else:
		sprite.modulate = role_color
	if is_instance_valid(target_enemy):
		sprite.flip_h = target_enemy.global_position.x < global_position.x
	else:
		sprite.flip_h = facing < 0.0
	if attack_windup > 0.0 or attack_recovery > 0.0:
		sprite.play("attack")
	elif absf(velocity.x) > 8.0:
		run_anim_grace = 0.15
		sprite.play("run")
	elif run_anim_grace > 0.0:
		# Same fix as RaggedEnemy: following/combat repositioning decelerates
		# smoothly through zero on every direction change, which briefly reads
		# as "stopped" and flashes the idle pose mid-stride without this grace.
		sprite.play("run")
	else:
		sprite.play("idle")
	if sprite.animation == "run":
		sprite.speed_scale = clampf(absf(velocity.x) / maxf(_follow_speed(), 1.0), 0.45, 1.15)
	else:
		sprite.speed_scale = 1.0

	# Keep the authored footfalls stable instead of adding an unrelated
	# procedural bob/squash cycle on top of them.
	sprite.position = sprite_base_position
	sprite.scale = sprite_base_scale
	if source_archetype == RaggedEnemy.Archetype.HANGED_SAILOR:
		var abs_frames: Array = HANGED_SAILOR_ANIM_FRAMES.get(sprite.animation, [])
		if sprite.frame < abs_frames.size():
			var abs_index: int = abs_frames[sprite.frame]
			if HANGED_SAILOR_FRAME_SCALE_X.has(abs_index):
				sprite.scale.x = HANGED_SAILOR_FRAME_SCALE_X[abs_index] * (sprite_base_scale.x / 0.627)

func can_be_raised() -> bool:
	return not resurrected
