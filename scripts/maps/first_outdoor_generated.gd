extends "res://scripts/maps/combat_sandbox.gd"

const OUTDOOR_OBJECTIVE_PANEL_SCRIPT := preload("res://scripts/ui/outdoor_objective_panel.gd")
const CONFIG_SCRIPT := preload("res://scripts/maps/procedural/map_generation_config.gd")
const GENERATOR_SCRIPT := preload("res://scripts/maps/procedural/map_generator.gd")
const DEBUG_SCRIPT := preload("res://scripts/maps/procedural/map_generation_debug.gd")
const OBJECT_CATALOG_SCRIPT := preload("res://scripts/maps/procedural/map_object_definition.gd")
const OBJECT_FACTORY_SCRIPT := preload("res://scripts/maps/procedural/map_object_factory.gd")
const BOUNDARY_PASS_SCRIPT := preload("res://scripts/maps/procedural/generated_boundary_pass.gd")
const ITEM_DATABASE := preload("res://scripts/items/item_database.gd")
const OUTDOOR_COLLISION := preload("res://scripts/physics/outdoor_collision.gd")
const NATIVE_WANG_TERRAIN_BUILDER_SCRIPT := preload("res://scripts/terrain/native_wang_terrain_builder.gd")

const FIRST_OUTDOOR_CONFIG_PATH := "res://data/maps/first_outdoor_map.json"
const CAMP_SCENE_PATH := "res://scenes/maps/camp_scene.tscn"
const TILE_SIZE := 32
const CAMP_EXIT_MIN_DISTANCE := 290.0
const DUNGEON_ENTRANCE_RADIUS := 170.0
const OUTDOOR_CAMERA_ZOOM := Vector2(1.18, 1.18)
const OUTDOOR_PLAYER_SPRITE_SCALE := Vector2(1.9, 1.9)
const DEFAULT_PROP_SCALE := 1.45
const SMALL_PROP_SCALE := 1.25
const LARGE_PROP_SCALE := 1.75
const TERRAIN_VISIBLE_PADDING := 720.0
const ROAD_SAMPLE_SPACING := 44.0
const ROAD_RIBBON_WIDTH := 92.0
const ROAD_EDGE_WIDTH := 18.0
const ROAD_JITTER := 14.0

@export var generation_seed := 24001

var map_config: MapGenerationConfig
var config_data := {}
var layout: GeneratedMapLayout
var validation_result := {}
var visuals_root: Node2D
var ground_base_layer: Node2D
var terrain_overlay_layer: Node2D
var road_layer: Node2D
var decal_layer: Node2D
var outer_buffer_layer: Node2D
var boundary_visual_layer: Node2D
var props_root: Node2D
var boundary_root: Node2D
var debug_overlay_root: Node2D
var route_markers := {}
var route_spawned := false
var dungeon_entrance_position := Vector2.ZERO
var camp_exit_y := 0.0
var boundary_visual_count := 0
var boundary_collider_count := 0
var prop_blocker_count := 0
var prop_visual_rects := {}
var prop_blocker_rects := {}
var prop_blocker_sources := {}
var asset_cache := {}
var object_catalog
var object_factory
var boundary_pass
var boundary_payload := {}
var native_wang_terrain_builder: NativeWangTerrainBuilder


func _ready() -> void:
	_load_first_outdoor_config()
	_generate_layout()
	_build_generated_world()
	super._ready()
	_apply_first_outdoor_runtime_scale()


func _process(_delta: float) -> void:
	_update_world_entity_z_indices()
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size != last_viewport_size:
		_layout_ui()
	_update_debug_label()
	_update_inventory_ui()
	_update_skill_tree_ui()
	_update_loadout_ui()
	_update_objective_flow()
	_update_cursor_item_ui()


func _build_objective_ui() -> void:
	objective_panel = OUTDOOR_OBJECTIVE_PANEL_SCRIPT.new()
	debug_canvas.add_child(objective_panel)
	objective_panel.call("setup")


func _spawn_wave() -> void:
	if route_spawned:
		return
	route_spawned = true
	_clear_enemies()
	_spawn_first_outdoor_encounters()
	_spawn_guaranteed_weapon_drop()


func _load_first_outdoor_config() -> void:
	map_config = CONFIG_SCRIPT.from_json_file(FIRST_OUTDOOR_CONFIG_PATH)
	object_catalog = OBJECT_CATALOG_SCRIPT.load_from_file()
	var file := FileAccess.open(FIRST_OUTDOOR_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("FirstOutdoor: missing config %s" % FIRST_OUTDOOR_CONFIG_PATH)
		config_data = {}
		return
	var parsed = JSON.parse_string(file.get_as_text())
	config_data = parsed if parsed is Dictionary else {}


func _generate_layout() -> void:
	layout = GENERATOR_SCRIPT.generate(map_config, generation_seed)
	validation_result = DEBUG_SCRIPT.validate_layout(layout)


func _build_generated_world() -> void:
	native_wang_terrain_builder = NATIVE_WANG_TERRAIN_BUILDER_SCRIPT.new()
	visuals_root = Node2D.new()
	visuals_root.name = "FirstOutdoorVisuals"
	add_child(visuals_root)
	_build_terrain_visual_layers()

	boundary_root = Node2D.new()
	boundary_root.name = "FirstOutdoorBlockers"
	add_child(boundary_root)

	props_root = Node2D.new()
	props_root.name = "FirstOutdoorProps"
	props_root.y_sort_enabled = true
	world_entities_root.add_child(props_root)

	debug_overlay_root = Node2D.new()
	debug_overlay_root.name = "FirstOutdoorDebugOverlay"
	debug_overlay_root.visible = false
	add_child(debug_overlay_root)

	object_factory = OBJECT_FACTORY_SCRIPT.new()
	object_factory.setup(object_catalog, props_root, boundary_root)

	_add_layout_ground()
	_add_layout_boundaries()
	_add_layout_markers()
	_add_route_props()
	_add_generated_boundary_pass()
	_add_debug_overlay()
	_place_player_at_spawn()


func _build_terrain_visual_layers() -> void:
	outer_buffer_layer = _add_visual_layer("OuterBufferLayer", -145)
	ground_base_layer = _add_visual_layer("GroundBaseLayer", -140)
	terrain_overlay_layer = _add_visual_layer("TerrainOverlayLayer", -126)
	road_layer = _add_visual_layer("RoadLayer", -116)
	decal_layer = _add_visual_layer("DecalLayer", -110)
	boundary_visual_layer = _add_visual_layer("BoundaryLayer", -132)


func _add_visual_layer(layer_name: String, z_index: int) -> Node2D:
	var layer := Node2D.new()
	layer.name = layer_name
	layer.z_index = z_index
	visuals_root.add_child(layer)
	return layer


func _add_layout_ground() -> void:
	var visible_bounds := _terrain_visible_bounds()
	_add_native_wang_outdoor_ground(visible_bounds)


func _add_native_wang_outdoor_ground(visible_bounds: Rect2) -> void:
	var builder: NativeWangTerrainBuilder = _native_wang_builder()
	var layer: TileMapLayer = builder.create_layer("NativeWangTerrainLayer", -139)
	ground_base_layer.add_child(layer)
	var dirt_cells: Array[Vector2i] = []
	for cell in builder.cells_for_rect(visible_bounds):
		var center: Vector2 = builder.cell_center(cell)
		if _is_native_wang_outdoor_dirt(center):
			dirt_cells.append(cell)
	builder.paint_rect(layer, visible_bounds, dirt_cells)


func _is_native_wang_outdoor_dirt(point: Vector2) -> bool:
	var start_anchor := layout.find_anchor_by_type("start")
	if not start_anchor.is_empty():
		var start_position: Vector2 = start_anchor.get("position", Vector2.ZERO)
		var top_connector := [Vector2(start_position.x, 0.0), start_position]
		if point.y <= start_position.y and _distance_to_polyline(point, top_connector) <= ROAD_RIBBON_WIDTH * 0.72:
			return true
	var main_points := _route_points_for_types(["start", "first_contact", "road", "fork", "elite_pressure", "required_exit"])
	if _distance_to_polyline(point, main_points) <= ROAD_RIBBON_WIDTH * 0.72:
		return true
	var fork_zone := _find_zone_by_type("fork")
	var branch_zone := _find_zone_by_type("required_branch")
	if not fork_zone.is_empty() and not branch_zone.is_empty():
		var branch_points := [
			Rect2(fork_zone.get("rect", Rect2())).get_center(),
			Rect2(branch_zone.get("rect", Rect2())).get_center(),
		]
		if _distance_to_polyline(point, branch_points) <= ROAD_RIBBON_WIDTH * 0.54:
			return true
	for zone in layout.zones:
		var rect: Rect2 = zone.get("rect", Rect2())
		var zone_type := str(zone.get("type", ""))
		if zone_type in ["start", "first_contact", "road", "fork", "optional_pocket", "elite_pressure"]:
			if _point_in_soft_rect(point, rect.grow(-rect.size.length() * 0.02)):
				return true
	return false


func _terrain_visible_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, layout.map_size)


func _route_points_for_types(zone_types: Array) -> Array:
	var points := []
	for zone_type in zone_types:
		var zone := _find_zone_by_type(str(zone_type))
		if zone.is_empty():
			continue
		points.append(Rect2(zone.get("rect", Rect2())).get_center())
	return points


func _add_layout_boundaries() -> void:
	# Runtime uses the generated contour boundary pass for blocking and visuals.
	# The older full-map edge rectangles created broad invisible walls at the
	# camp join, so keep them out of the playable scene.
	return


func _split_rect_for_connection_openings(rect: Rect2, source: String) -> Array:
	var opening := _connection_opening_rect_for_source(source)
	if opening.size == Vector2.ZERO or not rect.intersects(opening):
		return [rect]
	if source == "north_edge" or source == "south_edge":
		var parts := []
		var left_width := maxf(0.0, opening.position.x - rect.position.x)
		var right_x := opening.end.x
		var right_width := maxf(0.0, rect.end.x - right_x)
		if left_width > 0.0:
			parts.append(Rect2(rect.position, Vector2(left_width, rect.size.y)))
		if right_width > 0.0:
			parts.append(Rect2(Vector2(right_x, rect.position.y), Vector2(right_width, rect.size.y)))
		return parts
	if source == "west_edge" or source == "east_edge":
		var parts := []
		var top_height := maxf(0.0, opening.position.y - rect.position.y)
		var bottom_y := opening.end.y
		var bottom_height := maxf(0.0, rect.end.y - bottom_y)
		if top_height > 0.0:
			parts.append(Rect2(rect.position, Vector2(rect.size.x, top_height)))
		if bottom_height > 0.0:
			parts.append(Rect2(Vector2(rect.position.x, bottom_y), Vector2(rect.size.x, bottom_height)))
		return parts
	return [rect]


func _connection_opening_rect_for_source(source: String) -> Rect2:
	var edge := ""
	match source:
		"north_edge":
			edge = "north"
		"south_edge":
			edge = "south"
		"west_edge":
			edge = "west"
		"east_edge":
			edge = "east"
		_:
			return Rect2()
	var boundary_style: Dictionary = config_data.get("boundary_style", {})
	for opening_value in Array(boundary_style.get("connection_openings", [])):
		var opening: Dictionary = opening_value
		if str(opening.get("edge", "")) != edge:
			continue
		var anchor := layout.find_anchor_by_type(str(opening.get("anchor_type", "")))
		if anchor.is_empty():
			continue
		var center: Vector2 = anchor.get("position", Vector2.ZERO)
		var width := float(opening.get("width", 0.0))
		var depth := float(opening.get("depth", 0.0))
		if edge == "north":
			return Rect2(Vector2(center.x - width * 0.5, -depth), Vector2(width, depth + center.y))
		if edge == "south":
			return Rect2(Vector2(center.x - width * 0.5, center.y), Vector2(width, depth + layout.map_size.y - center.y))
		if edge == "west":
			return Rect2(Vector2(-depth, center.y - width * 0.5), Vector2(depth + center.x, width))
		if edge == "east":
			return Rect2(Vector2(center.x, center.y - width * 0.5), Vector2(depth + layout.map_size.x - center.x, width))
	return Rect2()


func _add_generated_boundary_pass() -> void:
	boundary_pass = BOUNDARY_PASS_SCRIPT.new()
	boundary_payload = boundary_pass.generate(layout, config_data.get("boundary_style", {}), object_factory, generation_seed)
	boundary_visual_count = Array(boundary_payload.get("boundary_objects", [])).size()
	var validation: Dictionary = boundary_pass.validate(int(config_data.get("boundary_style", {}).get("max_gap_cells", 2)))
	if not bool(validation.get("ok", false)):
		push_warning("FirstOutdoor boundary pass validation: %s" % str(validation.get("errors", [])))
	_add_boundary_contour_blockers()
	_refresh_factory_payload_cache()


func _add_boundary_contour_blockers() -> void:
	for segment in boundary_payload.get("contour_segments", []):
		_add_contour_segment_blocker(segment)
	for corner in boundary_payload.get("corner_points", []):
		var corner_data: Dictionary = corner
		var position := _vector_from_payload(corner_data.get("position", {}))
		var size := 14.0
		_add_blocker_rect("BoundaryContourCorner_%s" % str(corner_data.get("id", "")).replace(",", "_"), Rect2(position - Vector2(size, size) * 0.5, Vector2(size, size)), "boundary_contour")


func _add_contour_segment_blocker(segment: Dictionary) -> void:
	var start := _vector_from_payload(segment.get("start", {}))
	var end := _vector_from_payload(segment.get("end", {}))
	var thickness := 10.0
	var overlap := 2.0
	var rect := Rect2()
	if str(segment.get("orientation", "")) == "horizontal":
		var left := minf(start.x, end.x)
		var right := maxf(start.x, end.x)
		rect = Rect2(Vector2(left - overlap, start.y - thickness * 0.5), Vector2(right - left + overlap * 2.0, thickness))
	else:
		var top := minf(start.y, end.y)
		var bottom := maxf(start.y, end.y)
		rect = Rect2(Vector2(start.x - thickness * 0.5, top - overlap), Vector2(thickness, bottom - top + overlap * 2.0))
	_add_blocker_rect("BoundaryContour_%s" % str(segment.get("id", "")), rect, "boundary_contour")


func _collect_boundary_contour_segment(
	horizontal_segments: Dictionary,
	vertical_segments: Dictionary,
	horizontal_vertices: Dictionary,
	vertical_vertices: Dictionary,
	x: int,
	y: int,
	edge: String,
	pass_cell_size: int
) -> void:
	var left := x * pass_cell_size
	var right := (x + 1) * pass_cell_size
	var top := y * pass_cell_size
	var bottom := (y + 1) * pass_cell_size
	match edge:
		"north":
			_add_interval(horizontal_segments, bottom, left, right)
			_add_vertex(horizontal_vertices, left, bottom)
			_add_vertex(horizontal_vertices, right, bottom)
		"south":
			_add_interval(horizontal_segments, top, left, right)
			_add_vertex(horizontal_vertices, left, top)
			_add_vertex(horizontal_vertices, right, top)
		"west":
			_add_interval(vertical_segments, right, top, bottom)
			_add_vertex(vertical_vertices, right, top)
			_add_vertex(vertical_vertices, right, bottom)
		"east":
			_add_interval(vertical_segments, left, top, bottom)
			_add_vertex(vertical_vertices, left, top)
			_add_vertex(vertical_vertices, left, bottom)


func _add_interval(segments: Dictionary, line_key: int, start: int, end: int) -> void:
	var intervals: Array = segments.get(line_key, [])
	intervals.append({"start": mini(start, end), "end": maxi(start, end)})
	segments[line_key] = intervals


func _add_vertex(vertices: Dictionary, x: int, y: int) -> void:
	vertices["%d,%d" % [x, y]] = Vector2(x, y)


func _add_merged_boundary_segments(segments: Dictionary, horizontal: bool) -> void:
	var thickness := 22.0
	var overlap := 4.0
	for line_key in segments.keys():
		var intervals: Array = segments[line_key]
		intervals.sort_custom(func(a, b): return int(Dictionary(a).get("start", 0)) < int(Dictionary(b).get("start", 0)))
		var merged := []
		for interval_value in intervals:
			var interval: Dictionary = interval_value
			var start := int(interval.get("start", 0))
			var end := int(interval.get("end", 0))
			if merged.is_empty() or start > int(merged[-1].get("end", 0)):
				merged.append({"start": start, "end": end})
			else:
				merged[-1]["end"] = maxi(int(merged[-1].get("end", 0)), end)
		for run_value in merged:
			var run: Dictionary = run_value
			var start := float(run.get("start", 0))
			var end := float(run.get("end", 0))
			var line := float(line_key)
			var rect := Rect2()
			if horizontal:
				rect = Rect2(Vector2(start - overlap, line - thickness * 0.5), Vector2(end - start + overlap * 2.0, thickness))
			else:
				rect = Rect2(Vector2(line - thickness * 0.5, start - overlap), Vector2(thickness, end - start + overlap * 2.0))
			_add_blocker_rect("BoundaryContour_%s_%d_%d" % ["H" if horizontal else "V", int(line_key), int(start)], rect, "boundary_contour")


func _add_boundary_corner_plugs(horizontal_vertices: Dictionary, vertical_vertices: Dictionary) -> void:
	var size := 26.0
	for key in horizontal_vertices.keys():
		if not vertical_vertices.has(key):
			continue
		var point: Vector2 = horizontal_vertices[key]
		var rect := Rect2(point - Vector2(size, size) * 0.5, Vector2(size, size))
		_add_blocker_rect("BoundaryCorner_%s" % str(key).replace(",", "_"), rect, "boundary_contour")


func _refresh_factory_payload_cache() -> void:
	prop_visual_rects.clear()
	prop_blocker_rects.clear()
	prop_blocker_sources.clear()
	prop_blocker_count = 0
	for placed in object_factory.get_payload():
		var object_id := str(placed.get("id", ""))
		var blocker_id := str(placed.get("blocker_id", ""))
		if object_id.is_empty() or blocker_id.is_empty():
			continue
		prop_visual_rects[object_id] = _rect_from_payload(placed.get("visual_rect", {}))
		prop_blocker_sources[blocker_id] = str(placed.get("object_def", ""))
		var collision: Dictionary = placed.get("collision_shape", {})
		prop_blocker_rects[blocker_id] = _approx_collision_rect(_vector_from_payload(placed.get("position", {})), collision)
		prop_blocker_count += 1


func _add_layout_markers() -> void:
	var start_zone := _find_zone_by_type("start")
	var start_anchor := layout.find_anchor_by_type("start")
	var camp_entrance_anchor := layout.find_anchor_by_type("camp_entrance")
	var start_position: Vector2 = start_anchor.get("position", start_zone.get("rect", Rect2()).get_center())
	var spawn_position: Vector2 = camp_entrance_anchor.get("position", Vector2(start_position.x, 0.0))
	_add_route_marker("CampSpawn", spawn_position)
	_add_route_marker("CampEntrance", spawn_position)
	_add_route_marker("CampEntranceSpawn", spawn_position)

	var first_contact_zone := _find_zone_by_type("first_contact")
	_add_route_marker("FirstContact", Rect2(first_contact_zone.get("rect", Rect2())).get_center())

	var fork_zone := _find_zone_by_type("fork")
	_add_route_marker("RoadFork", Rect2(fork_zone.get("rect", Rect2())).get_center())

	var branch_zone := _find_zone_by_type("required_branch")
	dungeon_entrance_position = Rect2(branch_zone.get("rect", Rect2())).get_center()
	_add_route_marker("DungeonEntrance", dungeon_entrance_position)
	_add_route_marker("CorruptedHollowEntrance", dungeon_entrance_position)

	var pressure_zone := _find_zone_by_type("elite_pressure")
	_add_route_marker("ElitePressure", Rect2(pressure_zone.get("rect", Rect2())).get_center())

	var exit_anchor := layout.find_anchor_by_type("required_exit")
	var exit_position: Vector2 = exit_anchor.get("position", Rect2(_find_zone_by_type("required_exit").get("rect", Rect2())).get_center())
	_add_route_marker("NextAreaExit", exit_position)

	camp_exit_y = spawn_position.y + CAMP_EXIT_MIN_DISTANCE


func _add_route_props() -> void:
	var start_rect: Rect2 = _find_zone_by_type("start").get("rect", Rect2())
	var first_rect: Rect2 = _find_zone_by_type("first_contact").get("rect", Rect2())
	var road_rect: Rect2 = _find_zone_by_type("road").get("rect", Rect2())
	var fork_rect: Rect2 = _find_zone_by_type("fork").get("rect", Rect2())
	var branch_rect: Rect2 = _find_zone_by_type("required_branch").get("rect", Rect2())
	var pocket_rect: Rect2 = _find_zone_by_type("optional_pocket").get("rect", Rect2())
	var pressure_rect: Rect2 = _find_zone_by_type("elite_pressure").get("rect", Rect2())
	var exit_rect: Rect2 = _find_zone_by_type("required_exit").get("rect", Rect2())

	_place_defined_prop("CampGate", "camp_gate", start_rect.get_center() + Vector2(0, start_rect.size.y * 0.32), ["camp", "gate"])
	_place_defined_prop("CampSignpost", "route_sign_or_scout_marker", start_rect.get_center() + Vector2(start_rect.size.x * 0.32, start_rect.size.y * 0.22), ["route_sign"])

	_add_edge_props_for_zone(first_rect, "FirstContact")
	_place_defined_prop("BrokenCart", "broken_cart", road_rect.get_center() + Vector2(road_rect.size.x * 0.24, -road_rect.size.y * 0.14), ["road", "cart"])
	_place_defined_prop("RoadRockA", "rock_a", road_rect.get_center() + Vector2(-road_rect.size.x * 0.34, road_rect.size.y * 0.22), ["road", "rock"])
	_place_defined_prop("RoadRockB", "rock_b", road_rect.get_center() + Vector2(road_rect.size.x * 0.36, road_rect.size.y * 0.24), ["road", "rock"])

	_place_defined_prop("ForkSignpost", "route_sign_or_scout_marker", fork_rect.get_center() + Vector2(-fork_rect.size.x * 0.18, -fork_rect.size.y * 0.22), ["fork", "route_sign"])
	_place_defined_prop("ForkFenceA", "broken_fence_a", fork_rect.get_center() + Vector2(-fork_rect.size.x * 0.42, fork_rect.size.y * 0.18), ["fork", "fence"])
	_place_defined_prop("ForkFenceB", "broken_fence_b", fork_rect.get_center() + Vector2(fork_rect.size.x * 0.38, -fork_rect.size.y * 0.12), ["fork", "fence"])

	if pocket_rect.size != Vector2.ZERO:
		_place_defined_prop("OptionalShrine", "shrine_or_loot_marker", pocket_rect.get_center(), ["optional_pocket", "shrine"])
		_add_edge_props_for_zone(pocket_rect, "OptionalPocket")

	_place_defined_prop("CorruptedHollow", "dungeon_entrance", branch_rect.get_center(), ["dungeon_entrance", "hook"])
	_place_defined_prop("HollowRootA", "corrupted_root_a", branch_rect.get_center() + Vector2(-branch_rect.size.x * 0.32, branch_rect.size.y * 0.25), ["dungeon_entrance", "root"])
	_place_defined_prop("HollowRootB", "corrupted_root_b", branch_rect.get_center() + Vector2(branch_rect.size.x * 0.32, branch_rect.size.y * 0.24), ["dungeon_entrance", "root"])

	_add_edge_props_for_zone(pressure_rect, "Pressure")
	_place_defined_prop("PressureRootsA", "corrupted_root_a", pressure_rect.get_center() + Vector2(-pressure_rect.size.x * 0.34, 0), ["pressure", "root"])
	_place_defined_prop("PressureRootsB", "corrupted_root_b", pressure_rect.get_center() + Vector2(pressure_rect.size.x * 0.34, 0), ["pressure", "root"])

	_place_defined_prop("NextExitSign", "route_sign_or_scout_marker", exit_rect.get_center() + Vector2(-exit_rect.size.x * 0.22, -exit_rect.size.y * 0.18), ["next_exit", "soft_gate"])
	_place_defined_prop("NextExitRoots", "corrupted_root_b", exit_rect.get_center() + Vector2(exit_rect.size.x * 0.2, exit_rect.size.y * 0.2), ["next_exit", "soft_gate"])


func _add_edge_props_for_zone(rect: Rect2, prefix: String) -> void:
	if rect.size == Vector2.ZERO:
		return
	_place_defined_prop("%sTreeA" % prefix, "dead_tree_a", rect.position + Vector2(70, rect.size.y * 0.5), [prefix, "tree"])
	_place_defined_prop("%sTreeB" % prefix, "dead_tree_b", Vector2(rect.end.x - 72, rect.position.y + rect.size.y * 0.42), [prefix, "tree"])
	_place_defined_prop("%sRockA" % prefix, "rock_a", rect.position + Vector2(rect.size.x * 0.22, rect.size.y - 58), [prefix, "rock"])


func _spawn_first_outdoor_encounters() -> void:
	_spawn_pool_in_zone("weak_training", _find_zone_by_type("first_contact"))
	_spawn_pool_in_zone("road_patrol", _find_zone_by_type("road"))
	_spawn_pool_in_zone("loot_captain", _find_zone_by_type("road"), Vector2(0, 90))
	_spawn_pool_in_zone("optional_shrine", _find_zone_by_type("optional_pocket"))
	_spawn_pool_in_zone("elite_pressure", _find_zone_by_type("elite_pressure"))


func _spawn_pool_in_zone(pool_id: String, zone: Dictionary, offset: Vector2 = Vector2.ZERO) -> void:
	if zone.is_empty():
		return
	var enemy_pool: Dictionary = config_data.get("enemy_pool", {})
	var pool: Dictionary = enemy_pool.get(pool_id, {})
	if pool.is_empty():
		return
	var rect: Rect2 = zone.get("rect", Rect2())
	var count := int(pool.get("count", 1))
	var center := rect.get_center() + offset
	for index in range(count):
		var spawn_position := _spread_position(center, index, count, min(rect.size.x, rect.size.y) * 0.22)
		var is_elite := pool.has("elite_index") and index == int(pool.get("elite_index", -1))
		var enemy_name := "%s_%02d" % [pool_id.capitalize().replace(" ", ""), index]
		_spawn_configured_mummy(enemy_name, pool, spawn_position, is_elite)


func _spawn_configured_mummy(enemy_name: String, pool: Dictionary, spawn_position: Vector2, is_elite: bool) -> Node2D:
	var enemy := MUMMY_SCENE.instantiate()
	enemy.name = enemy_name
	enemy.enemy_display_name = str(pool.get("display_name", "Mummy"))
	enemy.sprite_root = str(pool.get("sprite_root", "res://assets/sprites/enemies/mummy"))
	enemy.sprite_file_prefix = str(pool.get("sprite_file_prefix", "enemy_mummy"))
	enemy.global_position = spawn_position
	enemy.max_hp = int(pool.get("elite_max_hp", pool.get("max_hp", 40))) if is_elite else int(pool.get("max_hp", 40))
	enemy.move_speed = float(pool.get("move_speed", 44.0))
	enemy.attack_damage = int(pool.get("elite_attack_damage", pool.get("attack_damage", 8))) if is_elite else int(pool.get("attack_damage", 8))
	enemy.attack_range = 50.0
	enemy.preferred_distance = 44.0
	enemy.attack_cooldown = 1.2
	enemy.display_scale = 1.95 if is_elite else 1.55
	enemy.xp_reward = int(pool.get("elite_xp_reward", pool.get("xp_reward", 10))) if is_elite else int(pool.get("xp_reward", 10))
	enemy.drops_loot = bool(pool.get("drops_loot", false))
	OUTDOOR_COLLISION.apply_enemy_body(enemy)
	enemy.add_to_group(str(pool.get("group", "outdoor_enemy")))
	get_world_item_parent().add_child(enemy)
	return enemy


func _spawn_guaranteed_weapon_drop() -> void:
	var road_zone := _find_zone_by_type("road")
	if road_zone.is_empty():
		return
	var rect: Rect2 = road_zone.get("rect", Rect2())
	var loot := WEAPON_PICKUP_SCENE.instantiate()
	if loot.has_method("setup_item"):
		loot.setup_item(ITEM_DATABASE.make_item_instance("weapon_iron_sword", "magic", {"damage": 12}, {"name": "Road-Worn Iron Sword"}))
	loot.name = "GuaranteedFirstWeaponDrop"
	loot.global_position = rect.get_center() + Vector2(-rect.size.x * 0.18, rect.size.y * 0.18)
	get_world_item_parent().add_child(loot)


func _add_debug_overlay() -> void:
	for zone in layout.zones:
		var rect: Rect2 = zone.get("rect", Rect2())
		_add_debug_label(str(zone.get("type", "")), rect.position + Vector2(12, 12))
	for marker_name in route_markers.keys():
		_add_debug_label(str(marker_name), route_markers[marker_name].position + Vector2(18, -24))


func _place_player_at_spawn() -> void:
	var spawn_position := get_route_marker_position("CampSpawn")
	if spawn_position == Vector2.ZERO:
		return
	player.global_position = spawn_position
	player.position = spawn_position


func _apply_first_outdoor_runtime_scale() -> void:
	if not is_instance_valid(player):
		return
	OUTDOOR_COLLISION.apply_player_body(player)
	var sprite := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite != null:
		sprite.scale = OUTDOOR_PLAYER_SPRITE_SCALE
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.zoom = OUTDOOR_CAMERA_ZOOM
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(layout.map_size.x)
		camera.limit_bottom = int(layout.map_size.y)


func has_player_left_camp() -> bool:
	return is_instance_valid(player) and player.global_position.y >= camp_exit_y


func is_encounter_group_cleared(group_name: String) -> bool:
	for enemy in get_tree().get_nodes_in_group(group_name):
		if is_instance_valid(enemy) and not bool(enemy.get("dead")):
			return false
	return true


func is_dungeon_entrance_reached() -> bool:
	return is_instance_valid(player) and player.global_position.distance_to(dungeon_entrance_position) <= DUNGEON_ENTRANCE_RADIUS


func get_route_marker_position(marker_name: String) -> Vector2:
	var marker: Marker2D = route_markers.get(marker_name, null)
	return marker.global_position if marker != null else Vector2.ZERO


func get_camp_entrance_position() -> Vector2:
	return get_route_marker_position("CampEntranceSpawn")


func get_camp_return_target_path() -> String:
	return CAMP_SCENE_PATH


func get_dungeon_entrance_position() -> Vector2:
	return dungeon_entrance_position


func get_playable_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, layout.map_size)


func get_generated_payload() -> Dictionary:
	if layout == null:
		return {}
	var payload := layout.to_payload()
	payload["boundary_pass"] = boundary_payload.duplicate(true)
	payload["placed_objects"] = object_factory.get_payload() if object_factory != null else []
	payload["object_defs_used"] = object_catalog.to_payload_used(object_factory.get_object_defs_used()) if object_catalog != null and object_factory != null else []
	payload["object_definition_warnings"] = object_factory.get_warnings() if object_factory != null else []
	return payload


func get_validation_result() -> Dictionary:
	return validation_result.duplicate(true)


func get_generation_seed() -> int:
	return generation_seed


func get_boundary_collider_count() -> int:
	return boundary_root.get_child_count() if boundary_root != null else boundary_collider_count


func get_boundary_visual_count() -> int:
	return boundary_visual_count


func get_prop_blocker_count() -> int:
	return prop_blocker_count


func get_prop_blocker_rects() -> Dictionary:
	return prop_blocker_rects.duplicate(true)


func get_prop_visual_rects() -> Dictionary:
	return prop_visual_rects.duplicate(true)


func get_prop_blocker_sources() -> Dictionary:
	return prop_blocker_sources.duplicate(true)


func get_boundary_pass_payload() -> Dictionary:
	return boundary_payload.duplicate(true)


func get_placed_object_payload() -> Array:
	return object_factory.get_payload() if object_factory != null else []


func get_object_definition_validation() -> Dictionary:
	return object_catalog.validate() if object_catalog != null else {"ok": false, "errors": ["missing catalog"], "warnings": []}


func get_first_contact_enemy_count() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("outdoor_training"):
		if is_instance_valid(enemy):
			count += 1
	return count


func get_spawn_distance_to_first_contact() -> float:
	return get_route_marker_position("CampSpawn").distance_to(get_route_marker_position("FirstContact"))


func get_dungeon_branch_distance_to_spawn() -> float:
	return get_route_marker_position("CampSpawn").distance_to(get_route_marker_position("DungeonEntrance"))


func get_camera_zoom() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	return camera.zoom if camera != null else Vector2.ZERO


func _add_background_rect(rect_name: String, rect: Rect2, color: Color, z_index: int, parent: Node = null) -> ColorRect:
	var color_rect := ColorRect.new()
	color_rect.name = rect_name
	color_rect.position = rect.position
	color_rect.size = rect.size
	color_rect.color = color
	color_rect.z_index = z_index
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var target_parent := parent if parent != null else visuals_root
	target_parent.add_child(color_rect)
	return color_rect


func _add_tiled_rect(rect: Rect2, texture: Texture2D, region: Rect2, node_name: String, parent: Node = null, z_index := -112, modulate := Color.WHITE) -> void:
	if texture == null:
		_add_background_rect("TileFallback_%s" % node_name, rect, Color(0.16, 0.14, 0.1, 1.0), z_index, parent)
		return
	var tile_root := Node2D.new()
	tile_root.name = node_name
	tile_root.z_index = z_index
	var target_parent := parent if parent != null else visuals_root
	target_parent.add_child(tile_root)
	var tile_texture := _make_atlas_texture(texture, region)
	var start_x := int(floor(rect.position.x / TILE_SIZE) * TILE_SIZE)
	var start_y := int(floor(rect.position.y / TILE_SIZE) * TILE_SIZE)
	var end_x := int(ceil(rect.end.x / TILE_SIZE) * TILE_SIZE)
	var end_y := int(ceil(rect.end.y / TILE_SIZE) * TILE_SIZE)
	for y in range(start_y, end_y, TILE_SIZE):
		for x in range(start_x, end_x, TILE_SIZE):
			var tile := Sprite2D.new()
			tile.texture = tile_texture
			tile.centered = false
			tile.position = Vector2(x, y)
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tile.modulate = modulate
			tile_root.add_child(tile)


func _terrain_keys(prefix: String) -> Array:
	return [
		_asset("%s_a" % prefix),
		_asset("%s_b" % prefix),
		_asset("%s_c" % prefix),
		_asset("%s_d" % prefix),
	].filter(func(texture): return texture != null)


func _add_variant_texture_rect(rect: Rect2, textures: Array, node_name: String, parent: Node = null, z_index := -140, modulate := Color.WHITE) -> void:
	if textures.is_empty():
		_add_background_rect("TileFallback_%s" % node_name, rect, Color(0.09, 0.105, 0.073, 1.0), z_index, parent)
		return
	var tile_size := int(maxf(16.0, (textures[0] as Texture2D).get_width()))
	var tile_root := Node2D.new()
	tile_root.name = node_name
	tile_root.z_index = z_index
	var target_parent := parent if parent != null else visuals_root
	target_parent.add_child(tile_root)
	var start_x := int(floor(rect.position.x / float(tile_size)) * tile_size)
	var start_y := int(floor(rect.position.y / float(tile_size)) * tile_size)
	var end_x := int(ceil(rect.end.x / float(tile_size)) * tile_size)
	var end_y := int(ceil(rect.end.y / float(tile_size)) * tile_size)
	for y in range(start_y, end_y, tile_size):
		for x in range(start_x, end_x, tile_size):
			var tile := Sprite2D.new()
			var variant_index := int(abs((x / tile_size) * 37 + (y / tile_size) * 19 + generation_seed)) % textures.size()
			tile.texture = textures[variant_index] as Texture2D
			tile.centered = false
			tile.position = Vector2(x, y)
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tile.modulate = modulate
			tile_root.add_child(tile)


func _add_soft_patch_grid(rect: Rect2, texture: Texture2D, node_name: String, parent: Node, z_index: int, spacing: float, modulate := Color.WHITE) -> void:
	if texture == null:
		return
	var patch_root := Node2D.new()
	patch_root.name = node_name
	patch_root.z_index = z_index
	parent.add_child(patch_root)
	var start_x := int(floor(rect.position.x / spacing) * spacing)
	var start_y := int(floor(rect.position.y / spacing) * spacing)
	var end_x := int(ceil(rect.end.x / spacing) * spacing)
	var end_y := int(ceil(rect.end.y / spacing) * spacing)
	for y in range(start_y, end_y, int(spacing)):
		for x in range(start_x, end_x, int(spacing)):
			var offset := Vector2(
				sin(float(x) * 0.019 + float(y) * 0.007 + float(generation_seed % 113)) * spacing * 0.18,
				cos(float(y) * 0.017 + float(x) * 0.011 + float(generation_seed % 71)) * spacing * 0.18
			)
			var patch := Sprite2D.new()
			patch.texture = texture
			patch.position = Vector2(x, y) + offset + Vector2(spacing * 0.5, spacing * 0.5)
			patch.rotation = sin(float(x + y) * 0.013) * 0.12
			patch.scale = Vector2.ONE * (0.78 + fposmod(float(x * 3 + y * 5), 17.0) / 100.0)
			patch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			patch.modulate = modulate
			patch_root.add_child(patch)


func _add_sprite_to_layer(parent: Node, sprite_name: String, texture: Texture2D, position: Vector2, z_index: int, scale := Vector2.ONE, flip_h := false) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.position = position
	sprite.z_index = z_index
	sprite.scale = scale
	sprite.flip_h = flip_h
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if texture == null:
		sprite.visible = false
	parent.add_child(sprite)
	return sprite


func _native_wang_builder() -> NativeWangTerrainBuilder:
	if native_wang_terrain_builder == null:
		native_wang_terrain_builder = NATIVE_WANG_TERRAIN_BUILDER_SCRIPT.new()
	return native_wang_terrain_builder


func _distance_to_polyline(point: Vector2, points: Array) -> float:
	if points.size() < 2:
		return INF
	var best := INF
	for index in range(points.size() - 1):
		best = minf(best, _distance_to_segment(point, points[index], points[index + 1]))
	return best


func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)


func _point_in_soft_rect(point: Vector2, rect: Rect2) -> bool:
	if rect.size == Vector2.ZERO:
		return false
	var center := rect.get_center()
	var radius := rect.size * 0.5
	if radius.x <= 0.0 or radius.y <= 0.0:
		return false
	var normalized := Vector2((point.x - center.x) / radius.x, (point.y - center.y) / radius.y)
	var wobble := sin(point.x * 0.011 + point.y * 0.017 + float(generation_seed % 83)) * 0.12
	return normalized.length_squared() <= 1.0 + wobble


func _place_defined_prop(prop_name: String, object_def: String, foot_position: Vector2, tags: Array = []) -> Dictionary:
	return object_factory.place_object(prop_name, object_def, foot_position, tags)


func _update_world_entity_z_indices() -> void:
	if world_entities_root == null:
		return
	for node in world_entities_root.get_children():
		if node == props_root:
			continue
		if node is Node2D and node is CanvasItem:
			_apply_absolute_z_index(node as CanvasItem, _collision_sort_y(node as Node2D))
	if props_root == null:
		return
	for prop in props_root.get_children():
		if prop is Node2D and prop is CanvasItem:
			_apply_absolute_z_index(prop as CanvasItem, _collision_sort_y(prop as Node2D))


func _apply_absolute_z_index(item: CanvasItem, sort_y: float) -> void:
	item.z_as_relative = false
	item.z_index = clampi(int(round(sort_y)), -4095, 4095)


func _collision_sort_y(node: Node2D) -> float:
	if node.has_meta("sort_y"):
		return float(node.get_meta("sort_y"))
	var bottom_y := -INF
	for child in node.get_children():
		var shape_node := child as CollisionShape2D
		if shape_node != null and shape_node.shape != null:
			bottom_y = maxf(bottom_y, _collision_shape_bottom_y(shape_node))
	if bottom_y > -INF:
		return bottom_y
	return node.global_position.y


func _collision_shape_bottom_y(shape_node: CollisionShape2D) -> float:
	if shape_node.shape is RectangleShape2D:
		var rectangle := shape_node.shape as RectangleShape2D
		var half_size := rectangle.size * 0.5
		return _max_transformed_y(shape_node.global_transform, [
			Vector2(-half_size.x, -half_size.y),
			Vector2(half_size.x, -half_size.y),
			Vector2(half_size.x, half_size.y),
			Vector2(-half_size.x, half_size.y),
		])
	if shape_node.shape is CircleShape2D:
		var circle := shape_node.shape as CircleShape2D
		var radius := circle.radius * maxf(absf(shape_node.global_scale.x), absf(shape_node.global_scale.y))
		return shape_node.global_position.y + radius
	if shape_node.shape is CapsuleShape2D:
		var capsule := shape_node.shape as CapsuleShape2D
		var half_height := capsule.height * 0.5
		var radius := capsule.radius
		return _max_transformed_y(shape_node.global_transform, [
			Vector2(-radius, -half_height),
			Vector2(radius, -half_height),
			Vector2(radius, half_height),
			Vector2(-radius, half_height),
		])
	return shape_node.global_position.y


func _max_transformed_y(transform: Transform2D, points: Array) -> float:
	var max_y := -INF
	for point in points:
		max_y = maxf(max_y, (transform * (point as Vector2)).y)
	return max_y


func _add_readable_boundary_blockers() -> void:
	var bounds := Rect2(Vector2.ZERO, layout.map_size)
	for spec in OUTDOOR_COLLISION.readable_boundary_specs(bounds):
		_add_blocker_rect(str(spec.get("name", "")), spec.get("rect", Rect2()), str(spec.get("source", "")))


func _add_blocker_rect(blocker_name: String, rect: Rect2, source: String) -> StaticBody2D:
	var body := OUTDOOR_COLLISION.add_blocker_rect(boundary_root, blocker_name, rect, source)
	boundary_collider_count += 1
	return body


func _add_route_marker(marker_name: String, marker_position: Vector2) -> void:
	var marker := Marker2D.new()
	marker.name = marker_name
	marker.position = marker_position
	add_child(marker)
	route_markers[marker_name] = marker


func _add_debug_label(text: String, position: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.7, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	debug_overlay_root.add_child(label)


func _find_zone_by_type(zone_type: String) -> Dictionary:
	for zone in layout.zones:
		if str(zone.get("type", "")) == zone_type:
			return zone
	return {}


func _spread_position(center: Vector2, index: int, count: int, radius: float) -> Vector2:
	if count <= 1:
		return center
	var angle := TAU * float(index) / float(count)
	return center + Vector2(cos(angle), sin(angle)) * radius


func _asset(asset_key: String) -> Texture2D:
	if asset_cache.has(asset_key):
		return asset_cache[asset_key]
	var slots: Dictionary = config_data.get("asset_slots", {})
	var path := str(slots.get(asset_key, ""))
	var texture := load(path) as Texture2D if not path.is_empty() and not path.begins_with("placeholder:") else null
	asset_cache[asset_key] = texture
	return texture


func _rect_from_payload(value) -> Rect2:
	if not (value is Dictionary):
		return Rect2()
	var data: Dictionary = value
	return Rect2(
		float(data.get("x", 0.0)),
		float(data.get("y", 0.0)),
		float(data.get("w", 0.0)),
		float(data.get("h", 0.0))
	)


func _vector_from_payload(value) -> Vector2:
	if not (value is Dictionary):
		return Vector2.ZERO
	var data: Dictionary = value
	return Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))


func _approx_collision_rect(foot_position: Vector2, collision: Dictionary) -> Rect2:
	var offset := _vector_from_payload(collision.get("offset", {}))
	match str(collision.get("shape", "")):
		"rect":
			var size := _size_from_payload(collision.get("size", {}))
			return Rect2(foot_position + offset - size * 0.5, size)
		"circle":
			var radius := float(collision.get("radius", 0.0))
			return Rect2(foot_position + offset - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0))
		"capsule":
			var radius := float(collision.get("radius", 0.0))
			var height := float(collision.get("height", radius * 2.0))
			if str(collision.get("orientation", "vertical")) == "horizontal":
				return Rect2(foot_position + offset - Vector2(height * 0.5, radius), Vector2(height, radius * 2.0))
			return Rect2(foot_position + offset - Vector2(radius, height * 0.5), Vector2(radius * 2.0, height))
	return Rect2(foot_position + offset - Vector2(16, 12), Vector2(32, 24))


func _size_from_payload(value) -> Vector2:
	if not (value is Dictionary):
		return Vector2.ZERO
	var data: Dictionary = value
	return Vector2(float(data.get("w", 0.0)), float(data.get("h", 0.0)))


func _make_atlas_texture(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	atlas.filter_clip = true
	return atlas
