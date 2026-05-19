extends "res://scripts/maps/combat_sandbox.gd"

const OUTDOOR_OBJECTIVE_PANEL_SCRIPT := preload("res://scripts/ui/outdoor_objective_panel.gd")
const CONFIG_SCRIPT := preload("res://scripts/maps/procedural/map_generation_config.gd")
const GENERATOR_SCRIPT := preload("res://scripts/maps/procedural/map_generator.gd")
const DEBUG_SCRIPT := preload("res://scripts/maps/procedural/map_generation_debug.gd")
const ITEM_DATABASE := preload("res://scripts/items/item_database.gd")
const OUTDOOR_COLLISION := preload("res://scripts/physics/outdoor_collision.gd")

const FIRST_OUTDOOR_CONFIG_PATH := "res://data/maps/first_outdoor_map.json"
const TILE_SIZE := 32
const CAMP_EXIT_MIN_DISTANCE := 290.0
const DUNGEON_ENTRANCE_RADIUS := 170.0
const OUTDOOR_CAMERA_ZOOM := Vector2(1.18, 1.18)
const OUTDOOR_PLAYER_SPRITE_SCALE := Vector2(1.9, 1.9)
const DEFAULT_PROP_SCALE := 1.45
const SMALL_PROP_SCALE := 1.25
const LARGE_PROP_SCALE := 1.75

@export var generation_seed := 24001

var map_config: MapGenerationConfig
var config_data := {}
var layout: GeneratedMapLayout
var validation_result := {}
var visuals_root: Node2D
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


func _ready() -> void:
	_load_first_outdoor_config()
	_generate_layout()
	_build_generated_world()
	super._ready()
	_apply_first_outdoor_runtime_scale()


func _process(_delta: float) -> void:
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
	visuals_root = Node2D.new()
	visuals_root.name = "FirstOutdoorVisuals"
	add_child(visuals_root)

	boundary_root = Node2D.new()
	boundary_root.name = "FirstOutdoorBlockers"
	add_child(boundary_root)

	props_root = Node2D.new()
	props_root.name = "FirstOutdoorProps"
	world_entities_root.add_child(props_root)

	debug_overlay_root = Node2D.new()
	debug_overlay_root.name = "FirstOutdoorDebugOverlay"
	debug_overlay_root.visible = false
	add_child(debug_overlay_root)

	_add_background_rect("OutdoorCanvas", Rect2(Vector2.ZERO, layout.map_size), Color(0.075, 0.09, 0.075, 1.0), -140)
	_add_layout_ground()
	_add_layout_boundaries()
	_add_layout_markers()
	_add_route_props()
	_add_debug_overlay()
	_place_player_at_spawn()


func _add_layout_ground() -> void:
	for corridor in layout.corridors:
		var rect: Rect2 = corridor.get("rect", Rect2())
		_add_tiled_rect(rect.grow(28.0), _asset("ground_tileset"), Rect2(32, 0, TILE_SIZE, TILE_SIZE), str(corridor.get("id", "")))
	for zone in layout.zones:
		var rect: Rect2 = zone.get("rect", Rect2())
		var zone_type := str(zone.get("type", ""))
		var color := Color(0.115, 0.13, 0.095, 0.98)
		if zone_type == "start":
			color = Color(0.14, 0.13, 0.095, 1.0)
		elif zone_type == "required_branch":
			color = Color(0.095, 0.105, 0.08, 1.0)
		elif zone_type == "elite_pressure":
			color = Color(0.105, 0.09, 0.075, 1.0)
		elif zone_type == "required_exit":
			color = Color(0.09, 0.105, 0.088, 1.0)
		_add_background_rect("Zone_%s" % str(zone.get("id", "")), rect, color, -125)
		if zone_type == "required_branch" or zone_type == "elite_pressure":
			_add_tiled_rect(rect.grow(-32.0), _asset("corrupted_ground"), Rect2(0, 0, TILE_SIZE, TILE_SIZE), "Corrupted_%s" % str(zone.get("id", "")))


func _add_layout_boundaries() -> void:
	for blocker in layout.blockers:
		var rect: Rect2 = blocker.get("rect", Rect2())
		_add_blocker_rect(str(blocker.get("id", "")), rect, str(blocker.get("source", "")))
	for visual in layout.boundary_visuals:
		var rect: Rect2 = visual.get("rect", Rect2())
		_add_background_rect(str(visual.get("id", "")), rect, Color(0.045, 0.065, 0.045, 1.0), -132)
		boundary_visual_count += 1


func _add_layout_markers() -> void:
	var start_zone := _find_zone_by_type("start")
	var start_anchor := layout.find_anchor_by_type("start")
	var spawn_position: Vector2 = start_anchor.get("position", start_zone.get("rect", Rect2()).get_center())
	_add_route_marker("CampSpawn", spawn_position)

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

	_add_prop_with_blocker("CampGate", "camp_gate", start_rect.get_center() + Vector2(0, start_rect.size.y * 0.32), LARGE_PROP_SCALE, "camp_gate", 0.86)
	_add_prop_with_blocker("CampSignpost", "route_sign_or_scout_marker", start_rect.get_center() + Vector2(start_rect.size.x * 0.32, start_rect.size.y * 0.22), DEFAULT_PROP_SCALE, "route_sign", 0.7)

	_add_edge_props_for_zone(first_rect, "FirstContact")
	_add_prop_with_blocker("BrokenCart", "broken_cart", road_rect.get_center() + Vector2(road_rect.size.x * 0.24, -road_rect.size.y * 0.14), DEFAULT_PROP_SCALE, "broken_cart", 0.82)
	_add_prop_with_blocker("RoadRockA", "rock_a", road_rect.get_center() + Vector2(-road_rect.size.x * 0.34, road_rect.size.y * 0.22), SMALL_PROP_SCALE, "rock", 0.9)
	_add_prop_with_blocker("RoadRockB", "rock_b", road_rect.get_center() + Vector2(road_rect.size.x * 0.36, road_rect.size.y * 0.24), SMALL_PROP_SCALE, "rock", 0.9)

	_add_prop_with_blocker("ForkSignpost", "route_sign_or_scout_marker", fork_rect.get_center() + Vector2(-fork_rect.size.x * 0.18, -fork_rect.size.y * 0.22), DEFAULT_PROP_SCALE, "route_sign", 0.7)
	_add_prop_with_blocker("ForkFenceA", "broken_fence_a", fork_rect.get_center() + Vector2(-fork_rect.size.x * 0.42, fork_rect.size.y * 0.18), DEFAULT_PROP_SCALE, "broken_fence", 0.88)
	_add_prop_with_blocker("ForkFenceB", "broken_fence_b", fork_rect.get_center() + Vector2(fork_rect.size.x * 0.38, -fork_rect.size.y * 0.12), DEFAULT_PROP_SCALE, "broken_fence", 0.88)

	if pocket_rect.size != Vector2.ZERO:
		_add_prop_with_blocker("OptionalShrine", "shrine_or_loot_marker", pocket_rect.get_center(), LARGE_PROP_SCALE, "shrine", 0.9)
		_add_edge_props_for_zone(pocket_rect, "OptionalPocket")

	_add_prop_with_blocker("CorruptedHollow", "dungeon_entrance", branch_rect.get_center(), 1.95, "dungeon_entrance", 0.9)
	_add_prop_with_blocker("HollowRootA", "corrupted_root_a", branch_rect.get_center() + Vector2(-branch_rect.size.x * 0.32, branch_rect.size.y * 0.25), LARGE_PROP_SCALE, "corrupted_root", 0.82)
	_add_prop_with_blocker("HollowRootB", "corrupted_root_b", branch_rect.get_center() + Vector2(branch_rect.size.x * 0.32, branch_rect.size.y * 0.24), LARGE_PROP_SCALE, "corrupted_root", 0.82)

	_add_edge_props_for_zone(pressure_rect, "Pressure")
	_add_prop_with_blocker("PressureRootsA", "corrupted_root_a", pressure_rect.get_center() + Vector2(-pressure_rect.size.x * 0.34, 0), DEFAULT_PROP_SCALE, "corrupted_root", 0.82)
	_add_prop_with_blocker("PressureRootsB", "corrupted_root_b", pressure_rect.get_center() + Vector2(pressure_rect.size.x * 0.34, 0), DEFAULT_PROP_SCALE, "corrupted_root", 0.82)

	_add_prop_with_blocker("NextExitSign", "route_sign_or_scout_marker", exit_rect.get_center() + Vector2(-exit_rect.size.x * 0.22, -exit_rect.size.y * 0.18), DEFAULT_PROP_SCALE, "soft_gate_sign", 0.7)
	_add_prop_with_blocker("NextExitRoots", "corrupted_root_b", exit_rect.get_center() + Vector2(exit_rect.size.x * 0.2, exit_rect.size.y * 0.2), LARGE_PROP_SCALE, "soft_gate_roots", 0.82)

	_add_outer_soft_boundary_props()
	_add_readable_boundary_blockers()


func _add_edge_props_for_zone(rect: Rect2, prefix: String) -> void:
	if rect.size == Vector2.ZERO:
		return
	_add_prop_with_blocker("%sTreeA" % prefix, "dead_tree_a", rect.position + Vector2(70, rect.size.y * 0.5), DEFAULT_PROP_SCALE, "dead_tree", 0.72)
	_add_prop_with_blocker("%sTreeB" % prefix, "dead_tree_b", Vector2(rect.end.x - 72, rect.position.y + rect.size.y * 0.42), DEFAULT_PROP_SCALE, "dead_tree", 0.72)
	_add_prop_with_blocker("%sRockA" % prefix, "rock_a", rect.position + Vector2(rect.size.x * 0.22, rect.size.y - 58), SMALL_PROP_SCALE, "rock", 0.9)


func _add_outer_soft_boundary_props() -> void:
	var bounds := Rect2(Vector2.ZERO, layout.map_size)
	var step := 210
	var top_y := 74.0
	var bottom_y := layout.map_size.y - 74.0
	for x in range(260, int(layout.map_size.x - 180), step):
		var top_asset := "dead_tree_a" if (x / step) % 2 == 0 else "broken_fence_a"
		var bottom_asset := "corrupted_root_a" if x > layout.map_size.x * 0.35 and x < layout.map_size.x * 0.65 else "dead_tree_b"
		_add_prop_with_blocker("BoundaryTop%d" % x, top_asset, Vector2(x, top_y), DEFAULT_PROP_SCALE, "boundary_prop", 0.76)
		_add_prop_with_blocker("BoundaryBottom%d" % x, bottom_asset, Vector2(x, bottom_y), DEFAULT_PROP_SCALE, "boundary_prop", 0.76)
	for y in range(360, int(layout.map_size.y - 260), step):
		var left_asset := "dead_tree_a" if (y / step) % 2 == 0 else "rock_a"
		var right_asset := "dead_tree_b" if (y / step) % 2 == 0 else "rock_b"
		_add_prop_with_blocker("BoundaryLeft%d" % y, left_asset, Vector2(74, y), DEFAULT_PROP_SCALE, "boundary_prop", 0.76)
		_add_prop_with_blocker("BoundaryRight%d" % y, right_asset, Vector2(layout.map_size.x - 74, y), DEFAULT_PROP_SCALE, "boundary_prop", 0.76)


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


func get_dungeon_entrance_position() -> Vector2:
	return dungeon_entrance_position


func get_playable_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, layout.map_size)


func get_generated_payload() -> Dictionary:
	return layout.to_payload() if layout != null else {}


func get_validation_result() -> Dictionary:
	return validation_result.duplicate(true)


func get_generation_seed() -> int:
	return generation_seed


func get_boundary_collider_count() -> int:
	return boundary_collider_count


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


func _add_background_rect(rect_name: String, rect: Rect2, color: Color, z_index: int) -> ColorRect:
	var color_rect := ColorRect.new()
	color_rect.name = rect_name
	color_rect.position = rect.position
	color_rect.size = rect.size
	color_rect.color = color
	color_rect.z_index = z_index
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visuals_root.add_child(color_rect)
	return color_rect


func _add_tiled_rect(rect: Rect2, texture: Texture2D, region: Rect2, node_name: String) -> void:
	if texture == null:
		_add_background_rect("TileFallback_%s" % node_name, rect, Color(0.16, 0.14, 0.1, 1.0), -118)
		return
	var tile_root := Node2D.new()
	tile_root.name = node_name
	tile_root.z_index = -112
	visuals_root.add_child(tile_root)
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
			tile_root.add_child(tile)


func _add_prop_with_blocker(prop_name: String, asset_key: String, prop_position: Vector2, prop_scale: float, blocker_source: String, blocker_ratio: float) -> Sprite2D:
	var texture := _asset(asset_key)
	var prop := Sprite2D.new()
	prop.name = prop_name
	prop.texture = texture
	prop.position = prop_position
	prop.scale = Vector2(prop_scale, prop_scale)
	prop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	props_root.add_child(prop)

	var collision_rects := OUTDOOR_COLLISION.prop_collision_rects(texture, prop_position, prop_scale, asset_key, blocker_source, blocker_ratio)
	var visual_rect: Rect2 = collision_rects.get("visual_rect", Rect2())
	var blocker_rect: Rect2 = collision_rects.get("blocker_rect", Rect2())
	_add_blocker_rect("%sBlocker" % prop_name, blocker_rect, blocker_source)
	prop_blocker_count += 1
	prop_visual_rects[prop_name] = visual_rect
	prop_blocker_rects["%sBlocker" % prop_name] = blocker_rect
	prop_blocker_sources["%sBlocker" % prop_name] = blocker_source
	return prop


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


func _make_atlas_texture(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	atlas.filter_clip = true
	return atlas
