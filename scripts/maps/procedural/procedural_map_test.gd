extends Node2D

const ConfigScript := preload("res://scripts/maps/procedural/map_generation_config.gd")
const GeneratorScript := preload("res://scripts/maps/procedural/map_generator.gd")
const DebugScript := preload("res://scripts/maps/procedural/map_generation_debug.gd")
const BoundaryPassScript := preload("res://scripts/maps/procedural/generated_boundary_pass.gd")

const DUMMY_CONFIG_PATH := "res://data/maps/procedural_dummy_config.json"
const FIRST_OUTDOOR_CONFIG_PATH := "res://data/maps/first_outdoor_map.json"
const FIRST_OUTDOOR_SEED := 24001

enum OverlayMode {
	LAYOUT,
	WALKABLE,
	COMBINED,
}

@export var test_seed := 23001
@export var config_path := DUMMY_CONFIG_PATH
@export var start_with_first_outdoor_config := false

var layout: GeneratedMapLayout
var config: MapGenerationConfig
var raw_config := {}
var validation_result := {}
var boundary_payload := {}
var camera: Camera2D
var overlay_label: Label
var mask_overlay_root: Node2D
var base_camera_zoom := 1.0
var zoom_multiplier := 1.0
var camera_move_speed := 900.0
var overlay_mode := OverlayMode.LAYOUT


func _ready() -> void:
	if start_with_first_outdoor_config:
		config_path = FIRST_OUTDOOR_CONFIG_PATH
		test_seed = FIRST_OUTDOOR_SEED
	_load_config()
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
		KEY_TAB, KEY_V:
			_cycle_overlay_mode()
		KEY_1:
			use_dummy_config()
		KEY_2, KEY_F:
			use_first_outdoor_config()
		KEY_Q:
			_adjust_zoom(1.0 / 1.18)
		KEY_E:
			_adjust_zoom(1.18)
		KEY_SPACE:
			_reset_camera_view()


func use_dummy_config() -> void:
	config_path = DUMMY_CONFIG_PATH
	test_seed = 23001
	_load_config()
	_rebuild_layout()


func use_first_outdoor_config() -> void:
	config_path = FIRST_OUTDOOR_CONFIG_PATH
	test_seed = FIRST_OUTDOOR_SEED
	_load_config()
	_rebuild_layout()


func set_overlay_mode(mode: int) -> void:
	overlay_mode = clampi(mode, OverlayMode.LAYOUT, OverlayMode.COMBINED)
	_apply_overlay_mode()
	_update_overlay()


func _rebuild_layout() -> void:
	layout = GeneratorScript.generate(config, test_seed)
	validation_result = DebugScript.validate_layout(layout)
	_rebuild_boundary_payload()
	DebugScript.build_scene(self, layout)
	_rebuild_mask_overlay()
	_apply_overlay_mode()
	_fit_camera_to_layout()
	_update_overlay()


func _load_config() -> void:
	raw_config = _load_json_dictionary(config_path)
	config = ConfigScript.from_json_file(config_path)


func _load_json_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _rebuild_boundary_payload() -> void:
	if layout == null:
		boundary_payload = {}
		return
	var boundary_pass = BoundaryPassScript.new()
	boundary_payload = boundary_pass.generate(layout, raw_config.get("boundary_style", {}), null, test_seed)


func _cycle_overlay_mode() -> void:
	set_overlay_mode((overlay_mode + 1) % 3)


func get_debug_payload() -> Dictionary:
	if layout == null:
		return {}
	return layout.to_payload()


func get_boundary_debug_payload() -> Dictionary:
	return boundary_payload.duplicate(true)


func get_overlay_mode() -> int:
	return overlay_mode


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


func _rebuild_mask_overlay() -> void:
	if mask_overlay_root != null:
		remove_child(mask_overlay_root)
		mask_overlay_root.free()
	mask_overlay_root = Node2D.new()
	mask_overlay_root.name = "WalkableMaskOverlay"
	add_child(mask_overlay_root)
	if boundary_payload.is_empty():
		return

	var cell_size := int(boundary_payload.get("cell_size", 64))
	var cells_root := Node2D.new()
	cells_root.name = "Cells"
	mask_overlay_root.add_child(cells_root)
	_add_cell_rects(cells_root, "BlockedCells", boundary_payload.get("blocked_cells", []), cell_size, Color(0.35, 0.06, 0.04, 0.18), -30)
	_add_cell_rects(cells_root, "WalkableCells", boundary_payload.get("walkable_cells", []), cell_size, Color(0.1, 0.82, 0.25, 0.32), -20)
	_add_cell_rects(cells_root, "BoundaryCells", boundary_payload.get("boundary_cells", []), cell_size, Color(1.0, 0.68, 0.1, 0.44), -10)
	_add_contour_lines(mask_overlay_root, boundary_payload.get("contour_segments", []))


func _add_cell_rects(parent: Node, root_name: String, cells: Array, cell_size: int, color: Color, z_index: int) -> void:
	var root := Node2D.new()
	root.name = root_name
	parent.add_child(root)
	for cell_value in cells:
		var cell: Dictionary = cell_value
		var rect := ColorRect.new()
		rect.name = "%s_%03d_%03d" % [root_name, int(cell.get("x", 0)), int(cell.get("y", 0))]
		rect.position = Vector2(int(cell.get("x", 0)) * cell_size, int(cell.get("y", 0)) * cell_size)
		rect.size = Vector2(cell_size, cell_size)
		rect.color = color
		rect.z_index = z_index
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(rect)


func _add_contour_lines(parent: Node, contour_segments: Array) -> void:
	var root := Node2D.new()
	root.name = "ContourLines"
	parent.add_child(root)
	for segment_value in contour_segments:
		var segment: Dictionary = segment_value
		var line := Line2D.new()
		line.name = str(segment.get("id", "contour"))
		line.width = 5.0
		line.default_color = Color(0.1, 1.0, 0.65, 0.95)
		line.z_index = 20
		line.add_point(_vector_from_payload(segment.get("start", {})))
		line.add_point(_vector_from_payload(segment.get("end", {})))
		root.add_child(line)


func _apply_overlay_mode() -> void:
	var generated_root := get_node_or_null("GeneratedProceduralMap") as CanvasItem
	if generated_root != null:
		generated_root.visible = overlay_mode != OverlayMode.WALKABLE
		generated_root.modulate = Color(1.0, 1.0, 1.0, 0.46) if overlay_mode == OverlayMode.COMBINED else Color.WHITE
	if mask_overlay_root != null:
		mask_overlay_root.visible = overlay_mode != OverlayMode.LAYOUT


func _update_overlay() -> void:
	if overlay_label == null or layout == null:
		return
	var validation_state := "PASS" if bool(validation_result.get("ok", false)) else "FAIL"
	var is_first_outdoor := config_path == FIRST_OUTDOOR_CONFIG_PATH
	var config_label := "FIRST OUTDOOR PLAYABLE CONFIG" if is_first_outdoor else "DUMMY DEBUG CONFIG - not the formal first map"
	var cell_size := int(boundary_payload.get("cell_size", 0))
	var walkable_count := Array(boundary_payload.get("walkable_cells", [])).size()
	var boundary_count := Array(boundary_payload.get("boundary_cells", [])).size()
	var blocked_count := Array(boundary_payload.get("blocked_cells", [])).size()
	var contour_count := Array(boundary_payload.get("contour_segments", [])).size()
	overlay_label.text = "\n".join([
		"Procedural map debug viewer",
		"Mode: %s" % _overlay_mode_name(),
		"Config: %s" % config_path,
		"Config type: %s" % config_label,
		"Seed: %d  Hash: %d  Validation: %s  Zoom: %.2fx" % [test_seed, DebugScript.stable_payload_hash(layout), validation_state, zoom_multiplier],
		"Cell size: %d  Walkable: %d  Boundary: %d  Blocked: %d  Contours: %d" % [cell_size, walkable_count, boundary_count, blocked_count, contour_count],
		"Controls: Tab/V mode, 1 dummy config, 2/F first outdoor, Mouse wheel/Q/E zoom, WASD/arrows pan, Space reset, R next seed, - previous seed, = +10 seeds",
		"",
		"Walkable View colors: green walkable, orange boundary, dark red blocked, bright green contour",
		"Large translucent blocks: zones",
		"Brown blocks: route corridors",
		"Yellow squares: anchors",
		"Cyan squares: map object hooks",
		"Red squares: monster spawn groups",
		"Dark empty canvas: unused in this core test, not final playable area",
	])


func _overlay_mode_name() -> String:
	match overlay_mode:
		OverlayMode.WALKABLE:
			return "Walkable View"
		OverlayMode.COMBINED:
			return "Combined View"
	return "Layout View"


func _vector_from_payload(value) -> Vector2:
	if not (value is Dictionary):
		return Vector2.ZERO
	var data: Dictionary = value
	return Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
