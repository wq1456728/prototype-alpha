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
	var loot_root := current_scene.get_node_or_null("Loot")
	if player == null or enemies.is_empty() or debug_label == null or loot_root == null:
		print("combat_sandbox FAIL player=%s enemies=%d debug=%s loot=%s" % [player != null, enemies.size(), debug_label != null, loot_root != null])
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
	for _i in range(110):
		await physics_frame
	var after_damage := int(player.call("get_current_attack_damage"))
	print("combat_sandbox loot ok: damage %d -> %d loot_left=%d enemies_left=%d" % [before_damage, after_damage, get_nodes_in_group("loot").size(), get_nodes_in_group("enemy").size()])
	quit(0)


func _first_loot() -> Node:
	var loot_nodes := get_nodes_in_group("loot")
	if loot_nodes.is_empty():
		return null
	return loot_nodes[0]
