extends SceneTree

const SCENE_PATH := "res://scenes/maps/combat_sandbox.tscn"


func _initialize() -> void:
	var error := change_scene_to_file(SCENE_PATH)
	if error != OK:
		push_error("Failed to load %s: %s" % [SCENE_PATH, error])
		quit(1)
		return
	_run.call_deferred()


func _run() -> void:
	await physics_frame
	var player := get_first_node_in_group("player") as Node2D
	var enemies := get_nodes_in_group("enemy")
	var debug_label := current_scene.get_node_or_null("DebugCanvas/DebugLabel")
	var inventory_panel := current_scene.get_node_or_null("DebugCanvas/InventoryPanel")
	var loot_root := current_scene.get_node_or_null("Loot")
	if player == null or enemies.is_empty() or debug_label == null or inventory_panel == null or loot_root == null:
		print("combat_sandbox FAIL player=%s enemies=%d debug=%s inventory=%s loot=%s" % [player != null, enemies.size(), debug_label != null, inventory_panel != null, loot_root != null])
		quit(1)
		return

	print("combat_sandbox launch ok: enemies=%d player_hp=%s damage=%s" % [enemies.size(), player.get("hp"), player.call("get_current_attack_damage")])
	for enemy in enemies:
		var enemy_node := enemy as CharacterBody2D
		if enemy_node == null:
			continue
		print("%s hp=%s speed=%s range=%s cooldown=%s preferred=%s" % [enemy_node.name, enemy_node.get("max_hp"), enemy_node.get("move_speed"), enemy_node.get("attack_range"), enemy_node.get("attack_cooldown"), enemy_node.get("preferred_distance")])

	var target := enemies[0]
	var before_damage := int(player.call("get_current_attack_damage"))
	target.call("take_damage", int(target.get("max_hp")), player.global_position)
	await physics_frame
	var feedback_after_hit := get_nodes_in_group("feedback").size()
	var loot := _first_loot() as Area2D
	if loot == null:
		print("combat_sandbox FAIL loot_missing")
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
	var bag_items: Array = player.call("get_inventory_items")
	if bag_items.size() != 1 or after_pickup_damage != before_damage:
		print("combat_sandbox FAIL pickup bag=%d damage %d -> %d" % [bag_items.size(), before_damage, after_pickup_damage])
		quit(1)
		return
	var equipped := bool(player.call("equip_bag_slot", 0))
	await process_frame
	var after_equip_damage := int(player.call("get_current_attack_damage"))
	var weapon_name := str(player.call("get_equipped_weapon_name"))
	if not equipped or after_equip_damage <= before_damage:
		print("combat_sandbox FAIL equip equipped=%s damage %d -> %d weapon=%s" % [equipped, before_damage, after_equip_damage, weapon_name])
		quit(1)
		return
	print("combat_sandbox loot ok: damage %d -> pickup %d -> equip %d weapon=%s bag=%d loot_left=%d enemies_left=%d feedback_after_hit=%d" % [before_damage, after_pickup_damage, after_equip_damage, weapon_name, player.call("get_inventory_items").size(), get_nodes_in_group("loot").size(), get_nodes_in_group("enemy").size(), feedback_after_hit])
	quit(0)


func _first_loot() -> Node:
	var loot_nodes := get_nodes_in_group("loot")
	if loot_nodes.is_empty():
		return null
	return loot_nodes[0]
