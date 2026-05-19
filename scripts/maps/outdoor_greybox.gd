extends "res://scripts/maps/combat_sandbox.gd"

const OUTDOOR_OBJECTIVE_PANEL_SCRIPT := preload("res://scripts/ui/outdoor_objective_panel.gd")
const OUTDOOR_MUMMY_SCENE := preload("res://scenes/enemy/mummy_enemy.tscn")
const OUTDOOR_COLLISION := preload("res://scripts/physics/outdoor_collision.gd")
const OUTDOOR_TILESET := preload("res://assets/sprites/tiles/outdoor_01/tileset_outdoor01_ground_32.png")
const CORRUPTED_GROUND := preload("res://assets/sprites/tiles/outdoor_01/tile_outdoor01_corrupted_ground_32.png")
const PROP_BROKEN_CART := preload("res://assets/sprites/props/outdoor_01/prop_outdoor01_broken_cart_96.png")
const PROP_BROKEN_FENCE_A := preload("res://assets/sprites/props/outdoor_01/prop_outdoor01_broken_fence_64_a.png")
const PROP_BROKEN_FENCE_B := preload("res://assets/sprites/props/outdoor_01/prop_outdoor01_broken_fence_64_b.png")
const PROP_CAMP_GATE := preload("res://assets/sprites/props/outdoor_01/prop_outdoor01_camp_gate_128.png")
const PROP_CORRUPTED_HOLLOW := preload("res://assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_hollow_128.png")
const PROP_CORRUPTED_ROOTS_A := preload("res://assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_roots_64_a.png")
const PROP_CORRUPTED_ROOTS_B := preload("res://assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_roots_64_b.png")
const PROP_DEAD_TREE_A := preload("res://assets/sprites/props/outdoor_01/prop_outdoor01_dead_tree_64_a.png")
const PROP_DEAD_TREE_B := preload("res://assets/sprites/props/outdoor_01/prop_outdoor01_dead_tree_64_b.png")
const PROP_ROCK_A := preload("res://assets/sprites/props/outdoor_01/prop_outdoor01_rock_small_32_a.png")
const PROP_ROCK_B := preload("res://assets/sprites/props/outdoor_01/prop_outdoor01_rock_small_32_b.png")
const PROP_SHRINE := preload("res://assets/sprites/props/outdoor_01/prop_outdoor01_shrine_96.png")
const PROP_SIGNPOST := preload("res://assets/sprites/props/outdoor_01/prop_outdoor01_signpost_64.png")

const TILE_SIZE := 32
const MAP_BOUNDS := Rect2(180, 120, 2200, 2760)
const CAMP_EXIT_Y := 580.0
const BOUNDARY_THICKNESS := 96.0
const DUNGEON_ENTRANCE_RADIUS := 150.0
const DUNGEON_ENTRANCE_POSITION := Vector2(1220, 2600)
const OUTDOOR_CAMERA_ZOOM := Vector2(1.28, 1.28)
const OUTDOOR_PLAYER_SPRITE_SCALE := Vector2(1.9, 1.9)
const DEFAULT_PROP_SCALE := 1.45
const SMALL_PROP_SCALE := 1.25
const LARGE_PROP_SCALE := 1.65

var route_markers := {}
var route_spawned := false
var visuals_root: Node2D
var props_root: Node2D
var boundary_root: Node2D
var boundary_visual_count := 0
var boundary_collider_count := 0
var prop_blocker_count := 0
var prop_visual_rects := {}
var prop_blocker_rects := {}


func _ready() -> void:
	_build_outdoor_world()
	super._ready()
	_apply_outdoor_runtime_scale()


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

	_spawn_outdoor_mummy("TrainingThrallA", "outdoor_training", Vector2(1110, 735), 30, 38.0, 5, 44.0, 40.0, 1.3, 1.6, 8, false)
	_spawn_outdoor_mummy("TrainingThrallB", "outdoor_training", Vector2(1360, 790), 30, 38.0, 5, 44.0, 40.0, 1.3, 1.6, 8, false)

	_spawn_outdoor_mummy("RoadPatrol", "outdoor_road", Vector2(1500, 1085), 36, 44.0, 6, 46.0, 42.0, 1.2, 1.7, 8, false)

	_spawn_outdoor_mummy("LootClearingGuard", "outdoor_loot", Vector2(920, 1370), 38, 46.0, 7, 48.0, 42.0, 1.18, 1.7, 8, false)
	_spawn_outdoor_mummy("FirstLootCaptain", "outdoor_loot", Vector2(1135, 1495), 48, 48.0, 8, 50.0, 44.0, 1.15, 1.85, 14, true)

	_spawn_outdoor_mummy("ShrineThrallA", "outdoor_shrine", Vector2(1635, 1760), 42, 50.0, 8, 50.0, 44.0, 1.12, 1.75, 8, false)
	_spawn_outdoor_mummy("ShrineThrallB", "outdoor_shrine", Vector2(1825, 1875), 42, 50.0, 8, 50.0, 44.0, 1.12, 1.75, 8, false)

	_spawn_outdoor_mummy("EntranceThrallA", "outdoor_entrance", Vector2(1188, 2330), 48, 54.0, 10, 52.0, 44.0, 1.08, 1.8, 8, false)
	_spawn_outdoor_mummy("EntranceThrallB", "outdoor_entrance", Vector2(1325, 2365), 48, 54.0, 10, 52.0, 44.0, 1.08, 1.8, 8, false)
	_spawn_outdoor_mummy("HollowGuard", "outdoor_entrance", Vector2(1238, 2415), 110, 48.0, 18, 60.0, 50.0, 1.32, 2.15, 18, false)


func _spawn_outdoor_mummy(
	enemy_name: String,
	encounter_group: String,
	spawn_position: Vector2,
	max_hp: int,
	move_speed: float,
	attack_damage: int,
	attack_range: float,
	preferred_distance: float,
	attack_cooldown: float,
	display_scale: float,
	xp_reward: int,
	drops_loot: bool
) -> Node2D:
	var enemy := OUTDOOR_MUMMY_SCENE.instantiate()
	enemy.name = enemy_name
	enemy.global_position = spawn_position
	enemy.max_hp = max_hp
	enemy.move_speed = move_speed
	enemy.attack_damage = attack_damage
	enemy.attack_range = attack_range
	enemy.preferred_distance = preferred_distance
	enemy.attack_cooldown = attack_cooldown
	enemy.display_scale = display_scale
	enemy.xp_reward = xp_reward
	enemy.drops_loot = drops_loot
	OUTDOOR_COLLISION.apply_enemy_body(enemy)
	enemy.add_to_group(encounter_group)
	get_world_item_parent().add_child(enemy)
	return enemy


func _build_outdoor_world() -> void:
	visuals_root = Node2D.new()
	visuals_root.name = "OutdoorVisuals"
	add_child(visuals_root)

	boundary_root = Node2D.new()
	boundary_root.name = "OutdoorBoundary"
	add_child(boundary_root)

	props_root = Node2D.new()
	props_root.name = "RouteProps"
	world_entities_root.add_child(props_root)

	_add_background_rect("OutdoorGround", MAP_BOUNDS, Color(0.11, 0.125, 0.095, 1.0), -130)
	_add_background_rect("OuterTreeMassNorth", Rect2(MAP_BOUNDS.position.x, MAP_BOUNDS.position.y, MAP_BOUNDS.size.x, 170), Color(0.055, 0.078, 0.06, 1.0), -128)
	_add_background_rect("OuterTreeMassSouth", Rect2(MAP_BOUNDS.position.x, MAP_BOUNDS.end.y - 220, MAP_BOUNDS.size.x, 220), Color(0.045, 0.06, 0.05, 1.0), -128)
	_add_background_rect("OuterTreeMassWest", Rect2(MAP_BOUNDS.position.x, MAP_BOUNDS.position.y, 150, MAP_BOUNDS.size.y), Color(0.052, 0.07, 0.055, 1.0), -128)
	_add_background_rect("OuterTreeMassEast", Rect2(MAP_BOUNDS.end.x - 150, MAP_BOUNDS.position.y, 150, MAP_BOUNDS.size.y), Color(0.052, 0.07, 0.055, 1.0), -128)

	_add_background_rect("CampSafeGround", Rect2(880, 170, 690, 420), Color(0.15, 0.13, 0.095, 1.0), -124)
	_add_background_rect("TrainingFieldGround", Rect2(930, 610, 620, 340), Color(0.125, 0.14, 0.105, 1.0), -124)
	_add_background_rect("LootClearingGround", Rect2(700, 1240, 740, 460), Color(0.12, 0.128, 0.088, 1.0), -124)
	_add_background_rect("ShrineForkGround", Rect2(1450, 1650, 560, 420), Color(0.098, 0.105, 0.082, 1.0), -124)

	_add_tiled_rect(Rect2(930, 300, 570, 250), OUTDOOR_TILESET, Rect2(32, 0, TILE_SIZE, TILE_SIZE), "CampRoad")
	_add_tiled_rect(Rect2(1080, 520, 300, 540), OUTDOOR_TILESET, Rect2(32, 0, TILE_SIZE, TILE_SIZE), "NorthRoad")
	_add_tiled_rect(Rect2(1070, 1020, 610, 210), OUTDOOR_TILESET, Rect2(32, 0, TILE_SIZE, TILE_SIZE), "BrokenRoad")
	_add_tiled_rect(Rect2(760, 1300, 650, 270), OUTDOOR_TILESET, Rect2(32, 0, TILE_SIZE, TILE_SIZE), "FirstLootClearingRoad")
	_add_tiled_rect(Rect2(1360, 1480, 310, 420), OUTDOOR_TILESET, Rect2(32, 0, TILE_SIZE, TILE_SIZE), "ShrineForkRoad")
	_add_tiled_rect(Rect2(1090, 1880, 280, 420), OUTDOOR_TILESET, Rect2(32, 0, TILE_SIZE, TILE_SIZE), "EntranceRoad")
	_add_tiled_rect(Rect2(840, 2200, 760, 440), CORRUPTED_GROUND, Rect2(0, 0, TILE_SIZE, TILE_SIZE), "CorruptedEntranceGround")

	_add_boundary_colliders()
	_add_outer_boundary_visuals()
	_add_route_markers()
	_add_route_props()


func _add_route_markers() -> void:
	_add_route_marker("CampGate", Vector2(1220, 430))
	_add_route_marker("TrainingVerge", Vector2(1235, 780))
	_add_route_marker("BrokenRoad", Vector2(1510, 1110))
	_add_route_marker("FirstLootClearing", Vector2(1040, 1450))
	_add_route_marker("ShrineFork", Vector2(1700, 1820))
	_add_route_marker("EntranceApproach", Vector2(1220, 2260))
	_add_route_marker("CorruptedHollowEntrance", DUNGEON_ENTRANCE_POSITION)


func _add_route_props() -> void:
	_add_prop_with_blocker("CampGate", PROP_CAMP_GATE, Vector2(1220, 335), LARGE_PROP_SCALE, "camp_gate", 0.86)
	_add_prop_with_blocker("CampSignpost", PROP_SIGNPOST, Vector2(1455, 505), DEFAULT_PROP_SCALE, "route_sign", 0.7)
	_add_prop_with_blocker("BrokenCart", PROP_BROKEN_CART, Vector2(1515, 1055), DEFAULT_PROP_SCALE, "broken_cart", 0.82)
	_add_prop_with_blocker("Shrine", PROP_SHRINE, Vector2(1730, 1670), LARGE_PROP_SCALE, "shrine", 0.9)
	_add_prop_with_blocker("CorruptedHollow", PROP_CORRUPTED_HOLLOW, DUNGEON_ENTRANCE_POSITION, 1.95, "dungeon_entrance", 0.9)

	_add_prop_with_blocker("CampFenceWest", PROP_BROKEN_FENCE_A, Vector2(875, 515), DEFAULT_PROP_SCALE, "broken_fence", 0.88)
	_add_prop_with_blocker("CampFenceEast", PROP_BROKEN_FENCE_B, Vector2(1575, 515), DEFAULT_PROP_SCALE, "broken_fence", 0.88)
	_add_prop_with_blocker("TrainingTreeA", PROP_DEAD_TREE_A, Vector2(910, 735), DEFAULT_PROP_SCALE, "dead_tree", 0.72)
	_add_prop_with_blocker("TrainingTreeB", PROP_DEAD_TREE_B, Vector2(1545, 875), DEFAULT_PROP_SCALE, "dead_tree", 0.72)
	_add_prop_with_blocker("RoadRockA", PROP_ROCK_A, Vector2(1040, 980), SMALL_PROP_SCALE, "rock", 0.9)
	_add_prop_with_blocker("RoadRockB", PROP_ROCK_B, Vector2(1710, 1190), SMALL_PROP_SCALE, "rock", 0.9)
	_add_prop_with_blocker("LootTreeA", PROP_DEAD_TREE_A, Vector2(675, 1340), DEFAULT_PROP_SCALE, "dead_tree", 0.72)
	_add_prop_with_blocker("LootTreeB", PROP_DEAD_TREE_B, Vector2(1435, 1580), DEFAULT_PROP_SCALE, "dead_tree", 0.72)
	_add_prop_with_blocker("LootRockA", PROP_ROCK_A, Vector2(820, 1630), SMALL_PROP_SCALE, "rock", 0.9)
	_add_prop_with_blocker("LootRockB", PROP_ROCK_B, Vector2(1370, 1285), SMALL_PROP_SCALE, "rock", 0.9)
	_add_prop_with_blocker("ShrineRootsA", PROP_CORRUPTED_ROOTS_A, Vector2(1540, 1955), DEFAULT_PROP_SCALE, "corrupted_root", 0.82)
	_add_prop_with_blocker("ShrineRootsB", PROP_CORRUPTED_ROOTS_B, Vector2(1935, 1890), DEFAULT_PROP_SCALE, "corrupted_root", 0.82)
	_add_prop_with_blocker("EntranceRootsA", PROP_CORRUPTED_ROOTS_A, Vector2(1005, 2475), LARGE_PROP_SCALE, "corrupted_root", 0.82)
	_add_prop_with_blocker("EntranceRootsB", PROP_CORRUPTED_ROOTS_B, Vector2(1475, 2460), LARGE_PROP_SCALE, "corrupted_root", 0.82)
	_add_prop_with_blocker("EntranceDeadTreeA", PROP_DEAD_TREE_A, Vector2(865, 2260), DEFAULT_PROP_SCALE, "dead_tree", 0.72)
	_add_prop_with_blocker("EntranceDeadTreeB", PROP_DEAD_TREE_B, Vector2(1600, 2255), DEFAULT_PROP_SCALE, "dead_tree", 0.72)


func _add_outer_boundary_visuals() -> void:
	var left_x := MAP_BOUNDS.position.x + 62.0
	var right_x := MAP_BOUNDS.end.x - 62.0
	var top_y := MAP_BOUNDS.position.y + 68.0
	var bottom_y := MAP_BOUNDS.end.y - 70.0
	for x in range(int(MAP_BOUNDS.position.x + 160), int(MAP_BOUNDS.end.x - 120), 145):
		var top_texture := PROP_BROKEN_FENCE_A if (x / 145) % 2 == 0 else PROP_DEAD_TREE_A
		var bottom_texture := PROP_CORRUPTED_ROOTS_A if x > 900 and x < 1600 else PROP_DEAD_TREE_B
		_add_boundary_prop("BoundaryTop%d" % x, top_texture, Vector2(x, top_y), DEFAULT_PROP_SCALE)
		_add_boundary_prop("BoundaryBottom%d" % x, bottom_texture, Vector2(x, bottom_y), DEFAULT_PROP_SCALE)
	for y in range(int(MAP_BOUNDS.position.y + 220), int(MAP_BOUNDS.end.y - 180), 155):
		var left_texture := PROP_DEAD_TREE_A if (y / 155) % 2 == 0 else PROP_ROCK_A
		var right_texture := PROP_DEAD_TREE_B if (y / 155) % 2 == 0 else PROP_ROCK_B
		_add_boundary_prop("BoundaryLeft%d" % y, left_texture, Vector2(left_x, y), DEFAULT_PROP_SCALE)
		_add_boundary_prop("BoundaryRight%d" % y, right_texture, Vector2(right_x, y), DEFAULT_PROP_SCALE)


func _add_boundary_colliders() -> void:
	_add_blocker_rect("BoundaryTop", Rect2(MAP_BOUNDS.position.x - BOUNDARY_THICKNESS, MAP_BOUNDS.position.y - BOUNDARY_THICKNESS, MAP_BOUNDS.size.x + BOUNDARY_THICKNESS * 2.0, BOUNDARY_THICKNESS))
	_add_blocker_rect("BoundaryBottom", Rect2(MAP_BOUNDS.position.x - BOUNDARY_THICKNESS, MAP_BOUNDS.end.y, MAP_BOUNDS.size.x + BOUNDARY_THICKNESS * 2.0, BOUNDARY_THICKNESS))
	_add_blocker_rect("BoundaryLeft", Rect2(MAP_BOUNDS.position.x - BOUNDARY_THICKNESS, MAP_BOUNDS.position.y - BOUNDARY_THICKNESS, BOUNDARY_THICKNESS, MAP_BOUNDS.size.y + BOUNDARY_THICKNESS * 2.0))
	_add_blocker_rect("BoundaryRight", Rect2(MAP_BOUNDS.end.x, MAP_BOUNDS.position.y - BOUNDARY_THICKNESS, BOUNDARY_THICKNESS, MAP_BOUNDS.size.y + BOUNDARY_THICKNESS * 2.0))
	for spec in OUTDOOR_COLLISION.readable_boundary_specs(MAP_BOUNDS):
		_add_blocker_rect(str(spec.get("name", "")), spec.get("rect", Rect2()), str(spec.get("source", "")))


func _add_blocker_rect(blocker_name: String, rect: Rect2, source: String = "") -> void:
	OUTDOOR_COLLISION.add_blocker_rect(boundary_root, blocker_name, rect, source)
	boundary_collider_count += 1


func _add_prop_with_blocker(
	prop_name: String,
	texture: Texture2D,
	prop_position: Vector2,
	prop_scale: float,
	blocker_source: String,
	blocker_ratio: float
) -> Sprite2D:
	var prop := _add_prop(prop_name, texture, prop_position, prop_scale)
	var collision_rects := OUTDOOR_COLLISION.prop_collision_rects(texture, prop_position, prop_scale, blocker_source, blocker_source, blocker_ratio)
	var visual_rect: Rect2 = collision_rects.get("visual_rect", Rect2())
	var blocker_rect: Rect2 = collision_rects.get("blocker_rect", Rect2())
	_add_blocker_rect("%sBlocker" % prop_name, blocker_rect, blocker_source)
	prop_blocker_count += 1
	prop_visual_rects[prop_name] = visual_rect
	prop_blocker_rects["%sBlocker" % prop_name] = blocker_rect
	return prop


func _add_route_marker(marker_name: String, marker_position: Vector2) -> void:
	var marker := Marker2D.new()
	marker.name = marker_name
	marker.position = marker_position
	add_child(marker)
	route_markers[marker_name] = marker


func _add_background_rect(rect_name: String, rect: Rect2, color: Color, z_index: int) -> void:
	var color_rect := ColorRect.new()
	color_rect.name = rect_name
	color_rect.position = rect.position
	color_rect.size = rect.size
	color_rect.color = color
	color_rect.z_index = z_index
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visuals_root.add_child(color_rect)


func _add_tiled_rect(rect: Rect2, texture: Texture2D, region: Rect2, node_name: String) -> void:
	var tile_root := Node2D.new()
	tile_root.name = node_name
	tile_root.z_index = -110
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


func _add_prop(prop_name: String, texture: Texture2D, prop_position: Vector2, prop_scale: float = DEFAULT_PROP_SCALE) -> Sprite2D:
	var prop := Sprite2D.new()
	prop.name = prop_name
	prop.texture = texture
	prop.position = prop_position
	prop.scale = Vector2(prop_scale, prop_scale)
	prop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	props_root.add_child(prop)
	return prop


func _add_boundary_prop(prop_name: String, texture: Texture2D, prop_position: Vector2, prop_scale: float = DEFAULT_PROP_SCALE) -> void:
	var prop := _add_prop(prop_name, texture, prop_position, prop_scale)
	prop.modulate = Color(0.82, 0.88, 0.78, 1.0)
	boundary_visual_count += 1


func _make_atlas_texture(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	atlas.filter_clip = true
	return atlas


func _apply_outdoor_runtime_scale() -> void:
	if not is_instance_valid(player):
		return
	OUTDOOR_COLLISION.apply_player_body(player)
	var sprite := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite != null:
		sprite.scale = OUTDOOR_PLAYER_SPRITE_SCALE
	var hp_bar := player.get_node_or_null("HPBar") as ProgressBar
	if hp_bar != null:
		hp_bar.offset_left = -34.0
		hp_bar.offset_top = -94.0
		hp_bar.offset_right = 34.0
		hp_bar.offset_bottom = -84.0
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.zoom = OUTDOOR_CAMERA_ZOOM
		camera.limit_left = int(MAP_BOUNDS.position.x)
		camera.limit_top = int(MAP_BOUNDS.position.y)
		camera.limit_right = int(MAP_BOUNDS.end.x)
		camera.limit_bottom = int(MAP_BOUNDS.end.y)


func has_player_left_camp() -> bool:
	return is_instance_valid(player) and player.global_position.y >= CAMP_EXIT_Y


func is_encounter_group_cleared(group_name: String) -> bool:
	for enemy in get_tree().get_nodes_in_group(group_name):
		if is_instance_valid(enemy) and not bool(enemy.get("dead")):
			return false
	return true


func is_dungeon_entrance_reached() -> bool:
	return is_instance_valid(player) and player.global_position.distance_to(DUNGEON_ENTRANCE_POSITION) <= DUNGEON_ENTRANCE_RADIUS


func get_route_marker_position(marker_name: String) -> Vector2:
	var marker: Marker2D = route_markers.get(marker_name, null)
	return marker.global_position if marker != null else Vector2.ZERO


func get_dungeon_entrance_position() -> Vector2:
	return DUNGEON_ENTRANCE_POSITION


func get_playable_bounds() -> Rect2:
	return MAP_BOUNDS


func get_boundary_collider_count() -> int:
	return boundary_collider_count


func get_boundary_visual_count() -> int:
	return boundary_visual_count


func get_prop_blocker_count() -> int:
	return prop_blocker_count


func get_prop_blocker_rects() -> Dictionary:
	return prop_blocker_rects.duplicate()


func get_prop_visual_rects() -> Dictionary:
	return prop_visual_rects.duplicate()


func get_camp_north_readable_limit_y() -> float:
	return MAP_BOUNDS.position.y + OUTDOOR_COLLISION.READABLE_BOUNDARY_THICKNESS


func get_outdoor_camera_zoom() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	return camera.zoom if camera != null else Vector2.ZERO


func get_player_visual_scale() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO
	var sprite := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	return sprite.scale if sprite != null else Vector2.ZERO
