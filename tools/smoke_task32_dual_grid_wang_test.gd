extends SceneTree

const SCENE_PATH := "res://scenes/dev/terrain_dual_grid_wang_test.tscn"


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
	if not _validate_nodes(scene):
		return
	if not _validate_summary(scene):
		return
	print("Task32DualGridWang smoke: PASS summary=%s" % str(scene.call("get_task32_dual_grid_summary")))
	quit(0)


func _validate_nodes(scene: Node) -> bool:
	for path in [
		"GroundDisplayTileMapLayer",
		"DecalPreviewLayer",
		"DebugOverlayLayer",
		"Camera2D",
	]:
		if scene.get_node_or_null(path) == null:
			_fail("missing_node=%s" % path)
			return false
	if not scene.get_node("GroundDisplayTileMapLayer") is TileMapLayer:
		_fail("ground_not_tile_map_layer")
		return false
	return true


func _validate_summary(scene: Node) -> bool:
	if not scene.has_method("get_task32_dual_grid_summary"):
		_fail("missing_summary_method")
		return false
	var summary: Dictionary = scene.call("get_task32_dual_grid_summary")
	if str(summary.get("source", "")).find("dual-grid") < 0:
		_fail("wrong_source=%s" % str(summary.get("source", "")))
		return false
	if int(summary.get("mask_mapping_count", 0)) != 16:
		_fail("mask_mapping_count=%d" % int(summary.get("mask_mapping_count", 0)))
		return false
	if int(summary.get("display_tiles", 0)) <= 0:
		_fail("no_display_tiles")
		return false
	if int(summary.get("transition_tiles", 0)) <= 0:
		_fail("no_transition_tiles")
		return false
	if int(summary.get("dirt_points", 0)) <= 0:
		_fail("no_dirt_points")
		return false
	if int(summary.get("road_points_painted", 0)) <= 0:
		_fail("no_road_points")
		return false
	if int(summary.get("patch_count", 0)) < 2:
		_fail("missing_irregular_patches")
		return false
	if int(summary.get("decal_count", 0)) < 8:
		_fail("too_few_decals")
		return false
	var atlas := str(summary.get("atlas", ""))
	if atlas.is_empty():
		_fail("missing_atlas")
		return false
	return true


func _wait_for_scene() -> bool:
	for _i in range(30):
		await process_frame
		if current_scene != null and current_scene.name == "TerrainDualGridWangTest":
			return true
	return false


func _fail(message: String) -> void:
	print("Task32DualGridWang smoke: FAIL %s" % message)
	quit(1)
