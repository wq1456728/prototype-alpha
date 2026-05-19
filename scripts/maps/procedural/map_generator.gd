extends RefCounted
class_name MapGenerator

const ConfigScript := preload("res://scripts/maps/procedural/map_generation_config.gd")
const LayoutScript := preload("res://scripts/maps/procedural/generated_map_layout.gd")


static func generate(config: MapGenerationConfig, seed: int) -> GeneratedMapLayout:
	var active_config: MapGenerationConfig = config
	if active_config == null:
		active_config = ConfigScript.new()

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var layout: GeneratedMapLayout = LayoutScript.new()
	layout.setup(seed, active_config.map_id, active_config.map_name, active_config.map_size, active_config.map_offset)

	var main_count := rng.randi_range(active_config.main_path_min_zones, active_config.main_path_max_zones)
	var main_zone_ids := _generate_main_path(layout, active_config, rng, main_count)
	_generate_required_branch(layout, active_config, rng, main_zone_ids)
	_generate_optional_pocket(layout, active_config, rng, main_zone_ids)
	_generate_boundary(layout, active_config)
	return layout


static func _generate_main_path(layout: GeneratedMapLayout, config: MapGenerationConfig, rng: RandomNumberGenerator, main_count: int) -> Array:
	var zone_ids := []
	var usable_height := config.map_size.y - config.map_margin * 2.0
	var y_step := usable_height / float(max(main_count - 1, 1))
	var previous_center := Vector2(config.map_size.x * 0.5 + rng.randf_range(-120.0, 120.0), config.map_margin)

	for index in range(main_count):
		var zone_type := _main_zone_type(index, main_count)
		var zone_size: Vector2 = config.get_zone_size(zone_type, rng)
		var target_y := config.map_margin + y_step * float(index)
		var center_x := previous_center.x + rng.randf_range(-config.route_x_jitter, config.route_x_jitter)
		if index == 0:
			center_x = config.map_size.x * 0.5 + rng.randf_range(-180.0, 180.0)
		center_x = clamp(center_x, config.map_margin + zone_size.x * 0.5, config.map_size.x - config.map_margin - zone_size.x * 0.5)
		var center := Vector2(center_x, target_y)
		var rect := Rect2(center - zone_size * 0.5, zone_size)
		var zone_id := "main_%02d_%s" % [index, zone_type]
		layout.add_zone(zone_id, zone_type, config.get_template_id(zone_type, rng), rect, config.get_zone_label(zone_type))
		_add_zone_anchors(layout, zone_id, zone_type, rect, index, main_count)
		_add_zone_placeholders(layout, config, rng, zone_id, zone_type, rect, index)

		if index > 0:
			var previous_zone_id := str(zone_ids[index - 1])
			_add_route_connection(layout, config, rng, previous_zone_id, zone_id, "main")
		zone_ids.append(zone_id)
		previous_center = center
	return zone_ids


static func _generate_required_branch(layout: GeneratedMapLayout, config: MapGenerationConfig, rng: RandomNumberGenerator, main_zone_ids: Array) -> void:
	var fork_zone_id := _find_main_zone_id_by_type(layout, main_zone_ids, "fork")
	if fork_zone_id.is_empty():
		fork_zone_id = str(main_zone_ids[max(main_zone_ids.size() - 2, 0)])
	var fork_zone := layout.find_zone(fork_zone_id)
	var fork_rect: Rect2 = fork_zone.get("rect", Rect2())
	var branch_type := "required_branch"
	var branch_size: Vector2 = config.get_zone_size(branch_type, rng)
	var branch_direction := -1.0 if rng.randi_range(0, 1) == 0 else 1.0
	var branch_distance := rng.randf_range(config.branch_distance_range.x, config.branch_distance_range.y)
	var branch_center := fork_rect.get_center() + Vector2(branch_direction * branch_distance, rng.randf_range(config.branch_y_offset_range.x, config.branch_y_offset_range.y))
	branch_center.x = clamp(branch_center.x, config.map_margin + branch_size.x * 0.5, config.map_size.x - config.map_margin - branch_size.x * 0.5)
	branch_center.y = clamp(branch_center.y, config.map_margin + branch_size.y * 0.5, config.map_size.y - config.map_margin - branch_size.y * 0.5)

	var branch_rect := Rect2(branch_center - branch_size * 0.5, branch_size)
	var branch_id := "branch_required_%s" % ("west" if branch_direction < 0.0 else "east")
	layout.add_zone(branch_id, branch_type, config.get_template_id(branch_type, rng), branch_rect, config.get_zone_label(branch_type))
	layout.add_anchor("anchor_required_branch", "required_branch", branch_rect.get_center(), true, branch_id)
	layout.add_anchor("anchor_required_branch_entry", "entry", branch_rect.get_center() + Vector2(-branch_direction * branch_size.x * 0.32, 0.0), false, branch_id)
	layout.add_map_object("object_required_branch_entrance", "dungeon_entrance_placeholder", branch_id, _random_point_in_rect(branch_rect, config.zone_padding, rng))
	layout.add_spawn_group("spawn_required_branch_guard", branch_id, "branch_guard_placeholder", rng.randi_range(1, 2), rng.randi_range(6, 10))
	_add_route_connection(layout, config, rng, fork_zone_id, branch_id, "required_branch")


static func _generate_optional_pocket(layout: GeneratedMapLayout, config: MapGenerationConfig, rng: RandomNumberGenerator, main_zone_ids: Array) -> void:
	if rng.randf() > config.optional_pocket_chance or main_zone_ids.size() < 4:
		return
	var attach_index := rng.randi_range(1, max(main_zone_ids.size() - 3, 1))
	var attach_zone_id := str(main_zone_ids[attach_index])
	var attach_zone := layout.find_zone(attach_zone_id)
	var attach_rect: Rect2 = attach_zone.get("rect", Rect2())
	var pocket_type := "optional_pocket"
	var pocket_size: Vector2 = config.get_zone_size(pocket_type, rng)
	var direction := -1.0 if rng.randi_range(0, 1) == 0 else 1.0
	var pocket_center := attach_rect.get_center() + Vector2(direction * rng.randf_range(680.0, 940.0), rng.randf_range(-120.0, 180.0))
	pocket_center.x = clamp(pocket_center.x, config.map_margin + pocket_size.x * 0.5, config.map_size.x - config.map_margin - pocket_size.x * 0.5)
	pocket_center.y = clamp(pocket_center.y, config.map_margin + pocket_size.y * 0.5, config.map_size.y - config.map_margin - pocket_size.y * 0.5)
	var pocket_rect := Rect2(pocket_center - pocket_size * 0.5, pocket_size)
	var pocket_id := "pocket_optional_%02d" % attach_index
	layout.add_zone(pocket_id, pocket_type, config.get_template_id(pocket_type, rng), pocket_rect, config.get_zone_label(pocket_type))
	layout.add_anchor("anchor_optional_pocket", "optional_pocket", pocket_rect.get_center(), false, pocket_id)
	layout.add_map_object("object_optional_reward", "reward_marker_placeholder", pocket_id, _random_point_in_rect(pocket_rect, config.zone_padding, rng))
	layout.add_spawn_group("spawn_optional_pocket", pocket_id, "optional_pack_placeholder", rng.randi_range(1, 3), rng.randi_range(4, 8))
	_add_route_connection(layout, config, rng, attach_zone_id, pocket_id, "optional_pocket")


static func _main_zone_type(index: int, main_count: int) -> String:
	if index == 0:
		return "start"
	if index == 1:
		return "first_contact"
	if index == main_count - 1:
		return "required_exit"
	if main_count >= 5 and index == main_count - 2:
		return "elite_pressure"
	if index == main_count - 3:
		return "fork"
	return "road"


static func _find_main_zone_id_by_type(layout: GeneratedMapLayout, main_zone_ids: Array, zone_type: String) -> String:
	for zone_id in main_zone_ids:
		var zone := layout.find_zone(str(zone_id))
		if str(zone.get("type", "")) == zone_type:
			return str(zone_id)
	return ""


static func _add_zone_anchors(layout: GeneratedMapLayout, zone_id: String, zone_type: String, rect: Rect2, index: int, main_count: int) -> void:
	if zone_type == "start":
		layout.add_anchor("anchor_start", "start", rect.get_center(), true, zone_id)
	else:
		layout.add_anchor("anchor_%s_entry" % zone_id, "entry", rect.get_center() + Vector2(0.0, -rect.size.y * 0.28), false, zone_id)

	if zone_type == "required_exit":
		layout.add_anchor("anchor_required_exit", "required_exit", rect.get_center(), true, zone_id)
	else:
		layout.add_anchor("anchor_%s_exit" % zone_id, "exit", rect.get_center() + Vector2(0.0, rect.size.y * 0.28), false, zone_id)

	if zone_type == "fork":
		layout.add_anchor("anchor_route_fork", "fork", rect.get_center(), true, zone_id)


static func _add_zone_placeholders(layout: GeneratedMapLayout, config: MapGenerationConfig, rng: RandomNumberGenerator, zone_id: String, zone_type: String, rect: Rect2, index: int) -> void:
	match zone_type:
		"start":
			layout.add_map_object("object_start_camp", "camp_spawn_placeholder", zone_id, rect.get_center())
		"first_contact":
			layout.add_spawn_group("spawn_first_contact", zone_id, "training_pack_placeholder", rng.randi_range(2, 4), rng.randi_range(4, 7))
			layout.add_map_object("object_first_contact_hint", "combat_hint_marker", zone_id, _random_point_in_rect(rect, config.zone_padding, rng))
		"road":
			layout.add_spawn_group("spawn_road_%02d" % index, zone_id, "road_pack_placeholder", rng.randi_range(1, 3), rng.randi_range(3, 6))
		"elite_pressure":
			layout.add_spawn_group("spawn_elite_pressure", zone_id, "elite_pressure_placeholder", 1, rng.randi_range(9, 14))
			layout.add_map_object("object_elite_reward_hint", "reward_hint_placeholder", zone_id, _random_point_in_rect(rect, config.zone_padding, rng))
		"fork":
			layout.add_map_object("object_fork_marker", "fork_marker_placeholder", zone_id, _random_point_in_rect(rect, config.zone_padding, rng))
		"required_exit":
			layout.add_map_object("object_required_exit", "next_area_exit_placeholder", zone_id, rect.get_center())


static func _add_route_connection(layout: GeneratedMapLayout, config: MapGenerationConfig, rng: RandomNumberGenerator, from_zone_id: String, to_zone_id: String, kind: String) -> void:
	var from_zone := layout.find_zone(from_zone_id)
	var to_zone := layout.find_zone(to_zone_id)
	var from_rect: Rect2 = from_zone.get("rect", Rect2())
	var to_rect: Rect2 = to_zone.get("rect", Rect2())
	var from_center := from_rect.get_center()
	var to_center := to_rect.get_center()
	var bend_horizontal_first := rng.randi_range(0, 1) == 0
	var bend := "horizontal_first" if bend_horizontal_first else "vertical_first"
	var connection_id := "connection_%02d_%s" % [layout.route_connections.size(), kind]
	var corridor_ids := []

	if bend_horizontal_first:
		var mid_a := Vector2(to_center.x, from_center.y)
		corridor_ids.append(_add_corridor_rect(layout, "%s_corridor_a" % connection_id, _corridor_rect(from_center, mid_a, config.corridor_width), connection_id))
		corridor_ids.append(_add_corridor_rect(layout, "%s_corridor_b" % connection_id, _corridor_rect(mid_a, to_center, config.corridor_width), connection_id))
	else:
		var mid_b := Vector2(from_center.x, to_center.y)
		corridor_ids.append(_add_corridor_rect(layout, "%s_corridor_a" % connection_id, _corridor_rect(from_center, mid_b, config.corridor_width), connection_id))
		corridor_ids.append(_add_corridor_rect(layout, "%s_corridor_b" % connection_id, _corridor_rect(mid_b, to_center, config.corridor_width), connection_id))

	layout.add_route_connection(connection_id, from_zone_id, to_zone_id, kind, bend, corridor_ids)


static func _add_corridor_rect(layout: GeneratedMapLayout, corridor_id: String, rect: Rect2, connection_id: String) -> String:
	layout.add_corridor(corridor_id, rect, connection_id)
	return corridor_id


static func _corridor_rect(start: Vector2, end: Vector2, width: float) -> Rect2:
	if abs(start.x - end.x) >= abs(start.y - end.y):
		var left: float = min(start.x, end.x)
		var right: float = max(start.x, end.x)
		return Rect2(Vector2(left, start.y - width * 0.5), Vector2(max(right - left, width), width))
	var top: float = min(start.y, end.y)
	var bottom: float = max(start.y, end.y)
	return Rect2(Vector2(start.x - width * 0.5, top), Vector2(width, max(bottom - top, width)))


static func _generate_boundary(layout: GeneratedMapLayout, config: MapGenerationConfig) -> void:
	var thickness := 112.0
	var bounds := Rect2(Vector2.ZERO, config.map_size)
	layout.add_boundary_pair("north_edge", Rect2(bounds.position.x, bounds.position.y - thickness, bounds.size.x, thickness), Rect2(bounds.position.x, bounds.position.y - thickness, bounds.size.x, thickness))
	layout.add_boundary_pair("south_edge", Rect2(bounds.position.x, bounds.end.y, bounds.size.x, thickness), Rect2(bounds.position.x, bounds.end.y, bounds.size.x, thickness))
	layout.add_boundary_pair("west_edge", Rect2(bounds.position.x - thickness, bounds.position.y - thickness, thickness, bounds.size.y + thickness * 2.0), Rect2(bounds.position.x - thickness, bounds.position.y - thickness, thickness, bounds.size.y + thickness * 2.0))
	layout.add_boundary_pair("east_edge", Rect2(bounds.end.x, bounds.position.y - thickness, thickness, bounds.size.y + thickness * 2.0), Rect2(bounds.end.x, bounds.position.y - thickness, thickness, bounds.size.y + thickness * 2.0))


static func _random_point_in_rect(rect: Rect2, padding: float, rng: RandomNumberGenerator) -> Vector2:
	var safe_padding: float = min(padding, min(rect.size.x, rect.size.y) * 0.35)
	return Vector2(
		rng.randf_range(rect.position.x + safe_padding, rect.end.x - safe_padding),
		rng.randf_range(rect.position.y + safe_padding, rect.end.y - safe_padding)
	)
