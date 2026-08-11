class_name RaggedEnemy
extends CharacterBody2D

signal died(enemy)
signal projectile_requested(origin: Vector2, direction: Vector2, speed: float, damage: int, visual_kind: String)
signal alerted(enemy)
signal damaged(position: Vector2, amount: int, heavy: bool)
signal support_pulsed(position: Vector2)

enum Archetype { WALKER, CHARGER, SENTRY, HOPPER, BRUTE, BELL_WRETCH, SHIELD_GUARD, LANTERN_TOSSER, BILGE_CRAWLER, HANGED_SAILOR, BONE_CROW, COFFIN_MIMIC }
enum State { PATROL, ALERT, POSITION, WINDUP, ATTACK, RECOVER, BACKSTEP, HURT, DEAD }

const GRAVITY: float = 820.0
# hanged_sailor's source art varies from 27% to 94% canvas-width fill between
# frames (measured directly from the PNGs); values are target-width / actual
# per-frame width fill, applied as an absolute scale.x override so every
# frame renders at the same effective width regardless of how it was drawn.
# Keyed by the ABSOLUTE enemy_N.png frame index, not AnimatedSprite2D's
# sprite.frame (which is local to whichever animation is currently playing -
# see HANGED_SAILOR_ANIM_FRAMES below for the local->absolute mapping).
const HANGED_SAILOR_FRAME_SCALE_X: Dictionary = {
	0: 0.400, 1: 0.554, 2: 1.384, 3: 0.899, 4: 0.765,
	5: 0.899, 6: 0.400, 7: 0.545, 8: 0.856, 9: 0.783
}
const HANGED_SAILOR_ANIM_FRAMES: Dictionary = {
	"dead": [0], "hurt": [1], "idle": [2, 3], "walk": [4, 5, 8, 9], "attack": [6, 7]
}

var target: NecromancerPlayer
var archetype: Archetype = Archetype.WALKER
var room_id: String = ""
var spawn_key: String = ""
var room_bounds: Rect2 = Rect2(0.0, 0.0, 384.0, 216.0)
var patrol_left: float = 0.0
var patrol_right: float = 0.0
var home_position: Vector2 = Vector2.ZERO
var max_health: int = 3
var health: int = 3
var attack_damage: int = 1
var is_elite: bool = false
var active: bool = true
var raised: bool = false
var state: State = State.PATROL
var state_timer: float = 0.0
var facing: float = -1.0
var hurt_time: float = 0.0
var action_triggered: bool = false
var attack_direction: Vector2 = Vector2.LEFT
var body_collision: CollisionShape2D
var sprite: AnimatedSprite2D
var base_modulate: Color = Color.WHITE
var walk_speed: float = 42.0
var awareness_range: float = 210.0
var attack_range: float = 30.0
var patrol_direction: float = -1.0
var touch_damage_cooldown: float = 0.0
var attack_cooldown: float = 0.0
var alert_timer: float = 0.0
var alert_sent: bool = false
var announce_cooldown: float = 0.0
var platform_jump_cooldown: float = 0.0
var preferred_distance: float = 78.0
var attack_phase_offset: float = 0.0
var combat_slot_offset: float = 0.0
var locked_flank_side: float = 1.0
var sprite_base_position: Vector2 = Vector2.ZERO
var sprite_base_scale: Vector2 = Vector2.ONE
var walk_cycle_phase: float = 0.0
var walk_anim_grace: float = 0.0
var lost_sight_timer: float = 0.0
var decision_delay: float = 0.0
var backstep_direction: float = 0.0
var combat_target: CharacterBody2D
var locked_attack_target: CharacterBody2D
var target_scan_timer: float = 0.0
var bell_buff_timer: float = 0.0
var hook_pull_time: float = 0.0
var hook_pull_target: Vector2 = Vector2.ZERO
var navigation_stuck_time: float = 0.0
var last_navigation_position: Vector2 = Vector2.ZERO
var airborne_time: float = 0.0
var corpse_settled: bool = false

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 5.0
	floor_stop_on_slope = true
	safe_margin = 0.04
	home_position = global_position
	if combat_slot_offset != 0.0:
		locked_flank_side = signf(combat_slot_offset)
	if patrol_left == 0.0 and patrol_right == 0.0:
		patrol_left = home_position.x - 70.0
		patrol_right = home_position.x + 70.0
	_configure_archetype()
	health = max_health
	attack_cooldown = attack_phase_offset + 0.35
	decision_delay = 0.1 + attack_phase_offset * 0.25
	body_collision = CollisionShape2D.new()
	var shape: CapsuleShape2D = CapsuleShape2D.new()
	shape.radius = 7.0
	shape.height = 37.0
	if archetype == Archetype.BILGE_CRAWLER:
		shape.radius = 6.0
		shape.height = 23.0
	elif archetype == Archetype.BONE_CROW:
		shape.radius = 5.0
		shape.height = 15.0
	elif archetype == Archetype.COFFIN_MIMIC:
		shape.radius = 9.0
		shape.height = 44.0
	body_collision.shape = shape
	var collision_y: float = -18.5
	if archetype == Archetype.BILGE_CRAWLER:
		collision_y = -12.0
	elif archetype == Archetype.BONE_CROW:
		collision_y = -12.0
	elif archetype == Archetype.COFFIN_MIMIC:
		collision_y = -22.0
	body_collision.position = Vector2(0.0, collision_y)
	add_child(body_collision)
	_build_sprite()
	last_navigation_position = global_position

func _configure_archetype() -> void:
	match archetype:
		Archetype.WALKER:
			walk_speed = 54.0
			awareness_range = 210.0
			attack_range = 34.0
			preferred_distance = 54.0
			max_health = maxi(max_health, 3)
			base_modulate = Color.WHITE
		Archetype.CHARGER:
			walk_speed = 42.0
			awareness_range = 285.0
			attack_range = 210.0
			preferred_distance = 145.0
			max_health = maxi(max_health, 4)
			base_modulate = Color(1.0, 0.72, 0.58, 1.0)
		Archetype.SENTRY:
			walk_speed = 40.0
			awareness_range = 310.0
			attack_range = 270.0
			preferred_distance = 178.0
			max_health = maxi(max_health, 3)
			base_modulate = Color(0.68, 0.82, 1.0, 1.0)
		Archetype.HOPPER:
			walk_speed = 32.0
			awareness_range = 245.0
			attack_range = 165.0
			preferred_distance = 105.0
			max_health = maxi(max_health, 2)
			base_modulate = Color(0.72, 1.0, 0.67, 1.0)
		Archetype.BRUTE:
			walk_speed = 34.0
			awareness_range = 235.0
			attack_range = 48.0
			preferred_distance = 62.0
			max_health = maxi(max_health, 6)
			attack_damage = 2
			base_modulate = Color(0.82, 0.58, 0.46, 1.0)
		Archetype.BELL_WRETCH:
			walk_speed = 36.0
			awareness_range = 320.0
			attack_range = 260.0
			preferred_distance = 190.0
			max_health = maxi(max_health, 3)
			base_modulate = Color(0.92, 0.78, 0.36, 1.0)
		Archetype.SHIELD_GUARD:
			walk_speed = 40.0
			awareness_range = 235.0
			attack_range = 42.0
			preferred_distance = 58.0
			max_health = maxi(max_health, 5)
			base_modulate = Color(0.72, 0.68, 0.82, 1.0)
		Archetype.LANTERN_TOSSER:
			walk_speed = 38.0
			awareness_range = 305.0
			attack_range = 245.0
			preferred_distance = 165.0
			max_health = maxi(max_health, 3)
			base_modulate = Color(1.0, 0.62, 0.28, 1.0)
		Archetype.BILGE_CRAWLER:
			walk_speed = 72.0
			awareness_range = 230.0
			attack_range = 38.0
			preferred_distance = 46.0
			max_health = maxi(max_health, 2)
			base_modulate = Color(0.58, 0.9, 0.62, 1.0)
		Archetype.HANGED_SAILOR:
			walk_speed = 34.0
			awareness_range = 280.0
			attack_range = 185.0
			preferred_distance = 112.0
			max_health = maxi(max_health, 3)
			base_modulate = Color(0.76, 0.67, 0.92, 1.0)
		Archetype.BONE_CROW:
			walk_speed = 88.0
			awareness_range = 290.0
			# Begin the telegraph only after the crow has closed the gap. Launch
			# then rechecks the target and scales the committed dive to the actual
			# distance, preventing out-of-range short dives from looping.
			attack_range = 105.0
			preferred_distance = 96.0
			max_health = maxi(max_health, 2)
			base_modulate = Color(0.78, 0.72, 0.92, 1.0)
		Archetype.COFFIN_MIMIC:
			walk_speed = 0.0
			awareness_range = 132.0
			attack_range = 105.0
			preferred_distance = 55.0
			max_health = maxi(max_health, 5)
			base_modulate = Color(0.82, 0.68, 0.52, 1.0)
	if is_elite:
		max_health += 3
		attack_damage = 2
		base_modulate = base_modulate.lerp(Color(0.9, 0.45, 0.8, 1.0), 0.35)

func _build_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.position = Vector2(0.0, -34.0)
	var animations: Dictionary = {
		"dead": {"frames": [0], "fps": 1.0, "loop": false},
		"hurt": {"frames": [1], "fps": 1.0, "loop": false},
		"idle": {"frames": [2, 3], "fps": 2.5, "loop": true},
		"walk": {"frames": [4, 5, 8, 9], "fps": 7.0, "loop": true},
		"attack": {"frames": [6, 7], "fps": 7.0, "loop": false}
	}
	sprite.sprite_frames = FrameLibrary.build_frames(_sprite_variant_folder(), "enemy", animations)
	# The source art in these folders was drawn filling far more of its 96x80
	# canvas than the player/guard art does (measured ~85-95% vs ~58-60%),
	# so archetypes sharing those folders render oversized relative to the
	# player unless corrected here. Position is scaled by the same factor so
	# feet stay grounded instead of floating once the sprite shrinks.
	# Re-measured directly against the current committed art (72d7ed) using
	# scale = target_h_fill(60.6%, the player average) / this archetype's own
	# measured raw h_fill, computed independently per archetype rather than
	# compounding onto whatever the previous correction pass's number was -
	# compounding is how bilge_crawler ended up wrong last pass (0.55 was
	# 0.68 * 0.806, not target/raw, and the art had also moved again since).
	# LANTERN_TOSSER/SENTRY/BELL_WRETCH/HANGED_SAILOR measured within 5pp of
	# target already and are untouched.
	if archetype == Archetype.CHARGER:
		sprite.scale = Vector2(0.67, 0.67)
		sprite.position = Vector2(0.0, -22.8)
	elif archetype == Archetype.HOPPER:
		sprite.scale = Vector2(0.88, 0.88)
	elif archetype == Archetype.SENTRY:
		sprite.scale = Vector2(0.66, 0.66)
		sprite.position = Vector2(0.0, -23.5)
	elif archetype == Archetype.BRUTE:
		sprite.scale = Vector2(0.74, 0.74)
		sprite.position = Vector2(0.0, -25.1)
	elif archetype == Archetype.BELL_WRETCH:
		sprite.scale = Vector2(0.62, 0.62)
		sprite.position = Vector2(0.0, -22.8)
	elif archetype == Archetype.SHIELD_GUARD:
		sprite.scale = Vector2(0.66, 0.66)
		sprite.position = Vector2(0.0, -22.5)
	elif archetype == Archetype.LANTERN_TOSSER:
		sprite.scale = Vector2(0.65, 0.65)
		sprite.position = Vector2(0.0, -23.5)
	elif archetype == Archetype.BILGE_CRAWLER:
		sprite.scale = Vector2(0.63, 0.84)
		sprite.position = Vector2(0.0, -29.6)
	elif archetype == Archetype.HANGED_SAILOR:
		# Height is consistent across frames (~92.5% fill) so a uniform scale
		# corrects it, but WIDTH varies wildly frame-to-frame (27%-94% fill) -
		# a fixed scale can't fix that, hence the per-frame scale.x override in
		# _update_animation() (see HANGED_SAILOR_FRAME_SCALE_X below).
		sprite.scale = Vector2(0.627, 0.627)
		sprite.position = Vector2(0.0, -21.3)
	elif archetype == Archetype.BONE_CROW:
		sprite.scale = Vector2(0.68, 0.68)
		sprite.position = Vector2(0.0, -10.6)
	elif archetype == Archetype.COFFIN_MIMIC:
		sprite.scale = Vector2(0.8, 0.8)
		sprite.position = Vector2(0.0, -32.1)
	if is_elite:
		sprite.scale *= 1.18
	sprite.modulate = base_modulate
	sprite_base_position = sprite.position
	sprite_base_scale = sprite.scale
	add_child(sprite)
	sprite.play("idle")

func _sprite_variant_folder() -> String:
	match archetype:
		Archetype.SHIELD_GUARD:
			return "res://assets/sprites/enemy_types/grave_guard"
		Archetype.LANTERN_TOSSER, Archetype.SENTRY:
			return "res://assets/sprites/enemy_types/lantern_tosser"
		Archetype.BILGE_CRAWLER, Archetype.HOPPER:
			return "res://assets/sprites/enemy_types/bilge_crawler"
		Archetype.BRUTE, Archetype.CHARGER:
			return "res://assets/sprites/enemy_types/hook_brute"
		Archetype.BELL_WRETCH:
			return "res://assets/sprites/enemy_types/bell_keeper"
		Archetype.HANGED_SAILOR:
			return "res://assets/sprites/enemy_types/hanged_sailor"
		Archetype.BONE_CROW:
			return "res://assets/sprites/enemy_types/bone_crow"
		Archetype.COFFIN_MIMIC:
			return "res://assets/sprites/enemy_types/coffin_mimic"
		_:
			return "res://assets/sprites/enemy_types/walker"

func _physics_process(delta: float) -> void:
	hurt_time = maxf(0.0, hurt_time - delta)
	touch_damage_cooldown = maxf(0.0, touch_damage_cooldown - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	alert_timer = maxf(0.0, alert_timer - delta)
	announce_cooldown = maxf(0.0, announce_cooldown - delta)
	platform_jump_cooldown = maxf(0.0, platform_jump_cooldown - delta)
	decision_delay = maxf(0.0, decision_delay - delta)
	target_scan_timer = maxf(0.0, target_scan_timer - delta)
	bell_buff_timer = maxf(0.0, bell_buff_timer - delta)
	walk_anim_grace = maxf(0.0, walk_anim_grace - delta)
	if bell_buff_timer > 0.0:
		attack_cooldown = maxf(0.0, attack_cooldown - delta * 0.28)
	if target_scan_timer <= 0.0:
		_select_combat_target()
		target_scan_timer = 0.15
	if state == State.DEAD:
		# breach's tight 202 fall_limit exists so a ground enemy knocked into
		# the water hazard mid-fight recovers instead of sinking forever, but
		# it sits mid-height through that room's platform layer. bone_crow's
		# home_position is mid-air (it never touches ground while alive), so
		# its corpse would fall, cross 202 almost immediately, get teleported
		# back to that same mid-air home_position, and fall again - forever.
		# Flying corpses get the generous room-bottom limit instead so they
		# can actually fall and settle like any other corpse.
		var corpse_fall_limit: float = room_bounds.end.y + 18.0
		if room_id == "breach" and archetype != Archetype.BONE_CROW:
			corpse_fall_limit = room_bounds.position.y + 202.0
		if global_position.y > corpse_fall_limit:
			global_position = home_position
			velocity = Vector2.ZERO
			corpse_settled = false
		if not is_on_floor():
			velocity.y += GRAVITY * delta
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			corpse_settled = true
		_update_animation()
		return

	if hook_pull_time > 0.0:
		hook_pull_time = maxf(0.0, hook_pull_time - delta)
		var pull_vector: Vector2 = hook_pull_target - global_position
		velocity = pull_vector.normalized() * 235.0
		if not is_on_floor():
			velocity.y += GRAVITY * delta * 0.25
		move_and_slide()
		_constrain_to_room()
		if pull_vector.length() < 26.0 or hook_pull_time <= 0.0 or is_on_wall():
			hook_pull_time = 0.0
			velocity *= 0.25
			attack_cooldown = maxf(attack_cooldown, 0.45)
		_update_animation()
		return
	if archetype == Archetype.BONE_CROW:
		state_timer = maxf(0.0, state_timer - delta)
		_process_bone_crow(delta)
		_constrain_flying_to_room()
		_update_animation()
		return

	if not is_on_floor():
		airborne_time += delta
		velocity.y += GRAVITY * delta
	else:
		airborne_time = 0.0

	var fall_limit: float = room_bounds.position.y + 202.0 if room_id == "breach" else room_bounds.end.y + 18.0
	if global_position.y > fall_limit:
		global_position = home_position
		velocity = Vector2.ZERO
		attack_cooldown = maxf(attack_cooldown, 0.8)
		_set_state(State.PATROL, 0.45)

	state_timer = maxf(0.0, state_timer - delta)
	match state:
		State.PATROL:
			_process_patrol(delta)
		State.ALERT:
			_process_alert(delta)
		State.POSITION:
			_process_position(delta)
		State.WINDUP:
			_process_windup(delta)
		State.ATTACK:
			_process_attack(delta)
		State.RECOVER:
			_process_recover(delta)
		State.BACKSTEP:
			_process_backstep(delta)
		State.HURT:
			_process_hurt(delta)

	var requested_horizontal_motion: float = velocity.x
	move_and_slide()
	_constrain_to_room()
	_resolve_navigation_integrity(delta, requested_horizontal_motion)
	_update_animation()

func _current_target() -> CharacterBody2D:
	if (state == State.WINDUP or state == State.ATTACK) and is_instance_valid(locked_attack_target) and _actor_is_alive(locked_attack_target):
		return locked_attack_target
	if is_instance_valid(combat_target) and _actor_is_alive(combat_target) and room_bounds.grow(28.0).has_point(combat_target.global_position):
		return combat_target
	if is_instance_valid(target) and target.health > 0 and room_bounds.grow(28.0).has_point(target.global_position):
		return target
	return null

func _actor_is_alive(actor: CharacterBody2D) -> bool:
	if actor is NecromancerPlayer:
		return (actor as NecromancerPlayer).health > 0
	if actor is RaisedGuard:
		return (actor as RaisedGuard).health > 0 and (actor as RaisedGuard).resurrected
	return false

func _select_combat_target() -> void:
	if state == State.WINDUP or state == State.ATTACK:
		return
	combat_target = target
	if not is_instance_valid(target) or target.health <= 0:
		combat_target = null
		return
	var player_is_valid: bool = _actor_is_valid_for_archetype(target)
	if not player_is_valid:
		combat_target = null
	var player_distance: float = global_position.distance_to(target.global_position)
	var best_distance: float = player_distance if player_is_valid else INF
	for node: Node in get_tree().get_nodes_in_group("allies"):
		if node is RaisedGuard:
			var ally: RaisedGuard = node as RaisedGuard
			if not _actor_is_alive(ally) or not room_bounds.grow(24.0).has_point(ally.global_position):
				continue
			if not _actor_is_valid_for_archetype(ally):
				continue
			var distance: float = global_position.distance_to(ally.global_position)
			if distance < 78.0 or distance < best_distance * 0.72:
				combat_target = ally
				best_distance = distance

func _actor_is_valid_for_archetype(actor: CharacterBody2D) -> bool:
	if not is_instance_valid(actor):
		return false
	var vertical: float = absf(actor.global_position.y - global_position.y)
	match archetype:
		Archetype.WALKER, Archetype.CHARGER, Archetype.BRUTE, Archetype.BILGE_CRAWLER:
			return vertical <= 52.0
		Archetype.HOPPER, Archetype.HANGED_SAILOR, Archetype.BONE_CROW:
			return vertical <= 150.0
		Archetype.SENTRY, Archetype.BELL_WRETCH, Archetype.LANTERN_TOSSER:
			return vertical <= 112.0
		Archetype.SHIELD_GUARD, Archetype.COFFIN_MIMIC:
			return vertical <= 58.0
	return false

func _target_is_available() -> bool:
	var actor: CharacterBody2D = _current_target()
	return is_instance_valid(actor) and _actor_is_alive(actor) and room_bounds.grow(28.0).has_point(actor.global_position)

func _target_difference() -> Vector2:
	var actor: CharacterBody2D = _current_target()
	if not is_instance_valid(actor):
		return Vector2(9999.0, 9999.0)
	return actor.global_position - global_position

func _target_position() -> Vector2:
	var actor: CharacterBody2D = _current_target()
	return actor.global_position if is_instance_valid(actor) else global_position

func _target_velocity() -> Vector2:
	var actor: CharacterBody2D = _current_target()
	return actor.velocity if is_instance_valid(actor) else Vector2.ZERO

func _has_line_of_sight() -> bool:
	if not _target_is_available():
		return false
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0.0, -24.0),
		_target_position() + Vector2(0.0, -24.0),
		1
	)
	query.exclude = [get_rid()]
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()

func _can_notice_target() -> bool:
	if not _target_is_available():
		return false
	var difference: Vector2 = _target_difference()
	if absf(difference.x) > awareness_range or not _actor_is_valid_for_archetype(_current_target()):
		return false
	return _has_line_of_sight() or alert_timer > 0.0

func receive_alert(duration: float = 3.0) -> void:
	if state == State.DEAD:
		return
	alert_timer = maxf(alert_timer, duration)
	if state == State.PATROL:
		_set_state(State.ALERT, 0.12 + attack_phase_offset * 0.1)

func _announce_alert() -> void:
	if alert_sent or announce_cooldown > 0.0:
		return
	alert_sent = true
	announce_cooldown = 2.6
	alerted.emit(self)

func _process_patrol(delta: float) -> void:
	alert_sent = false
	if _can_notice_target():
		_announce_alert()
		facing = signf(_target_difference().x) if absf(_target_difference().x) > 1.0 else facing
		_set_state(State.ALERT, 0.12 + attack_phase_offset * 0.14)
		return

	if archetype == Archetype.SENTRY or archetype == Archetype.COFFIN_MIMIC:
		velocity.x = move_toward(velocity.x, 0.0, 520.0 * delta)
		return
	if global_position.x <= patrol_left + 3.0:
		patrol_direction = 1.0
	elif global_position.x >= patrol_right - 3.0:
		patrol_direction = -1.0
	if not _has_floor_ahead(patrol_direction):
		patrol_direction *= -1.0
	facing = patrol_direction
	velocity.x = move_toward(velocity.x, patrol_direction * walk_speed * 0.72, 420.0 * delta)

func _process_alert(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 760.0 * delta)
	if not _target_is_available():
		_set_state(State.PATROL, 0.0)
		return
	facing = signf(_target_difference().x) if absf(_target_difference().x) > 1.0 else facing
	if state_timer <= 0.0:
		decision_delay = 0.07 + attack_phase_offset * 0.14
		_set_state(State.POSITION, 0.0)

func _process_position(delta: float) -> void:
	if not _target_is_available():
		lost_sight_timer += delta
		if lost_sight_timer > 0.55:
			_set_state(State.PATROL, 0.0)
		return
	lost_sight_timer = 0.0
	if not _actor_is_valid_for_archetype(_current_target()):
		velocity.x = move_toward(velocity.x, 0.0, 780.0 * delta)
		_set_state(State.PATROL, 0.15)
		return
	var difference: Vector2 = _target_difference()
	facing = signf(difference.x) if absf(difference.x) > 1.0 else facing

	if absf(difference.y) > 150.0 or absf(difference.x) > awareness_range * 1.35:
		_set_state(State.PATROL, 0.0)
		return

	if _should_backstep(difference):
		_begin_backstep(-signf(difference.x))
		return

	match archetype:
		Archetype.WALKER:
			_position_walker(delta, difference)
		Archetype.CHARGER:
			_position_charger(delta, difference)
		Archetype.SENTRY:
			_position_sentry(delta, difference)
		Archetype.HOPPER:
			_position_hopper(delta, difference)
		Archetype.BRUTE:
			_position_brute(delta, difference)
		Archetype.BELL_WRETCH:
			_position_bell(delta, difference)
		Archetype.SHIELD_GUARD:
			_position_walker(delta, difference)
		Archetype.LANTERN_TOSSER:
			_position_sentry(delta, difference)
		Archetype.BILGE_CRAWLER:
			_position_crawler(delta, difference)
		Archetype.HANGED_SAILOR:
			_position_hanged(delta, difference)
		Archetype.COFFIN_MIMIC:
			_position_mimic(delta, difference)

func _flank_offset() -> float:
	# combat_slot_offset only carries a spawn-assigned magnitude; the side is
	# picked dynamically from wherever the enemy currently stands relative to
	# the target, so a group spreads around whoever it's actually engaging
	# instead of drifting toward a slot fixed at spawn time.
	# Recomputing the raw sign every frame flip-flops constantly for melee
	# archetypes closing to near-zero distance from the target, reversing
	# direction every time noise crosses zero. A deadzone locks the side in
	# once committed and only reconsiders it once clearly on the other side.
	var actor: CharacterBody2D = _current_target()
	if not is_instance_valid(actor):
		return absf(combat_slot_offset) * locked_flank_side
	var dx: float = global_position.x - actor.global_position.x
	if absf(dx) > 12.0:
		locked_flank_side = signf(dx)
	return absf(combat_slot_offset) * locked_flank_side

func _position_walker(delta: float, difference: Vector2) -> void:
	var desired_x: float = _target_position().x + _flank_offset()
	var slot_difference: float = desired_x - global_position.x
	if absf(difference.x) <= attack_range and absf(difference.y) <= 42.0 and attack_cooldown <= 0.0 and decision_delay <= 0.0 and _has_line_of_sight():
		_try_begin_attack()
		return
	_move_toward_slot(delta, slot_difference, walk_speed)

func _position_charger(delta: float, difference: Vector2) -> void:
	var distance_x: float = absf(difference.x)
	if distance_x < 72.0:
		_begin_backstep(-signf(difference.x))
		return
	if attack_cooldown <= 0.0 and decision_delay <= 0.0 and distance_x >= 88.0 and distance_x <= attack_range and absf(difference.y) <= 42.0 and _has_clear_charge_lane(facing):
		_try_begin_attack()
		return
	var desired_x: float = _target_position().x - facing * preferred_distance + _flank_offset() * 0.35
	_move_toward_slot(delta, desired_x - global_position.x, walk_speed)

func _position_sentry(delta: float, difference: Vector2) -> void:
	var distance_x: float = absf(difference.x)
	if attack_cooldown <= 0.0 and decision_delay <= 0.0 and distance_x <= attack_range and absf(difference.y) <= 105.0 and _has_line_of_sight():
		_try_begin_attack()
		return
	var desired_distance: float = preferred_distance + absf(combat_slot_offset) * 0.35
	if distance_x < desired_distance - 34.0:
		var retreat_direction: float = -signf(difference.x)
		_move_direction_if_safe(delta, retreat_direction, walk_speed)
	elif distance_x > desired_distance + 58.0:
		_move_direction_if_safe(delta, signf(difference.x), walk_speed * 0.8)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 780.0 * delta)

func _position_hopper(delta: float, difference: Vector2) -> void:
	var distance_x: float = absf(difference.x)
	if attack_cooldown <= 0.0 and decision_delay <= 0.0 and distance_x >= 55.0 and distance_x <= attack_range and absf(difference.y) <= 92.0:
		_try_begin_attack()
		return
	var desired_x: float = _target_position().x - facing * preferred_distance + _flank_offset() * 0.5
	_move_toward_slot(delta, desired_x - global_position.x, walk_speed)

func _position_brute(delta: float, difference: Vector2) -> void:
	if absf(difference.x) <= attack_range and absf(difference.y) <= 46.0 and attack_cooldown <= 0.0 and decision_delay <= 0.0:
		_try_begin_attack()
		return
	var desired_x: float = _target_position().x + _flank_offset() * 0.35
	_move_toward_slot(delta, desired_x - global_position.x, walk_speed)

func _position_bell(delta: float, difference: Vector2) -> void:
	var distance_x: float = absf(difference.x)
	if attack_cooldown <= 0.0 and decision_delay <= 0.0 and distance_x <= attack_range:
		_try_begin_attack()
		return
	if distance_x < preferred_distance - 45.0:
		_move_direction_if_safe(delta, -signf(difference.x), walk_speed)
	elif distance_x > preferred_distance + 65.0:
		_move_direction_if_safe(delta, signf(difference.x), walk_speed * 0.75)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 780.0 * delta)

func _position_crawler(delta: float, difference: Vector2) -> void:
	if absf(difference.x) <= attack_range and absf(difference.y) <= 34.0 and attack_cooldown <= 0.0 and decision_delay <= 0.0:
		_try_begin_attack()
		return
	var desired_x: float = _target_position().x + _flank_offset() * 0.4
	_move_toward_slot(delta, desired_x - global_position.x, walk_speed)

func _position_hanged(delta: float, difference: Vector2) -> void:
	var distance_x: float = absf(difference.x)
	if attack_cooldown <= 0.0 and decision_delay <= 0.0 and distance_x >= 52.0 and distance_x <= attack_range and absf(difference.y) <= 112.0:
		_try_begin_attack()
		return
	var desired_x: float = _target_position().x - facing * preferred_distance + _flank_offset() * 0.4
	_move_toward_slot(delta, desired_x - global_position.x, walk_speed)

func _position_mimic(delta: float, difference: Vector2) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	if absf(difference.x) <= attack_range and absf(difference.y) <= 52.0 and attack_cooldown <= 0.0 and decision_delay <= 0.0 and _has_line_of_sight():
		_try_begin_attack()

func _move_toward_slot(delta: float, slot_difference: float, speed_value: float) -> void:
	if absf(slot_difference) < 16.0:
		velocity.x = move_toward(velocity.x, 0.0, 760.0 * delta)
		return
	var direction: float = signf(slot_difference)
	_move_direction_if_safe(delta, direction, speed_value)

func _move_direction_if_safe(delta: float, direction: float, speed_value: float) -> void:
	if is_on_floor() and (not _has_floor_ahead(direction) or _enemy_blocks_lane(direction)):
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	else:
		var buff_multiplier: float = 1.18 if bell_buff_timer > 0.0 else 1.0
		velocity.x = move_toward(velocity.x, direction * speed_value * buff_multiplier, 520.0 * delta)

func _enemy_blocks_lane(direction: float) -> bool:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node == self or not node is RaggedEnemy:
			continue
		var other: RaggedEnemy = node as RaggedEnemy
		if other.room_id != room_id or not other.is_hostile_active() or absf(other.global_position.y - global_position.y) > 34.0:
			continue
		var horizontal: float = other.global_position.x - global_position.x
		if signf(horizontal) == signf(direction) and absf(horizontal) < 27.0:
			return true
	return false

func _should_backstep(difference: Vector2) -> bool:
	var actor: CharacterBody2D = _current_target()
	if not actor is NecromancerPlayer:
		return false
	var player_actor: NecromancerPlayer = actor as NecromancerPlayer
	if not player_actor.can_control or not player_actor.is_attack_active() or absf(difference.y) > 42.0:
		return false
	if archetype in [Archetype.BRUTE, Archetype.BELL_WRETCH, Archetype.COFFIN_MIMIC, Archetype.BONE_CROW]:
		return false
	var player_is_facing_enemy: bool = signf(global_position.x - player_actor.global_position.x) == signf(player_actor.facing)
	return player_is_facing_enemy and absf(difference.x) < 58.0 and state != State.WINDUP and state != State.ATTACK

func _begin_backstep(direction: float) -> void:
	if not is_on_floor() or not _has_floor_ahead(direction):
		return
	backstep_direction = direction
	velocity = Vector2(direction * 112.0, -118.0)
	attack_cooldown = maxf(attack_cooldown, 0.28)
	_set_state(State.BACKSTEP, 0.34)

func _process_backstep(delta: float) -> void:
	velocity.x = move_toward(velocity.x, backstep_direction * 78.0, 340.0 * delta)
	if state_timer <= 0.0 or (is_on_floor() and velocity.y >= 0.0):
		decision_delay = 0.14
		_set_state(State.POSITION, 0.0)

func _attack_slot_available() -> bool:
	if archetype == Archetype.BELL_WRETCH or archetype == Archetype.SENTRY:
		return true
	var my_target: CharacterBody2D = _current_target()
	var active_attackers: int = 0
	var engaged_total: int = 0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is RaggedEnemy:
			var other: RaggedEnemy = node as RaggedEnemy
			if other == self or other.room_id != room_id or not other.is_hostile_active():
				continue
			if other._current_target() != my_target:
				continue
			engaged_total += 1
			if other.state == State.WINDUP or other.state == State.ATTACK:
				if other.archetype == Archetype.SENTRY or other.archetype == Archetype.BELL_WRETCH:
					continue
				active_attackers += 1
	# A lone or paired enemy still takes turns fairly; once a real mob (3+) is
	# engaged, letting two attack at once makes the group feel like a threat
	# instead of a queue.
	var slot_limit: int = 2 if engaged_total >= 3 else 1
	return active_attackers < slot_limit

func _try_begin_attack() -> void:
	if attack_cooldown > 0.0 or not _target_is_available():
		return
	if not _attack_slot_available():
		decision_delay = 0.14 + attack_phase_offset * 0.08
		return
	var difference: Vector2 = _target_difference()
	facing = signf(difference.x) if absf(difference.x) > 1.0 else facing
	attack_direction = Vector2(facing, 0.0)
	locked_attack_target = _current_target()
	action_triggered = false
	match archetype:
		Archetype.WALKER:
			_set_state(State.WINDUP, 0.38)
		Archetype.CHARGER:
			if absf(difference.y) > 42.0 or not _has_clear_charge_lane(facing):
				decision_delay = 0.18
				return
			_set_state(State.WINDUP, 0.74 if not is_elite else 0.56)
		Archetype.SENTRY:
			attack_direction = (_target_position() + _target_velocity() * 0.28 - global_position).normalized()
			_set_state(State.WINDUP, 0.9 if not is_elite else 0.68)
		Archetype.HOPPER:
			attack_direction.x = signf((_target_position().x + _target_velocity().x * 0.4) - global_position.x)
			if not _has_hopper_landing(attack_direction.x):
				decision_delay = 0.24
				return
			_set_state(State.WINDUP, 0.58)
		Archetype.BRUTE:
			_set_state(State.WINDUP, 0.92 if not is_elite else 0.72)
		Archetype.BELL_WRETCH:
			_set_state(State.WINDUP, 0.82)
		Archetype.SHIELD_GUARD:
			_set_state(State.WINDUP, 0.5)
		Archetype.LANTERN_TOSSER:
			attack_direction = (_target_position() + _target_velocity() * 0.16 - global_position).normalized()
			_set_state(State.WINDUP, 0.72)
		Archetype.BILGE_CRAWLER:
			_set_state(State.WINDUP, 0.26)
		Archetype.HANGED_SAILOR:
			attack_direction.x = signf((_target_position().x + _target_velocity().x * 0.25) - global_position.x)
			if not _has_hopper_landing(attack_direction.x):
				decision_delay = 0.2
				return
			_set_state(State.WINDUP, 0.66)
		Archetype.COFFIN_MIMIC:
			_set_state(State.WINDUP, 0.72)

func _process_windup(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 980.0 * delta)
	if state_timer > 0.0:
		return
	match archetype:
		Archetype.WALKER:
			_set_state(State.ATTACK, 0.24)
		Archetype.CHARGER:
			_set_state(State.ATTACK, 0.78)
			velocity.x = attack_direction.x * (220.0 if not is_elite else 258.0)
		Archetype.SENTRY:
			_set_state(State.ATTACK, 0.2)
		Archetype.HOPPER:
			# Fixed 128 px/s horizontal only closes ~89px over the jump's ~0.7s
			# airtime, but the trigger range is 165px - most hops landed 50-95px
			# short of the target and never connected. Scale horizontal speed to
			# the actual distance (recomputed here, not at trigger time, so a
			# moving target doesn't reintroduce the gap) so the hop's landing
			# spot tracks where the target actually is.
			var hop_target_x: float = _target_position().x + _target_velocity().x * 0.15
			var hop_distance: float = absf(hop_target_x - global_position.x)
			var hop_airtime: float = 2.0 * 286.0 / GRAVITY
			var hop_speed: float = clampf(hop_distance / hop_airtime, 90.0, 260.0)
			_set_state(State.ATTACK, 1.08)
			velocity = Vector2(attack_direction.x * hop_speed, -286.0)
		Archetype.BRUTE:
			_set_state(State.ATTACK, 0.34)
		Archetype.BELL_WRETCH:
			_set_state(State.ATTACK, 0.28)
		Archetype.SHIELD_GUARD:
			_set_state(State.ATTACK, 0.28)
		Archetype.LANTERN_TOSSER:
			_set_state(State.ATTACK, 0.24)
		Archetype.BILGE_CRAWLER:
			_set_state(State.ATTACK, 0.22)
			velocity.x = facing * 138.0
		Archetype.HANGED_SAILOR:
			_set_state(State.ATTACK, 1.02)
			velocity = Vector2(attack_direction.x * 112.0, -305.0)
		Archetype.COFFIN_MIMIC:
			_set_state(State.ATTACK, 0.36)
			velocity.x = facing * 154.0

func _process_attack(delta: float) -> void:
	match archetype:
		Archetype.WALKER:
			velocity.x = move_toward(velocity.x, facing * 82.0, 920.0 * delta)
			if not action_triggered:
				action_triggered = true
				_try_melee_hit(35.0, 39.0)
			if state_timer <= 0.0:
				attack_cooldown = 0.75 + attack_phase_offset * 0.25
				_set_state(State.RECOVER, 0.72)
		Archetype.CHARGER:
			if not _has_floor_ahead(attack_direction.x) and is_on_floor():
				velocity.x = 0.0
				state_timer = 0.0
			if touch_damage_cooldown <= 0.0:
				_try_melee_hit(31.0, 37.0)
			if state_timer <= 0.0 or is_on_wall():
				velocity.x = 0.0
				attack_cooldown = 1.05
				_set_state(State.RECOVER, 1.18 if not is_elite else 0.86)
		Archetype.SENTRY:
			velocity.x = 0.0
			if not action_triggered:
				action_triggered = true
				projectile_requested.emit(global_position + Vector2(facing * 12.0, -25.0), attack_direction, 168.0 if not is_elite else 198.0, attack_damage, "bolt")
			if state_timer <= 0.0:
				attack_cooldown = 1.15 + attack_phase_offset * 0.3
				_set_state(State.RECOVER, 1.28 if not is_elite else 0.94)
		Archetype.HOPPER:
			if touch_damage_cooldown <= 0.0:
				_try_melee_hit(28.0, 34.0)
			if is_on_floor() and velocity.y >= 0.0 and state_timer < 0.8:
				velocity.x = 0.0
				attack_cooldown = 0.9
				_set_state(State.RECOVER, 0.82)
			elif state_timer <= 0.0:
				attack_cooldown = 0.9
				_set_state(State.RECOVER, 0.82)
		Archetype.BRUTE:
			velocity.x = move_toward(velocity.x, facing * 58.0, 520.0 * delta)
			if not action_triggered:
				action_triggered = true
				_try_melee_hit(50.0, 45.0)
			if state_timer <= 0.0:
				attack_cooldown = 1.15
				_set_state(State.RECOVER, 1.28)
		Archetype.BELL_WRETCH:
			velocity.x = 0.0
			if not action_triggered:
				action_triggered = true
				_ring_bell()
			if state_timer <= 0.0:
				attack_cooldown = 2.65
				_set_state(State.RECOVER, 1.05)
		Archetype.SHIELD_GUARD:
			velocity.x = move_toward(velocity.x, facing * 52.0, 620.0 * delta)
			if not action_triggered:
				action_triggered = true
				_try_melee_hit(42.0, 41.0)
			if state_timer <= 0.0:
				attack_cooldown = 0.95
				_set_state(State.RECOVER, 0.82)
		Archetype.LANTERN_TOSSER:
			velocity.x = 0.0
			if not action_triggered:
				action_triggered = true
				projectile_requested.emit(global_position + Vector2(facing * 10.0, -27.0), attack_direction, 142.0, attack_damage, "lantern")
			if state_timer <= 0.0:
				attack_cooldown = 1.35 + attack_phase_offset * 0.25
				_set_state(State.RECOVER, 1.05)
		Archetype.BILGE_CRAWLER:
			velocity.x = move_toward(velocity.x, facing * 118.0, 700.0 * delta)
			if not action_triggered:
				action_triggered = true
				_try_melee_hit(40.0, 30.0)
			if state_timer <= 0.0 or is_on_wall():
				velocity.x = 0.0
				attack_cooldown = 0.72
				_set_state(State.RECOVER, 0.42)
		Archetype.HANGED_SAILOR:
			if touch_damage_cooldown <= 0.0:
				_try_melee_hit(31.0, 42.0)
			if is_on_floor() and velocity.y >= 0.0 and state_timer < 0.76:
				velocity.x = 0.0
				attack_cooldown = 1.05
				_set_state(State.RECOVER, 0.9)
			elif state_timer <= 0.0:
				attack_cooldown = 1.05
				_set_state(State.RECOVER, 0.9)
		Archetype.COFFIN_MIMIC:
			if not action_triggered:
				action_triggered = true
				_try_melee_hit(46.0, 45.0)
			if state_timer <= 0.0 or is_on_wall():
				velocity.x = 0.0
				attack_cooldown = 1.55
				_set_state(State.RECOVER, 1.05)

func _process_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 780.0 * delta)
	if state_timer <= 0.0:
		locked_attack_target = null
		decision_delay = 0.1 + attack_phase_offset * 0.12
		if _can_notice_target():
			_set_state(State.POSITION, 0.0)
		else:
			_set_state(State.PATROL, 0.0)

func _process_hurt(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 520.0 * delta)
	if state_timer <= 0.0:
		attack_cooldown = maxf(attack_cooldown, 0.3)
		decision_delay = 0.12
		_set_state(State.POSITION if _can_notice_target() else State.PATROL, 0.0)

func _try_melee_hit(horizontal_range: float, vertical_range: float) -> void:
	if not _target_is_available() or touch_damage_cooldown > 0.0:
		return
	var difference: Vector2 = _target_difference()
	var in_front: bool = absf(difference.x) <= 5.0 or signf(difference.x) == signf(facing)
	if absf(difference.x) <= horizontal_range and absf(difference.y) <= vertical_range and in_front and _has_line_of_sight():
		touch_damage_cooldown = 0.48
		var actor: CharacterBody2D = _current_target()
		if is_instance_valid(actor) and actor.has_method("take_damage"):
			actor.take_damage(attack_damage, global_position.x)

func _ring_bell() -> void:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is RaggedEnemy:
			var other: RaggedEnemy = node as RaggedEnemy
			if other == self or other.room_id != room_id or not other.is_hostile_active():
				continue
			if global_position.distance_to(other.global_position) < 280.0:
				other.receive_bell_buff(4.0)
	support_pulsed.emit(global_position)

func receive_bell_buff(duration: float) -> void:
	bell_buff_timer = maxf(bell_buff_timer, duration)
	alert_timer = maxf(alert_timer, duration)

func apply_hook_pull(toward_position: Vector2) -> bool:
	if state == State.DEAD or is_elite or archetype in [Archetype.BRUTE, Archetype.CHARGER, Archetype.COFFIN_MIMIC]:
		return false
	hook_pull_target = toward_position + Vector2(-signf(toward_position.x - global_position.x) * 34.0, 0.0)
	hook_pull_time = 0.45
	hurt_time = 0.25
	_set_state(State.HURT, 0.5)
	return true

func _process_bone_crow(delta: float) -> void:
	var actor: CharacterBody2D = _current_target()
	match state:
		State.PATROL:
			if _can_notice_target():
				_announce_alert()
				_set_state(State.ALERT, 0.24)
			else:
				var hover_target := home_position + Vector2(sin(Time.get_ticks_msec() * 0.0018 + attack_phase_offset * 4.0) * 72.0, sin(Time.get_ticks_msec() * 0.0031 + attack_phase_offset * 5.0) * 14.0)
				velocity = velocity.move_toward((hover_target - global_position).normalized() * 58.0, 210.0 * delta)
		State.ALERT:
			velocity = velocity.move_toward(Vector2.ZERO, 340.0 * delta)
			if state_timer <= 0.0:
				_set_state(State.POSITION, 0.0)
		State.POSITION:
			if not is_instance_valid(actor):
				_set_state(State.PATROL, 0.0)
			else:
				var diff: Vector2 = actor.global_position - global_position
				facing = signf(diff.x) if absf(diff.x) > 1.0 else facing
				var flank: float = -facing * (88.0 + absf(combat_slot_offset) * 0.2)
				var desired := actor.global_position + Vector2(flank, -68.0)
				var desired_velocity := (desired - global_position).limit_length(90.0) * 1.35
				velocity = velocity.move_toward(desired_velocity, 330.0 * delta)
				if attack_cooldown <= 0.0 and diff.length() <= attack_range and _has_line_of_sight():
					locked_attack_target = actor
					_set_state(State.WINDUP, 0.30)
		State.WINDUP:
			velocity = velocity.move_toward(Vector2.ZERO, 430.0 * delta)
			if state_timer <= 0.0:
				if not is_instance_valid(locked_attack_target) or not _actor_is_alive(locked_attack_target):
					locked_attack_target = null
					attack_cooldown = 0.2
					_set_state(State.POSITION if _can_notice_target() else State.PATROL, 0.0)
				else:
					# Recompute at launch instead of committing to the target's old position
					# from before the telegraph. A moving player could add roughly 50px of
					# separation during the old 0.44s windup, recreating the repeated short
					# dive even with a smaller trigger range.
					var predicted_target: Vector2 = locked_attack_target.global_position + locked_attack_target.velocity * 0.18
					var dive_vector: Vector2 = predicted_target - global_position
					var dive_distance: float = dive_vector.length()
					if dive_distance > 210.0 or dive_distance < 1.0 or not _has_line_of_sight():
						locked_attack_target = null
						attack_cooldown = 0.24
						_set_state(State.POSITION, 0.0)
					else:
						attack_direction = dive_vector / dive_distance
						var dive_speed: float = clampf(dive_distance / 0.36, 255.0, 360.0)
						velocity = attack_direction * dive_speed
						var dive_duration: float = clampf(dive_distance / dive_speed + 0.16, 0.42, 0.68)
						_set_state(State.ATTACK, dive_duration)
		State.ATTACK:
			if touch_damage_cooldown <= 0.0:
				_try_melee_hit(27.0, 30.0)
			if state_timer <= 0.0 or is_on_wall():
				attack_cooldown = 1.0 + attack_phase_offset * 0.25
				_set_state(State.RECOVER, 0.62)
		State.RECOVER:
			var recover_target := home_position + Vector2(0.0, -8.0)
			velocity = velocity.move_toward((recover_target - global_position).limit_length(72.0), 280.0 * delta)
			if state_timer <= 0.0:
				locked_attack_target = null
				_set_state(State.POSITION if _can_notice_target() else State.PATROL, 0.0)
		State.HURT:
			velocity *= maxf(0.0, 1.0 - 4.0 * delta)
			if state_timer <= 0.0:
				_set_state(State.POSITION if _can_notice_target() else State.PATROL, 0.0)
	move_and_slide()

func _constrain_flying_to_room() -> void:
	global_position.x = clampf(global_position.x, room_bounds.position.x + 18.0, room_bounds.end.x - 18.0)
	global_position.y = clampf(global_position.y, room_bounds.position.y + 38.0, room_bounds.end.y - 58.0)

func _has_floor_ahead(direction: float) -> bool:
	if not is_on_floor() or absf(direction) < 0.01:
		return true
	# Two probes prevent actors from mistaking a tiny corner or collider seam
	# for a complete landing surface.
	var supported_probes: int = 0
	for horizontal_offset: float in [14.0, 23.0]:
		var start: Vector2 = global_position + Vector2(direction * horizontal_offset, -2.0)
		var finish: Vector2 = start + Vector2(0.0, 44.0)
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, finish, 1)
		query.exclude = [get_rid()]
		if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			supported_probes += 1
	return supported_probes == 2


func _has_hopper_landing(direction: float) -> bool:
	var predicted_x: float = global_position.x + direction * 112.0
	var support_hits: int = 0
	for offset: float in [-8.0, 0.0, 8.0]:
		var start: Vector2 = Vector2(predicted_x + offset, global_position.y - 18.0)
		var finish: Vector2 = start + Vector2(0.0, 170.0)
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, finish, 1)
		query.exclude = [get_rid()]
		if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			support_hits += 1
	return support_hits >= 2

func _has_clear_charge_lane(direction: float) -> bool:
	var start: Vector2 = global_position + Vector2(0.0, -20.0)
	var lane_length: float = minf(175.0, absf(_target_difference().x))
	var finish: Vector2 = start + Vector2(direction * lane_length, 0.0)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, finish, 1)
	query.exclude = [get_rid()]
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		return false
	for distance: float in [28.0, 56.0, 84.0, 112.0, 140.0]:
		if distance > lane_length:
			break
		var floor_start: Vector2 = global_position + Vector2(direction * distance, -2.0)
		var floor_end: Vector2 = floor_start + Vector2(0.0, 48.0)
		var floor_query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(floor_start, floor_end, 1)
		floor_query.exclude = [get_rid()]
		if get_world_2d().direct_space_state.intersect_ray(floor_query).is_empty():
			return false
	return true

func _set_state(new_state: State, duration: float) -> void:
	state = new_state
	state_timer = duration
	action_triggered = false

func _constrain_to_room() -> void:
	if state == State.DEAD:
		return
	var minimum_x: float = room_bounds.position.x + 8.0
	var maximum_x: float = room_bounds.end.x - 8.0
	var clamped_x: float = clampf(global_position.x, minimum_x, maximum_x)
	if not is_equal_approx(clamped_x, global_position.x):
		var hit_left: bool = global_position.x < minimum_x
		global_position.x = clamped_x
		velocity.x = 0.0
		patrol_direction = 1.0 if hit_left else -1.0
		facing = patrol_direction
		if state != State.WINDUP and state != State.ATTACK and state != State.HURT:
			_set_state(State.PATROL, 0.15)

func _resolve_navigation_integrity(delta: float, requested_horizontal_motion: float) -> void:
	if state == State.DEAD or hook_pull_time > 0.0:
		last_navigation_position = global_position
		return
	var moved_distance: float = global_position.distance_to(last_navigation_position)
	var intended_motion: bool = absf(requested_horizontal_motion) > 10.0
	if intended_motion and moved_distance < 0.28 and is_on_floor():
		navigation_stuck_time += delta
	else:
		navigation_stuck_time = maxf(0.0, navigation_stuck_time - delta * 2.0)

	var fell_off_assigned_level: bool = room_id != "breach" and airborne_time > 0.65 and global_position.y > home_position.y + 86.0
	if navigation_stuck_time > 0.72 or fell_off_assigned_level:
		global_position = home_position
		velocity = Vector2.ZERO
		navigation_stuck_time = 0.0
		airborne_time = 0.0
		attack_cooldown = maxf(attack_cooldown, 0.75)
		patrol_direction = -1.0 if home_position.x > (patrol_left + patrol_right) * 0.5 else 1.0
		_set_state(State.PATROL, 0.35)
	last_navigation_position = global_position


func _update_animation() -> void:
	if sprite == null:
		return
	sprite.flip_h = facing < 0.0
	if state == State.DEAD:
		sprite.play("dead")
	elif state == State.HURT:
		sprite.play("hurt")
	elif state == State.WINDUP or state == State.ATTACK:
		sprite.play("attack")
	elif absf(velocity.x) > 5.0:
		walk_anim_grace = 0.15
		sprite.play("walk")
	elif walk_anim_grace > 0.0:
		# Patrol/position movement decelerates smoothly through zero velocity on
		# every direction reversal (e.g. hitting a patrol boundary), which briefly
		# reads as "stopped" to a raw threshold check and flashes the idle pose
		# mid-stride. A short grace period bridges that crossing without masking
		# a real, sustained stop.
		sprite.play("walk")
	else:
		sprite.play("idle")

	# The four authored poses carry the gait. Avoid procedural squash/bob,
	# which made the silhouettes snap around independently of the footfalls.
	sprite.position = sprite_base_position
	sprite.scale = sprite_base_scale
	if archetype == Archetype.HANGED_SAILOR:
		var abs_frames: Array = HANGED_SAILOR_ANIM_FRAMES.get(sprite.animation, [])
		if sprite.frame < abs_frames.size():
			var abs_index: int = abs_frames[sprite.frame]
			if HANGED_SAILOR_FRAME_SCALE_X.has(abs_index):
				sprite.scale.x = HANGED_SAILOR_FRAME_SCALE_X[abs_index]

	var color: Color = base_modulate
	if state == State.ALERT:
		color = base_modulate.lerp(Color(1.0, 0.82, 0.46, 1.0), 0.35)
	elif state == State.WINDUP:
		var pulse: float = 0.7 + 0.3 * absf(sin(Time.get_ticks_msec() * 0.025))
		color = base_modulate.lerp(Color(1.0, 0.94, 0.5, 1.0), pulse)
	elif state == State.RECOVER:
		color = base_modulate.darkened(0.36)
	elif state == State.BACKSTEP:
		color = base_modulate.lerp(Color(0.65, 0.9, 1.0, 1.0), 0.25)
	if bell_buff_timer > 0.0:
		color = color.lerp(Color(1.0, 0.72, 0.22, 1.0), 0.22 + 0.12 * absf(sin(Time.get_ticks_msec() * 0.018)))
	if hurt_time > 0.0 and int(hurt_time * 28.0) % 2 == 0:
		color = Color(1.0, 0.3, 0.3, 0.45)
	sprite.modulate = color

func take_hit(from_x: float, damage: int = 1, heavy: bool = false) -> bool:
	if state == State.DEAD or not active:
		return false
	if archetype == Archetype.SHIELD_GUARD and not heavy:
		var incoming_side: float = signf(from_x - global_position.x)
		if incoming_side == facing:
			hurt_time = 0.12
			velocity.x = -facing * 24.0
			attack_cooldown = maxf(attack_cooldown, 0.22)
			return true
	health -= damage
	hurt_time = 0.24 if heavy else 0.2
	damaged.emit(global_position, damage, heavy)
	alert_timer = 3.0
	_announce_alert()
	var has_poise: bool = (archetype == Archetype.BRUTE or is_elite or archetype == Archetype.CHARGER) and not heavy
	velocity = Vector2(signf(global_position.x - from_x) * (42.0 if has_poise else 108.0), -28.0 if has_poise else -70.0)
	if health <= 0:
		active = false
		locked_attack_target = null
		_set_state(State.DEAD, 0.0)
		corpse_settled = false
		died.emit(self)
	elif not has_poise:
		locked_attack_target = null
		_set_state(State.HURT, (0.34 if heavy else 0.26) if not is_elite else 0.16)
	else:
		attack_cooldown = maxf(attack_cooldown, 0.12)
	return true

func is_hostile_active() -> bool:
	return active and not raised and state != State.DEAD

func is_engaged_with(candidate: NecromancerPlayer) -> bool:
	return is_hostile_active() and candidate == target and room_bounds.grow(28.0).has_point(candidate.global_position)

func can_be_raised() -> bool:
	return state == State.DEAD and not raised and corpse_settled

func mark_raised() -> void:
	raised = true
	remove_from_group("enemies")
	queue_free()

func mark_pre_dead() -> void:
	# Used when a room reloads with this spawn already recorded as killed:
	# spawn the corpse directly, skipping the fall/settle sequence, so it's
	# immediately raise-able instead of coming back alive.
	health = 0
	active = false
	state = State.DEAD
	state_timer = 0.0
	corpse_settled = true
	velocity = Vector2.ZERO
