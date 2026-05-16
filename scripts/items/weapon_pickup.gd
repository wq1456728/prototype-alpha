extends Area2D

const FLOATING_FEEDBACK_SCENE := preload("res://scenes/ui/floating_feedback.tscn")
const PICKUP_SFX := preload("res://assets/audio/sfx/loot_pickup_coin.mp3")
const PICKUP_TEXT_COLOR := Color(0.55, 1.0, 0.48, 1.0)
const FULL_TEXT_COLOR := Color(1.0, 0.48, 0.34, 1.0)

@onready var icon: Sprite2D = $Icon

var item_data: Dictionary = {}
var picked_up := false


func _ready() -> void:
	add_to_group("loot")
	if item_data.is_empty():
		item_data = _default_weapon_item()
	_apply_visual()
	body_entered.connect(_on_body_entered)


func setup_item(data: Dictionary) -> void:
	item_data = data.duplicate(true)
	if is_inside_tree():
		_apply_visual()


func _on_body_entered(body: Node2D) -> void:
	if picked_up:
		return
	if not body.has_method("pickup_weapon_item"):
		return
	var accepted := bool(body.pickup_weapon_item(item_data))
	if not accepted:
		_spawn_feedback("Bag Full", FULL_TEXT_COLOR)
		return
	picked_up = true
	_spawn_feedback("Picked up %s" % str(item_data.get("name", "Weapon")), PICKUP_TEXT_COLOR)
	_spawn_pickup_sfx()
	queue_free()


func _apply_visual() -> void:
	var icon_path := str(item_data.get("icon", ""))
	var texture := load(icon_path) as Texture2D
	if texture != null:
		icon.texture = texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.scale = Vector2(1.35, 1.35)


func _spawn_feedback(text: String, color: Color) -> void:
	var feedback := FLOATING_FEEDBACK_SCENE.instantiate()
	feedback.global_position = global_position + Vector2(0, -30)
	get_tree().current_scene.add_child(feedback)
	feedback.setup(text, color)


func _spawn_pickup_sfx() -> void:
	var audio := AudioStreamPlayer2D.new()
	audio.stream = PICKUP_SFX
	audio.volume_db = -15.0
	audio.pitch_scale = 1.05
	audio.global_position = global_position
	audio.finished.connect(audio.queue_free)
	get_tree().current_scene.add_child(audio)
	audio.play()


func _default_weapon_item() -> Dictionary:
	return {
		"type": "weapon",
		"id": "rusty_short_sword",
		"name": "Rusty Short Sword",
		"rarity": "normal",
		"damage_bonus": 8,
		"icon": "res://assets/sprites/items/item_weapon_rusty_short_sword_icon.png",
		"color": Color(0.82, 0.78, 0.68, 1.0),
	}
