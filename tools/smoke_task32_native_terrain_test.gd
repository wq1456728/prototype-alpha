extends SceneTree

const SCENE_PATH := "res://scenes/dev/terrain_native_terrain_test.tscn"


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
	print("Task32NativeTerrain smoke: PASS summary=%s" % str(scene.call("get_task32_native_terrain_summary")))
	quit(0)


func _validate_nodes(scene: Node) -> bool:
	if scene.get_node_or_null("NativeTerrainTileMapLayer") == null:
		_fail("missing_tilemap_layer")
		return false
	if not scene.get_node("NativeTerrainTileMapLayer") is TileMapLayer:
		_fail("native_layer_not_tilemap")
		return false
	if scene.get_node_or_null("Camera2D") == null:
		_fail("missing_camera")
		return false
	return true


func _validate_summary(scene: Node) -> bool:
	if not scene.has_method("get_task32_native_terrain_summary"):
		_fail("missing_summary_method")
		return false
	var summary: Dictionary = scene.call("get_task32_native_terrain_summary")
	if not bool(summary.get("native_connect_used", false)):
		_fail("native_connect_not_used")
		return false
	if str(summary.get("atlas", "")).find("candidate_02") < 0:
		_fail("wrong_atlas=%s" % str(summary.get("atlas", "")))
		return false
	if int(summary.get("all_cells", 0)) <= 0:
		_fail("no_all_cells")
		return false
	if int(summary.get("dirt_cells", 0)) <= 0:
		_fail("no_dirt_cells")
		return false
	if int(summary.get("used_cells", 0)) <= 0:
		_fail("no_used_cells")
		return false
	if int(summary.get("distinct_atlas_coords", 0)) < 4:
		_fail("too_few_native_tiles=%d" % int(summary.get("distinct_atlas_coords", 0)))
		return false
	return true


func _wait_for_scene() -> bool:
	for _i in range(30):
		await process_frame
		if current_scene != null and current_scene.name == "TerrainNativeTerrainTest":
			return true
	return false


func _fail(message: String) -> void:
	print("Task32NativeTerrain smoke: FAIL %s" % message)
	quit(1)
