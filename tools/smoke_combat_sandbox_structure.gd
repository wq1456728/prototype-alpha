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
	await physics_frame

	var player := current_scene.get_node_or_null("KnightPlayer")
	var enemies := get_nodes_in_group("enemy")
	var debug_label := current_scene.get_node_or_null("DebugCanvas/DebugLabel")
	var inventory_panel := current_scene.get_node_or_null("DebugCanvas/InventoryPanel")
	var loot_root := current_scene.get_node_or_null("Loot")
	var missing := PackedStringArray()

	if player == null:
		missing.append("player")
	if enemies.is_empty():
		missing.append("enemies")
	if debug_label == null:
		missing.append("debug_label")
	if inventory_panel == null:
		missing.append("inventory_panel")
	if loot_root == null:
		missing.append("loot_root")

	if not missing.is_empty():
		print("CombatSandbox smoke: FAIL missing=%s enemies=%d" % [",".join(missing), enemies.size()])
		quit(1)
		return

	print("CombatSandbox smoke: PASS player=%s enemies=%d debug_label=ok inventory_panel=ok loot_root=ok" % [player.name, enemies.size()])
	quit(0)
