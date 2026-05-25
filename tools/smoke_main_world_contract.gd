extends SceneTree

const SCENE_PATH := "res://scenes/world/main_world.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var error := change_scene_to_file(SCENE_PATH)
	if error != OK:
		_fail("scene_load=%s" % error)
		return
	if not await _wait_for_scene():
		_fail("scene_not_ready")
		return

	var scene := current_scene
	if not _validate_contract(scene):
		return
	if not _validate_terrain_layers(scene):
		return
	if not _validate_enemy_variety(scene):
		return
	if not await _validate_player_can_move_toward_wilderness(scene):
		return

	print("MainWorldContract smoke: PASS enemy_types=%s town_exit=%s wilderness_start=%s" % [
		str(scene.call("get_enemy_type_counts")),
		str(scene.call("get_town_exit_socket_position")),
		str(scene.call("get_wilderness_start_socket_position")),
	])
	quit(0)


func _validate_contract(scene: Node) -> bool:
	for path in [
		"FixedTown",
		"FixedTown/TownSpawn",
		"FixedTown/TownExitSocket",
		"FixedTown/TownBounds",
		"FixedTown/Props",
		"FixedTown/NPCPlaceholders",
		"FixedTown/Interactables",
		"GeneratedRegion",
		"GeneratedRegion/TransitionChunk",
		"GeneratedRegion/TransitionChunk/WildernessStartSocket",
		"GeneratedRegion/TransitionChunk/NorthSocket",
		"GeneratedRegion/TransitionChunk/SouthSocket",
		"WorldEntities/KnightPlayer",
	]:
		if scene.get_node_or_null(path) == null:
			_fail("missing_node=%s" % path)
			return false
	var contract: Dictionary = scene.call("get_main_world_contract")
	if not bool(contract.get("fixed_town", false)) or not bool(contract.get("generated_region", false)):
		_fail("contract_missing_world_parts=%s" % str(contract))
		return false
	if bool(contract.get("uses_scene_switch_for_wilderness", true)):
		_fail("contract_uses_scene_switch")
		return false
	if str(contract.get("player_parent", "")) != "WorldEntities":
		_fail("player_parent_changed=%s" % str(contract.get("player_parent", "")))
		return false
	if int(contract.get("player_z_index", 0)) <= int(contract.get("fixed_town_z_index", 0)):
		_fail("player_z_not_above_fixed_town player=%s fixed=%s" % [
			str(contract.get("player_z_index", null)),
			str(contract.get("fixed_town_z_index", null)),
		])
		return false
	if int(contract.get("generation_seed", 0)) <= 0:
		_fail("generation_seed_invalid=%s" % str(contract.get("generation_seed", null)))
		return false
	var town_bounds: Rect2 = scene.call("get_town_bounds_rect")
	var town_spawn: Vector2 = scene.call("get_town_spawn_position")
	var player := scene.get_node_or_null("WorldEntities/KnightPlayer") as Node2D
	if not town_bounds.has_point(town_spawn):
		_fail("town_spawn_outside_bounds spawn=%s bounds=%s" % [str(town_spawn), str(town_bounds)])
		return false
	if player == null or not town_bounds.has_point(player.global_position):
		_fail("player_spawn_outside_bounds player=%s bounds=%s" % [str(player.global_position if player != null else Vector2.ZERO), str(town_bounds)])
		return false
	var town_exit: Vector2 = scene.call("get_town_exit_socket_position")
	var wilderness_start: Vector2 = scene.call("get_wilderness_start_socket_position")
	var generated_start: Vector2 = scene.call("get_generated_start_anchor_position")
	if town_exit == Vector2.ZERO or wilderness_start == Vector2.ZERO or generated_start == Vector2.ZERO:
		_fail("missing_socket_positions")
		return false
	if wilderness_start.distance_to(generated_start) > 1.0:
		_fail("wilderness_start_not_generated_start")
		return false
	if town_exit.distance_to(wilderness_start) > 900.0:
		_fail("town_too_far_from_wilderness distance=%.1f" % town_exit.distance_to(wilderness_start))
		return false
	var opening_rect: Rect2 = scene.call("get_town_exit_opening_rect")
	if not opening_rect.has_point(town_exit):
		_fail("town_exit_not_in_opening exit=%s opening=%s" % [str(town_exit), str(opening_rect)])
		return false
	if not _validate_town_connection_is_unblocked(scene):
		return false
	if not _validate_town_connection_motion(scene):
		return false
	return true


func _validate_terrain_layers(scene: Node) -> bool:
	var required_paths := [
		"GeneratedRegion/FirstOutdoorVisuals",
		"GeneratedRegion/FirstOutdoorVisuals/GroundBaseLayer",
		"GeneratedRegion/FirstOutdoorVisuals/GroundBaseLayer/NativeWangTerrainLayer",
		"GeneratedRegion/FirstOutdoorVisuals/TerrainOverlayLayer",
		"GeneratedRegion/FirstOutdoorVisuals/RoadLayer",
		"GeneratedRegion/FirstOutdoorVisuals/DecalLayer",
		"GeneratedRegion/FirstOutdoorVisuals/OuterBufferLayer",
		"GeneratedRegion/FirstOutdoorVisuals/BoundaryLayer",
		"FixedTown/Ground/NativeWangCampTerrainLayer",
		"GeneratedRegion/TransitionChunk",
		"GeneratedRegion/TransitionChunk/WildernessStartSocket",
	]
	for path in required_paths:
		if scene.get_node_or_null(path) == null:
			_fail("missing_terrain_layer=%s" % path)
			return false

	var paint_paths := [
		"GeneratedRegion/FirstOutdoorVisuals/GroundBaseLayer",
		"GeneratedRegion/FirstOutdoorVisuals/TerrainOverlayLayer",
		"GeneratedRegion/FirstOutdoorVisuals/RoadLayer",
		"GeneratedRegion/FirstOutdoorVisuals/DecalLayer",
		"GeneratedRegion/FirstOutdoorVisuals/OuterBufferLayer",
	]
	for path in paint_paths:
		var node := scene.get_node_or_null(path)
		if node == null:
			continue
		if _has_collision_shape(node):
			_fail("terrain_layer_has_collision=%s" % path)
			return false
	for path in [
		"FixedTown/Ground/NativeWangCampTerrainLayer",
		"GeneratedRegion/FirstOutdoorVisuals/GroundBaseLayer/NativeWangTerrainLayer",
	]:
		var layer := scene.get_node_or_null(path) as TileMapLayer
		if layer == null:
			_fail("native_wang_layer_missing=%s" % path)
			return false
		if layer.get_used_cells().is_empty():
			_fail("native_wang_layer_empty=%s" % path)
			return false

	return true


func _has_collision_shape(node: Node) -> bool:
	if node is CollisionShape2D:
		return true
	for child in node.get_children():
		if _has_collision_shape(child):
			return true
	return false


func _validate_enemy_variety(scene: Node) -> bool:
	var counts: Dictionary = scene.call("get_enemy_type_counts")
	if counts.keys().size() < 3:
		_fail("enemy_type_count=%d counts=%s" % [counts.keys().size(), str(counts)])
		return false
	for enemy_type in ["Mummy", "Snake", "Hyena"]:
		if int(counts.get(enemy_type, 0)) <= 0:
			_fail("missing_enemy_type=%s counts=%s" % [enemy_type, str(counts)])
			return false
	return true


func _validate_player_can_move_toward_wilderness(scene: Node) -> bool:
	var player := scene.get_node_or_null("WorldEntities/KnightPlayer") as CharacterBody2D
	if player == null:
		_fail("missing_player")
		return false
	var start_position := player.global_position
	var target: Vector2 = scene.call("get_town_exit_socket_position")
	var direction := (target - start_position).normalized()
	for _i in range(8):
		player.velocity = direction * 180.0
		player.move_and_slide()
		await physics_frame
	if player.global_position.distance_to(target) >= start_position.distance_to(target):
		_fail("player_did_not_move_toward_town_exit")
		return false
	return true


func _validate_town_connection_is_unblocked(scene: Node) -> bool:
	var corridor: Rect2 = scene.call("get_town_connection_corridor_rect")
	var payload: Dictionary = scene.call("get_boundary_pass_payload")
	for boundary_object in payload.get("boundary_objects", []):
		var object_data: Dictionary = boundary_object
		var position_data: Dictionary = object_data.get("position", {})
		var position := Vector2(float(position_data.get("x", 0.0)), float(position_data.get("y", 0.0)))
		if corridor.has_point(position):
			_fail("boundary_object_blocks_town_connection=%s pos=%s corridor=%s" % [
				str(object_data.get("id", "")),
				str(position),
				str(corridor),
			])
			return false
	return true


func _validate_town_connection_motion(scene: Node) -> bool:
	var player := scene.get_node_or_null("WorldEntities/KnightPlayer") as CharacterBody2D
	if player == null:
		_fail("missing_player_for_connection_motion")
		return false
	var from: Vector2 = scene.call("get_town_exit_socket_position")
	var to: Vector2 = scene.call("get_wilderness_start_socket_position")
	var original := player.global_transform
	var params := PhysicsTestMotionParameters2D.new()
	params.from = Transform2D(player.global_rotation, from)
	params.motion = to - from
	var result := PhysicsTestMotionResult2D.new()
	var blocked := PhysicsServer2D.body_test_motion(player.get_rid(), params, result)
	player.global_transform = original
	if blocked:
		_fail("town_connection_motion_blocked from=%s to=%s collision=%s" % [str(from), str(to), str(result.get_collision_point())])
		return false
	return true


func _wait_for_scene() -> bool:
	for _i in range(40):
		await process_frame
		if current_scene != null and current_scene.name == "MainWorld":
			return true
	return false


func _fail(message: String) -> void:
	print("MainWorldContract smoke: FAIL %s" % message)
	quit(1)
