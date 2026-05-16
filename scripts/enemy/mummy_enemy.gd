extends CharacterBody2D

const WEAPON_PICKUP_SCENE := preload("res://scenes/items/weapon_pickup.tscn")
const FLOATING_FEEDBACK_SCENE := preload("res://scenes/ui/floating_feedback.tscn")
const ITEM_DATABASE := preload("res://scripts/items/item_database.gd")
const HIT_IMPACT_SFX := preload("res://assets/audio/sfx/enemy_hit_impact.mp3")
const DEATH_SFX := preload("res://assets/audio/sfx/enemy_mummy_death.mp3")

@export var max_hp := 60
@export var move_speed := 72.0
@export var attack_damage := 12
@export var detect_range := 360.0
@export var attack_range := 48.0
@export var preferred_distance := 42.0
@export var attack_cooldown := 1.05
@export var display_scale := 3.0
@export var ai_min_think_time := 0.45
@export var ai_max_think_time := 1.1
@export var drops_loot := true
@export var xp_reward := 20

const ATTACK_LOCK_TIME := 0.62
const ATTACK_HIT_DELAY := 0.32
const HURT_LOCK_TIME := 0.22
const DEATH_CLEANUP_TIME := 1.6
const PLAYER_SOFT_COLLISION_DISTANCE := 46.0
const PLAYER_SOFT_COLLISION_FORCE := 135.0
const ENEMY_SOFT_COLLISION_DISTANCE := 44.0
const ENEMY_SOFT_COLLISION_FORCE := 115.0
const MAX_SOFT_COLLISION_SPEED := 125.0
const SPRITE_ROOT := "res://assets/sprites/enemies/mummy"
const SPRITE_FRAME_WIDTH := 64
const SPRITE_FRAME_HEIGHT := 64
const HIT_FLASH_TIME := 0.12
const HIT_FLASH_COLOR := Color(1.0, 0.42, 0.36, 1.0)
const HURT_KNOCKBACK_SPEED := 130.0
const DAMAGE_NUMBER_COLOR := Color(1.0, 0.86, 0.36, 1.0)
const XP_NUMBER_COLOR := Color(0.45, 0.78, 1.0, 1.0)
const WEAPON_BASES := [
	{
		"id": "rusty_short_sword",
		"definition_id": "weapon_rusty_short_sword",
		"name": "Short Sword",
		"icon": "res://assets/sprites/items/item_weapon_rusty_short_sword_icon.png",
	},
	{
		"id": "iron_sword",
		"definition_id": "weapon_iron_sword",
		"name": "Iron Sword",
		"icon": "res://assets/sprites/items/item_weapon_iron_sword_icon.png",
	},
	{
		"id": "bone_axe",
		"definition_id": "weapon_bone_axe",
		"name": "Bone Axe",
		"icon": "res://assets/sprites/items/item_weapon_bone_axe_icon.png",
	},
	{
		"id": "crystal_sword",
		"definition_id": "weapon_crystal_sword",
		"name": "Crystal Sword",
		"icon": "res://assets/sprites/items/item_weapon_crystal_sword_icon.png",
	},
	{
		"id": "flame_sword",
		"definition_id": "weapon_flame_sword",
		"name": "Flame Sword",
		"icon": "res://assets/sprites/items/item_weapon_flame_sword_icon.png",
	},
]
const RARITY_DATA := {
	"normal": {
		"prefix": "Worn",
		"damage_min": 6,
		"damage_max": 9,
		"color": Color(0.82, 0.78, 0.68, 1.0),
	},
	"magic": {
		"prefix": "Glimmering",
		"damage_min": 10,
		"damage_max": 14,
		"color": Color(0.36, 0.64, 1.0, 1.0),
	},
	"rare": {
		"prefix": "Ancient",
		"damage_min": 15,
		"damage_max": 20,
		"color": Color(1.0, 0.78, 0.25, 1.0),
	},
}
const MAGIC_DROP_CHANCE := 0.24
const RARE_DROP_CHANCE := 0.08

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_bar: ProgressBar = $HPBar

var hp := 0
var player: Node2D
var dead := false
var action_lock := 0.0
var locked_velocity := Vector2.ZERO
var attack_timer := 0.0
var pending_attack_hit := false
var pending_attack_time := -1.0
var ai_mode := "approach"
var ai_timer := 0.0
var strafe_sign := 1.0
var flash_time := 0.0
var base_modulate := Color.WHITE


func _ready() -> void:
	randomize()
	add_to_group("enemy")
	hp = max_hp
	sprite.sprite_frames = _build_sprite_frames()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(display_scale, display_scale)
	base_modulate = sprite.modulate
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	_find_player()
	_play("idle")


func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_update_hit_flash(delta)

	if not is_instance_valid(player):
		_find_player()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	ai_timer -= delta

	if action_lock > 0.0:
		action_lock -= delta
		if pending_attack_hit:
			pending_attack_time -= delta
			if pending_attack_time <= 0.0:
				_apply_attack_hit()
				pending_attack_hit = false
		velocity = locked_velocity
		move_and_slide()
		if action_lock <= 0.0:
			locked_velocity = Vector2.ZERO
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()
	if ai_timer <= 0.0:
		_pick_ai_mode(distance)

	if distance > detect_range:
		velocity = _soft_collision_velocity()
		_play("idle")
	elif distance <= attack_range and attack_timer <= 0.0:
		_start_attack()
	elif ai_mode == "pause" or distance <= preferred_distance:
		velocity = _soft_collision_velocity()
		_update_facing(to_player)
		_play("idle")
	else:
		var direction := _movement_direction(to_player, distance)
		velocity = direction * move_speed + _soft_collision_velocity()
		_update_facing(direction)
		_play("walk")

	move_and_slide()


func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if dead:
		return
	hp = maxi(hp - amount, 0)
	hp_bar.value = hp
	_spawn_feedback(str(amount), DAMAGE_NUMBER_COLOR, Vector2(0, -78))
	_spawn_sfx(HIT_IMPACT_SFX, -14.0, 1.05)
	_start_hit_flash()
	_update_facing(source_position - global_position)
	if hp <= 0:
		_die()
		return
	action_lock = HURT_LOCK_TIME
	locked_velocity = _knockback_from(source_position)
	pending_attack_hit = false
	velocity = Vector2.ZERO
	_play("hurt", true)


func _start_attack() -> void:
	action_lock = ATTACK_LOCK_TIME
	locked_velocity = Vector2.ZERO
	attack_timer = attack_cooldown
	pending_attack_hit = true
	pending_attack_time = ATTACK_HIT_DELAY
	velocity = Vector2.ZERO
	_update_facing(player.global_position - global_position)
	_play("attack", true)


func _apply_attack_hit() -> void:
	if not is_instance_valid(player) or not player.has_method("take_damage"):
		return
	if global_position.distance_to(player.global_position) <= attack_range + 12.0:
		player.take_damage(attack_damage, global_position)


func _movement_direction(to_player: Vector2, distance: float) -> Vector2:
	var direction := to_player.normalized()
	if ai_mode == "strafe" and distance < detect_range * 0.75:
		var tangent := Vector2(-direction.y, direction.x) * strafe_sign
		return (direction * 0.45 + tangent * 0.85).normalized()
	return direction


func _soft_collision_velocity() -> Vector2:
	var push := Vector2.ZERO

	if is_instance_valid(player):
		push += _push_from_node(player, PLAYER_SOFT_COLLISION_DISTANCE, PLAYER_SOFT_COLLISION_FORCE)

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == self or not is_instance_valid(enemy):
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


func _pick_ai_mode(distance: float) -> void:
	ai_timer = randf_range(ai_min_think_time, ai_max_think_time)
	if distance > preferred_distance * 3.0:
		ai_mode = "approach"
		return

	var roll := randf()
	if distance > preferred_distance * 1.8:
		if roll < 0.08:
			ai_mode = "pause"
		else:
			ai_mode = "approach"
		return

	if roll < 0.18:
		ai_mode = "pause"
	elif roll < 0.56:
		ai_mode = "strafe"
		strafe_sign = -1.0 if randf() < 0.5 else 1.0
	else:
		ai_mode = "approach"


func _die() -> void:
	dead = true
	remove_from_group("enemy")
	velocity = Vector2.ZERO
	locked_velocity = Vector2.ZERO
	action_lock = 0.0
	pending_attack_hit = false
	hp_bar.visible = false
	_spawn_sfx(DEATH_SFX, -13.0, 1.0)
	_grant_player_xp()
	_drop_loot()
	_heal_player_on_death()
	_play("death", true)
	await get_tree().create_timer(DEATH_CLEANUP_TIME).timeout
	queue_free()


func _heal_player_on_death() -> void:
	if not is_instance_valid(player):
		_find_player()
	if is_instance_valid(player) and player.has_method("heal_fraction"):
		player.heal_fraction(1.0 / 3.0)


func _grant_player_xp() -> void:
	if not is_instance_valid(player):
		_find_player()
	if not is_instance_valid(player) or not player.has_method("gain_xp"):
		return
	player.gain_xp(xp_reward)
	_spawn_feedback("+%d XP" % xp_reward, XP_NUMBER_COLOR, Vector2(0, -96))


func _drop_loot() -> void:
	if not drops_loot:
		return
	var loot := WEAPON_PICKUP_SCENE.instantiate()
	if loot.has_method("setup_item"):
		loot.setup_item(_make_weapon_drop())
	loot.global_position = global_position
	var loot_parent := get_parent()
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.has_method("get_world_item_parent"):
		loot_parent = current_scene.get_world_item_parent()
	elif current_scene != null and current_scene.get_node_or_null("Loot") != null:
		loot_parent = current_scene.get_node_or_null("Loot") as Node2D
	if loot_parent == null and current_scene != null:
		loot_parent = current_scene
	if loot_parent == null:
		add_child(loot)
	else:
		loot_parent.add_child(loot)


func _make_weapon_drop() -> Dictionary:
	var rarity := _roll_weapon_rarity()
	var rarity_data: Dictionary = RARITY_DATA[rarity]
	var base: Dictionary = WEAPON_BASES.pick_random()
	var damage_bonus := randi_range(int(rarity_data["damage_min"]), int(rarity_data["damage_max"]))
	var item_id := "%s_%s_%d" % [rarity, str(base["id"]), damage_bonus]
	return ITEM_DATABASE.make_item_instance(str(base["definition_id"]), rarity, {"damage": damage_bonus}, {
		"id": item_id,
		"name": "%s %s" % [str(rarity_data["prefix"]), str(base["name"])],
		"color": rarity_data["color"],
	})


func _roll_weapon_rarity() -> String:
	var roll := randf()
	if roll < RARE_DROP_CHANCE:
		return "rare"
	if roll < RARE_DROP_CHANCE + MAGIC_DROP_CHANCE:
		return "magic"
	return "normal"


func _spawn_feedback(text: String, color: Color, offset: Vector2) -> void:
	var feedback := FLOATING_FEEDBACK_SCENE.instantiate()
	feedback.global_position = global_position + offset
	get_tree().current_scene.add_child(feedback)
	feedback.setup(text, color)


func _spawn_sfx(stream: AudioStream, volume_db: float, pitch_scale: float = 1.0) -> void:
	var audio := AudioStreamPlayer2D.new()
	audio.stream = stream
	audio.volume_db = volume_db
	audio.pitch_scale = pitch_scale
	audio.global_position = global_position
	audio.finished.connect(audio.queue_free)
	get_tree().current_scene.add_child(audio)
	audio.play()


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0] as Node2D


func _update_facing(direction: Vector2) -> void:
	if absf(direction.x) > 0.01:
		sprite.flip_h = direction.x > 0


func _knockback_from(source_position: Vector2) -> Vector2:
	var away := global_position - source_position
	if away.length_squared() <= 0.01:
		return Vector2.ZERO
	return away.normalized() * HURT_KNOCKBACK_SPEED


func _start_hit_flash() -> void:
	flash_time = HIT_FLASH_TIME
	sprite.modulate = HIT_FLASH_COLOR


func _update_hit_flash(delta: float) -> void:
	if flash_time <= 0.0:
		return
	flash_time -= delta
	if flash_time <= 0.0:
		sprite.modulate = base_modulate


func _play(anim_name: StringName, restart: bool = false) -> void:
	if restart or sprite.animation != anim_name:
		sprite.play(anim_name)


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_frames(frames, "idle", "idle", 4, 6.0, true)
	_add_frames(frames, "walk", "walk", 6, 8.0, true)
	_add_frames(frames, "attack", "attack", 6, 10.0, false)
	_add_frames(frames, "hurt", "hurt", 2, 10.0, false)
	_add_frames(frames, "death", "death", 6, 8.0, false)
	return frames


func _add_frames(frames: SpriteFrames, anim_name: StringName, prefix: String, count: int, speed: float, loops: bool) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, speed)
	frames.set_animation_loop(anim_name, loops)
	var sheet_path := "%s/enemy_mummy_%s_side.png" % [SPRITE_ROOT, prefix]
	var sheet := load(sheet_path) as Texture2D
	if sheet == null:
		return

	for i in range(count):
		frames.add_frame(anim_name, _make_atlas_frame(sheet, i))


func _make_atlas_frame(sheet: Texture2D, frame_index: int) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = sheet
	frame.region = Rect2(frame_index * SPRITE_FRAME_WIDTH, 0, SPRITE_FRAME_WIDTH, SPRITE_FRAME_HEIGHT)
	frame.filter_clip = true
	return frame
