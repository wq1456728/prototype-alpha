extends SceneTree

const SCENE_PATH := "res://scenes/dev/terrain_tilemap_test.tscn"


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
	if not _validate_required_nodes(scene):
		return
	if not _validate_summary(scene):
		return
	print("Task32TerrainTilemapTest smoke: PASS summary=%s" % str(scene.call("get_task32_tilemap_summary")))
	quit(0)


func _validate_required_nodes(scene: Node) -> bool:
	for path in [
		"GroundBaseTileMapLayer",
		"DirtRoadTileMapLayer",
		"TerrainOverlayTileMapLayer",
		"DecalPreviewLayer",
		"PropPreviewLayer",
	]:
		if scene.get_node_or_null(path) == null:
			_fail("missing_node=%s" % path)
			return false
	for path in [
		"GroundBaseTileMapLayer",
		"DirtRoadTileMapLayer",
		"TerrainOverlayTileMapLayer",
	]:
		if not scene.get_node(path) is TileMapLayer:
			_fail("not_tile_map_layer=%s" % path)
			return false
	return true


func _validate_summary(scene: Node) -> bool:
	if not scene.has_method("get_task32_tilemap_summary"):
		_fail("missing_summary_method")
		return false
	var summary: Dictionary = scene.call("get_task32_tilemap_summary")
	var source := str(summary.get("source", ""))
	if not source.contains("dual-grid") and not source.contains("PixelLab") and not source.contains("FrameRonin"):
		_fail("source_not_declared=%s" % source)
		return false
	if int(summary.get("dirt_world_cells", 0)) <= 0:
		_fail("no_dirt_world_cells")
		return false
	if int(summary.get("grass_world_cells", 0)) <= 0:
		_fail("no_grass_world_cells")
		return false
	if int(summary.get("road_world_cells", 0)) <= 0:
		_fail("no_road_world_cells")
		return false
	if int(summary.get("display_tiles", 0)) <= 0:
		_fail("no_dual_grid_display_tiles")
		return false
	if int(summary.get("display_transition_tiles", 0)) <= 0:
		_fail("no_dual_grid_transition_tiles")
		return false
	if int(summary.get("road_ribbon_children", 0)) < 2:
		_fail("missing_road_ribbon=%d" % int(summary.get("road_ribbon_children", 0)))
		return false
	if int(summary.get("decal_count", 0)) < 8:
		_fail("too_few_decals=%d" % int(summary.get("decal_count", 0)))
		return false
	if int(summary.get("prop_count", 0)) < 3:
		_fail("too_few_props=%d" % int(summary.get("prop_count", 0)))
		return false
	return true


func _wait_for_scene() -> bool:
	for _i in range(30):
		await process_frame
		if current_scene != null and current_scene.name == "TerrainTilemapTest":
			return true
	return false


func _fail(message: String) -> void:
	print("Task32TerrainTilemapTest smoke: FAIL %s" % message)
	quit(1)
