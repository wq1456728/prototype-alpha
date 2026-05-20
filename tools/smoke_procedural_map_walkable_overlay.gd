extends SceneTree

const SCENE_PATH := "res://scenes/maps/procedural_map_test.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene_error := change_scene_to_file(SCENE_PATH)
	if scene_error != OK:
		_fail("scene_load=%s" % scene_error)
		return
	if not await _wait_for_scene():
		_fail("scene_not_ready")
		return

	current_scene.call("use_first_outdoor_config")
	await process_frame
	current_scene.call("set_overlay_mode", 1)
	await process_frame
	if not _payload_ok("first_outdoor_walkable"):
		return
	if not _overlay_nodes_ok(true, false):
		return

	current_scene.call("set_overlay_mode", 2)
	await process_frame
	if not _overlay_nodes_ok(true, true):
		return

	current_scene.call("use_dummy_config")
	await process_frame
	var dummy_payload: Dictionary = current_scene.call("get_debug_payload")
	if str(dummy_payload.get("map_id", "")) == "first_outdoor":
		_fail("dummy_switch_failed map_id=%s" % str(dummy_payload.get("map_id", "")))
		return
	if not _payload_ok("dummy"):
		return

	print("ProceduralMapWalkableOverlay smoke: PASS first_outdoor_mask=ok dummy_mask=ok")
	quit(0)


func _payload_ok(context: String) -> bool:
	var payload: Dictionary = current_scene.call("get_boundary_debug_payload")
	var cell_size := int(payload.get("cell_size", 0))
	var walkable := Array(payload.get("walkable_cells", []))
	var boundary := Array(payload.get("boundary_cells", []))
	var blocked := Array(payload.get("blocked_cells", []))
	var contours := Array(payload.get("contour_segments", []))
	if cell_size <= 0 or walkable.is_empty() or boundary.is_empty() or blocked.is_empty() or contours.is_empty():
		_fail("%s payload_invalid cell_size=%d walkable=%d boundary=%d blocked=%d contours=%d" % [
			context,
			cell_size,
			walkable.size(),
			boundary.size(),
			blocked.size(),
			contours.size(),
		])
		return false
	return true


func _overlay_nodes_ok(expect_mask_visible: bool, expect_layout_visible: bool) -> bool:
	var mask_root := current_scene.get_node_or_null("WalkableMaskOverlay") as CanvasItem
	if mask_root == null:
		_fail("mask_overlay_missing")
		return false
	if mask_root.visible != expect_mask_visible:
		_fail("mask_visibility expected=%s actual=%s" % [str(expect_mask_visible), str(mask_root.visible)])
		return false
	for required in ["Cells/WalkableCells", "Cells/BoundaryCells", "Cells/BlockedCells", "ContourLines"]:
		if mask_root.get_node_or_null(required) == null:
			_fail("mask_child_missing=%s" % required)
			return false
	var generated_root := current_scene.get_node_or_null("GeneratedProceduralMap") as CanvasItem
	if generated_root == null:
		_fail("layout_root_missing")
		return false
	if generated_root.visible != expect_layout_visible:
		_fail("layout_visibility expected=%s actual=%s" % [str(expect_layout_visible), str(generated_root.visible)])
		return false
	return true


func _wait_for_scene() -> bool:
	for _i in range(30):
		await process_frame
		if current_scene != null and current_scene.has_method("get_boundary_debug_payload"):
			return true
	return false


func _fail(message: String) -> void:
	print("ProceduralMapWalkableOverlay smoke: FAIL %s" % message)
	quit(1)
