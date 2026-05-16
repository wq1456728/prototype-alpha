extends SceneTree

const SCENE_PATH := "res://scenes/maps/combat_sandbox.tscn"
const SAMPLE_FRAMES := [1, 30, 90, 180]
const LAST_FRAME := 180


func _initialize() -> void:
	var error := change_scene_to_file(SCENE_PATH)
	if error != OK:
		push_error("Failed to load %s: %s" % [SCENE_PATH, error])
		quit(1)
		return
	_run.call_deferred()


func _run() -> void:
	for frame in range(1, LAST_FRAME + 1):
		await physics_frame
		if SAMPLE_FRAMES.has(frame):
			_print_sample(frame)
	quit()


func _print_sample(frame: int) -> void:
	var player := get_first_node_in_group("player") as Node2D
	print("-- frame %d --" % frame)
	if player != null:
		print("player pos=%s hp=%s" % [_fmt_vec(player.global_position), player.get("hp")])

	for enemy in get_nodes_in_group("enemy"):
		var enemy_node := enemy as CharacterBody2D
		if enemy_node == null:
			continue
		var distance := 0.0
		if player != null:
			distance = enemy_node.global_position.distance_to(player.global_position)
		print(
			"%s pos=%s velocity=%s distance=%.1f move_speed=%s ai=%s action_lock=%.2f"
			% [
				enemy_node.name,
				_fmt_vec(enemy_node.global_position),
				_fmt_vec(enemy_node.velocity),
				distance,
				enemy_node.get("move_speed"),
				enemy_node.get("ai_mode"),
				float(enemy_node.get("action_lock")),
			]
		)


func _fmt_vec(value: Vector2) -> String:
	return "(%.1f, %.1f)" % [value.x, value.y]
