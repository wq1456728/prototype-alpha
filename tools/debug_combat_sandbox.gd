extends SceneTree

const SCENE_PATH := "res://scenes/maps/combat_sandbox.tscn"
const ITEM_DATABASE := preload("res://scripts/items/item_database.gd")


func _initialize() -> void:
	var error := change_scene_to_file(SCENE_PATH)
	if error != OK:
		push_error("Failed to load %s: %s" % [SCENE_PATH, error])
		quit(1)
		return
	_run.call_deferred()


func _run() -> void:
	if not await _wait_for_scene():
		print("combat_sandbox FAIL scene_not_ready")
		quit(1)
		return
	var player := get_first_node_in_group("player") as Node2D
	var enemies := get_nodes_in_group("enemy")
	var debug_label := current_scene.get_node_or_null("DebugCanvas/DebugLabel")
	var inventory_panel := current_scene.get_node_or_null("DebugCanvas/InventoryPanel")
	var world_entities_root := current_scene.get_node_or_null("WorldEntities")
	var loot_root := current_scene.get_node_or_null("Loot")
	if player == null or enemies.is_empty() or debug_label == null or inventory_panel == null or world_entities_root == null or loot_root == null:
		print("combat_sandbox FAIL player=%s enemies=%d debug=%s inventory=%s world_entities=%s loot=%s" % [player != null, enemies.size(), debug_label != null, inventory_panel != null, world_entities_root != null, loot_root != null])
		quit(1)
		return
	if ITEM_DATABASE.get_definition("weapon_rusty_short_sword").is_empty() or ITEM_DATABASE.get_equipment_slot("weapon").is_empty():
		print("combat_sandbox FAIL item_database_not_loaded")
		quit(1)
		return
	if not player.has_method("get_equipment_items") or not player.call("get_equipment_items").has("weapon"):
		print("combat_sandbox FAIL generic_equipment_slots_missing")
		quit(1)
		return
	if player.get_parent() != world_entities_root:
		print("combat_sandbox FAIL player_parent=%s world_entities=%s" % [player.get_parent().name, world_entities_root.name])
		quit(1)
		return
	for enemy in enemies:
		if enemy.get_parent() != world_entities_root:
			print("combat_sandbox FAIL enemy_parent name=%s parent=%s" % [enemy.name, enemy.get_parent().name])
			quit(1)
			return
	if current_scene.has_method("is_inventory_visible") and bool(current_scene.call("is_inventory_visible")):
		print("combat_sandbox FAIL inventory_visible_by_default")
		quit(1)
		return
	if current_scene.has_method("toggle_inventory_visibility"):
		current_scene.call("toggle_inventory_visibility")
		await process_frame
		if not bool(current_scene.call("is_inventory_visible")):
			print("combat_sandbox FAIL inventory_toggle_show")
			quit(1)
			return
		current_scene.call("toggle_inventory_visibility")
		await process_frame
		if bool(current_scene.call("is_inventory_visible")):
			print("combat_sandbox FAIL inventory_toggle_hide")
			quit(1)
			return

	print("combat_sandbox launch ok: enemies=%d player_hp=%s damage=%s" % [enemies.size(), player.get("hp"), player.call("get_current_attack_damage")])
	for enemy in enemies:
		var enemy_node := enemy as CharacterBody2D
		if enemy_node == null:
			continue
		print("%s hp=%s speed=%s range=%s cooldown=%s preferred=%s" % [enemy_node.name, enemy_node.get("max_hp"), enemy_node.get("move_speed"), enemy_node.get("attack_range"), enemy_node.get("attack_cooldown"), enemy_node.get("preferred_distance")])
	if not _validate_drop_roll(enemies[0]):
		quit(1)
		return

	var target := enemies[0]
	var before_damage := int(player.call("get_current_attack_damage"))
	var before_xp := int(player.call("get_current_xp"))
	target.call("take_damage", int(target.get("max_hp")), player.global_position)
	await physics_frame
	var after_kill_xp := int(player.call("get_current_xp"))
	if after_kill_xp <= before_xp:
		print("combat_sandbox FAIL xp_not_awarded xp %d -> %d reward=%s" % [before_xp, after_kill_xp, target.get("xp_reward")])
		quit(1)
		return
	var feedback_after_hit := get_nodes_in_group("feedback").size()
	var loot := _first_loot() as Area2D
	if loot == null:
		print("combat_sandbox FAIL loot_missing")
		quit(1)
		return
	if loot.get_parent() != world_entities_root:
		print("combat_sandbox FAIL loot_parent=%s world_entities=%s" % [loot.get_parent().name, world_entities_root.name])
		quit(1)
		return
	if loot.get("item_data") == null or not _validate_item_shape(loot.get("item_data")):
		print("combat_sandbox FAIL loot_item_shape")
		quit(1)
		return
	player.global_position = loot.global_position
	await physics_frame
	await physics_frame
	await process_frame
	await process_frame
	for _i in range(12):
		await physics_frame
	var after_pickup_damage := int(player.call("get_current_attack_damage"))
	if _filled_bag_count(player) != 0 or after_pickup_damage != before_damage:
		print("combat_sandbox FAIL walkover_pickup bag=%d damage %d -> %d" % [_filled_bag_count(player), before_damage, after_pickup_damage])
		quit(1)
		return
	current_scene.call("toggle_inventory_visibility")
	current_scene.call("click_ground_item", loot)
	await process_frame
	if not bool(current_scene.call("has_cursor_item")) or _filled_bag_count(player) != 0:
		print("combat_sandbox FAIL open_inventory_ground_to_cursor cursor=%s bag=%d" % [current_scene.call("has_cursor_item"), _filled_bag_count(player)])
		quit(1)
		return
	if not bool(player.call("is_attack_input_blocked")):
		print("combat_sandbox FAIL cursor_should_block_attack")
		quit(1)
		return
	current_scene.call("click_inventory_slot", 0)
	await process_frame
	if bool(current_scene.call("has_cursor_item")) or _filled_bag_count(player) != 1:
		print("combat_sandbox FAIL cursor_to_bag cursor=%s bag=%d" % [current_scene.call("has_cursor_item"), _filled_bag_count(player)])
		quit(1)
		return
	current_scene.call("click_inventory_slot", 0)
	await process_frame
	if not bool(current_scene.call("has_cursor_item")) or _filled_bag_count(player) != 0:
		print("combat_sandbox FAIL bag_to_cursor cursor=%s bag=%d" % [current_scene.call("has_cursor_item"), _filled_bag_count(player)])
		quit(1)
		return
	current_scene.call("click_equipment_slot")
	await process_frame
	var after_equip_damage := int(player.call("get_current_attack_damage"))
	var weapon_name := str(player.call("get_equipped_weapon_name"))
	if bool(current_scene.call("has_cursor_item")) or after_equip_damage <= before_damage:
		print("combat_sandbox FAIL cursor_equip cursor=%s damage %d -> %d weapon=%s" % [current_scene.call("has_cursor_item"), before_damage, after_equip_damage, weapon_name])
		quit(1)
		return
	current_scene.call("click_equipment_slot")
	await process_frame
	if not bool(current_scene.call("has_cursor_item")) or int(player.call("get_current_attack_damage")) != before_damage:
		print("combat_sandbox FAIL equipped_to_cursor cursor=%s damage=%d" % [current_scene.call("has_cursor_item"), int(player.call("get_current_attack_damage"))])
		quit(1)
		return
	var loot_before_drop := get_nodes_in_group("loot").size()
	var requested_drop_position := player.global_position + Vector2(72, 0)
	current_scene.call("click_empty_world", requested_drop_position)
	await process_frame
	if bool(current_scene.call("has_cursor_item")) or get_nodes_in_group("loot").size() <= loot_before_drop:
		print("combat_sandbox FAIL cursor_drop cursor=%s loot_before=%d loot_after=%d" % [current_scene.call("has_cursor_item"), loot_before_drop, get_nodes_in_group("loot").size()])
		quit(1)
		return
	var dropped_loot := _first_loot()
	if dropped_loot == null or (dropped_loot as Node2D).global_position.distance_to(player.global_position) > 50.0:
		print("combat_sandbox FAIL cursor_drop_too_far drop=%s player=%s requested=%s" % [(dropped_loot as Node2D).global_position if dropped_loot != null else null, player.global_position, requested_drop_position])
		quit(1)
		return
	current_scene.call("click_ground_item", dropped_loot)
	await process_frame
	if not bool(current_scene.call("has_cursor_item")):
		print("combat_sandbox FAIL dropped_ground_to_cursor")
		quit(1)
		return
	current_scene.call("click_inventory_slot", 1)
	await process_frame
	if bool(current_scene.call("has_cursor_item")) or _filled_bag_count(player) != 1:
		print("combat_sandbox FAIL cursor_back_to_bag cursor=%s bag=%d" % [current_scene.call("has_cursor_item"), _filled_bag_count(player)])
		quit(1)
		return
	var before_level := int(player.call("get_level"))
	var before_level_damage := int(player.call("get_current_attack_damage"))
	var xp_needed := int(player.call("get_xp_to_next_level")) - int(player.call("get_current_xp"))
	player.call("gain_xp", xp_needed)
	await process_frame
	var after_level := int(player.call("get_level"))
	var after_level_damage := int(player.call("get_current_attack_damage"))
	if after_level <= before_level or after_level_damage <= before_level_damage:
		print("combat_sandbox FAIL level_growth level %d -> %d damage %d -> %d" % [before_level, after_level, before_level_damage, after_level_damage])
		quit(1)
		return
	print("combat_sandbox loot ok: damage %d -> walkover %d -> equip %d weapon=%s bag=%d cursor=%s loot_left=%d enemies_left=%d feedback_after_hit=%d" % [before_damage, after_pickup_damage, after_equip_damage, weapon_name, _filled_bag_count(player), current_scene.call("has_cursor_item"), get_nodes_in_group("loot").size(), get_nodes_in_group("enemy").size(), feedback_after_hit])
	print("combat_sandbox progression ok: xp %d -> %d level %d -> %d damage %d -> %d" % [before_xp, after_kill_xp, before_level, after_level, before_level_damage, after_level_damage])
	quit(0)


func _first_loot() -> Node:
	var loot_nodes := get_nodes_in_group("loot")
	if loot_nodes.is_empty():
		return null
	return loot_nodes[0]


func _validate_drop_roll(enemy: Node) -> bool:
	seed(12012)
	var names := {}
	var rarities := {}
	var damage_values := {}
	for _i in range(80):
		var item: Dictionary = enemy.call("_make_weapon_drop")
		if not _validate_item_shape(item):
			print("combat_sandbox FAIL generated_item_shape=%s" % item)
			return false
		names[str(item["name"])] = true
		rarities[str(item["rarity"])] = true
		damage_values[int(item["damage_bonus"])] = true
	if names.size() < 2 or rarities.size() < 3 or damage_values.size() < 3:
		print("combat_sandbox FAIL drop_variety names=%d rarities=%d damage_values=%d" % [names.size(), rarities.size(), damage_values.size()])
		return false
	print("combat_sandbox drop roll ok: names=%d rarities=%d damage_values=%d" % [names.size(), rarities.size(), damage_values.size()])
	return true


func _validate_item_shape(item: Dictionary) -> bool:
	var required := ["schema", "instance_id", "definition_id", "item_type", "type", "id", "name", "rarity", "damage_bonus", "icon", "color", "equip_slot", "stat_modifiers"]
	for key in required:
		if not item.has(key):
			return false
	return str(item["schema"]) == "ItemInstance" and str(item["type"]) == "weapon" and str(item["definition_id"]).begins_with("weapon_") and int(item["damage_bonus"]) > 0 and not str(item["icon"]).is_empty()


func _filled_bag_count(player: Node) -> int:
	var count := 0
	var items: Array = player.call("get_inventory_items")
	for item in items:
		if item is Dictionary and not item.is_empty():
			count += 1
	return count


func _wait_for_scene() -> bool:
	for _i in range(20):
		await physics_frame
		if current_scene != null:
			return true
	return false
