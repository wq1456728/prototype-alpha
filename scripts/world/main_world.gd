extends "res://scripts/maps/first_outdoor_generated.gd"

const COLLISION_LAYERS := preload("res://scripts/physics/collision_layers.gd")

const MAIN_WORLD_TOWN_BOUNDS := Rect2(Vector2(960, -940), Vector2(1660, 920))
const TOWN_EXIT_OFFSET := Vector2(0, -70)
const TOWN_SPAWN_OFFSET := Vector2(-430, 520)
const TOWN_CAMERA_PADDING := 180.0
const TOWN_EXIT_OPENING_WIDTH := 720.0
const MAIN_WORLD_DYNAMIC_Z_OFFSET := 1200.0
const FIXED_TOWN_STATIC_Z := -2600

@export var randomize_generation_seed_on_ready := true

var fixed_town: Node2D
var generated_region: Node2D
var transition_chunk: Node2D
var town_spawn_marker: Marker2D
var town_exit_socket: Marker2D
var wilderness_start_socket: Marker2D
var town_blockers_root: StaticBody2D


func _ready() -> void:
	if randomize_generation_seed_on_ready:
		generation_seed = _make_runtime_seed()
	super._ready()


func _build_generated_world() -> void:
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
	_add_town_rect(ground, "TownGround", MAIN_WORLD_TOWN_BOUNDS, Color(0.13, 0.115, 0.078, 1.0), -122)
	_add_town_rect(ground, "TownTrampledCenter", Rect2(MAIN_WORLD_TOWN_BOUNDS.position + Vector2(360, 260), Vector2(820, 390)), Color(0.17, 0.142, 0.09, 1.0), -118)
	_add_town_rect(ground, "TownExitRoad", Rect2(Vector2(_town_center_x() - 130, MAIN_WORLD_TOWN_BOUNDS.end.y - 260), Vector2(260, 420)), Color(0.19, 0.158, 0.102, 1.0), -117)

	var props := Node2D.new()
	props.name = "Props"
	props.y_sort_enabled = true
	fixed_town.add_child(props)
	_add_town_prop(props, "TownCampGate", _asset("camp_gate"), get_town_exit_socket_position() + Vector2(0, -72), 1.55)
	_add_town_prop(props, "TownSignpost", _asset("route_sign_or_scout_marker"), get_town_exit_socket_position() + Vector2(170, -36), 1.25)
	_add_town_prop(props, "TownSupplyCart", _asset("broken_cart"), MAIN_WORLD_TOWN_BOUNDS.position + Vector2(1180, 450), 1.25)
	_add_town_prop(props, "TownFenceWest", _asset("broken_fence_a"), MAIN_WORLD_TOWN_BOUNDS.position + Vector2(320, 150), 1.35)
	_add_town_prop(props, "TownFenceEast", _asset("broken_fence_b"), MAIN_WORLD_TOWN_BOUNDS.position + Vector2(520, 150), 1.35)
	_add_town_prop(props, "TownRock", _asset("rock_a"), MAIN_WORLD_TOWN_BOUNDS.position + Vector2(1420, 640), 1.7)
	_add_town_prop(props, "TownDeadTree", _asset("dead_tree_a"), MAIN_WORLD_TOWN_BOUNDS.position + Vector2(170, 520), 1.45)

	var npc_root := Node2D.new()
	npc_root.name = "NPCPlaceholders"
	npc_root.y_sort_enabled = true
	fixed_town.add_child(npc_root)
	_add_placeholder_body(npc_root, "QuestGiverPlaceholder", MAIN_WORLD_TOWN_BOUNDS.position + Vector2(470, 470), Color(0.34, 0.29, 0.18, 1.0))
	_add_placeholder_body(npc_root, "GuardPlaceholder", MAIN_WORLD_TOWN_BOUNDS.position + Vector2(720, 650), Color(0.26, 0.28, 0.22, 1.0))

	var interactables := Node2D.new()
	interactables.name = "Interactables"
	interactables.y_sort_enabled = true
	fixed_town.add_child(interactables)
	_add_placeholder_body(interactables, "StashPlaceholder", MAIN_WORLD_TOWN_BOUNDS.position + Vector2(1250, 520), Color(0.22, 0.14, 0.075, 1.0), Vector2(96, 62))
	_add_town_prop(interactables, "WaypointPlaceholder", _asset("shrine_or_loot_marker"), MAIN_WORLD_TOWN_BOUNDS.position + Vector2(1040, 350), 1.15)

	town_blockers_root = StaticBody2D.new()
	town_blockers_root.name = "TownBounds"
	town_blockers_root.collision_layer = COLLISION_LAYERS.WORLD
	town_blockers_root.collision_mask = 0
	fixed_town.add_child(town_blockers_root)
	_add_town_bound_shape("North", Rect2(MAIN_WORLD_TOWN_BOUNDS.position - Vector2(0, 80), Vector2(MAIN_WORLD_TOWN_BOUNDS.size.x, 80)))
	_add_town_bound_shape("West", Rect2(MAIN_WORLD_TOWN_BOUNDS.position - Vector2(80, 80), Vector2(80, MAIN_WORLD_TOWN_BOUNDS.size.y + 160)))
	_add_town_bound_shape("East", Rect2(Vector2(MAIN_WORLD_TOWN_BOUNDS.end.x, MAIN_WORLD_TOWN_BOUNDS.position.y - 80), Vector2(80, MAIN_WORLD_TOWN_BOUNDS.size.y + 160)))
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
	gameplay_bounds.set_meta("rect", MAIN_WORLD_TOWN_BOUNDS)
	fixed_town.add_child(gameplay_bounds)


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
	var top := minf(start.y, end.y)
	var bottom := maxf(start.y, end.y)
	_add_town_rect(transition_chunk, "FixedTransitionRoad", Rect2(Vector2(start.x - 150, top), Vector2(300, bottom - top + 110)), Color(0.18, 0.15, 0.095, 1.0), -116)
	_add_town_rect(transition_chunk, "FixedTransitionField", Rect2(Vector2(start.x - 420, top - 40), Vector2(840, bottom - top + 180)), Color(0.09, 0.108, 0.074, 0.72), -121)

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
		camera.limit_left = int(minf(0.0, MAIN_WORLD_TOWN_BOUNDS.position.x - TOWN_CAMERA_PADDING))
		camera.limit_top = int(MAIN_WORLD_TOWN_BOUNDS.position.y - TOWN_CAMERA_PADDING)
		camera.limit_right = int(maxf(layout.map_size.x, MAIN_WORLD_TOWN_BOUNDS.end.x + TOWN_CAMERA_PADDING))
		camera.limit_bottom = int(layout.map_size.y)


func get_town_spawn_position() -> Vector2:
	return Vector2(_town_center_x(), MAIN_WORLD_TOWN_BOUNDS.position.y) + TOWN_SPAWN_OFFSET


func get_town_exit_socket_position() -> Vector2:
	return Vector2(_town_center_x(), MAIN_WORLD_TOWN_BOUNDS.end.y) + TOWN_EXIT_OFFSET


func get_town_exit_opening_rect() -> Rect2:
	return Rect2(
		Vector2(_town_center_x() - TOWN_EXIT_OPENING_WIDTH * 0.5, MAIN_WORLD_TOWN_BOUNDS.end.y - 120.0),
		Vector2(TOWN_EXIT_OPENING_WIDTH, 320.0)
	)


func get_town_bounds_rect() -> Rect2:
	return MAIN_WORLD_TOWN_BOUNDS


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
	return MAIN_WORLD_TOWN_BOUNDS.position.x + MAIN_WORLD_TOWN_BOUNDS.size.x * 0.5


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


func _apply_absolute_z_index(item: CanvasItem, sort_y: float) -> void:
	item.z_as_relative = false
	item.z_index = clampi(int(round(sort_y + MAIN_WORLD_DYNAMIC_Z_OFFSET)), -4095, 4095)


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


func _add_town_exit_opening_bounds() -> void:
	var opening := get_town_exit_opening_rect()
	var south_y := MAIN_WORLD_TOWN_BOUNDS.end.y
	var thickness := 80.0
	var left_width := maxf(0.0, opening.position.x - MAIN_WORLD_TOWN_BOUNDS.position.x)
	var right_x := opening.end.x
	var right_width := maxf(0.0, MAIN_WORLD_TOWN_BOUNDS.end.x - right_x)
	if left_width > 0.0:
		_add_town_bound_shape("SouthWest", Rect2(Vector2(MAIN_WORLD_TOWN_BOUNDS.position.x, south_y), Vector2(left_width, thickness)))
	if right_width > 0.0:
		_add_town_bound_shape("SouthEast", Rect2(Vector2(right_x, south_y), Vector2(right_width, thickness)))
