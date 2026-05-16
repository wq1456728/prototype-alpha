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
	if collision_debug_overlay.visible:
		print("CombatSandbox smoke: FAIL collision_debug_should_start_hidden")
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
		current_scene.call("_unhandled_input", collision_toggle_event)
		await process_frame
		if collision_debug_overlay.visible:
			print("CombatSandbox smoke: FAIL collision_debug_p_toggle_hide")
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
		current_scene.call("_unhandled_input", skill_toggle_event)
		await process_frame
		if skill_tree_panel.visible:
			print("CombatSandbox smoke: FAIL skill_tree_k_toggle_hide")
			quit(1)
			return

	print("CombatSandbox smoke: PASS player=%s enemies=%d world_entities_y_sort=ok debug_label=ok inventory_panel=hidden skill_tree=ok loadout=ok collision_debug=ok loot_root=ok" % [player.name, enemies.size()])
	quit(0)


func _wait_for_scene() -> bool:
	for _i in range(20):
		await physics_frame
		if current_scene != null:
			return true
	return false
