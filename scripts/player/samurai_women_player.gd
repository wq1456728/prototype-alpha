extends CharacterBody2D

const IDLE_FRAMES_RESOURCE := "res://assets/animations/samurai_women_idle.tres"
const WALK_SPEED := 130.0
const RUN_SPEED := 220.0
const MAX_HP := 100

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_bar: ProgressBar = $HPBar

var hp := MAX_HP


func _ready() -> void:
	add_to_group("player")
	sprite.sprite_frames = load(IDLE_FRAMES_RESOURCE)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hp_bar.max_value = MAX_HP
	hp_bar.value = hp
	sprite.play("idle")


func _physics_process(_delta: float) -> void:
	var direction := _read_move_direction()
	var wants_run := Input.is_key_pressed(KEY_SHIFT)
	var target_speed := RUN_SPEED if wants_run else WALK_SPEED
	velocity = direction * target_speed
	move_and_slide()

	if absf(direction.x) > 0.01:
		sprite.flip_h = direction.x < 0
	if sprite.animation != "idle" or not sprite.is_playing():
		sprite.play("idle")


func take_damage(amount: int, _source_position: Vector2 = Vector2.ZERO) -> void:
	hp = maxi(hp - amount, 0)
	hp_bar.value = hp


func heal_fraction(fraction: float) -> void:
	var heal_amount := int(round(MAX_HP * fraction))
	hp = mini(hp + heal_amount, MAX_HP)
	hp_bar.value = hp


func _read_move_direction() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y += 1.0
	return direction.normalized()
