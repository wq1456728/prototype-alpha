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
	if not _validate_prop_collision_fit(scene):
		return false
	if not _validate_collision_layers(scene):
		return false
	if not await _validate_readable_boundary_blocks(scene):
		return false
	if not _validate_enemy_soft_collision_ignores_player():
		return false
	var loadout_bar := scene.get_node_or_null("DebugCanvas/SkillLoadoutBar")
	if loadout_bar == null or loadout_bar.get_child_count() != 6:
		_fail("loadout_bar_invalid")
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
		if width_ratio < 0.25 or height_ratio < 0.20 or width_ratio > 1.01 or height_ratio > 0.72:
			_fail("prop_collision_mismatch=%s ratio=%.2fx%.2f visual=%s blocker=%s" % [blocker_name, width_ratio, height_ratio, visual_rect, blocker_rect])
			return false
		if blocker_rect.get_center().y <= visual_rect.get_center().y:
			_fail("prop_collision_not_bottom_weighted=%s visual=%s blocker=%s" % [blocker_name, visual_rect, blocker_rect])
			return false
		if blocker_rect.end.y > visual_rect.end.y + 1.0 or blocker_rect.end.y < visual_rect.position.y + visual_rect.size.y * 0.62:
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


func _validate_readable_boundary_blocks(scene: Node) -> bool:
	var player := get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		_fail("boundary_player_missing")
		return false
	var bounds: Rect2 = scene.call("get_playable_bounds")
	var original_position := player.global_position
	var checks := [
		[Vector2(bounds.get_center().x, 190.0), Vector2(0.0, -170.0), "top"],
		[Vector2(bounds.get_center().x, bounds.end.y - 190.0), Vector2(0.0, 170.0), "bottom"],
		[Vector2(190.0, bounds.get_center().y), Vector2(-170.0, 0.0), "left"],
		[Vector2(bounds.end.x - 190.0, bounds.get_center().y), Vector2(170.0, 0.0), "right"],
	]
	for check in checks:
		player.global_position = check[0]
		await physics_frame
		if not player.test_move(player.global_transform, check[1]):
			player.global_position = original_position
			await physics_frame
			_fail("readable_boundary_open side=%s position=%s motion=%s" % [check[2], check[0], check[1]])
			return false
	player.global_position = original_position
	await physics_frame
	return true


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
