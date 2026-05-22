extends "res://scripts/maps/first_outdoor_generated.gd"

const COLLISION_LAYERS := preload("res://scripts/physics/collision_layers.gd")

const CAMP_LAYOUT_PATH := "res://data/maps/camp_01_layout.json"
const MAIN_WORLD_DYNAMIC_Z_OFFSET := 1200.0
const FIXED_TOWN_STATIC_Z := -2600
const CAMP_ALPHA_VISIBLE_THRESHOLD := 0.05

@export var randomize_generation_seed_on_ready := true

var camp_layout := {}
var camp_assets := {}
var camp_animation_assets := {}
var camp_bounds := Rect2(Vector2(960, -940), Vector2(1660, 920))
var town_spawn_offset := Vector2(-430, 520)
var town_exit_offset := Vector2(0, -70)
var town_camera_padding := 180.0
var town_exit_opening_width := 720.0
var town_boundary_collision_thickness := 8.0
var fixed_town: Node2D
var generated_region: Node2D
var transition_chunk: Node2D
var town_spawn_marker: Marker2D
var town_exit_socket: Marker2D
var wilderness_start_socket: Marker2D
var town_blockers_root: StaticBody2D
var camp_interaction_label: Label


func _ready() -> void:
	if randomize_generation_seed_on_ready:
		generation_seed = _make_runtime_seed()
	super._ready()


func _build_generated_world() -> void:
	_load_camp_layout()
	_build_fixed_town()
	generated_region = Node2D.new()
	generated_region.name = "GeneratedRegion"
	generated_region.y_sort_enabled = true
	add_child(generated_region)
	super._build_generated_world()
	_collect_generated_children()
	_build_fixed_transition_chunk()


func _build_fixed_town() -> void:
	fixed_town = Node2D.new()
	fixed_town.name = "FixedTown"
	fixed_town.y_sort_enabled = true
	fixed_town.z_as_relative = false
	fixed_town.z_index = FIXED_TOWN_STATIC_Z
	add_child(fixed_town)

	var ground := Node2D.new()
	ground.name = "Ground"
	fixed_town.add_child(ground)
	_build_camp_ground(ground)

	var props := Node2D.new()
	props.name = "Props"
	props.y_sort_enabled = true
	fixed_town.add_child(props)
	_build_camp_modules(props, "props")

	var npc_root := Node2D.new()
	npc_root.name = "NPCPlaceholders"
	npc_root.y_sort_enabled = true
	fixed_town.add_child(npc_root)
	_build_camp_modules(npc_root, "npcs")

	var interactables := Node2D.new()
	interactables.name = "Interactables"
	interactables.y_sort_enabled = true
	fixed_town.add_child(interactables)
	_build_camp_modules(interactables, "interactables")

	town_blockers_root = StaticBody2D.new()
	town_blockers_root.name = "TownBounds"
	town_blockers_root.collision_layer = COLLISION_LAYERS.WORLD
	town_blockers_root.collision_mask = 0
	fixed_town.add_child(town_blockers_root)
	_add_town_thin_bounds()
	_add_town_exit_opening_bounds()

	town_spawn_marker = Marker2D.new()
	town_spawn_marker.name = "TownSpawn"
	town_spawn_marker.global_position = get_town_spawn_position()
	fixed_town.add_child(town_spawn_marker)

	town_exit_socket = Marker2D.new()
	town_exit_socket.name = "TownExitSocket"
	town_exit_socket.global_position = get_town_exit_socket_position()
	fixed_town.add_child(town_exit_socket)

	var gameplay_bounds := Node2D.new()
	gameplay_bounds.name = "GameplayBounds"
	gameplay_bounds.set_meta("rect", camp_bounds)
	fixed_town.add_child(gameplay_bounds)
	_update_fixed_town_z_indices()


func _build_camp_ground(parent: Node) -> void:
	var terrain := _camp_terrain()
	for entry in terrain.get("ground_rects", []):
		var rect_config := entry as Dictionary
		if rect_config.is_empty():
			continue
		var rect := camp_bounds if bool(rect_config.get("use_bounds", false)) else _rect_from_dict(rect_config.get("rect", {}), Rect2())
		_add_town_rect(parent, str(rect_config.get("id", "GroundRect")), rect, _color_from_array(rect_config.get("color", [1.0, 1.0, 1.0, 1.0])), int(rect_config.get("z", 0)))
	for entry in terrain.get("ground_decals", []):
		var decal_config := entry as Dictionary
		if decal_config.is_empty():
			continue
		_add_ground_decal(
			parent,
			str(decal_config.get("id", "GroundDecal")),
			_camp_asset(str(decal_config.get("asset", ""))),
			_vector2_from_array(decal_config.get("position", [0, 0])),
			float(decal_config.get("scale", 1.0))
		)


func _build_camp_modules(parent: Node, target: String) -> void:
	for entry in camp_layout.get("object_modules", []):
		var module_config := entry as Dictionary
		if module_config.is_empty() or str(module_config.get("target", "")) != target:
			continue
		match str(module_config.get("placement_mode", "explicit")):
			"explicit":
				_build_explicit_object_module(parent, module_config)
			_:
				push_warning("MainWorld: unsupported object module placement_mode=%s id=%s" % [str(module_config.get("placement_mode", "")), str(module_config.get("id", ""))])


func _build_explicit_object_module(parent: Node, module_config: Dictionary) -> void:
	var item_index := 0
	for entry in module_config.get("items", []):
		var item_config := entry as Dictionary
		if item_config.is_empty():
			continue
		var resolved_config := _resolve_module_item_config(module_config, item_config, item_index)
		if str(resolved_config.get("type", "")) == "quest_giver":
			_add_quest_giver_placeholder_from_config(parent, resolved_config)
		elif resolved_config.has("animation"):
			_add_camp_animated_prop_from_config(parent, resolved_config)
		else:
			_add_camp_prop_from_config(parent, resolved_config)
		item_index += 1


func _resolve_module_item_config(module_config: Dictionary, item_config: Dictionary, item_index: int) -> Dictionary:
	var resolved := {}
	var defaults = module_config.get("defaults", {})
	if defaults is Dictionary:
		resolved = defaults.duplicate(true)
	for key in item_config.keys():
		resolved[key] = item_config[key]
	if not resolved.has("id"):
		var prefix := str(resolved.get("id_prefix", module_config.get("id", "Object")))
		var digits := int(resolved.get("id_digits", 2))
		resolved["id"] = "%s%s" % [prefix, str(item_index).pad_zeros(digits)]
	return resolved


func _add_camp_prop_from_config(parent: Node, prop_config: Dictionary) -> StaticBody2D:
	var collision := _collision_from_config(prop_config.get("collision", {}))
	return _add_camp_prop_body(
		parent,
		str(prop_config.get("id", "CampProp")),
		_camp_asset(str(prop_config.get("asset", ""))),
		_vector2_from_array(prop_config.get("position", [0, 0])),
		float(prop_config.get("scale", 1.0)),
		str(collision.get("shape", "rect")),
		collision.get("size", Vector2.ZERO),
		collision.get("offset", Vector2.ZERO),
		_vector2_from_array(prop_config.get("sprite_offset", [0, 0])),
		float(prop_config.get("rotation", 0.0)),
		bool(prop_config.get("flip_h", false))
	)


func _add_camp_animated_prop_from_config(parent: Node, prop_config: Dictionary) -> StaticBody2D:
	var collision := _collision_from_config(prop_config.get("collision", {}))
	return _add_camp_animated_prop_body(
		parent,
		str(prop_config.get("id", "AnimatedCampProp")),
		_camp_animation_frames(str(prop_config.get("animation", ""))),
		_vector2_from_array(prop_config.get("position", [0, 0])),
		float(prop_config.get("scale", 1.0)),
		float(prop_config.get("fps", 6.0)),
		str(collision.get("shape", "rect")),
		collision.get("size", Vector2.ZERO),
		collision.get("offset", Vector2.ZERO),
		_vector2_from_array(prop_config.get("sprite_offset", [0, 0]))
	)


func _collect_generated_children() -> void:
	if generated_region == null:
		return
	for child in [visuals_root, boundary_root, props_root]:
		if child != null and child.get_parent() != generated_region:
			child.reparent(generated_region, true)


func _build_fixed_transition_chunk() -> void:
	transition_chunk = Node2D.new()
	transition_chunk.name = "TransitionChunk"
	generated_region.add_child(transition_chunk)

	var start := get_town_exit_socket_position()
	var end := get_camp_entrance_position()
	var top := minf(start.y, end.y) - 48.0
	var bottom := maxf(start.y, end.y)
	_add_town_rect(transition_chunk, "FixedTransitionRoad", Rect2(Vector2(start.x - 180, top), Vector2(360, bottom - top + 130)), Color(0.18, 0.15, 0.095, 1.0), -116)
	_add_town_rect(transition_chunk, "FixedTransitionField", Rect2(Vector2(start.x - 470, top - 56), Vector2(940, bottom - top + 210)), Color(0.09, 0.108, 0.074, 0.82), -121)

	wilderness_start_socket = Marker2D.new()
	wilderness_start_socket.name = "WildernessStartSocket"
	wilderness_start_socket.global_position = end
	transition_chunk.add_child(wilderness_start_socket)

	var north_socket := Marker2D.new()
	north_socket.name = "NorthSocket"
	north_socket.global_position = start
	transition_chunk.add_child(north_socket)

	var south_socket := Marker2D.new()
	south_socket.name = "SouthSocket"
	south_socket.global_position = end
	transition_chunk.add_child(south_socket)

	var gameplay_bounds := Node2D.new()
	gameplay_bounds.name = "GameplayBounds"
	gameplay_bounds.set_meta("rect", Rect2(Vector2(start.x - 420, top - 40), Vector2(840, bottom - top + 180)))
	transition_chunk.add_child(gameplay_bounds)


func _place_player_at_spawn() -> void:
	if player == null:
		return
	player.global_position = get_town_spawn_position()
	player.position = player.global_position


func _apply_first_outdoor_runtime_scale() -> void:
	super._apply_first_outdoor_runtime_scale()
	var camera := player.get_node_or_null("Camera2D") as Camera2D if is_instance_valid(player) else null
	if camera != null and layout != null:
		camera.limit_left = int(minf(0.0, camp_bounds.position.x - town_camera_padding))
		camera.limit_top = int(camp_bounds.position.y - town_camera_padding)
		camera.limit_right = int(maxf(layout.map_size.x, camp_bounds.end.x + town_camera_padding))
		camera.limit_bottom = int(layout.map_size.y)


func _update_world_entity_z_indices() -> void:
	super._update_world_entity_z_indices()
	_update_fixed_town_z_indices()


func get_town_spawn_position() -> Vector2:
	return Vector2(_town_center_x(), camp_bounds.position.y) + town_spawn_offset


func get_town_exit_socket_position() -> Vector2:
	return Vector2(_town_center_x(), camp_bounds.end.y) + town_exit_offset


func get_town_exit_opening_rect() -> Rect2:
	return Rect2(
		Vector2(_town_center_x() - town_exit_opening_width * 0.5, camp_bounds.end.y - 120.0),
		Vector2(town_exit_opening_width, 320.0)
	)


func get_town_bounds_rect() -> Rect2:
	return camp_bounds


func get_generated_start_anchor_position() -> Vector2:
	return get_camp_entrance_position()


func get_wilderness_start_socket_position() -> Vector2:
	return wilderness_start_socket.global_position if wilderness_start_socket != null else Vector2.ZERO


func get_town_connection_corridor_rect() -> Rect2:
	var start := get_town_exit_socket_position()
	var end := get_wilderness_start_socket_position()
	var center_width := 360.0
	var left := minf(start.x, end.x) - center_width * 0.5
	var right := maxf(start.x, end.x) + center_width * 0.5
	var top := minf(start.y, end.y) - 96.0
	var bottom := maxf(start.y, end.y) + 96.0
	return Rect2(Vector2(left, top), Vector2(right - left, bottom - top))


func get_main_world_contract() -> Dictionary:
	return {
		"fixed_town": fixed_town != null,
		"generated_region": generated_region != null,
		"generation_seed": generation_seed,
		"town_exit_socket": get_town_exit_socket_position(),
		"wilderness_start_socket": get_wilderness_start_socket_position(),
		"fixed_town_z_index": fixed_town.z_index if fixed_town != null else 0,
		"player_z_index": player.z_index if is_instance_valid(player) else 0,
		"player_parent": str(player.get_parent().name) if is_instance_valid(player) and player.get_parent() != null else "",
		"uses_scene_switch_for_wilderness": false,
	}


func get_enemy_type_counts() -> Dictionary:
	var counts: Dictionary = {}
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var display_name := str(enemy.get("enemy_display_name"))
		if display_name.is_empty() or display_name == "<null>":
			display_name = str(enemy.name)
		counts[display_name] = int(counts.get(display_name, 0)) + 1
	return counts


func _town_center_x() -> float:
	return camp_bounds.position.x + camp_bounds.size.x * 0.5


func _make_runtime_seed() -> int:
	var now := Time.get_datetime_dict_from_system()
	var seed_text := "%s-%s-%s-%s-%s-%s-%s" % [
		str(now.get("year", 0)),
		str(now.get("month", 0)),
		str(now.get("day", 0)),
		str(now.get("hour", 0)),
		str(now.get("minute", 0)),
		str(now.get("second", 0)),
		str(Time.get_ticks_usec()),
	]
	return maxi(1, int(abs(hash(seed_text))))


func _load_camp_layout() -> void:
	var file := FileAccess.open(CAMP_LAYOUT_PATH, FileAccess.READ)
	if file == null:
		push_error("MainWorld: missing camp layout %s" % CAMP_LAYOUT_PATH)
		camp_layout = {}
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("MainWorld: invalid camp layout JSON %s" % CAMP_LAYOUT_PATH)
		camp_layout = {}
		return
	camp_layout = parsed
	var terrain := _camp_terrain()
	camp_bounds = _rect_from_dict(terrain.get("bounds", {}), camp_bounds)
	town_spawn_offset = _vector2_from_array(terrain.get("spawn_offset", [town_spawn_offset.x, town_spawn_offset.y]), town_spawn_offset)
	town_exit_offset = _vector2_from_array(terrain.get("exit_offset", [town_exit_offset.x, town_exit_offset.y]), town_exit_offset)
	town_camera_padding = float(terrain.get("camera_padding", town_camera_padding))
	town_exit_opening_width = float(terrain.get("exit_opening_width", town_exit_opening_width))
	town_boundary_collision_thickness = float(terrain.get("boundary_collision_thickness", town_boundary_collision_thickness))
	camp_assets = camp_layout.get("asset_library", camp_layout.get("assets", {}))
	camp_animation_assets = camp_layout.get("animation_library", camp_layout.get("animations", {}))


func _camp_terrain() -> Dictionary:
	var terrain = camp_layout.get("terrain", {})
	return terrain if terrain is Dictionary else {}


func _camp_boundary() -> Dictionary:
	var terrain := _camp_terrain()
	var boundary = terrain.get("boundary", {})
	return boundary if boundary is Dictionary else {}


func _vector2_from_array(value, fallback := Vector2.ZERO) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	if value is Dictionary:
		return Vector2(float(value.get("x", fallback.x)), float(value.get("y", fallback.y)))
	return fallback


func _rect_from_dict(value, fallback: Rect2) -> Rect2:
	if not (value is Dictionary):
		return fallback
	return Rect2(
		Vector2(float(value.get("x", fallback.position.x)), float(value.get("y", fallback.position.y))),
		Vector2(float(value.get("w", fallback.size.x)), float(value.get("h", fallback.size.y)))
	)


func _color_from_array(value, fallback := Color.WHITE) -> Color:
	if value is Array and value.size() >= 4:
		return Color(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	return fallback


func _collision_from_config(value, fallback_shape := "rect", fallback_size := Vector2.ZERO, fallback_offset := Vector2.ZERO) -> Dictionary:
	var collision := {}
	if value is Dictionary:
		collision = value
	if collision.is_empty():
		return {
			"shape": fallback_shape,
			"size": fallback_size,
			"offset": fallback_offset,
		}
	return {
		"shape": str(collision.get("shape", fallback_shape)),
		"size": _vector2_from_array(collision.get("size", [fallback_size.x, fallback_size.y]), fallback_size),
		"offset": _vector2_from_array(collision.get("offset", [fallback_offset.x, fallback_offset.y]), fallback_offset),
	}


func _apply_absolute_z_index(item: CanvasItem, sort_y: float) -> void:
	item.z_as_relative = false
	item.z_index = clampi(int(round(sort_y + MAIN_WORLD_DYNAMIC_Z_OFFSET)), -4095, 4095)


func _update_fixed_town_z_indices() -> void:
	if fixed_town == null:
		return
	for root_path in ["Props", "NPCPlaceholders", "Interactables"]:
		var root := fixed_town.get_node_or_null(root_path)
		if root == null:
			continue
		for node in root.get_children():
			if node is Node2D and node is CanvasItem:
				_apply_absolute_z_index(node as CanvasItem, _collision_sort_y(node as Node2D))


func _add_town_rect(parent: Node, rect_name: String, rect: Rect2, color: Color, z: int) -> ColorRect:
	var node := ColorRect.new()
	node.name = rect_name
	node.position = rect.position
	node.size = rect.size
	node.color = color
	node.z_index = z
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


func _add_town_prop(parent: Node, prop_name: String, texture: Texture2D, position: Vector2, scale_value: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = prop_name
	sprite.texture = texture
	sprite.global_position = position
	sprite.scale = Vector2(scale_value, scale_value)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(sprite)
	return sprite


func _add_ground_decal(parent: Node, decal_name: String, texture: Texture2D, position: Vector2, scale_value: float) -> Sprite2D:
	var sprite := _add_town_prop(parent, decal_name, texture, position, scale_value)
	sprite.z_index = -116
	sprite.modulate = Color(1, 1, 1, 0.86)
	return sprite


func _add_camp_prop_body(
	parent: Node,
	body_name: String,
	texture: Texture2D,
	foot_position: Vector2,
	scale_value: float,
	shape_type: String,
	collision_size: Vector2,
	collision_offset: Vector2,
	sprite_offset: Vector2 = Vector2.ZERO,
	sprite_rotation: float = 0.0,
	sprite_flip_h: bool = false
) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = body_name
	body.global_position = foot_position
	body.collision_layer = COLLISION_LAYERS.WORLD
	body.collision_mask = 0
	body.set_meta("camp_prop", true)
	body.set_meta("collision_size", collision_size)
	body.set_meta("collision_offset", collision_offset)
	parent.add_child(body)

	var shape_node := CollisionShape2D.new()
	shape_node.name = "CollisionShape2D"
	shape_node.position = collision_offset
	match shape_type:
		"circle":
			var circle := CircleShape2D.new()
			circle.radius = maxf(collision_size.x, collision_size.y) * 0.5
			shape_node.shape = circle
		"capsule_h":
			var capsule_h := CapsuleShape2D.new()
			capsule_h.radius = maxf(8.0, collision_size.y * 0.5)
			capsule_h.height = maxf(collision_size.x, collision_size.y)
			shape_node.rotation = PI * 0.5
			shape_node.shape = capsule_h
		"capsule_v":
			var capsule_v := CapsuleShape2D.new()
			capsule_v.radius = maxf(8.0, collision_size.x * 0.5)
			capsule_v.height = maxf(collision_size.y, collision_size.x)
			shape_node.shape = capsule_v
		_:
			var rectangle := RectangleShape2D.new()
			rectangle.size = collision_size
			shape_node.shape = rectangle
	body.add_child(shape_node)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = texture
	sprite.scale = Vector2(scale_value, scale_value)
	sprite.rotation = sprite_rotation
	sprite.flip_h = sprite_flip_h
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if texture != null:
		sprite.position = sprite_offset + _sprite_visible_foot_offset(texture, scale_value, sprite_rotation)
	else:
		sprite.position = sprite_offset
	body.add_child(sprite)
	return body


func _add_camp_animated_prop_body(
	parent: Node,
	body_name: String,
	frames: Array,
	foot_position: Vector2,
	scale_value: float,
	fps: float,
	shape_type: String,
	collision_size: Vector2,
	collision_offset: Vector2,
	sprite_offset: Vector2 = Vector2.ZERO
) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = body_name
	body.global_position = foot_position
	body.collision_layer = COLLISION_LAYERS.WORLD
	body.collision_mask = 0
	body.set_meta("camp_prop", true)
	body.set_meta("collision_size", collision_size)
	body.set_meta("collision_offset", collision_offset)
	parent.add_child(body)

	var shape_node := CollisionShape2D.new()
	shape_node.name = "CollisionShape2D"
	shape_node.position = collision_offset
	match shape_type:
		"circle":
			var circle := CircleShape2D.new()
			circle.radius = maxf(collision_size.x, collision_size.y) * 0.5
			shape_node.shape = circle
		"capsule_v":
			var capsule_v := CapsuleShape2D.new()
			capsule_v.radius = maxf(8.0, collision_size.x * 0.5)
			capsule_v.height = maxf(collision_size.y, collision_size.x)
			shape_node.shape = capsule_v
		_:
			var rectangle := RectangleShape2D.new()
			rectangle.size = collision_size
			shape_node.shape = rectangle
	body.add_child(shape_node)

	var animated := AnimatedSprite2D.new()
	animated.name = "AnimatedSprite2D"
	animated.sprite_frames = SpriteFrames.new()
	animated.sprite_frames.add_animation("idle")
	animated.sprite_frames.set_animation_speed("idle", fps)
	animated.sprite_frames.set_animation_loop("idle", true)
	for frame in frames:
		var texture := frame as Texture2D
		if texture != null:
			animated.sprite_frames.add_frame("idle", texture)
	animated.scale = Vector2(scale_value, scale_value)
	animated.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not frames.is_empty() and frames[0] is Texture2D:
		animated.position = sprite_offset + _sprite_visible_foot_offset(frames[0] as Texture2D, scale_value, 0.0)
	else:
		animated.position = sprite_offset
	body.add_child(animated)
	animated.play("idle")
	return body


func _add_quest_giver_placeholder(parent: Node, position: Vector2) -> StaticBody2D:
	var body := _add_camp_animated_prop_body(parent, "QuestGiverPlaceholder", _camp_animation_frames("quest_giver_idle"), position, 0.95, 4.0, "capsule_v", Vector2(32, 46), Vector2(0, -12), Vector2(0, 4))
	_configure_quest_giver_interaction(body, "Clear the den outside the camp.", Vector2(-150, -138))
	return body


func _add_quest_giver_placeholder_from_config(parent: Node, npc_config: Dictionary) -> StaticBody2D:
	var collision := _collision_from_config(npc_config.get("collision", {}), "capsule_v", Vector2(32, 46), Vector2(0, -12))
	var body := _add_camp_animated_prop_body(
		parent,
		str(npc_config.get("id", "QuestGiverPlaceholder")),
		_camp_animation_frames(str(npc_config.get("animation", "quest_giver_idle"))),
		_vector2_from_array(npc_config.get("position", [0, 0])),
		float(npc_config.get("scale", 0.95)),
		float(npc_config.get("fps", 4.0)),
		str(collision.get("shape", "capsule_v")),
		collision.get("size", Vector2(32, 46)),
		collision.get("offset", Vector2(0, -12)),
		_vector2_from_array(npc_config.get("sprite_offset", [0, 4]))
	)
	_configure_quest_giver_interaction(
		body,
		str(npc_config.get("hint", "Clear the den outside the camp.")),
		_vector2_from_array(npc_config.get("hint_position", [-150, -138]), Vector2(-150, -138))
	)
	return body


func _configure_quest_giver_interaction(body: StaticBody2D, hint_text: String, hint_position: Vector2) -> void:
	var area := Area2D.new()
	area.name = "InteractionArea"
	area.collision_layer = 0
	area.collision_mask = COLLISION_LAYERS.PLAYER
	body.add_child(area)

	var area_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 110.0
	area_shape.shape = circle
	area.add_child(area_shape)
	area.body_entered.connect(_on_quest_giver_body_entered)
	area.body_exited.connect(_on_quest_giver_body_exited)

	camp_interaction_label = Label.new()
	camp_interaction_label.name = "QuestHintLabel"
	camp_interaction_label.text = hint_text
	camp_interaction_label.position = hint_position
	camp_interaction_label.visible = false
	camp_interaction_label.add_theme_font_size_override("font_size", 18)
	camp_interaction_label.add_theme_color_override("font_color", Color(0.92, 0.84, 0.58, 1.0))
	camp_interaction_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	camp_interaction_label.add_theme_constant_override("shadow_offset_x", 2)
	camp_interaction_label.add_theme_constant_override("shadow_offset_y", 2)
	body.add_child(camp_interaction_label)


func _on_quest_giver_body_entered(body: Node2D) -> void:
	if camp_interaction_label == null:
		return
	if body == player or body.is_in_group("player"):
		camp_interaction_label.visible = true


func _on_quest_giver_body_exited(body: Node2D) -> void:
	if camp_interaction_label == null:
		return
	if body == player or body.is_in_group("player"):
		camp_interaction_label.visible = false


func _camp_asset(asset_key: String) -> Texture2D:
	var path := str(camp_assets.get(asset_key, ""))
	return load(path) as Texture2D if not path.is_empty() else null


func _camp_animation_frames(asset_key: String) -> Array:
	var frames := []
	for path in camp_animation_assets.get(asset_key, []):
		var texture := load(str(path)) as Texture2D
		if texture != null:
			frames.append(texture)
	return frames


func _sprite_visible_foot_offset(texture: Texture2D, scale_value: float, sprite_rotation: float) -> Vector2:
	var visible := _texture_visible_bounds(texture)
	var texture_size := texture.get_size()
	var foot := Vector2(visible.position.x + visible.size.x * 0.5, visible.end.y)
	var offset := (texture_size * 0.5 - foot) * scale_value
	if absf(sprite_rotation) <= 0.01:
		return offset
	return offset.rotated(sprite_rotation)


func _texture_visible_bounds(texture: Texture2D) -> Rect2:
	var image := texture.get_image()
	if image == null:
		return Rect2(Vector2.ZERO, texture.get_size())
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > CAMP_ALPHA_VISIBLE_THRESHOLD:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2(Vector2.ZERO, texture.get_size())
	return Rect2(float(min_x), float(min_y), float(max_x - min_x + 1), float(max_y - min_y + 1))


func _add_placeholder_body(parent: Node, body_name: String, position: Vector2, color: Color, size: Vector2 = Vector2(64, 96)) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = body_name
	body.global_position = position
	body.collision_layer = COLLISION_LAYERS.WORLD
	body.collision_mask = 0
	parent.add_child(body)

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(maxf(32.0, size.x * 0.72), 34.0)
	shape.position = Vector2(0, size.y * 0.22)
	shape.shape = rectangle
	body.add_child(shape)

	var visual := ColorRect.new()
	visual.name = "Visual"
	visual.position = Vector2(-size.x * 0.5, -size.y * 0.75)
	visual.size = size
	visual.color = color
	body.add_child(visual)
	return body


func _add_town_bound_shape(shape_name: String, rect: Rect2) -> void:
	var shape := CollisionShape2D.new()
	shape.name = shape_name
	shape.global_position = rect.get_center()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	town_blockers_root.add_child(shape)


func _add_town_thin_bounds() -> void:
	var boundary := _camp_boundary()
	var left_x := camp_bounds.position.x + float(boundary.get("left_x_offset", 95.0))
	var right_x := camp_bounds.end.x + float(boundary.get("right_x_offset", -95.0))
	var top_y := camp_bounds.position.y + float(boundary.get("top_y_offset", 85.0))
	var bottom_y := camp_bounds.end.y + float(boundary.get("bottom_y_offset", -85.0))
	var t := town_boundary_collision_thickness
	_add_town_bound_shape("NorthThin", Rect2(Vector2(left_x, top_y - t * 0.5), Vector2(right_x - left_x, t)))
	_add_town_bound_shape("WestThin", Rect2(Vector2(left_x - t * 0.5, top_y), Vector2(t, bottom_y - top_y)))
	_add_town_bound_shape("EastThin", Rect2(Vector2(right_x - t * 0.5, top_y), Vector2(t, bottom_y - top_y)))


func _add_town_exit_opening_bounds() -> void:
	var opening := get_town_exit_opening_rect()
	var boundary := _camp_boundary()
	var left_x := camp_bounds.position.x + float(boundary.get("left_x_offset", 95.0))
	var right_x := camp_bounds.end.x + float(boundary.get("right_x_offset", -95.0))
	var south_y := camp_bounds.end.y + float(boundary.get("bottom_y_offset", -85.0))
	var thickness := town_boundary_collision_thickness
	var left_width := maxf(0.0, opening.position.x - left_x)
	var east_segment_x := opening.end.x
	var right_width := maxf(0.0, right_x - east_segment_x)
	if left_width > 0.0:
		_add_town_bound_shape("SouthWestThin", Rect2(Vector2(left_x, south_y - thickness * 0.5), Vector2(left_width, thickness)))
	if right_width > 0.0:
		_add_town_bound_shape("SouthEastThin", Rect2(Vector2(east_segment_x, south_y - thickness * 0.5), Vector2(right_width, thickness)))
