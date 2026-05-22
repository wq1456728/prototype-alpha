extends "res://scripts/maps/first_outdoor_generated.gd"

const COLLISION_LAYERS := preload("res://scripts/physics/collision_layers.gd")

const MAIN_WORLD_TOWN_BOUNDS := Rect2(Vector2(960, -940), Vector2(1660, 920))
const TOWN_EXIT_OFFSET := Vector2(0, -70)
const TOWN_SPAWN_OFFSET := Vector2(-430, 520)
const TOWN_CAMERA_PADDING := 180.0
const TOWN_EXIT_OPENING_WIDTH := 720.0
const TOWN_BOUNDARY_COLLISION_THICKNESS := 8.0
const MAIN_WORLD_DYNAMIC_Z_OFFSET := 1200.0
const FIXED_TOWN_STATIC_Z := -2600
const CAMP_ALPHA_VISIBLE_THRESHOLD := 0.05
const CAMP_ASSETS := {
	"wood_fence_straight": "res://assets/sprites/props/camp_01/prop_camp01_wood_fence_straight_96_a.png",
	"wood_fence_side": "res://assets/sprites/props/camp_01/prop_camp01_wood_fence_side_pixellab_64.png",
	"wood_fence_broken": "res://assets/sprites/props/camp_01/prop_camp01_wood_fence_broken_96_a.png",
	"wood_fence_gate_side": "res://assets/sprites/props/camp_01/prop_camp01_wood_fence_gate_side_96_a.png",
	"palisade_wall": "res://assets/sprites/props/camp_01/prop_camp01_palisade_wall_96_a.png",
	"tent": "res://assets/sprites/props/camp_01/prop_camp01_tent_128_a.png",
	"campfire": "res://assets/sprites/props/camp_01/prop_camp01_campfire_64_a.png",
	"stash_chest": "res://assets/sprites/props/camp_01/prop_camp01_stash_chest_64_a.png",
	"crate_barrel_stack": "res://assets/sprites/props/camp_01/prop_camp01_crate_barrel_stack_96_a.png",
	"waypoint_marker": "res://assets/sprites/props/camp_01/prop_camp01_waypoint_marker_96_a.png",
	"quest_giver": "res://assets/sprites/npc/camp_01/npc_camp01_quest_giver_idle_64_a.png",
	"trampled_ground": "res://assets/sprites/decals/outdoor_01/decal_camp01_trampled_ground_64_a.png",
}
const CAMP_ANIMATION_ASSETS := {
	"campfire_idle": [
		"res://assets/sprites/props/camp_01/campfire_idle_pixellab/frame_0.png",
		"res://assets/sprites/props/camp_01/campfire_idle_pixellab/frame_1.png",
		"res://assets/sprites/props/camp_01/campfire_idle_pixellab/frame_2.png",
		"res://assets/sprites/props/camp_01/campfire_idle_pixellab/frame_3.png",
		"res://assets/sprites/props/camp_01/campfire_idle_pixellab/frame_4.png",
	],
	"quest_giver_idle": [
		"res://assets/sprites/npc/camp_01/quest_giver_idle_pixellab/frame_0.png",
		"res://assets/sprites/npc/camp_01/quest_giver_idle_pixellab/frame_1.png",
		"res://assets/sprites/npc/camp_01/quest_giver_idle_pixellab/frame_2.png",
		"res://assets/sprites/npc/camp_01/quest_giver_idle_pixellab/frame_3.png",
	],
}

@export var randomize_generation_seed_on_ready := true

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
	_add_ground_decal(ground, "CampTrampledGroundCenter", _camp_asset("trampled_ground"), MAIN_WORLD_TOWN_BOUNDS.position + Vector2(785, 470), 3.6)
	_add_ground_decal(ground, "CampTrampledGroundStash", _camp_asset("trampled_ground"), MAIN_WORLD_TOWN_BOUNDS.position + Vector2(1195, 490), 2.4)

	var props := Node2D.new()
	props.name = "Props"
	props.y_sort_enabled = true
	fixed_town.add_child(props)
	_build_camp_fence(props)
	_add_camp_prop_body(props, "CampTentNorthWest", _camp_asset("tent"), MAIN_WORLD_TOWN_BOUNDS.position + Vector2(410, 315), 1.15, "rect", Vector2(41, 27), Vector2(0, -13))
	_add_camp_prop_body(props, "CampTentSouthWest", _camp_asset("tent"), MAIN_WORLD_TOWN_BOUNDS.position + Vector2(345, 610), 1.0, "rect", Vector2(36, 23), Vector2(0, -12))
	_add_camp_prop_body(props, "CampSupplyStack", _camp_asset("crate_barrel_stack"), MAIN_WORLD_TOWN_BOUNDS.position + Vector2(1170, 575), 1.15, "rect", Vector2(59, 28), Vector2(0, -14))
	_add_camp_prop_body(props, "CampPalisadeStorage", _camp_asset("palisade_wall"), MAIN_WORLD_TOWN_BOUNDS.position + Vector2(1290, 265), 1.0, "capsule_h", Vector2(78, 18), Vector2(0, -9))
	_add_camp_prop_body(props, "CampBrokenFenceDetail", _camp_asset("wood_fence_broken"), MAIN_WORLD_TOWN_BOUNDS.position + Vector2(575, 720), 1.1, "capsule_h", Vector2(76, 18), Vector2(0, -9))

	var npc_root := Node2D.new()
	npc_root.name = "NPCPlaceholders"
	npc_root.y_sort_enabled = true
	fixed_town.add_child(npc_root)
	_add_quest_giver_placeholder(npc_root, MAIN_WORLD_TOWN_BOUNDS.position + Vector2(605, 500))

	var interactables := Node2D.new()
	interactables.name = "Interactables"
	interactables.y_sort_enabled = true
	fixed_town.add_child(interactables)
	_add_camp_prop_body(interactables, "StashPlaceholder", _camp_asset("stash_chest"), MAIN_WORLD_TOWN_BOUNDS.position + Vector2(1180, 410), 1.25, "rect", Vector2(49, 23), Vector2(0, -11))
	_add_camp_prop_body(interactables, "WaypointPlaceholder", _camp_asset("waypoint_marker"), MAIN_WORLD_TOWN_BOUNDS.position + Vector2(940, 375), 1.15, "rect", Vector2(40, 21), Vector2(0, -10))
	_add_camp_animated_prop_body(interactables, "CampfireIdle", _camp_animation_frames("campfire_idle"), MAIN_WORLD_TOWN_BOUNDS.position + Vector2(800, 505), 1.18, 6.0, "rect", Vector2(33, 21), Vector2(0, -11))

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
	gameplay_bounds.set_meta("rect", MAIN_WORLD_TOWN_BOUNDS)
	fixed_town.add_child(gameplay_bounds)
	_update_fixed_town_z_indices()


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
		camera.limit_left = int(minf(0.0, MAIN_WORLD_TOWN_BOUNDS.position.x - TOWN_CAMERA_PADDING))
		camera.limit_top = int(MAIN_WORLD_TOWN_BOUNDS.position.y - TOWN_CAMERA_PADDING)
		camera.limit_right = int(maxf(layout.map_size.x, MAIN_WORLD_TOWN_BOUNDS.end.x + TOWN_CAMERA_PADDING))
		camera.limit_bottom = int(layout.map_size.y)


func _update_world_entity_z_indices() -> void:
	super._update_world_entity_z_indices()
	_update_fixed_town_z_indices()


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


func _build_camp_fence(parent: Node) -> void:
	var left_x := MAIN_WORLD_TOWN_BOUNDS.position.x + 95.0
	var right_x := MAIN_WORLD_TOWN_BOUNDS.end.x - 95.0
	var top_y := MAIN_WORLD_TOWN_BOUNDS.position.y + 85.0
	var bottom_y := MAIN_WORLD_TOWN_BOUNDS.end.y - 85.0
	var gate_left_x := _town_center_x() - 145.0
	var gate_right_x := _town_center_x() + 145.0
	var horizontal_spacing := 86.0
	var vertical_spacing := 76.0
	var horizontal_fence_collision := Vector2(77, 18)
	var horizontal_fence_offset := Vector2(0, -9)

	var segment_index := 0
	var x := left_x + horizontal_spacing * 0.5
	while x < right_x - horizontal_spacing * 0.5:
		_add_camp_prop_body(parent, "NorthFence%02d" % segment_index, _camp_asset("wood_fence_straight"), Vector2(x, top_y), 1.12, "capsule_h", horizontal_fence_collision, horizontal_fence_offset)
		segment_index += 1
		x += horizontal_spacing

	segment_index = 0
	x = left_x + horizontal_spacing * 0.5
	while x < gate_left_x - 116.0:
		_add_camp_prop_body(parent, "SouthWestFence%02d" % segment_index, _camp_asset("wood_fence_straight"), Vector2(x, bottom_y), 1.12, "capsule_h", horizontal_fence_collision, horizontal_fence_offset)
		segment_index += 1
		x += horizontal_spacing
	_add_camp_prop_body(parent, "SouthWestFenceGateJoin", _camp_asset("wood_fence_straight"), Vector2(gate_left_x - 74.0, bottom_y), 1.12, "capsule_h", horizontal_fence_collision, horizontal_fence_offset)

	segment_index = 0
	_add_camp_prop_body(parent, "SouthEastFenceGateJoin", _camp_asset("wood_fence_straight"), Vector2(gate_right_x + 74.0, bottom_y), 1.12, "capsule_h", horizontal_fence_collision, horizontal_fence_offset)
	x = gate_right_x + 160.0
	while x < right_x - horizontal_spacing * 0.5:
		_add_camp_prop_body(parent, "SouthEastFence%02d" % segment_index, _camp_asset("wood_fence_straight"), Vector2(x, bottom_y), 1.12, "capsule_h", horizontal_fence_collision, horizontal_fence_offset)
		segment_index += 1
		x += horizontal_spacing
	_add_camp_prop_body(parent, "SouthEastFenceCornerJoin", _camp_asset("wood_fence_straight"), Vector2(right_x - 48.0, bottom_y), 1.12, "capsule_h", horizontal_fence_collision, horizontal_fence_offset)

	segment_index = 0
	var y := top_y + vertical_spacing * 0.5
	while y < bottom_y:
		_add_camp_prop_body(parent, "WestSideFence%02d" % segment_index, _camp_asset("wood_fence_side"), Vector2(left_x, y), 1.08, "capsule_v", Vector2(19, 78), Vector2(0, -39))
		_add_camp_prop_body(parent, "EastSideFence%02d" % segment_index, _camp_asset("wood_fence_side"), Vector2(right_x, y), 1.08, "capsule_v", Vector2(19, 78), Vector2(0, -39))
		segment_index += 1
		y += vertical_spacing

	_add_camp_prop_body(parent, "CampGateLeftPost", _camp_asset("wood_fence_gate_side"), Vector2(gate_left_x, bottom_y + 8.0), 1.08, "rect", Vector2(42, 32), Vector2(0, -16))
	_add_camp_prop_body(parent, "CampGateRightPost", _camp_asset("wood_fence_gate_side"), Vector2(gate_right_x, bottom_y + 8.0), 1.08, "rect", Vector2(42, 32), Vector2(0, -16), Vector2.ZERO, 0.0, true)


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
	camp_interaction_label.text = "Clear the den outside the camp."
	camp_interaction_label.position = Vector2(-150, -138)
	camp_interaction_label.visible = false
	camp_interaction_label.add_theme_font_size_override("font_size", 18)
	camp_interaction_label.add_theme_color_override("font_color", Color(0.92, 0.84, 0.58, 1.0))
	camp_interaction_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	camp_interaction_label.add_theme_constant_override("shadow_offset_x", 2)
	camp_interaction_label.add_theme_constant_override("shadow_offset_y", 2)
	body.add_child(camp_interaction_label)
	return body


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
	var path := str(CAMP_ASSETS.get(asset_key, ""))
	return load(path) as Texture2D if not path.is_empty() else null


func _camp_animation_frames(asset_key: String) -> Array:
	var frames := []
	for path in CAMP_ANIMATION_ASSETS.get(asset_key, []):
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
	var left_x := MAIN_WORLD_TOWN_BOUNDS.position.x + 95.0
	var right_x := MAIN_WORLD_TOWN_BOUNDS.end.x - 95.0
	var top_y := MAIN_WORLD_TOWN_BOUNDS.position.y + 85.0
	var bottom_y := MAIN_WORLD_TOWN_BOUNDS.end.y - 85.0
	var t := TOWN_BOUNDARY_COLLISION_THICKNESS
	_add_town_bound_shape("NorthThin", Rect2(Vector2(left_x, top_y - t * 0.5), Vector2(right_x - left_x, t)))
	_add_town_bound_shape("WestThin", Rect2(Vector2(left_x - t * 0.5, top_y), Vector2(t, bottom_y - top_y)))
	_add_town_bound_shape("EastThin", Rect2(Vector2(right_x - t * 0.5, top_y), Vector2(t, bottom_y - top_y)))


func _add_town_exit_opening_bounds() -> void:
	var opening := get_town_exit_opening_rect()
	var left_x := MAIN_WORLD_TOWN_BOUNDS.position.x + 95.0
	var right_x := MAIN_WORLD_TOWN_BOUNDS.end.x - 95.0
	var south_y := MAIN_WORLD_TOWN_BOUNDS.end.y - 85.0
	var thickness := TOWN_BOUNDARY_COLLISION_THICKNESS
	var left_width := maxf(0.0, opening.position.x - left_x)
	var east_segment_x := opening.end.x
	var right_width := maxf(0.0, right_x - east_segment_x)
	if left_width > 0.0:
		_add_town_bound_shape("SouthWestThin", Rect2(Vector2(left_x, south_y - thickness * 0.5), Vector2(left_width, thickness)))
	if right_width > 0.0:
		_add_town_bound_shape("SouthEastThin", Rect2(Vector2(east_segment_x, south_y - thickness * 0.5), Vector2(right_width, thickness)))
