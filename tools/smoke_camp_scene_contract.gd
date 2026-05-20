extends SceneTree

const COLLISION_LAYERS := preload("res://scripts/physics/collision_layers.gd")

const CAMP_SCENE_PATH := "res://scenes/maps/camp_scene.tscn"
const FIRST_OUTDOOR_SCENE_PATH := "res://scenes/maps/first_outdoor_generated.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not ResourceLoader.exists(CAMP_SCENE_PATH):
		_fail("missing_camp_scene")
		return
	if not ResourceLoader.exists(FIRST_OUTDOOR_SCENE_PATH):
		_fail("missing_first_outdoor_scene")
		return

	var error := change_scene_to_file(CAMP_SCENE_PATH)
	if error != OK:
		_fail("camp_scene_load=%s" % error)
		return
	if not await _wait_for_scene("CampScene"):
		_fail("camp_scene_not_ready")
		return

	var camp := current_scene
	if not _validate_camp_contract(camp):
		return
	for _i in range(6):
		await physics_frame
		if get_nodes_in_group("enemy").size() > 0:
			_fail("camp_spawned_enemy_during_physics")
			return
	if not _validate_camp_bounds_block_motion(camp):
		return

	error = camp.call("transition_to_outdoor")
	if error != OK:
		_fail("transition_to_outdoor=%s" % error)
		return
	if not await _wait_for_scene("FirstOutdoorGenerated"):
		_fail("first_outdoor_not_ready_after_transition")
		return
	if not _validate_outdoor_contract(current_scene):
		return

	print("CampSceneContract smoke: PASS target=%s spawn=%s" % [
		FIRST_OUTDOOR_SCENE_PATH,
		str(current_scene.call("get_route_marker_position", "CampSpawn")),
	])
	quit(0)


func _validate_camp_contract(camp: Node) -> bool:
	for node_name in camp.call("get_contract_node_names"):
		if camp.get_node_or_null(str(node_name)) == null:
			_fail("camp_missing_contract_node=%s" % str(node_name))
			return false
	if get_nodes_in_group("enemy").size() > 0:
		_fail("camp_has_enemies=%d" % get_nodes_in_group("enemy").size())
		return false
	var target_path := str(camp.call("get_transition_target_path"))
	if target_path != FIRST_OUTDOOR_SCENE_PATH:
		_fail("camp_transition_target=%s" % target_path)
		return false
	var payload: Dictionary = camp.call("get_transition_payload")
	if str(payload.get("target_scene", "")) != FIRST_OUTDOOR_SCENE_PATH:
		_fail("camp_payload_target_scene=%s" % str(payload.get("target_scene", "")))
		return false
	if str(payload.get("target_spawn_anchor", "")) != "CampEntranceSpawn":
		_fail("camp_payload_target_spawn=%s" % str(payload.get("target_spawn_anchor", "")))
		return false
	if str(payload.get("return_scene", "")) != CAMP_SCENE_PATH or str(payload.get("return_spawn_anchor", "")) != "CampSpawn":
		_fail("camp_payload_return=%s" % str(payload))
		return false
	if int(camp.call("get_camp_bounds_shape_count")) < 4:
		_fail("camp_bounds_shape_count=%d" % int(camp.call("get_camp_bounds_shape_count")))
		return false
	var player := camp.get_node_or_null("WorldEntities/KnightPlayer") as CollisionObject2D
	if player == null:
		_fail("camp_missing_player")
		return false
	if player.collision_layer != COLLISION_LAYERS.PLAYER or player.collision_mask != COLLISION_LAYERS.WORLD:
		_fail("camp_player_collision layer=%d mask=%d" % [player.collision_layer, player.collision_mask])
		return false
	var spawn_position: Vector2 = camp.call("get_spawn_position")
	if (player as Node2D).global_position.distance_to(spawn_position) > 1.0:
		_fail("camp_player_not_at_spawn")
		return false
	return true


func _validate_camp_bounds_block_motion(camp: Node) -> bool:
	var player := camp.get_node_or_null("WorldEntities/KnightPlayer") as CharacterBody2D
	if player == null:
		_fail("camp_motion_missing_player")
		return false
	var motions := {
		"west": Vector2(-520, 0),
		"east": Vector2(1380, 0),
		"north": Vector2(0, -560),
		"south": Vector2(0, 570),
	}
	for direction in motions.keys():
		var params := PhysicsTestMotionParameters2D.new()
		params.from = player.global_transform
		params.motion = motions[direction]
		var result := PhysicsTestMotionResult2D.new()
		if not PhysicsServer2D.body_test_motion(player.get_rid(), params, result):
			_fail("camp_bounds_not_blocking_%s" % str(direction))
			return false
	return true


func _validate_outdoor_contract(outdoor: Node) -> bool:
	if str(outdoor.call("get_camp_return_target_path")) != CAMP_SCENE_PATH:
		_fail("outdoor_return_target=%s" % str(outdoor.call("get_camp_return_target_path")))
		return false
	var camp_spawn: Vector2 = outdoor.call("get_route_marker_position", "CampSpawn")
	var camp_entrance: Vector2 = outdoor.call("get_camp_entrance_position")
	var camp_entrance_marker: Vector2 = outdoor.call("get_route_marker_position", "CampEntranceSpawn")
	if camp_spawn == Vector2.ZERO or camp_entrance == Vector2.ZERO:
		_fail("outdoor_missing_camp_spawn_or_entrance")
		return false
	if camp_spawn.distance_to(camp_entrance) > 1.0 or camp_entrance.distance_to(camp_entrance_marker) > 1.0:
		_fail("outdoor_camp_entrance_mismatch")
		return false
	var player := outdoor.get_node_or_null("WorldEntities/KnightPlayer") as Node2D
	if player == null:
		_fail("outdoor_missing_player")
		return false
	if player.global_position.distance_to(camp_entrance) > 1.0:
		_fail("outdoor_player_not_at_camp_entrance")
		return false
	return true


func _wait_for_scene(expected_name: String) -> bool:
	for _i in range(30):
		await process_frame
		if current_scene != null and current_scene.name == expected_name:
			return true
	return false


func _fail(message: String) -> void:
	print("CampSceneContract smoke: FAIL %s" % message)
	quit(1)
