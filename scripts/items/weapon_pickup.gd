extends Area2D

const FLOATING_FEEDBACK_SCENE := preload("res://scenes/ui/floating_feedback.tscn")
const PICKUP_SFX := preload("res://assets/audio/sfx/loot_pickup_coin.mp3")
const ITEM_DATABASE := preload("res://scripts/items/item_database.gd")
const PICKUP_TEXT_COLOR := Color(0.55, 1.0, 0.48, 1.0)
const FULL_TEXT_COLOR := Color(1.0, 0.48, 0.34, 1.0)

@onready var icon: Sprite2D = $Icon

var item_data: Dictionary = {}
var picked_up := false


func _ready() -> void:
	add_to_group("loot")
	if item_data.is_empty():
		item_data = _default_weapon_item()
	else:
		item_data = ITEM_DATABASE.normalize_item_instance(item_data)
	_apply_visual()


func setup_item(data: Dictionary) -> void:
	item_data = ITEM_DATABASE.normalize_item_instance(data)
	if is_inside_tree():
		_apply_visual()


func get_item_data() -> Dictionary:
	return item_data.duplicate(true)


func collect_from_world() -> Dictionary:
	if picked_up:
		return {}
	picked_up = true
	_spawn_feedback("Picked up %s" % str(item_data.get("name", "Weapon")), PICKUP_TEXT_COLOR)
	_spawn_pickup_sfx()
	queue_free()
	return item_data.duplicate(true)


func show_reject_feedback(text: String) -> void:
	_spawn_feedback(text, FULL_TEXT_COLOR)


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
	return ITEM_DATABASE.make_item_instance("weapon_rusty_short_sword", "normal", {"damage": 8}, {"name": "Worn Short Sword"})
