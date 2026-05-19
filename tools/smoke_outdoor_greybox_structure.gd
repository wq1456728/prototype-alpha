extends SceneTree

const SCENE_PATH := "res://scenes/maps/outdoor_greybox.tscn"


func _initialize() -> void:
	var error := change_scene_to_file(SCENE_PATH)
	if error != OK:
		print("OutdoorGreybox smoke: FAIL scene_load=%s" % error)
		quit(1)
		return
	_run.call_deferred()


func _run() -> void:
	if not await _wait_for_scene():
		print("OutdoorGreybox smoke: FAIL scene_not_ready")
		quit(1)
		return

	var player := current_scene.get_node_or_null("WorldEntities/KnightPlayer")
	var world_entities_root := current_scene.get_node_or_null("WorldEntities")
	var visuals := current_scene.get_node_or_null("OutdoorVisuals")
	var props := current_scene.get_node_or_null("WorldEntities/RouteProps")
	var debug_label := current_scene.get_node_or_null("DebugCanvas/DebugLabel")
	var inventory_panel := current_scene.get_node_or_null("DebugCanvas/InventoryPanel")
	var skill_tree_panel := current_scene.get_node_or_null("DebugCanvas/SkillTreePanel")
	var loadout_bar := current_scene.get_node_or_null("DebugCanvas/SkillLoadoutBar")
	var objective_panel := current_scene.get_node_or_null("DebugCanvas/ObjectivePanel")
	var missing := PackedStringArray()

	if player == null:
		missing.append("player")
	if world_entities_root == null:
		missing.append("world_entities")
	if visuals == null:
		missing.append("visuals")
	if props == null:
		missing.append("props")
	if debug_label == null:
		missing.append("debug_label")
	if inventory_panel == null:
		missing.append("inventory_panel")
	if skill_tree_panel == null:
		missing.append("skill_tree_panel")
	if loadout_bar == null:
		missing.append("loadout_bar")
	if objective_panel == null:
		missing.append("objective_panel")
	if not missing.is_empty():
		print("OutdoorGreybox smoke: FAIL missing=%s" % ",".join(missing))
		quit(1)
		return

	if not world_entities_root.y_sort_enabled:
		print("OutdoorGreybox smoke: FAIL world_entities_y_sort_disabled")
		quit(1)
		return
	if player.get_parent() != world_entities_root:
		print("OutdoorGreybox smoke: FAIL player_not_in_world_entities")
		quit(1)
		return
	if inventory_panel.visible or skill_tree_panel.visible:
		print("OutdoorGreybox smoke: FAIL large_panel_visible_by_default inventory=%s skill=%s" % [inventory_panel.visible, skill_tree_panel.visible])
		quit(1)
		return
	if loadout_bar.get_child_count() != 6:
		print("OutdoorGreybox smoke: FAIL loadout_slot_count=%d" % loadout_bar.get_child_count())
		quit(1)
		return
	for group_name in ["outdoor_training", "outdoor_road", "outdoor_loot", "outdoor_shrine", "outdoor_entrance"]:
		if get_nodes_in_group(group_name).is_empty():
			print("OutdoorGreybox smoke: FAIL empty_group=%s" % group_name)
			quit(1)
			return
	for marker_name in ["CampGate", "TrainingVerge", "FirstLootClearing", "ShrineFork", "CorruptedHollowEntrance"]:
		if current_scene.call("get_route_marker_position", marker_name) == Vector2.ZERO:
			print("OutdoorGreybox smoke: FAIL missing_marker=%s" % marker_name)
			quit(1)
			return
	var viewport_size := root.get_visible_rect().size
	if not _rect_inside_viewport(loadout_bar.get_global_rect(), viewport_size):
		print("OutdoorGreybox smoke: FAIL loadout_offscreen rect=%s viewport=%s" % [loadout_bar.get_global_rect(), viewport_size])
		quit(1)
		return
	print("OutdoorGreybox smoke: PASS enemies=%d props=%d route_markers=ok ui=ok" % [get_nodes_in_group("enemy").size(), props.get_child_count()])
	quit(0)


func _rect_inside_viewport(rect: Rect2, viewport_size: Vector2) -> bool:
	return rect.position.x >= -0.1 and rect.position.y >= -0.1 and rect.end.x <= viewport_size.x + 0.1 and rect.end.y <= viewport_size.y + 0.1


func _wait_for_scene() -> bool:
	for _i in range(20):
		await physics_frame
		if current_scene != null and get_first_node_in_group("player") != null:
			return true
	return false
