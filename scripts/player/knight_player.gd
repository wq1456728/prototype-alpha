extends CharacterBody2D

const LIGHT_ATTACK_SFX := preload("res://assets/audio/sfx/player_attack_light_slash.mp3")
const HEAVY_ATTACK_SFX := preload("res://assets/audio/sfx/player_attack_heavy_slash.mp3")
const SHIELD_IMPACT_SFX := preload("res://assets/audio/sfx/player_shield_impact.mp3")
const FOOTSTEPS_SFX := preload("res://assets/audio/sfx/player_footsteps_run_loop.mp3")
const SPRITE_ROOT := "res://assets/sprites/characters/knight"
const SHIELD_CHARGE_FRAMES_RESOURCE := "res://assets/animations/knight_shield_charge_attack.tres"
const SPRITE_FRAME_WIDTH := 96
const SPRITE_FRAME_HEIGHT := 84

const WALK_SPEED := 130.0
const RUN_SPEED := 220.0
const MAX_HP := 100
const HURT_LOCK_TIME := 0.22

const LIGHT_ATTACK_LOCK_TIME := 0.42
const LIGHT_ATTACK_1_HIT_DELAY := 0.2
const LIGHT_ATTACK_2_HIT_DELAY := 0.11
const LIGHT_ATTACK_1_SFX_DELAY := 0.13
const LIGHT_ATTACK_2_SFX_DELAY := 0.04
const LIGHT_ATTACK_DAMAGE := 24
const LIGHT_ATTACK_FORWARD_RANGE := 105.0
const LIGHT_ATTACK_SIDE_RANGE := 60.0
const LIGHT_COMBO_MOVE_RESET_TIME := 0.5

const HEAVY_ATTACK_LOCK_TIME := 0.58
const HEAVY_ATTACK_HIT_DELAY := 0.28
const HEAVY_ATTACK_DAMAGE := 42
const HEAVY_ATTACK_FORWARD_RANGE := 125.0
const HEAVY_ATTACK_SIDE_RANGE := 110.0

const SHIELD_CHARGE_LOCK_TIME := 0.66
const SHIELD_CHARGE_HIT_DELAY := 0.44
const SHIELD_CHARGE_SECOND_HIT_DELAY := 0.5
const SHIELD_CHARGE_DAMAGE := 34
const SHIELD_CHARGE_FORWARD_RANGE := 96.0
const SHIELD_CHARGE_SIDE_RANGE := 54.0
const SHIELD_CHARGE_COOLDOWN := 1.25

const ENEMY_SOFT_COLLISION_DISTANCE := 48.0
const ENEMY_SOFT_COLLISION_FORCE := 120.0
const MAX_SOFT_COLLISION_SPEED := 95.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_bar: ProgressBar = $HPBar

var footstep_audio: AudioStreamPlayer2D
var facing := Vector2.RIGHT
var move_direction := Vector2.ZERO
var aim_direction := Vector2.RIGHT
var facing_direction := Vector2.RIGHT
var action_direction := Vector2.RIGHT
var action_lock := 0.0
var locked_velocity := Vector2.ZERO
var key_was_down := {}
var mouse_button_was_down := {}
var hp := MAX_HP
var dead := false
var damage_bonus := 0
var next_light_attack := 1
var movement_time_since_light_attack := 0.0
var pending_hit_time := -1.0
var pending_sfx_time := -1.0
var pending_sfx_stream: AudioStream
var pending_sfx_volume_db := 0.0
var pending_sfx_pitch_scale := 1.0
var pending_hit_damage := 0
var pending_forward_range := 0.0
var pending_side_range := 0.0
var shield_charge_cooldown := 0.0
var pending_second_hit_time := -1.0
var hit_enemies := {}


func _ready() -> void:
	add_to_group("player")
	sprite.sprite_frames = _build_sprite_frames()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hp_bar.max_value = MAX_HP
	hp_bar.value = hp
	_setup_footstep_audio()
	_play("idle")


func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		_update_footstep_audio(false, false)
		move_and_slide()
		return

	shield_charge_cooldown = maxf(shield_charge_cooldown - delta, 0.0)
	var light_attack_pressed := _consume_mouse_button_press(MOUSE_BUTTON_LEFT)
	var heavy_attack_pressed := _consume_mouse_button_press(MOUSE_BUTTON_RIGHT)
	var shield_charge_pressed := _consume_press(KEY_V)
	move_direction = _read_move_direction()
	aim_direction = _read_aim_direction()

	if action_lock > 0.0:
		_update_footstep_audio(false, false)
		_set_facing_direction(action_direction)
		action_lock -= delta
		if pending_hit_time >= 0.0:
			pending_hit_time -= delta
			if pending_hit_time <= 0.0:
				_apply_attack_hit()
				pending_hit_time = -1.0
		if pending_second_hit_time >= 0.0:
			pending_second_hit_time -= delta
			if pending_second_hit_time <= 0.0:
				_apply_attack_hit()
				pending_second_hit_time = -1.0
		if pending_sfx_time >= 0.0:
			pending_sfx_time -= delta
			if pending_sfx_time <= 0.0:
				_play_pending_sfx()
		velocity = locked_velocity
		move_and_slide()
		if action_lock <= 0.0:
			locked_velocity = Vector2.ZERO
			pending_hit_time = -1.0
			pending_second_hit_time = -1.0
			pending_sfx_time = -1.0
			hit_enemies.clear()
			if move_direction != Vector2.ZERO:
				_set_facing_direction(move_direction)
		return

	if move_direction != Vector2.ZERO:
		_set_facing_direction(move_direction)
		if next_light_attack != 1:
			movement_time_since_light_attack += delta
			if movement_time_since_light_attack >= LIGHT_COMBO_MOVE_RESET_TIME:
				next_light_attack = 1
	else:
		movement_time_since_light_attack = 0.0

	if shield_charge_pressed and shield_charge_cooldown <= 0.0:
		_start_shield_charge()
	elif heavy_attack_pressed:
		_start_attack("attack_3", HEAVY_ATTACK_LOCK_TIME, HEAVY_ATTACK_DAMAGE, HEAVY_ATTACK_HIT_DELAY, HEAVY_ATTACK_FORWARD_RANGE, HEAVY_ATTACK_SIDE_RANGE, aim_direction, HEAVY_ATTACK_SFX, 0.12, -11.0, 0.9)
	elif light_attack_pressed:
		var anim_name := StringName("attack_%d" % next_light_attack)
		var hit_delay := LIGHT_ATTACK_1_HIT_DELAY if next_light_attack == 1 else LIGHT_ATTACK_2_HIT_DELAY
		var sfx_delay := LIGHT_ATTACK_1_SFX_DELAY if next_light_attack == 1 else LIGHT_ATTACK_2_SFX_DELAY
		next_light_attack = 2 if next_light_attack == 1 else 1
		movement_time_since_light_attack = 0.0
		_start_attack(anim_name, LIGHT_ATTACK_LOCK_TIME, LIGHT_ATTACK_DAMAGE, hit_delay, LIGHT_ATTACK_FORWARD_RANGE, LIGHT_ATTACK_SIDE_RANGE, aim_direction, LIGHT_ATTACK_SFX, sfx_delay, -15.0, 1.18)

	if action_lock > 0.0:
		move_and_slide()
		return

	var wants_run := _held(KEY_SHIFT)
	var target_speed := RUN_SPEED if wants_run else WALK_SPEED
	var soft_collision := _soft_collision_velocity() if move_direction != Vector2.ZERO else Vector2.ZERO
	velocity = move_direction * target_speed + soft_collision
	move_and_slide()
	_update_footstep_audio(move_direction != Vector2.ZERO, wants_run)

	if move_direction == Vector2.ZERO:
		_play("idle")
	elif wants_run:
		_play("run")
	else:
		_play("walk")


func _start_attack(
	anim_name: StringName,
	duration: float,
	damage: int,
	hit_delay: float,
	forward_range: float,
	side_range: float,
	attack_direction: Vector2,
	sfx_stream: AudioStream,
	sfx_delay: float,
	sfx_volume_db: float,
	sfx_pitch_scale: float
) -> void:
	action_lock = duration
	locked_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	action_direction = _valid_direction_or_facing(attack_direction)
	_set_facing_direction(action_direction)
	pending_hit_damage = damage + damage_bonus
	pending_hit_time = hit_delay
	pending_second_hit_time = -1.0
	pending_forward_range = forward_range
	pending_side_range = side_range
	hit_enemies.clear()
	_schedule_sfx(sfx_stream, sfx_delay, sfx_volume_db, sfx_pitch_scale)
	_play(anim_name, true)


func _apply_attack_hit() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		var enemy_node: Node2D = enemy as Node2D
		if enemy_node == null:
			continue
		var to_enemy: Vector2 = enemy_node.global_position - global_position
		if not _is_in_attack_area(to_enemy):
			continue
		var enemy_id := enemy.get_instance_id()
		if hit_enemies.has(enemy_id):
			continue
		hit_enemies[enemy_id] = true
		enemy.take_damage(pending_hit_damage, global_position)


func _start_shield_charge() -> void:
	if not sprite.sprite_frames.has_animation("shield_charge"):
		return
	shield_charge_cooldown = SHIELD_CHARGE_COOLDOWN
	action_lock = SHIELD_CHARGE_LOCK_TIME
	locked_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	action_direction = _valid_direction_or_facing(aim_direction)
	_set_facing_direction(action_direction)
	pending_hit_damage = SHIELD_CHARGE_DAMAGE + damage_bonus
	pending_hit_time = SHIELD_CHARGE_HIT_DELAY
	pending_second_hit_time = SHIELD_CHARGE_SECOND_HIT_DELAY
	pending_forward_range = SHIELD_CHARGE_FORWARD_RANGE
	pending_side_range = SHIELD_CHARGE_SIDE_RANGE
	hit_enemies.clear()
	_schedule_sfx(SHIELD_IMPACT_SFX, SHIELD_CHARGE_HIT_DELAY, -13.0, 0.92)
	_play("shield_charge", true)


func _is_in_attack_area(offset: Vector2) -> bool:
	if offset == Vector2.ZERO:
		return true
	var forward := _valid_direction_or_facing(action_direction)
	var right := Vector2(-forward.y, forward.x)
	var forward_distance := offset.dot(forward)
	var side_distance := absf(offset.dot(right))
	return forward_distance >= -18.0 and forward_distance <= pending_forward_range and side_distance <= pending_side_range


func _soft_collision_velocity() -> Vector2:
	var push := Vector2.ZERO
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var enemy_node := enemy as Node2D
		if enemy_node == null:
			continue
		push += _push_from_node(enemy_node, ENEMY_SOFT_COLLISION_DISTANCE, ENEMY_SOFT_COLLISION_FORCE)
	return push.limit_length(MAX_SOFT_COLLISION_SPEED)


func _push_from_node(other: Node2D, distance_limit: float, force: float) -> Vector2:
	var away := global_position - other.global_position
	var distance := away.length()
	if distance <= 0.01 or distance >= distance_limit:
		return Vector2.ZERO
	var strength := 1.0 - distance / distance_limit
	return away.normalized() * force * strength


func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if dead:
		return
	hp = maxi(hp - amount, 0)
	hp_bar.value = hp
	if hp <= 0:
		_die()
		return
	var knockback := (global_position - source_position).normalized() * 70.0
	_start_hurt(knockback)


func heal_fraction(fraction: float) -> void:
	if dead:
		return
	var heal_amount := int(round(MAX_HP * fraction))
	hp = mini(hp + heal_amount, MAX_HP)
	hp_bar.value = hp


func add_damage_bonus(amount: int) -> void:
	if dead:
		return
	damage_bonus += amount


func get_damage_bonus() -> int:
	return damage_bonus


func get_current_attack_damage() -> int:
	return LIGHT_ATTACK_DAMAGE + damage_bonus


func _start_hurt(knockback: Vector2) -> void:
	action_lock = HURT_LOCK_TIME
	locked_velocity = knockback
	action_direction = facing_direction
	pending_hit_time = -1.0
	pending_sfx_time = -1.0
	if sprite.sprite_frames.has_animation("hurt"):
		_play("hurt", true)


func _die() -> void:
	dead = true
	velocity = Vector2.ZERO
	locked_velocity = Vector2.ZERO
	action_lock = 0.0
	pending_hit_time = -1.0
	pending_second_hit_time = -1.0
	pending_sfx_time = -1.0
	hit_enemies.clear()
	hp_bar.value = 0
	if sprite.sprite_frames.has_animation("death"):
		_play("death", true)


func _read_move_direction() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or _held(KEY_A):
		direction.x -= 1.0
	if Input.is_action_pressed("ui_right") or _held(KEY_D):
		direction.x += 1.0
	if Input.is_action_pressed("ui_up") or _held(KEY_W):
		direction.y -= 1.0
	if Input.is_action_pressed("ui_down") or _held(KEY_S):
		direction.y += 1.0
	return direction.normalized()


func _read_aim_direction() -> Vector2:
	var direction := get_global_mouse_position() - global_position
	if direction.length_squared() <= 0.01:
		return aim_direction
	return direction.normalized()


func _valid_direction_or_facing(direction: Vector2) -> Vector2:
	if direction.length_squared() <= 0.01:
		return facing_direction
	return direction.normalized()


func _set_facing_direction(direction: Vector2) -> void:
	facing_direction = _valid_direction_or_facing(direction)
	facing = facing_direction
	if absf(facing_direction.x) > 0.01:
		sprite.flip_h = facing_direction.x < 0.0


func get_facing_direction() -> Vector2:
	return facing_direction


func get_action_direction() -> Vector2:
	return action_direction


func _held(keycode: Key) -> bool:
	return Input.is_key_pressed(keycode)


func _consume_press(keycode: Key) -> bool:
	var down := Input.is_key_pressed(keycode)
	var was_down := bool(key_was_down.get(keycode, false))
	key_was_down[keycode] = down
	return down and not was_down


func _consume_mouse_button_press(button: int) -> bool:
	var down := Input.is_mouse_button_pressed(button)
	var was_down := bool(mouse_button_was_down.get(button, false))
	mouse_button_was_down[button] = down
	return down and not was_down


func _play(anim_name: StringName, restart: bool = false) -> void:
	if restart or sprite.animation != anim_name:
		sprite.play(anim_name)


func _play_sfx(stream: AudioStream, volume_db: float, pitch_scale: float = 1.0) -> void:
	var audio := AudioStreamPlayer2D.new()
	audio.stream = stream
	audio.volume_db = volume_db
	audio.pitch_scale = pitch_scale
	audio.finished.connect(audio.queue_free)
	add_child(audio)
	audio.play()


func _schedule_sfx(stream: AudioStream, delay: float, volume_db: float, pitch_scale: float = 1.0) -> void:
	pending_sfx_stream = stream
	pending_sfx_time = delay
	pending_sfx_volume_db = volume_db
	pending_sfx_pitch_scale = pitch_scale


func _play_pending_sfx() -> void:
	if pending_sfx_stream != null:
		_play_sfx(pending_sfx_stream, pending_sfx_volume_db, pending_sfx_pitch_scale)
	pending_sfx_time = -1.0
	pending_sfx_stream = null


func _setup_footstep_audio() -> void:
	footstep_audio = AudioStreamPlayer2D.new()
	footstep_audio.stream = FOOTSTEPS_SFX
	footstep_audio.volume_db = -25.0
	add_child(footstep_audio)


func _update_footstep_audio(is_moving: bool, wants_run: bool) -> void:
	if footstep_audio == null:
		return
	if not is_moving:
		if footstep_audio.playing:
			footstep_audio.stop()
		return
	footstep_audio.pitch_scale = 1.08 if wants_run else 0.88
	if not footstep_audio.playing:
		footstep_audio.play()


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	_add_frames(frames, "idle", "idle", 7, 8.0, true)
	_add_frames(frames, "walk", "walk", 8, 8.0, true)
	_add_frames(frames, "run", "run", 8, 12.0, true)
	_add_frames(frames, "attack_1", "attack_1", 6, 16.0, false)
	_add_frames(frames, "attack_2", "attack_2", 5, 15.0, false)
	_add_frame_sequence(frames, "attack_3", "attack_3", [0, 0, 1, 1, 2, 3, 4, 5], 16.0, false)
	_add_frames_from_resource(frames, "shield_charge", SHIELD_CHARGE_FRAMES_RESOURCE, "shield_charge_attack")
	_add_frames(frames, "hurt", "hurt", 4, 12.0, false)
	_add_frames(frames, "death", "death", 12, 12.0, false)

	return frames


func _add_frames(
	frames: SpriteFrames,
	anim_name: StringName,
	file_prefix: String,
	count: int,
	speed: float,
	loops: bool
) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, speed)
	frames.set_animation_loop(anim_name, loops)

	var sheet_path := "%s/class_knight_%s_side.png" % [SPRITE_ROOT, file_prefix]
	var sheet := load(sheet_path) as Texture2D
	if sheet == null:
		return

	for i in range(count):
		frames.add_frame(anim_name, _make_atlas_frame(sheet, i))


func _add_frames_from_resource(
	frames: SpriteFrames,
	anim_name: StringName,
	resource_path: String,
	source_anim_name: StringName
) -> void:
	var source := load(resource_path) as SpriteFrames
	if source == null or not source.has_animation(source_anim_name):
		return

	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, source.get_animation_speed(source_anim_name))
	frames.set_animation_loop(anim_name, source.get_animation_loop(source_anim_name))

	for i in range(source.get_frame_count(source_anim_name)):
		frames.add_frame(anim_name, source.get_frame_texture(source_anim_name, i), source.get_frame_duration(source_anim_name, i))


func _add_frame_sequence(
	frames: SpriteFrames,
	anim_name: StringName,
	file_prefix: String,
	sequence: Array[int],
	speed: float,
	loops: bool
) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, speed)
	frames.set_animation_loop(anim_name, loops)

	var sheet_path := "%s/class_knight_%s_side.png" % [SPRITE_ROOT, file_prefix]
	var sheet := load(sheet_path) as Texture2D
	if sheet == null:
		return

	for index in sequence:
		frames.add_frame(anim_name, _make_atlas_frame(sheet, index))


func _make_atlas_frame(sheet: Texture2D, frame_index: int) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = sheet
	frame.region = Rect2(frame_index * SPRITE_FRAME_WIDTH, 0, SPRITE_FRAME_WIDTH, SPRITE_FRAME_HEIGHT)
	frame.filter_clip = true
	return frame
