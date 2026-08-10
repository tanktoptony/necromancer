class_name NecromancerPlayer
extends CharacterBody2D

signal attacked(origin: Vector2, facing: float, attack_kind: String, combo_step: int, damage: int, reach: float)
signal interact_requested
signal interact_released
signal hook_requested
signal hook_aim_released(direction: Vector2)
signal command_requested
signal health_changed(current: int)
signal hurt_received(position: Vector2)
signal hook_completed(position: Vector2)

const SPEED: float = 174.0
const GROUND_ACCELERATION: float = 1520.0
const AIR_ACCELERATION: float = 840.0
const FRICTION: float = 1880.0
const JUMP_VELOCITY: float = -320.0
const GRAVITY: float = 900.0
const COYOTE_TIME: float = 0.1
const JUMP_BUFFER_TIME: float = 0.12
const HOOK_SPEED: float = 520.0
const COMBO_RESET_TIME: float = 0.42
const LEDGE_ASSIST_FORWARD: float = 15.0
const LEDGE_ASSIST_UP: float = 13.0
const LEDGE_ASSIST_DOWN: float = 9.0

var facing: float = 1.0
var health: int = 5
var attack_time: float = 0.0
var attack_duration: float = 0.0
var attack_hit_emitted: bool = false
var attack_buffered: bool = false
var attack_step: int = 0
var combo_timer: float = 0.0
var hurt_time: float = 0.0
var coyote_time: float = 0.0
var jump_buffer_time: float = 0.0
var can_control: bool = true
var jump_was_down: bool = false
var attack_was_down: bool = false
var e_was_down: bool = false
var q_was_down: bool = false
var c_was_down: bool = false
var sprite: AnimatedSprite2D
var sprite_base_position: Vector2 = Vector2.ZERO
var sprite_base_scale: Vector2 = Vector2.ONE
var walk_cycle_phase: float = 0.0
var run_anim_grace: float = 0.0
var hooking: bool = false
var hook_target: Vector2 = Vector2.ZERO
var hook_time: float = 0.0
var ledge_assist_cooldown: float = 0.0
var ritual_channeling: bool = false
var hook_aiming: bool = false
var hook_aim_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 5.0
	floor_stop_on_slope = true
	safe_margin = 0.04
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CapsuleShape2D = CapsuleShape2D.new()
	shape.radius = 7.0
	shape.height = 38.0
	collision.shape = shape
	collision.position = Vector2(0.0, -19.0)
	add_child(collision)
	_build_sprite()
	health_changed.emit(health)

func _build_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.position = Vector2(0.0, -34.0)
	var animations: Dictionary = {
		"idle": {"frames": [0, 1], "fps": 2.5, "loop": true},
		"run": {"frames": [2, 3, 4, 8], "fps": 8.0, "loop": true},
		"jump": {"frames": [5], "fps": 1.0, "loop": false},
		"attack": {"frames": [6, 7], "fps": 11.0, "loop": false}
	}
	sprite.sprite_frames = FrameLibrary.build_frames(
		"res://assets/sprites/player",
		"player",
		animations
	)
	sprite_base_position = sprite.position
	sprite_base_scale = sprite.scale
	add_child(sprite)
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	hurt_time = maxf(0.0, hurt_time - delta)
	ledge_assist_cooldown = maxf(0.0, ledge_assist_cooldown - delta)
	combo_timer = maxf(0.0, combo_timer - delta)
	run_anim_grace = maxf(0.0, run_anim_grace - delta)
	_update_attack(delta)

	# Interaction release matters for charged resurrection even while control is locked.
	var e_down: bool = Input.is_key_pressed(KEY_E)
	var e_just_pressed: bool = e_down and not e_was_down
	var e_just_released: bool = e_was_down and not e_down
	if e_just_released:
		interact_released.emit()
	e_was_down = e_down

	var q_down: bool = Input.is_key_pressed(KEY_Q)
	var q_just_pressed: bool = q_down and not q_was_down
	var q_just_released: bool = q_was_down and not q_down
	if q_just_released and hook_aiming:
		hook_aim_released.emit(hook_aim_direction)
		hook_aiming = false
	q_was_down = q_down

	# Edge-tracked every frame, even while hooking/ritual/aiming lock out other input,
	# so a key held through one of those states doesn't read as a fresh press on release.
	var jump_down: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var jump_just_pressed: bool = jump_down and not jump_was_down
	jump_was_down = jump_down

	var attack_down: bool = Input.is_key_pressed(KEY_F) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var attack_just_pressed: bool = attack_down and not attack_was_down
	attack_was_down = attack_down

	var c_down: bool = Input.is_key_pressed(KEY_C)
	var c_just_pressed: bool = c_down and not c_was_down
	c_was_down = c_down

	if hooking:
		_hook_motion(delta)
		_update_animation()
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		coyote_time = COYOTE_TIME

	if ritual_channeling:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		move_and_slide()
		_update_animation()
		return

	if hook_aiming:
		var aim := Vector2.ZERO
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			aim.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			aim.x += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			aim.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			aim.y += 1.0
		if aim.length() > 0.1:
			hook_aim_direction = aim.normalized()
			if absf(hook_aim_direction.x) > 0.25:
				facing = signf(hook_aim_direction.x)
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		move_and_slide()
		_update_animation()
		return

	if not is_on_floor():
		coyote_time = maxf(0.0, coyote_time - delta)

	var direction: float = 0.0
	if can_control and health > 0:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			direction -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			direction += 1.0

	var movement_scale: float = 0.48 if attack_time > 0.0 and is_on_floor() else 1.0
	if direction != 0.0:
		facing = direction
		var acceleration: float = GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION
		velocity.x = move_toward(velocity.x, direction * SPEED * movement_scale, acceleration * delta)
	else:
		var drag: float = FRICTION if is_on_floor() else AIR_ACCELERATION * 0.35
		velocity.x = move_toward(velocity.x, 0.0, drag * delta)

	jump_buffer_time = maxf(0.0, jump_buffer_time - delta)
	if can_control and health > 0 and jump_just_pressed:
		jump_buffer_time = JUMP_BUFFER_TIME
	if can_control and health > 0 and jump_buffer_time > 0.0 and coyote_time > 0.0:
		velocity.y = JUMP_VELOCITY
		coyote_time = 0.0
		jump_buffer_time = 0.0

	if can_control and health > 0 and attack_just_pressed:
		_request_attack()

	if can_control and health > 0 and e_just_pressed and not ritual_channeling:
		interact_requested.emit()

	if can_control and health > 0 and q_just_pressed and not hook_aiming:
		hook_requested.emit()

	if can_control and health > 0 and c_just_pressed:
		command_requested.emit()

	if direction != 0.0:
		_try_ledge_assist(direction)
	move_and_slide()
	_update_animation()

func _try_ledge_assist(direction: float) -> void:
	if is_on_floor() or hooking or ledge_assist_cooldown > 0.0:
		return
	if velocity.y < -70.0 or velocity.y > 190.0 or absf(direction) < 0.01:
		return
	var probe_x: float = global_position.x + direction * LEDGE_ASSIST_FORWARD
	var ray_start: Vector2 = Vector2(probe_x, global_position.y - LEDGE_ASSIST_UP)
	var ray_end: Vector2 = Vector2(probe_x, global_position.y + LEDGE_ASSIST_DOWN)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(ray_start, ray_end, 1)
	query.exclude = [get_rid()]
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var landing_position: Vector2 = hit["position"]
	var landing_y: float = landing_position.y
	if landing_y < global_position.y - LEDGE_ASSIST_UP or landing_y > global_position.y + LEDGE_ASSIST_DOWN:
		return
	# Do not mantle through a wall: the player's upper body needs a clear lane.
	var clearance_start: Vector2 = global_position + Vector2(0.0, -27.0)
	var clearance_end: Vector2 = Vector2(probe_x, landing_y - 27.0)
	var clearance_query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(clearance_start, clearance_end, 1)
	clearance_query.exclude = [get_rid()]
	if not get_world_2d().direct_space_state.intersect_ray(clearance_query).is_empty():
		return
	global_position = Vector2(probe_x - direction * 2.0, landing_y - 1.0)
	velocity.y = 0.0
	ledge_assist_cooldown = 0.16

func is_attack_active() -> bool:
	if attack_time <= 0.0 or attack_duration <= 0.0:
		return false
	var elapsed_ratio: float = 1.0 - attack_time / attack_duration
	return elapsed_ratio >= 0.28 and elapsed_ratio <= 0.78

func confirm_hit(combo_step: int) -> void:
	if combo_step == 5:
		velocity.y = -185.0
		velocity.x *= 0.45
	elif combo_step == 6:
		velocity.x = -facing * 38.0
	elif combo_step >= 3:
		velocity.x = -facing * 24.0
	else:
		velocity.x *= 0.38

func _request_attack() -> void:
	if attack_time > 0.0:
		attack_buffered = true
		return
	var wants_up: bool = Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var wants_down: bool = Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	if wants_down and not is_on_floor():
		_start_special_attack(5)
		return
	if wants_down and is_on_floor():
		_start_special_attack(6)
		return
	if wants_up:
		_start_special_attack(4)
		return
	if combo_timer > 0.0 and attack_step > 0 and attack_step <= 3:
		attack_step = mini(attack_step + 1, 3)
	else:
		attack_step = 1
	_start_attack(attack_step)

func _start_special_attack(step: int) -> void:
	attack_step = step
	attack_hit_emitted = false
	attack_buffered = false
	combo_timer = 0.0
	if step == 4:
		attack_duration = 0.3
		attack_time = attack_duration
		if is_on_floor():
			velocity.y = -150.0
	elif step == 5:
		attack_duration = 0.38
		attack_time = attack_duration
		velocity.y = 390.0
	elif step == 6:
		attack_duration = 0.56
		attack_time = attack_duration
		velocity.x = 0.0

func _start_attack(step: int) -> void:
	attack_step = clampi(step, 1, 3)
	attack_duration = 0.21 if attack_step == 1 else (0.23 if attack_step == 2 else 0.34)
	attack_time = attack_duration
	attack_hit_emitted = false
	attack_buffered = false
	combo_timer = 0.0
	if attack_step == 3 and is_on_floor():
		velocity.x = facing * 92.0

func _update_attack(delta: float) -> void:
	if attack_time <= 0.0:
		if combo_timer <= 0.0:
			attack_step = 0
		return
	attack_time = maxf(0.0, attack_time - delta)
	var elapsed_ratio: float = 1.0 - attack_time / maxf(attack_duration, 0.001)
	var hit_threshold: float = 0.48 if attack_step == 6 else 0.34
	if not attack_hit_emitted and elapsed_ratio >= hit_threshold:
		attack_hit_emitted = true
		var damage: int = 3 if attack_step == 6 else (2 if attack_step == 3 or attack_step == 5 else 1)
		var reach: float = 60.0 if attack_step == 6 else (51.0 if attack_step == 3 else (38.0 if attack_step >= 4 else (46.0 if attack_step == 2 else 42.0)))
		var kind: String = "heavy" if attack_step == 6 else ("anti_air" if attack_step == 4 else ("plunge" if attack_step == 5 else "combo"))
		attacked.emit(global_position, facing, kind, attack_step, damage, reach)
	if attack_time <= 0.0:
		if attack_buffered and attack_step < 3:
			_start_attack(attack_step + 1)
		else:
			combo_timer = COMBO_RESET_TIME if attack_step <= 3 else 0.0

func _hook_motion(delta: float) -> void:
	hook_time -= delta
	var to_target: Vector2 = hook_target - global_position
	if to_target.length() < 12.0 or hook_time <= 0.0:
		global_position = hook_target
		velocity = Vector2.ZERO
		hooking = false
		can_control = true
		hook_completed.emit(global_position)
		return
	velocity = to_target.normalized() * HOOK_SPEED
	facing = signf(velocity.x) if absf(velocity.x) > 1.0 else facing
	move_and_slide()

func start_hook(target_position: Vector2) -> void:
	if hooking or health <= 0:
		return
	hooking = true
	can_control = false
	hook_target = target_position
	hook_time = 0.72
	attack_time = 0.0
	attack_buffered = false
	velocity = Vector2.ZERO

func begin_ritual() -> void:
	if health <= 0 or hooking:
		return
	ritual_channeling = true
	attack_time = 0.0
	attack_buffered = false
	velocity.x = 0.0

func end_ritual() -> void:
	ritual_channeling = false

func begin_hook_aim() -> void:
	if health <= 0 or hooking:
		return
	hook_aiming = true
	hook_aim_direction = Vector2(facing, 0.0)
	attack_time = 0.0
	attack_buffered = false

func cancel_hook_aim() -> void:
	hook_aiming = false

func _update_animation() -> void:
	if sprite == null:
		return
	sprite.flip_h = facing < 0.0
	if hooking:
		sprite.play("jump")
	elif ritual_channeling:
		sprite.play("attack")
		sprite.speed_scale = 0.45
	elif hook_aiming:
		sprite.play("idle")
	elif attack_time > 0.0:
		if sprite.animation != "attack" or not sprite.is_playing():
			sprite.play("attack")
	elif not is_on_floor():
		sprite.play("jump")
	elif absf(velocity.x) > 12.0:
		run_anim_grace = 0.15
		sprite.play("run")
	elif run_anim_grace > 0.0:
		# Same fix as RaggedEnemy/RaisedGuard: releasing or reversing a move key
		# decelerates smoothly through zero, which briefly reads as "stopped"
		# and flashes the idle pose mid-stride without this grace.
		sprite.play("run")
	else:
		sprite.play("idle")
	if not ritual_channeling:
		sprite.speed_scale = 1.0

	# Keep the authored player animation and its stable foot baseline intact.
	# layer a second procedural movement cycle over the authored frames.
	sprite.position = sprite_base_position
	sprite.scale = sprite_base_scale

	var flashing: bool = hurt_time > 0.0 and int(hurt_time * 24.0) % 2 == 0
	sprite.modulate = Color(1.0, 0.55, 0.55, 1.0) if flashing else Color.WHITE
	if health <= 0:
		sprite.rotation = move_toward(sprite.rotation, -0.35 * facing, 0.08)

func take_damage(amount: int, from_x: float) -> void:
	if hurt_time > 0.0 or health <= 0 or hooking:
		return
	health -= amount
	hurt_time = 0.72
	attack_time = 0.0
	attack_buffered = false
	combo_timer = 0.0
	ritual_channeling = false
	hook_aiming = false
	velocity = Vector2(signf(global_position.x - from_x) * 135.0, -105.0)
	health_changed.emit(health)
	hurt_received.emit(global_position)

func heal(amount: int) -> void:
	health = mini(GameState.max_health, health + maxi(amount, 0))
	health_changed.emit(health)

func heal_to_full() -> void:
	health = GameState.max_health
	health_changed.emit(health)

func reset_at(position_value: Vector2) -> void:
	global_position = position_value
	velocity = Vector2.ZERO
	health = GameState.max_health
	hurt_time = 0.0
	can_control = true
	hooking = false
	ritual_channeling = false
	hook_aiming = false
	attack_time = 0.0
	attack_step = 0
	jump_buffer_time = 0.0
	if sprite != null:
		sprite.rotation = 0.0
	health_changed.emit(health)

func recover_from_pit(position_value: Vector2) -> void:
	health = maxi(health - 1, 0)
	global_position = position_value
	velocity = Vector2.ZERO
	hurt_time = 0.75
	can_control = health > 0
	hooking = false
	ritual_channeling = false
	hook_aiming = false
	attack_time = 0.0
	jump_buffer_time = 0.0
	health_changed.emit(health)
	hurt_received.emit(global_position)

func enter_room(position_value: Vector2) -> void:
	global_position = position_value
	velocity = Vector2.ZERO
	hooking = false
	hook_time = 0.0
	can_control = health > 0
	attack_time = 0.0
	attack_duration = 0.0
	attack_hit_emitted = false
	attack_buffered = false
	attack_step = 0
	combo_timer = 0.0
	hurt_time = 0.0
	ledge_assist_cooldown = 0.0
	if sprite != null:
		sprite.rotation = 0.0
