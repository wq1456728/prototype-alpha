extends SceneTree

const SCENE_PATH := "res://scenes/maps/outdoor_greybox.tscn"


func _initialize() -> void:
	var error := change_scene_to_file(SCENE_PATH)
	if error != OK:
		print("outdoor_greybox FAIL scene_load=%s" % error)
		quit(1)
		return
	_run.call_deferred()


func _run() -> void:
	if not await _wait_for_scene():
		print("outdoor_greybox FAIL scene_not_ready")
		quit(1)
		return
	var player := get_first_node_in_group("player") as Node2D
	if player == null:
		print("outdoor_greybox FAIL player_missing")
		quit(1)
		return

	player.global_position = current_scene.call("get_route_marker_position", "TrainingVerge")
	if not await _wait_for_objective_stage(1):
		print("outdoor_greybox FAIL camp_exit_stage=%d" % int(current_scene.call("get_objective_stage")))
		quit(1)
		return

	await _kill_group("outdoor_training")
	if not await _wait_for_objective_stage(2):
		print("outdoor_greybox FAIL training_stage=%d" % int(current_scene.call("get_objective_stage")))
		quit(1)
		return

	await _kill_group("outdoor_road")
	await _kill_group("outdoor_loot")
	var loot := _first_loot()
	if loot == null:
		print("outdoor_greybox FAIL first_loot_missing")
		quit(1)
		return
	var before_damage := int(player.call("get_current_attack_damage"))
	current_scene.call("toggle_inventory_visibility")
	await process_frame
	current_scene.call("click_ground_item", loot)
	await process_frame
	if not bool(current_scene.call("has_cursor_item")):
		print("outdoor_greybox FAIL loot_to_cursor")
		quit(1)
		return
	current_scene.call("click_equipment_slot")
	await process_frame
	if bool(current_scene.call("has_cursor_item")) or int(player.call("get_current_attack_damage")) <= before_damage:
		print("outdoor_greybox FAIL cursor_equip cursor=%s damage %d -> %d" % [current_scene.call("has_cursor_item"), before_damage, int(player.call("get_current_attack_damage"))])
		quit(1)
		return
	current_scene.call("toggle_inventory_visibility")
	await _pump_frames()
	if int(current_scene.call("get_objective_stage")) < 3:
		print("outdoor_greybox FAIL equip_stage=%d" % int(current_scene.call("get_objective_stage")))
		quit(1)
		return

	await _kill_group("outdoor_shrine")
	if int(player.call("get_level")) < 2 or int(player.call("get_available_skill_points")) < 2:
		print("outdoor_greybox FAIL level_or_points level=%d points=%d" % [int(player.call("get_level")), int(player.call("get_available_skill_points"))])
		quit(1)
		return
	if bool(player.call("can_unlock_skill", "shield_charge")):
		print("outdoor_greybox FAIL shield_charge_unlockable_before_heavy")
		quit(1)
		return
	if not bool(player.call("unlock_skill", "heavy_strike")):
		print("outdoor_greybox FAIL heavy_strike_unlock")
		quit(1)
		return
	if not bool(player.call("unlock_skill", "shield_charge")):
		print("outdoor_greybox FAIL shield_charge_unlock")
		quit(1)
		return
	await _pump_frames()
	current_scene.call("click_loadout_slot", "v")
	await _pump_frames()
	if not bool(current_scene.call("is_loadout_picker_visible")) or int(current_scene.call("get_loadout_picker_option_count")) < 1:
		print("outdoor_greybox FAIL loadout_picker visible=%s options=%d" % [current_scene.call("is_loadout_picker_visible"), int(current_scene.call("get_loadout_picker_option_count"))])
		quit(1)
		return
	if not bool(current_scene.call("click_loadout_picker_skill", "shield_charge")) or str(player.call("get_loadout_skill", "v")) != "shield_charge":
		print("outdoor_greybox FAIL shield_charge_assign slot_v=%s" % player.call("get_loadout_skill", "v"))
		quit(1)
		return
	await _pump_frames(10)
	if not await _trigger_entrance_pressure_skill(player):
		print("outdoor_greybox FAIL shield_charge_pressure_input use_count=%d entrance_hp=%d action_direction=%s aim=%s" % [
			int(player.call("get_skill_use_count", "shield_charge")),
			_group_hp_total("outdoor_entrance"),
			str(player.call("get_action_direction")),
			str(player.get("aim_direction")),
		])
		quit(1)
		return
	await _kill_group("outdoor_entrance")
	player.global_position = current_scene.call("get_dungeon_entrance_position")
	await _pump_frames()
	if not bool(current_scene.call("is_objective_complete")):
		print("outdoor_greybox FAIL objective_not_complete stage=%d" % int(current_scene.call("get_objective_stage")))
		quit(1)
		return

	print("outdoor_greybox route ok: damage %d -> %d level=%d skill_points=%d shield_charge_slot=%s enemies_left=%d" % [
		before_damage,
		int(player.call("get_current_attack_damage")),
		int(player.call("get_level")),
		int(player.call("get_available_skill_points")),
		str(player.call("get_loadout_skill", "v")),
		get_nodes_in_group("enemy").size(),
	])
	quit(0)


func _kill_group(group_name: String) -> void:
	for enemy in get_nodes_in_group(group_name):
		if not is_instance_valid(enemy):
			continue
		enemy.call("take_damage", int(enemy.get("max_hp")), get_first_node_in_group("player").global_position)
		await physics_frame
		await process_frame
	for _i in range(3):
		await process_frame


func _first_loot() -> Node:
	var loot_nodes := get_nodes_in_group("loot")
	if loot_nodes.is_empty():
		return null
	return loot_nodes[0]


func _trigger_entrance_pressure_skill(player: Node2D) -> bool:
	player.global_position = current_scene.call("get_dungeon_entrance_position") + Vector2(60.0, -100.0)
	await _pump_frames(1)
	Input.warp_mouse(player.get_global_transform_with_canvas().origin + Vector2.DOWN * 320.0)
	player.set("aim_direction", Vector2.DOWN)
	player.set("facing_direction", Vector2.DOWN)
	var hp_before := _group_hp_total("outdoor_entrance")
	var use_before := int(player.call("get_skill_use_count", "shield_charge"))
	await _tap_key(KEY_V)
	await _pump_frames(45)
	var hp_after := _group_hp_total("outdoor_entrance")
	return int(player.call("get_skill_use_count", "shield_charge")) > use_before and hp_after < hp_before


func _group_hp_total(group_name: String) -> int:
	var total := 0
	for enemy in get_nodes_in_group(group_name):
		if is_instance_valid(enemy) and not bool(enemy.get("dead")):
			total += int(enemy.get("hp"))
	return total


func _wait_for_scene() -> bool:
	for _i in range(20):
		await physics_frame
		if current_scene != null and get_first_node_in_group("player") != null:
			return true
	return false


func _wait_for_objective_stage(stage: int, max_frames: int = 8) -> bool:
	for _i in range(max_frames):
		await _pump_frames(1)
		if int(current_scene.call("get_objective_stage")) >= stage:
			return true
	return false


func _tap_key(keycode: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = keycode
	press.physical_keycode = keycode
	press.pressed = true
	Input.parse_input_event(press)
	await physics_frame
	var release := InputEventKey.new()
	release.keycode = keycode
	release.physical_keycode = keycode
	release.pressed = false
	Input.parse_input_event(release)
	await physics_frame


func _pump_frames(count: int = 2) -> void:
	for _i in range(count):
		await process_frame
		await physics_frame
