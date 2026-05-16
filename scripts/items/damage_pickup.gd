extends Area2D

const FLOATING_FEEDBACK_SCENE := preload("res://scenes/ui/floating_feedback.tscn")
const PICKUP_SFX := preload("res://assets/audio/sfx/loot_pickup_coin.mp3")
const PICKUP_TEXT_COLOR := Color(0.55, 1.0, 0.48, 1.0)

@export var damage_bonus := 8

var picked_up := false


func _ready() -> void:
	add_to_group("loot")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if picked_up:
		return
	if not body.has_method("add_damage_bonus"):
		return
	picked_up = true
	body.add_damage_bonus(damage_bonus)
	_spawn_pickup_feedback()
	_spawn_pickup_sfx()
	queue_free()


func _spawn_pickup_feedback() -> void:
	var feedback := FLOATING_FEEDBACK_SCENE.instantiate()
	feedback.global_position = global_position + Vector2(0, -26)
	get_tree().current_scene.add_child(feedback)
	feedback.setup("Damage +%d" % damage_bonus, PICKUP_TEXT_COLOR)


func _spawn_pickup_sfx() -> void:
	var audio := AudioStreamPlayer2D.new()
	audio.stream = PICKUP_SFX
	audio.volume_db = -15.0
	audio.pitch_scale = 1.05
	audio.global_position = global_position
	audio.finished.connect(audio.queue_free)
	get_tree().current_scene.add_child(audio)
	audio.play()
