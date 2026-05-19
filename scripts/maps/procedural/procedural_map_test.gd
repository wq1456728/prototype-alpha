extends Node2D

const ConfigScript := preload("res://scripts/maps/procedural/map_generation_config.gd")
const GeneratorScript := preload("res://scripts/maps/procedural/map_generator.gd")
const DebugScript := preload("res://scripts/maps/procedural/map_generation_debug.gd")

@export var test_seed := 23001
@export var config_path := "res://data/maps/procedural_dummy_config.json"

var layout: GeneratedMapLayout
var config: MapGenerationConfig
var validation_result := {}
var camera: Camera2D
var overlay_label: Label
var base_camera_zoom := 1.0
var zoom_multiplier := 1.0
var camera_move_speed := 900.0


func _ready() -> void:
	config = ConfigScript.from_json_file(config_path)
	_setup_camera()
	_setup_overlay()
	_rebuild_layout()


func _process(delta: float) -> void:
	if camera == null:
		return
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if direction != Vector2.ZERO:
		camera.position += direction.normalized() * camera_move_speed * delta / max(camera.zoom.x, 0.001)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom(1.18)
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom(1.0 / 1.18)
		return
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_R:
			test_seed += 1
			_rebuild_layout()
		KEY_MINUS:
			test_seed -= 1
			_rebuild_layout()
		KEY_EQUAL:
			test_seed += 10
			_rebuild_layout()
		KEY_Q:
			_adjust_zoom(1.0 / 1.18)
		KEY_E:
			_adjust_zoom(1.18)
		KEY_SPACE:
			_reset_camera_view()


func _rebuild_layout() -> void:
	layout = GeneratorScript.generate(config, test_seed)
	validation_result = DebugScript.validate_layout(layout)
	DebugScript.build_scene(self, layout)
	_fit_camera_to_layout()
	_update_overlay()


func get_debug_payload() -> Dictionary:
	if layout == null:
		return {}
	return layout.to_payload()


func get_validation_result() -> Dictionary:
	return validation_result.duplicate(true)


func get_payload_hash() -> int:
	if layout == null:
		return 0
	return DebugScript.stable_payload_hash(layout)


func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.name = "DebugCamera"
	camera.enabled = true
	add_child(camera)


func _fit_camera_to_layout() -> void:
	if layout == null or camera == null:
		return
	var viewport_size := get_viewport_rect().size
	var padding := 260.0
	var zoom_x := viewport_size.x / (layout.map_size.x + padding * 2.0)
	var zoom_y := viewport_size.y / (layout.map_size.y + padding * 2.0)
	base_camera_zoom = min(zoom_x, zoom_y)
	camera.position = layout.map_size * 0.5
	_apply_camera_zoom()


func _adjust_zoom(factor: float) -> void:
	zoom_multiplier = clamp(zoom_multiplier * factor, 0.45, 7.0)
	_apply_camera_zoom()
	_update_overlay()


func _apply_camera_zoom() -> void:
	if camera == null:
		return
	var zoom_value := base_camera_zoom * zoom_multiplier
	camera.zoom = Vector2(zoom_value, zoom_value)


func _reset_camera_view() -> void:
	if layout == null or camera == null:
		return
	zoom_multiplier = 1.0
	camera.position = layout.map_size * 0.5
	_apply_camera_zoom()
	_update_overlay()


func _setup_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "DebugOverlay"
	add_child(canvas)
	overlay_label = Label.new()
	overlay_label.name = "Legend"
	overlay_label.position = Vector2(18.0, 18.0)
	overlay_label.add_theme_font_size_override("font_size", 18)
	overlay_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.78, 1.0))
	overlay_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	overlay_label.add_theme_constant_override("shadow_offset_x", 2)
	overlay_label.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(overlay_label)


func _update_overlay() -> void:
	if overlay_label == null or layout == null:
		return
	var validation_state := "PASS" if bool(validation_result.get("ok", false)) else "FAIL"
	overlay_label.text = "\n".join([
		"Procedural map debug viewer",
		"Config: %s" % config_path,
		"Seed: %d  Hash: %d  Validation: %s  Zoom: %.2fx" % [test_seed, DebugScript.stable_payload_hash(layout), validation_state, zoom_multiplier],
		"Controls: Mouse wheel / Q/E zoom, WASD/arrows pan, Space reset, R next seed, - previous seed, = +10 seeds",
		"",
		"Large translucent blocks: zones",
		"Brown blocks: route corridors",
		"Yellow squares: anchors",
		"Cyan squares: map object hooks",
		"Red squares: monster spawn groups",
		"Dark empty canvas: unused in this core test, not final playable area",
	])
