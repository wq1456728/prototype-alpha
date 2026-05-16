extends CharacterBody2D

const LIGHT_ATTACK_SFX := preload("res://assets/audio/sfx/player_attack_light_slash.mp3")
const HEAVY_ATTACK_SFX := preload("res://assets/audio/sfx/player_attack_heavy_slash.mp3")
const SHIELD_IMPACT_SFX := preload("res://assets/audio/sfx/player_shield_impact.mp3")
const FOOTSTEPS_SFX := preload("res://assets/audio/sfx/player_footsteps_run_loop.mp3")
const ITEM_DATABASE := preload("res://scripts/items/item_database.gd")
const PROGRESSION_STATE := preload("res://scripts/progression/progression_state.gd")
const SKILL_TREE_STATE := preload("res://scripts/skills/skill_tree_state.gd")
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
const BAG_SLOT_COUNT := 10
const EQUIP_SLOT_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]
const LEVEL_UP_HEAL_FRACTION := 0.25
const DEBUG_ATTACK_AREA_COLOR := Color(1.0, 0.18, 0.12, 0.22)
const DEBUG_ATTACK_AREA_OUTLINE := Color(1.0, 0.28, 0.16, 0.8)

@export var show_attack_debug := true

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
var progression: RefCounted = PROGRESSION_STATE.new()
var skill_tree: RefCounted = SKILL_TREE_STATE.new()
var inventory_items: Array[Dictionary] = []
var equipment_slots := {}
var equipped_weapon: Dictionary = {}
var item_cursor_blocks_attacks := false
var attack_input_suppression_time := 0.0
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
	_initialize_inventory()
	_setup_footstep_audio()
	_play("idle")


func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		_update_footstep_audio(false, false)
		move_and_slide()
		return

	shield_charge_cooldown = maxf(shield_charge_cooldown - delta, 0.0)
	attack_input_suppression_time = maxf(attack_input_suppression_time - delta, 0.0)
	var attacks_blocked := _is_attack_input_blocked()
	var light_attack_pressed := false
	var heavy_attack_pressed := false
	var shield_charge_pressed := false
	if attacks_blocked:
		_consume_mouse_button_press(MOUSE_BUTTON_LEFT)
		_consume_mouse_button_press(MOUSE_BUTTON_RIGHT)
		_consume_press(KEY_V)
	else:
		light_attack_pressed = _consume_mouse_button_press(MOUSE_BUTTON_LEFT)
		heavy_attack_pressed = _consume_mouse_button_press(MOUSE_BUTTON_RIGHT)
		shield_charge_pressed = _consume_press(KEY_V)
	_handle_inventory_input()
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
		queue_redraw()
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

	if shield_charge_pressed and shield_charge_cooldown <= 0.0 and is_skill_unlocked("shield_charge"):
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
		queue_redraw()
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
	queue_redraw()


func _draw() -> void:
	if not show_attack_debug or action_lock <= 0.0 or pending_forward_range <= 0.0:
		return

	var forward := _valid_direction_or_facing(action_direction)
	var right := Vector2(-forward.y, forward.x)
	var back_distance := 18.0
	var polygon := PackedVector2Array([
		-forward * back_distance - right * pending_side_range,
		forward * pending_forward_range - right * pending_side_range,
		forward * pending_forward_range + right * pending_side_range,
		-forward * back_distance + right * pending_side_range,
	])
	draw_colored_polygon(polygon, DEBUG_ATTACK_AREA_COLOR)
	draw_polyline(PackedVector2Array([polygon[0], polygon[1], polygon[2], polygon[3], polygon[0]]), DEBUG_ATTACK_AREA_OUTLINE, 2.0)


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
	pending_hit_damage = damage + get_total_damage_bonus()
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
	pending_hit_damage = SHIELD_CHARGE_DAMAGE + get_total_damage_bonus()
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


func pickup_weapon_item(item_data: Dictionary) -> bool:
	return pickup_item(item_data)


func pickup_item(item_data: Dictionary) -> bool:
	if dead:
		return false
	var slot_index := _first_empty_bag_slot()
	if slot_index < 0:
		return false
	inventory_items[slot_index] = ITEM_DATABASE.normalize_item_instance(item_data)
	return true


func get_damage_bonus() -> int:
	return damage_bonus


func get_total_damage_bonus() -> int:
	return damage_bonus + get_level_damage_bonus()


func get_current_attack_damage() -> int:
	return LIGHT_ATTACK_DAMAGE + get_total_damage_bonus()


func gain_xp(amount: int) -> bool:
	if dead or amount <= 0:
		return false
	var leveled_up: bool = progression.gain_xp(amount)
	if leveled_up:
		hp = mini(hp + int(round(MAX_HP * LEVEL_UP_HEAL_FRACTION)), MAX_HP)
		hp_bar.value = hp
	return leveled_up


func get_level() -> int:
	return int(progression.level)


func get_current_xp() -> int:
	return int(progression.current_xp)


func get_xp_to_next_level() -> int:
	return progression.get_xp_to_next_level()


func get_level_damage_bonus() -> int:
	return progression.get_damage_bonus()


func get_available_skill_points() -> int:
	return int(progression.available_skill_points)


func spend_skill_points(amount: int) -> bool:
	return progression.spend_skill_points(amount)


func get_skill_rank(skill_id: String) -> int:
	return skill_tree.get_rank(skill_id)


func is_skill_unlocked(skill_id: String) -> bool:
	return skill_tree.is_unlocked(skill_id)


func can_unlock_skill(skill_id: String) -> bool:
	return skill_tree.can_unlock(skill_id, get_level(), get_available_skill_points())


func unlock_skill(skill_id: String) -> bool:
	var result: Dictionary = skill_tree.unlock(skill_id, get_level(), get_available_skill_points())
	if not bool(result.get("ok", false)):
		return false
	return spend_skill_points(int(result.get("cost", 0)))


func equip_bag_slot(slot_index: int) -> bool:
	if dead:
		return false
	if not _is_valid_bag_slot(slot_index):
		return false
	var item := inventory_items[slot_index]
	if item.is_empty():
		return false
	var equip_slot := str(item.get("equip_slot", "weapon"))
	if not _can_use_equipment_slot(equip_slot):
		return false
	var previous_item: Dictionary = equipment_slots[equip_slot].duplicate(true)
	equipment_slots[equip_slot] = ITEM_DATABASE.normalize_item_instance(item)
	inventory_items[slot_index] = previous_item
	_refresh_equipment_stats()
	return true


func get_inventory_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for item in inventory_items:
		items.append(item.duplicate(true))
	return items


func get_equipped_weapon() -> Dictionary:
	return equipped_weapon.duplicate(true)


func get_equipment_items() -> Dictionary:
	var items := {}
	for slot_id in equipment_slots.keys():
		items[slot_id] = equipment_slots[slot_id].duplicate(true)
	return items


func get_equipment_slot_item(slot_id: String) -> Dictionary:
	return equipment_slots.get(slot_id, {}).duplicate(true)


func get_equipped_weapon_name() -> String:
	if equipped_weapon.is_empty():
		return "None"
	return str(equipped_weapon.get("name", "Weapon"))


func get_equipped_weapon_damage_bonus() -> int:
	return damage_bonus


func get_bag_slot_count() -> int:
	return BAG_SLOT_COUNT


func take_bag_slot(slot_index: int) -> Dictionary:
	if not _is_valid_bag_slot(slot_index):
		return {}
	var item := inventory_items[slot_index].duplicate(true)
	inventory_items[slot_index] = {}
	return item


func place_bag_slot(slot_index: int, item_data: Dictionary) -> Dictionary:
	if not _is_valid_bag_slot(slot_index) or item_data.is_empty():
		return item_data
	var displaced := inventory_items[slot_index].duplicate(true)
	inventory_items[slot_index] = ITEM_DATABASE.normalize_item_instance(item_data)
	return displaced


func take_equipped_weapon() -> Dictionary:
	var item := take_equipment_slot("weapon")
	return item


func take_equipment_slot(slot_id: String) -> Dictionary:
	if not _can_use_equipment_slot(slot_id):
		return {}
	var item: Dictionary = equipment_slots[slot_id].duplicate(true)
	equipment_slots[slot_id] = {}
	_refresh_equipment_stats()
	return item


func place_equipped_weapon(item_data: Dictionary) -> Dictionary:
	return place_equipment_slot("weapon", item_data)


func place_equipment_slot(slot_id: String, item_data: Dictionary) -> Dictionary:
	if item_data.is_empty() or not _can_use_equipment_slot(slot_id):
		return item_data
	var normalized := ITEM_DATABASE.normalize_item_instance(item_data)
	if not ITEM_DATABASE.can_equip_in_slot(normalized, slot_id):
		return item_data
	var displaced: Dictionary = equipment_slots[slot_id].duplicate(true)
	equipment_slots[slot_id] = normalized
	_refresh_equipment_stats()
	return displaced


func set_item_cursor_blocks_attacks(blocked: bool) -> void:
	item_cursor_blocks_attacks = blocked


func suppress_attack_inputs(duration: float = 0.12) -> void:
	attack_input_suppression_time = maxf(attack_input_suppression_time, duration)
	_consume_mouse_button_press(MOUSE_BUTTON_LEFT)
	_consume_mouse_button_press(MOUSE_BUTTON_RIGHT)
	_consume_press(KEY_V)


func is_attack_input_blocked() -> bool:
	return _is_attack_input_blocked()


func _initialize_inventory() -> void:
	inventory_items.clear()
	for _i in range(BAG_SLOT_COUNT):
		inventory_items.append({})
	_initialize_equipment_slots()


func _initialize_equipment_slots() -> void:
	equipment_slots.clear()
	for slot_id in ITEM_DATABASE.get_equipment_slot_ids():
		equipment_slots[slot_id] = {}
	equipped_weapon = equipment_slots.get("weapon", {})


func _first_empty_bag_slot() -> int:
	for i in range(inventory_items.size()):
		if inventory_items[i].is_empty():
			return i
	return -1


func _is_valid_bag_slot(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < inventory_items.size()


func _is_attack_input_blocked() -> bool:
	return item_cursor_blocks_attacks or attack_input_suppression_time > 0.0


func _handle_inventory_input() -> void:
	for i in range(EQUIP_SLOT_KEYS.size()):
		if _consume_press(EQUIP_SLOT_KEYS[i]):
			equip_bag_slot(i)
			return


func _refresh_equipment_stats() -> void:
	damage_bonus = 0
	for slot_id in equipment_slots.keys():
		var item: Dictionary = equipment_slots[slot_id]
		if item.is_empty():
			continue
		damage_bonus += ITEM_DATABASE.get_stat_modifier_total(item, "damage")
	equipped_weapon = equipment_slots.get("weapon", {})


func _can_use_equipment_slot(slot_id: String) -> bool:
	if not equipment_slots.has(slot_id):
		return false
	var slot := ITEM_DATABASE.get_equipment_slot(slot_id)
	return bool(slot.get("active", false))


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
