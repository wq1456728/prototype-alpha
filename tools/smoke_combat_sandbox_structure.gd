extends SceneTree

const SCENE_PATH := "res://scenes/maps/combat_sandbox.tscn"


func _initialize() -> void:
	var error := change_scene_to_file(SCENE_PATH)
	if error != OK:
		print("CombatSandbox smoke: FAIL scene_load=%s" % error)
		quit(1)
		return
	_run.call_deferred()


func _run() -> void:
	if not await _wait_for_scene():
		print("CombatSandbox smoke: FAIL scene_not_ready")
		quit(1)
		return

	var world_entities_root := current_scene.get_node_or_null("WorldEntities")
	var player := current_scene.get_node_or_null("WorldEntities/KnightPlayer")
	var enemies := get_nodes_in_group("enemy")
	var debug_label := current_scene.get_node_or_null("DebugCanvas/DebugLabel")
	var inventory_panel := current_scene.get_node_or_null("DebugCanvas/InventoryPanel")
	var skill_tree_panel := current_scene.get_node_or_null("DebugCanvas/SkillTreePanel")
	var loadout_bar := current_scene.get_node_or_null("DebugCanvas/SkillLoadoutBar")
	var loadout_picker := current_scene.get_node_or_null("DebugCanvas/SkillLoadoutPicker")
	var objective_panel := current_scene.get_node_or_null("DebugCanvas/ObjectivePanel")
	var collision_debug_overlay := current_scene.get_node_or_null("CollisionDebugOverlay")
	var loot_root := current_scene.get_node_or_null("Loot")
	var missing := PackedStringArray()

	if player == null:
		missing.append("player")
	if world_entities_root == null:
		missing.append("world_entities")
	if enemies.is_empty():
		missing.append("enemies")
	if debug_label == null:
		missing.append("debug_label")
	if inventory_panel == null:
		missing.append("inventory_panel")
	if skill_tree_panel == null:
		missing.append("skill_tree_panel")
	if loadout_bar == null:
		missing.append("loadout_bar")
	if loadout_picker == null:
		missing.append("loadout_picker")
	if objective_panel == null:
		missing.append("objective_panel")
	if collision_debug_overlay == null:
		missing.append("collision_debug_overlay")
	if loot_root == null:
		missing.append("loot_root")

	if not missing.is_empty():
		print("CombatSandbox smoke: FAIL missing=%s enemies=%d" % [",".join(missing), enemies.size()])
		quit(1)
		return
	if not world_entities_root.y_sort_enabled:
		print("CombatSandbox smoke: FAIL world_entities_y_sort_disabled")
		quit(1)
		return
	if player.get_parent() != world_entities_root:
		print("CombatSandbox smoke: FAIL player_not_in_world_entities")
		quit(1)
		return
	for enemy in enemies:
		if enemy.get_parent() != world_entities_root:
			print("CombatSandbox smoke: FAIL enemy_not_in_world_entities name=%s parent=%s" % [enemy.name, enemy.get_parent().name])
			quit(1)
			return
	if inventory_panel.visible:
		print("CombatSandbox smoke: FAIL inventory_panel_should_start_hidden")
		quit(1)
		return
	if skill_tree_panel.visible:
		print("CombatSandbox smoke: FAIL skill_tree_panel_should_start_hidden")
		quit(1)
		return
	if loadout_bar.get_child_count() != 6:
		print("CombatSandbox smoke: FAIL loadout_slot_count=%d" % loadout_bar.get_child_count())
		quit(1)
		return
	var viewport_size := root.get_visible_rect().size
	if inventory_panel.size.x < 720.0 or inventory_panel.size.y < 360.0:
		print("CombatSandbox smoke: FAIL inventory_too_small size=%s" % inventory_panel.size)
		quit(1)
		return
	if skill_tree_panel.size.x < 620.0 or skill_tree_panel.size.y < 520.0:
		print("CombatSandbox smoke: FAIL skill_tree_too_small size=%s" % skill_tree_panel.size)
		quit(1)
		return
	if loadout_bar.position.y < viewport_size.y - 120.0:
		print("CombatSandbox smoke: FAIL loadout_not_bottom y=%.1f viewport=%.1f" % [loadout_bar.position.y, viewport_size.y])
		quit(1)
		return
	if not _rect_inside_viewport(inventory_panel.get_global_rect(), viewport_size) or not _rect_inside_viewport(skill_tree_panel.get_global_rect(), viewport_size) or not _rect_inside_viewport(loadout_bar.get_global_rect(), viewport_size):
		print("CombatSandbox smoke: FAIL ui_offscreen inventory=%s skill=%s loadout=%s viewport=%s" % [inventory_panel.get_global_rect(), skill_tree_panel.get_global_rect(), loadout_bar.get_global_rect(), viewport_size])
		quit(1)
		return
	if objective_panel.position.x < viewport_size.x * 0.5:
		print("CombatSandbox smoke: FAIL objective_not_top_right objective=%s viewport=%s" % [objective_panel.get_global_rect(), viewport_size])
		quit(1)
		return
	if not _assert_visible_ui_layout("initial", [debug_label, inventory_panel, skill_tree_panel, loadout_bar, loadout_picker, objective_panel], viewport_size):
		quit(1)
		return
	if collision_debug_overlay.visible:
		print("CombatSandbox smoke: FAIL collision_debug_should_start_hidden")
		quit(1)
		return
	if bool(player.get("show_attack_debug")):
		print("CombatSandbox smoke: FAIL attack_debug_should_start_hidden")
		quit(1)
		return
	if current_scene.has_method("_unhandled_input"):
		var collision_toggle_event := InputEventKey.new()
		collision_toggle_event.pressed = true
		collision_toggle_event.keycode = KEY_P
		current_scene.call("_unhandled_input", collision_toggle_event)
		await process_frame
		if not collision_debug_overlay.visible:
			print("CombatSandbox smoke: FAIL collision_debug_p_toggle_show")
			quit(1)
			return
		if not bool(player.get("show_attack_debug")):
			print("CombatSandbox smoke: FAIL attack_debug_p_toggle_show")
			quit(1)
			return
		current_scene.call("_unhandled_input", collision_toggle_event)
		await process_frame
		if collision_debug_overlay.visible:
			print("CombatSandbox smoke: FAIL collision_debug_p_toggle_hide")
			quit(1)
			return
		if bool(player.get("show_attack_debug")):
			print("CombatSandbox smoke: FAIL attack_debug_p_toggle_hide")
			quit(1)
			return
		var skill_toggle_event := InputEventKey.new()
		skill_toggle_event.pressed = true
		skill_toggle_event.keycode = KEY_K
		current_scene.call("_unhandled_input", skill_toggle_event)
		await process_frame
		if not skill_tree_panel.visible:
			print("CombatSandbox smoke: FAIL skill_tree_k_toggle_show")
			quit(1)
			return
		if inventory_panel.visible or debug_label.visible or objective_panel.visible:
			print("CombatSandbox smoke: FAIL skill_tree_focus_state inventory=%s debug=%s objective=%s" % [inventory_panel.visible, debug_label.visible, objective_panel.visible])
			quit(1)
			return
		if not _assert_visible_ui_layout("skill_open", [debug_label, inventory_panel, skill_tree_panel, loadout_bar, loadout_picker, objective_panel], viewport_size):
			quit(1)
			return
		var inventory_toggle_event := InputEventKey.new()
		inventory_toggle_event.pressed = true
		inventory_toggle_event.keycode = KEY_B
		current_scene.call("_unhandled_input", inventory_toggle_event)
		await process_frame
		if not inventory_panel.visible or skill_tree_panel.visible:
			print("CombatSandbox smoke: FAIL inventory_should_replace_skill inventory=%s skill=%s" % [inventory_panel.visible, skill_tree_panel.visible])
			quit(1)
			return
		if debug_label.visible or objective_panel.visible:
			print("CombatSandbox smoke: FAIL inventory_focus_state debug=%s objective=%s" % [debug_label.visible, objective_panel.visible])
			quit(1)
			return
		if not _assert_visible_ui_layout("inventory_open", [debug_label, inventory_panel, skill_tree_panel, loadout_bar, loadout_picker, objective_panel], viewport_size):
			quit(1)
			return
		current_scene.call("_unhandled_input", inventory_toggle_event)
		await process_frame
		if inventory_panel.visible:
			print("CombatSandbox smoke: FAIL inventory_b_toggle_hide")
			quit(1)
			return
		if not debug_label.visible or not objective_panel.visible:
			print("CombatSandbox smoke: FAIL focus_ui_should_restore debug=%s objective=%s" % [debug_label.visible, objective_panel.visible])
			quit(1)
			return
		if not _assert_visible_ui_layout("panels_closed", [debug_label, inventory_panel, skill_tree_panel, loadout_bar, loadout_picker, objective_panel], viewport_size):
			quit(1)
			return
		current_scene.call("_unhandled_input", skill_toggle_event)
		await process_frame
		current_scene.call("_unhandled_input", skill_toggle_event)
		await process_frame
		if skill_tree_panel.visible:
			print("CombatSandbox smoke: FAIL skill_tree_k_toggle_hide")
			quit(1)
			return

	print("CombatSandbox smoke: PASS player=%s enemies=%d world_entities_y_sort=ok debug_label=ok inventory_panel=hidden skill_tree=ok loadout=ok objective=ok collision_debug=ok loot_root=ok" % [player.name, enemies.size()])
	quit(0)


func _rect_inside_viewport(rect: Rect2, viewport_size: Vector2) -> bool:
	return rect.position.x >= -0.1 and rect.position.y >= -0.1 and rect.end.x <= viewport_size.x + 0.1 and rect.end.y <= viewport_size.y + 0.1


func _assert_visible_ui_layout(label: String, controls: Array, viewport_size: Vector2) -> bool:
	var visible_controls: Array[Control] = []
	for control in controls:
		var control_node := control as Control
		if control_node == null or not control_node.is_visible_in_tree():
			continue
		var rect := control_node.get_global_rect()
		if not _rect_inside_viewport(rect, viewport_size):
			print("CombatSandbox smoke: FAIL layout_%s_offscreen control=%s rect=%s viewport=%s" % [label, control_node.name, rect, viewport_size])
			return false
		for other in visible_controls:
			if rect.intersects(other.get_global_rect()):
				print("CombatSandbox smoke: FAIL layout_%s_overlap a=%s rect_a=%s b=%s rect_b=%s" % [label, control_node.name, rect, other.name, other.get_global_rect()])
				return false
		visible_controls.append(control_node)
	return true


func _wait_for_scene() -> bool:
	for _i in range(20):
		await physics_frame
		if current_scene != null:
			return true
	return false
