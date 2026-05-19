extends SceneTree

const COLLISION_LAYERS := preload("res://scripts/physics/collision_layers.gd")

const SCENE_PATH := "res://scenes/maps/outdoor_greybox.tscn"


func _initialize() -> void:
	var error := change_scene_to_file(SCENE_PATH)
	if error != OK:
		print("OutdoorPlayable smoke: FAIL scene_load=%s" % error)
		quit(1)
		return
	_run.call_deferred()


func _run() -> void:
	if not await _wait_for_scene():
		print("OutdoorPlayable smoke: FAIL scene_not_ready")
		quit(1)
		return

	var player := get_first_node_in_group("player") as CharacterBody2D
	var loadout_bar := current_scene.get_node_or_null("DebugCanvas/SkillLoadoutBar") as Control
	var objective_panel := current_scene.get_node_or_null("DebugCanvas/ObjectivePanel") as Control
	if player == null or loadout_bar == null or objective_panel == null:
		print("OutdoorPlayable smoke: FAIL missing player/loadout/objective")
		quit(1)
		return

	var bounds: Rect2 = current_scene.call("get_playable_bounds")
	if bounds.size.x < 2000.0 or bounds.size.y < 2500.0:
		print("OutdoorPlayable smoke: FAIL bounds_too_small=%s" % bounds)
		quit(1)
		return
	if int(current_scene.call("get_boundary_collider_count")) < 4:
		print("OutdoorPlayable smoke: FAIL boundary_colliders=%d" % int(current_scene.call("get_boundary_collider_count")))
		quit(1)
		return
	if int(current_scene.call("get_boundary_visual_count")) < 40:
		print("OutdoorPlayable smoke: FAIL boundary_visuals=%d" % int(current_scene.call("get_boundary_visual_count")))
		quit(1)
		return
	if int(current_scene.call("get_prop_blocker_count")) < 18:
		print("OutdoorPlayable smoke: FAIL prop_blockers=%d" % int(current_scene.call("get_prop_blocker_count")))
		quit(1)
		return

	var camera_zoom: Vector2 = current_scene.call("get_outdoor_camera_zoom")
	var player_scale: Vector2 = current_scene.call("get_player_visual_scale")
	if camera_zoom.x > 1.55 or camera_zoom.y > 1.55 or camera_zoom.x < 1.0 or camera_zoom.y < 1.0:
		print("OutdoorPlayable smoke: FAIL camera_zoom=%s" % camera_zoom)
		quit(1)
		return
	if player_scale.x > 2.3 or player_scale.y > 2.3 or player_scale.x < 1.8 or player_scale.y < 1.8:
		print("OutdoorPlayable smoke: FAIL player_scale=%s" % player_scale)
		quit(1)
		return

	for group_name in ["outdoor_training", "outdoor_road", "outdoor_loot", "outdoor_shrine", "outdoor_entrance"]:
		var count := get_nodes_in_group(group_name).size()
		if count <= 0 or count > 3:
			print("OutdoorPlayable smoke: FAIL encounter_density %s=%d" % [group_name, count])
			quit(1)
			return

	if not _route_spacing_ok():
		print("OutdoorPlayable smoke: FAIL route_spacing")
		quit(1)
		return
	if not await _boundary_collision_ok(player, bounds):
		print("OutdoorPlayable smoke: FAIL boundary_collision")
		quit(1)
		return
	if not await _camp_north_boundary_ok(player):
		print("OutdoorPlayable smoke: FAIL camp_north_boundary")
		quit(1)
		return
	if not await _key_prop_blockers_ok(player):
		print("OutdoorPlayable smoke: FAIL key_prop_blockers")
		quit(1)
		return
	if not _collision_layers_ok(player):
		print("OutdoorPlayable smoke: FAIL collision_layers")
		quit(1)
		return
	if not _prop_collision_fit_ok():
		print("OutdoorPlayable smoke: FAIL prop_collision_fit")
		quit(1)
		return
	if not await _route_markers_remain_walkable(player):
		print("OutdoorPlayable smoke: FAIL route_marker_walkability")
		quit(1)
		return

	if not _ui_layout_ok_for(loadout_bar, objective_panel, Vector2(1920, 1080)):
		print("OutdoorPlayable smoke: FAIL ui_layout_1920 loadout=%s objective=%s" % [loadout_bar.get_global_rect(), objective_panel.get_global_rect()])
		quit(1)
		return
	if not _ui_layout_ok_for(loadout_bar, objective_panel, Vector2(1280, 720)):
		print("OutdoorPlayable smoke: FAIL ui_layout_1280 loadout=%s objective=%s" % [loadout_bar.get_global_rect(), objective_panel.get_global_rect()])
		quit(1)
		return

	print("OutdoorPlayable smoke: PASS root_viewport=%s simulated_ui=1920x1080,1280x720 bounds=%s boundary_colliders=%d boundary_visuals=%d prop_blockers=%d player_scale=%s camera_zoom=%s enemies=%d" % [
		root.get_visible_rect().size,
		bounds,
		int(current_scene.call("get_boundary_collider_count")),
		int(current_scene.call("get_boundary_visual_count")),
		int(current_scene.call("get_prop_blocker_count")),
		player_scale,
		camera_zoom,
		get_nodes_in_group("enemy").size(),
	])
	quit(0)


func _route_spacing_ok() -> bool:
	var marker_names := ["CampGate", "TrainingVerge", "FirstLootClearing", "ShrineFork", "EntranceApproach", "CorruptedHollowEntrance"]
	var previous := Vector2.ZERO
	for marker_name in marker_names:
		var position: Vector2 = current_scene.call("get_route_marker_position", marker_name)
		if position == Vector2.ZERO:
			return false
		if previous != Vector2.ZERO and position.distance_to(previous) < 300.0:
			return false
		previous = position
	return true


func _boundary_collision_ok(player: CharacterBody2D, bounds: Rect2) -> bool:
	var original_position := player.global_position
	var checks := [
		[Vector2(bounds.position.x + 12.0, bounds.get_center().y), Vector2(-160.0, 0.0)],
		[Vector2(bounds.end.x - 12.0, bounds.get_center().y), Vector2(160.0, 0.0)],
		[Vector2(bounds.get_center().x, bounds.position.y + 12.0), Vector2(0.0, -160.0)],
		[Vector2(bounds.get_center().x, bounds.end.y - 12.0), Vector2(0.0, 160.0)],
	]
	for check in checks:
		player.global_position = check[0]
		await physics_frame
		if not player.test_move(player.global_transform, check[1]):
			player.global_position = original_position
			return false
	player.global_position = original_position
	await physics_frame
	return true


func _camp_north_boundary_ok(player: CharacterBody2D) -> bool:
	var original_position := player.global_position
	var camp_gate: Vector2 = current_scene.call("get_route_marker_position", "CampGate")
	var limit_y := float(current_scene.call("get_camp_north_readable_limit_y"))
	player.global_position = Vector2(camp_gate.x, limit_y + 46.0)
	await physics_frame
	var blocked := player.test_move(player.global_transform, Vector2(0.0, -140.0))
	player.global_position = original_position
	await physics_frame
	return blocked


func _key_prop_blockers_ok(player: CharacterBody2D) -> bool:
	var blocker_rects: Dictionary = current_scene.call("get_prop_blocker_rects")
	var required_blockers := [
		"CampGateBlocker",
		"CampFenceWestBlocker",
		"CampFenceEastBlocker",
		"BrokenCartBlocker",
		"ShrineBlocker",
		"CorruptedHollowBlocker",
		"RoadRockABlocker",
		"RoadRockBBlocker",
		"EntranceRootsABlocker",
		"EntranceRootsBBlocker",
	]
	for blocker_name in required_blockers:
		if not blocker_rects.has(blocker_name):
			return false
		if not await _blocker_rect_blocks(player, blocker_rects[blocker_name]):
			return false
	return true


func _blocker_rect_blocks(player: CharacterBody2D, rect: Rect2) -> bool:
	var original_position := player.global_position
	var center := rect.get_center()
	player.global_position = Vector2(rect.position.x - 42.0, center.y)
	await physics_frame
	var blocked := player.test_move(player.global_transform, Vector2(rect.size.x + 84.0, 0.0))
	player.global_position = original_position
	await physics_frame
	return blocked


func _collision_layers_ok(player: CharacterBody2D) -> bool:
	if player.collision_layer != COLLISION_LAYERS.PLAYER or player.collision_mask != COLLISION_LAYERS.WORLD:
		return false
	for enemy in get_nodes_in_group("enemy"):
		var enemy_body := enemy as CharacterBody2D
		if enemy_body == null:
			continue
		if enemy_body.collision_layer != COLLISION_LAYERS.ENEMY or enemy_body.collision_mask != COLLISION_LAYERS.WORLD:
			return false
	var blocker_root := current_scene.get_node_or_null("OutdoorBoundary")
	if blocker_root == null:
		return false
	for blocker in blocker_root.get_children():
		var body := blocker as StaticBody2D
		if body == null:
			continue
		if body.collision_layer != COLLISION_LAYERS.WORLD or body.collision_mask != 0:
			return false
	return true


func _prop_collision_fit_ok() -> bool:
	if not current_scene.has_method("get_prop_visual_rects"):
		return false
	var visuals: Dictionary = current_scene.call("get_prop_visual_rects")
	var blockers: Dictionary = current_scene.call("get_prop_blocker_rects")
	for blocker_name in blockers.keys():
		var prop_name := str(blocker_name).replace("Blocker", "")
		if not visuals.has(prop_name):
			return false
		var visual_rect: Rect2 = visuals[prop_name]
		var blocker_rect: Rect2 = blockers[blocker_name]
		var width_ratio := blocker_rect.size.x / maxf(visual_rect.size.x, 0.01)
		var height_ratio := blocker_rect.size.y / maxf(visual_rect.size.y, 0.01)
		if width_ratio < 0.25 or height_ratio < 0.20 or width_ratio > 1.01 or height_ratio > 0.72:
			return false
		if blocker_rect.get_center().y <= visual_rect.get_center().y:
			return false
		if blocker_rect.end.y > visual_rect.end.y + 1.0 or blocker_rect.end.y < visual_rect.position.y + visual_rect.size.y * 0.62:
			return false
	return true


func _route_markers_remain_walkable(player: CharacterBody2D) -> bool:
	var original_position := player.global_position
	for marker_name in ["CampGate", "TrainingVerge", "BrokenRoad", "FirstLootClearing", "ShrineFork", "EntranceApproach"]:
		player.global_position = current_scene.call("get_route_marker_position", marker_name)
		await physics_frame
		var open_directions := 0
		for motion in [Vector2.RIGHT * 40.0, Vector2.LEFT * 40.0, Vector2.DOWN * 40.0, Vector2.UP * 40.0]:
			if not player.test_move(player.global_transform, motion):
				open_directions += 1
		if open_directions <= 0:
			player.global_position = original_position
			await physics_frame
			return false
	player.global_position = original_position
	await physics_frame
	return true


func _rect_inside_viewport(rect: Rect2, viewport_size: Vector2) -> bool:
	return rect.position.x >= -0.1 and rect.position.y >= -0.1 and rect.end.x <= viewport_size.x + 0.1 and rect.end.y <= viewport_size.y + 0.1


func _ui_layout_ok_for(loadout_bar: Control, objective_panel: Control, viewport_size: Vector2) -> bool:
	loadout_bar.call("layout", viewport_size)
	objective_panel.call("layout", viewport_size)
	return _rect_inside_viewport(loadout_bar.get_global_rect(), viewport_size) and _rect_inside_viewport(objective_panel.get_global_rect(), viewport_size)


func _wait_for_scene() -> bool:
	for _i in range(20):
		await physics_frame
		if current_scene != null and get_first_node_in_group("player") != null:
			return true
	return false
