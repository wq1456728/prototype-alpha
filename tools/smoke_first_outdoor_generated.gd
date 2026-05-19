extends SceneTree

const CONFIG_SCRIPT := preload("res://scripts/maps/procedural/map_generation_config.gd")
const GENERATOR_SCRIPT := preload("res://scripts/maps/procedural/map_generator.gd")
const DEBUG_SCRIPT := preload("res://scripts/maps/procedural/map_generation_debug.gd")

const SCENE_PATH := "res://scenes/maps/first_outdoor_generated.tscn"
const CONFIG_PATH := "res://data/maps/first_outdoor_map.json"
const TEST_SEEDS := [24001, 24002, 24003]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var config := CONFIG_SCRIPT.from_json_file(CONFIG_PATH)
	for seed_value in TEST_SEEDS:
		var seed := int(seed_value)
		var layout: GeneratedMapLayout = GENERATOR_SCRIPT.generate(config, seed)
		var validation := DEBUG_SCRIPT.validate_layout(layout)
		if not bool(validation.get("ok", false)):
			_fail("layout_validate seed=%d errors=%s" % [seed, validation.get("errors", [])])
			return
		var payload := layout.to_payload()
		for zone_type in ["start", "first_contact", "fork", "required_branch", "elite_pressure", "required_exit"]:
			if not _payload_has_zone_type(payload, zone_type):
				_fail("seed=%d missing_zone_type=%s" % [seed, zone_type])
				return

	var error := change_scene_to_file(SCENE_PATH)
	if error != OK:
		_fail("scene_load=%s" % error)
		return
	if not await _wait_for_scene():
		_fail("scene_not_ready")
		return

	if not await _validate_scene_structure(current_scene):
		return
	if not await _validate_first_weapon_loop(current_scene):
		return

	print("FirstOutdoorGenerated smoke: PASS seeds=%s enemies=%d props=%d blockers=%d loot=%d" % [
		str(TEST_SEEDS),
		get_nodes_in_group("enemy").size(),
		current_scene.get_node("WorldEntities/FirstOutdoorProps").get_child_count(),
		int(current_scene.call("get_boundary_collider_count")),
		get_nodes_in_group("loot").size(),
	])
	quit(0)


func _validate_scene_structure(scene: Node) -> bool:
	var validation: Dictionary = scene.call("get_validation_result")
	if not bool(validation.get("ok", false)):
		_fail("scene_validation errors=%s" % validation.get("errors", []))
		return false
	var payload: Dictionary = scene.call("get_generated_payload")
	if not _payload_has_zone_type(payload, "required_branch") or not _payload_has_zone_type(payload, "elite_pressure"):
		_fail("scene_payload_missing_required_zone")
		return false
	for marker_name in ["CampSpawn", "FirstContact", "RoadFork", "DungeonEntrance", "ElitePressure", "NextAreaExit"]:
		if scene.call("get_route_marker_position", marker_name) == Vector2.ZERO:
			_fail("missing_route_marker=%s" % marker_name)
			return false
	if int(scene.call("get_first_contact_enemy_count")) != 3:
		_fail("first_contact_enemy_count=%d" % int(scene.call("get_first_contact_enemy_count")))
		return false
	if float(scene.call("get_spawn_distance_to_first_contact")) < 620.0:
		_fail("first_contact_too_close distance=%.1f" % float(scene.call("get_spawn_distance_to_first_contact")))
		return false
	if float(scene.call("get_dungeon_branch_distance_to_spawn")) < 1000.0:
		_fail("dungeon_branch_too_close distance=%.1f" % float(scene.call("get_dungeon_branch_distance_to_spawn")))
		return false
	if int(scene.call("get_boundary_collider_count")) < int(scene.call("get_boundary_visual_count")):
		_fail("boundary_colliders_less_than_visuals")
		return false
	if int(scene.call("get_prop_blocker_count")) < 18:
		_fail("prop_blocker_count_too_low=%d" % int(scene.call("get_prop_blocker_count")))
		return false
	var object_validation: Dictionary = scene.call("get_object_definition_validation")
	if not bool(object_validation.get("ok", false)):
		_fail("object_definition_validation errors=%s" % object_validation.get("errors", []))
		return false
	if not _validate_placed_objects(scene):
		return false
	if not _validate_boundary_pass_payload(scene):
		return false
	if not _validate_prop_collision_fit(scene):
		return false
	if not _validate_collision_layers(scene):
		return false
	if not _validate_boundary_does_not_use_large_readable_rects(scene):
		return false
	if not await _validate_boundary_contour_blocks(scene):
		return false
	if not _validate_enemy_soft_collision_ignores_player():
		return false
	var loadout_bar := scene.get_node_or_null("DebugCanvas/SkillLoadoutBar")
	if loadout_bar == null or loadout_bar.get_child_count() != 6:
		_fail("loadout_bar_invalid")
		return false
	return true


func _validate_placed_objects(scene: Node) -> bool:
	var placed: Array = scene.call("get_placed_object_payload")
	if placed.is_empty():
		_fail("placed_objects_empty")
		return false
	for object_payload in placed:
		var placed_object: Dictionary = object_payload
		if str(placed_object.get("object_def", "")).is_empty():
			_fail("placed_object_missing_def=%s" % str(placed_object.get("id", "")))
			return false
		if bool(placed_object.get("uses_fallback", false)):
			_fail("placed_object_uses_fallback=%s" % str(placed_object.get("id", "")))
			return false
		var collision: Dictionary = placed_object.get("collision_shape", {})
		var shape := str(collision.get("shape", ""))
		if not ["rect", "circle", "capsule"].has(shape):
			_fail("placed_object_bad_collision_shape=%s shape=%s" % [str(placed_object.get("id", "")), shape])
			return false
		if shape == "capsule" and not ["vertical", "horizontal"].has(str(collision.get("orientation", ""))):
			_fail("placed_object_capsule_bad_orientation=%s" % str(placed_object.get("id", "")))
			return false
	return true


func _validate_boundary_pass_payload(scene: Node) -> bool:
	var payload: Dictionary = scene.call("get_boundary_pass_payload")
	if int(payload.get("cell_size", 0)) != 64:
		_fail("boundary_cell_size_invalid=%s" % str(payload.get("cell_size", null)))
		return false
	if Array(payload.get("walkable_cells", [])).is_empty() or Array(payload.get("boundary_cells", [])).is_empty() or Array(payload.get("blocked_cells", [])).is_empty():
		_fail("boundary_mask_missing walkable=%d boundary=%d blocked=%d" % [
			Array(payload.get("walkable_cells", [])).size(),
			Array(payload.get("boundary_cells", [])).size(),
			Array(payload.get("blocked_cells", [])).size(),
		])
		return false
	if Array(payload.get("contour_segments", [])).is_empty() or Array(payload.get("corner_points", [])).is_empty():
		_fail("boundary_contour_payload_missing segments=%d corners=%d" % [
			Array(payload.get("contour_segments", [])).size(),
			Array(payload.get("corner_points", [])).size(),
		])
		return false
	var uncovered := 0
	for cell in payload.get("boundary_cells", []):
		if not bool(Dictionary(cell).get("covered", false)):
			uncovered += 1
	if uncovered > 0:
		_fail("boundary_uncovered_cells=%d" % uncovered)
		return false
	var families := {}
	var contour_by_id := {}
	for contour_value in payload.get("contour_segments", []):
		var contour: Dictionary = contour_value
		contour_by_id[str(contour.get("id", ""))] = contour
	for segment in payload.get("boundary_segments", []):
		var segment_dict: Dictionary = segment
		families[str(segment_dict.get("material_family", ""))] = true
		if int(segment_dict.get("gap_cells", 0)) > 2:
			_fail("boundary_gap_too_large segment=%s" % str(segment_dict.get("id", "")))
			return false
	if families.size() > 1:
		_fail("boundary_material_family_count=%d" % families.size())
		return false
	for object_payload in payload.get("boundary_objects", []):
		var boundary_object: Dictionary = object_payload
		if str(boundary_object.get("material_family", "")) != "rock":
			_fail("boundary_object_not_rock_family=%s family=%s" % [str(boundary_object.get("id", "")), str(boundary_object.get("material_family", ""))])
			return false
		if not ["boundary_contour", "boundary_contour_corner"].has(str(boundary_object.get("zone_or_edge_source", ""))):
			_fail("boundary_object_not_on_contour=%s source=%s" % [str(boundary_object.get("id", "")), str(boundary_object.get("zone_or_edge_source", ""))])
			return false
		if not boundary_object.has("sort_y"):
			_fail("boundary_object_missing_sort_y=%s" % str(boundary_object.get("id", "")))
			return false
		if str(boundary_object.get("zone_or_edge_source", "")) == "boundary_contour":
			var contour_id := str(boundary_object.get("contour_segment_id", ""))
			var contour: Dictionary = contour_by_id.get(contour_id, {})
			if str(contour.get("orientation", "")) == "horizontal":
				var object_position: Dictionary = boundary_object.get("position", {})
				var contour_start: Dictionary = contour.get("start", {})
				if float(object_position.get("y", 0.0)) < float(contour_start.get("y", 0.0)) + 4.0:
					_fail("horizontal_boundary_object_not_covering_line=%s object_y=%.1f line_y=%.1f" % [
						str(boundary_object.get("id", "")),
						float(object_position.get("y", 0.0)),
						float(contour_start.get("y", 0.0)),
					])
					return false
	return true


func _validate_prop_collision_fit(scene: Node) -> bool:
	var visuals: Dictionary = scene.call("get_prop_visual_rects")
	var blockers: Dictionary = scene.call("get_prop_blocker_rects")
	for blocker_name in blockers.keys():
		var prop_name := str(blocker_name).replace("Blocker", "")
		if not visuals.has(prop_name):
			_fail("prop_blocker_missing_visual=%s" % blocker_name)
			return false
		var visual_rect: Rect2 = visuals[prop_name]
		var blocker_rect: Rect2 = blockers[blocker_name]
		var width_ratio := blocker_rect.size.x / maxf(visual_rect.size.x, 0.01)
		var height_ratio := blocker_rect.size.y / maxf(visual_rect.size.y, 0.01)
		if width_ratio < 0.10 or height_ratio < 0.08 or width_ratio > 1.01 or height_ratio > 0.86:
			_fail("prop_collision_mismatch=%s ratio=%.2fx%.2f visual=%s blocker=%s" % [blocker_name, width_ratio, height_ratio, visual_rect, blocker_rect])
			return false
		if blocker_rect.get_center().y <= visual_rect.get_center().y:
			_fail("prop_collision_not_bottom_weighted=%s visual=%s blocker=%s" % [blocker_name, visual_rect, blocker_rect])
			return false
		if blocker_rect.end.y > visual_rect.end.y + 6.0 or blocker_rect.end.y < visual_rect.position.y + visual_rect.size.y * 0.58:
			_fail("prop_collision_bad_bottom_alignment=%s visual=%s blocker=%s" % [blocker_name, visual_rect, blocker_rect])
			return false
	return true


func _validate_collision_layers(scene: Node) -> bool:
	var player := get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		_fail("layer_player_missing")
		return false
	if player.collision_layer != 2 or player.collision_mask != 1:
		_fail("layer_player_invalid layer=%d mask=%d" % [player.collision_layer, player.collision_mask])
		return false
	for enemy in get_nodes_in_group("enemy"):
		var enemy_body := enemy as CharacterBody2D
		if enemy_body == null:
			continue
		if enemy_body.collision_layer != 4 or enemy_body.collision_mask != 1:
			_fail("layer_enemy_invalid name=%s layer=%d mask=%d" % [enemy_body.name, enemy_body.collision_layer, enemy_body.collision_mask])
			return false
	var blocker_root := scene.get_node_or_null("FirstOutdoorBlockers")
	if blocker_root == null:
		_fail("layer_blocker_root_missing")
		return false
	for blocker in blocker_root.get_children():
		var body := blocker as StaticBody2D
		if body == null:
			continue
		if body.collision_layer != 1 or body.collision_mask != 0:
			_fail("layer_blocker_invalid name=%s layer=%d mask=%d" % [body.name, body.collision_layer, body.collision_mask])
			return false
	return true


func _validate_boundary_does_not_use_large_readable_rects(scene: Node) -> bool:
	var blocker_root := scene.get_node_or_null("FirstOutdoorBlockers")
	if blocker_root == null:
		_fail("boundary_blocker_root_missing")
		return false
	for blocker in blocker_root.get_children():
		var body := blocker as StaticBody2D
		if body == null:
			continue
		if str(body.get_meta("source", "")) == "readable_boundary":
			_fail("readable_boundary_rect_still_present=%s" % body.name)
			return false
	return true


func _validate_boundary_contour_blocks(scene: Node) -> bool:
	var player := get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		_fail("boundary_player_missing")
		return false
	var payload: Dictionary = scene.call("get_boundary_pass_payload")
	var cell_size := int(payload.get("cell_size", 64))
	var original_position := player.global_position
	var checked := 0
	for cell_value in payload.get("boundary_cells", []):
		var cell: Dictionary = cell_value
		if not bool(cell.get("covered", false)):
			continue
		var x := int(cell.get("x", 0))
		var y := int(cell.get("y", 0))
		for edge_value in Array(cell.get("edges", [])):
			var edge := str(edge_value)
			var check := _boundary_collision_check(x, y, edge, cell_size)
			player.global_position = check["position"]
			await physics_frame
			if not player.test_move(player.global_transform, check["motion"]):
				player.global_position = original_position
				await physics_frame
				_fail("boundary_contour_open cell=%d,%d edge=%s position=%s motion=%s" % [x, y, edge, check["position"], check["motion"]])
				return false
			checked += 1
			if checked >= 80:
				player.global_position = original_position
				await physics_frame
				return true
	player.global_position = original_position
	await physics_frame
	if checked <= 0:
		_fail("boundary_contour_no_checks")
		return false
	return true


func _boundary_collision_check(x: int, y: int, edge: String, cell_size: int) -> Dictionary:
	var left := float(x * cell_size)
	var right := float((x + 1) * cell_size)
	var top := float(y * cell_size)
	var bottom := float((y + 1) * cell_size)
	var center_x := (left + right) * 0.5
	var center_y := (top + bottom) * 0.5
	match edge:
		"north":
			return {"position": Vector2(center_x, bottom + 56.0), "motion": Vector2(0.0, -96.0)}
		"south":
			return {"position": Vector2(center_x, top - 56.0), "motion": Vector2(0.0, 96.0)}
		"west":
			return {"position": Vector2(right + 56.0, center_y), "motion": Vector2(-96.0, 0.0)}
		"east":
			return {"position": Vector2(left - 56.0, center_y), "motion": Vector2(96.0, 0.0)}
	return {"position": Vector2(center_x, center_y), "motion": Vector2.ZERO}


func _validate_enemy_soft_collision_ignores_player() -> bool:
	var player := get_first_node_in_group("player") as Node2D
	if player == null:
		_fail("soft_collision_player_missing")
		return false
	var enemy: CharacterBody2D = null
	for node in get_nodes_in_group("enemy"):
		enemy = node as CharacterBody2D
		if enemy != null:
			break
	if enemy == null:
		_fail("soft_collision_enemy_missing")
		return false
	var original_player_position := player.global_position
	var original_enemy_position := enemy.global_position
	var moved_enemy_positions := {}
	for other in get_nodes_in_group("enemy"):
		if other != enemy and other is Node2D:
			var other_node := other as Node2D
			moved_enemy_positions[other_node] = other_node.global_position
			other_node.global_position += Vector2(2000.0, 2000.0)
	enemy.global_position = Vector2(900.0, 900.0)
	player.global_position = enemy.global_position + Vector2(20.0, 0.0)
	enemy.set("player", player)
	var soft_velocity: Vector2 = enemy.call("_soft_collision_velocity")
	player.global_position = original_player_position
	enemy.global_position = original_enemy_position
	for other_node in moved_enemy_positions.keys():
		if is_instance_valid(other_node):
			(other_node as Node2D).global_position = moved_enemy_positions[other_node]
	if soft_velocity.length() > 0.01:
		_fail("enemy_soft_collision_pushes_from_player velocity=%s" % soft_velocity)
		return false
	return true


func _validate_first_weapon_loop(scene: Node) -> bool:
	var player := get_first_node_in_group("player")
	var loot_nodes := get_nodes_in_group("loot")
	if player == null:
		_fail("player_missing")
		return false
	if loot_nodes.is_empty():
		_fail("early_weapon_loot_missing")
		return false
	var before_damage := int(player.call("get_current_attack_damage"))
	scene.call("toggle_inventory_visibility")
	await process_frame
	scene.call("click_ground_item", loot_nodes[0])
	await process_frame
	if not bool(scene.call("has_cursor_item")):
		_fail("loot_not_on_cursor")
		return false
	scene.call("click_equipment_slot")
	await process_frame
	if bool(scene.call("has_cursor_item")):
		_fail("cursor_item_not_equipped")
		return false
	var after_damage := int(player.call("get_current_attack_damage"))
	if after_damage <= before_damage:
		_fail("weapon_loop_no_damage_gain %d -> %d" % [before_damage, after_damage])
		return false
	for _i in range(60):
		await process_frame
	return true


func _payload_has_zone_type(payload: Dictionary, zone_type: String) -> bool:
	for zone in payload.get("zones", []):
		if str(zone.get("type", "")) == zone_type:
			return true
	return false


func _wait_for_scene() -> bool:
	for _i in range(30):
		await physics_frame
		if current_scene != null and get_first_node_in_group("player") != null and current_scene.has_method("get_generated_payload"):
			return true
	return false


func _fail(message: String) -> void:
	print("FirstOutdoorGenerated smoke: FAIL %s" % message)
	quit(1)
