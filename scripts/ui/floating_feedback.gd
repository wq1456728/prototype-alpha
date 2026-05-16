extends Node2D

@export var rise_speed := 38.0
@export var lifetime := 0.75

@onready var label: Label = $Label

var age := 0.0
var pending_text := ""
var pending_color := Color.WHITE


func _ready() -> void:
	add_to_group("feedback")
	_apply_pending()


func setup(text: String, color: Color) -> void:
	pending_text = text
	pending_color = color
	if is_node_ready():
		_apply_pending()


func _process(delta: float) -> void:
	age += delta
	position.y -= rise_speed * delta
	modulate.a = maxf(1.0 - age / lifetime, 0.0)
	if age >= lifetime:
		queue_free()


func _apply_pending() -> void:
	label.text = pending_text
	label.label_settings.font_color = pending_color
