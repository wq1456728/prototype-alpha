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
	if not await _wait_for_scene():
		print("player_inputs FAIL scene_not_ready")
		quit(1)
		return
	await _test_mouse_button("left_mouse", MOUSE_BUTTON_LEFT)
	await _test_mouse_button("right_mouse", MOUSE_BUTTON_RIGHT)
	await _test_locked_shield_charge()
	await _unlock_shield_charge()
	await _test_key("shield_charge_v", KEY_V)
	quit()


func _test_mouse_button(label: String, button: MouseButton) -> void:
	var player := get_first_node_in_group("player")
	_send_mouse(button, true)
	await process_frame
	await physics_frame
	_send_mouse(button, false)
	await physics_frame
	_print_player_state(label, player)
	_clear_player_action(player)


func _test_key(label: String, keycode: Key) -> void:
	var player := get_first_node_in_group("player")
	_send_key(keycode, true)
	await physics_frame
	_send_key(keycode, false)
	await physics_frame
	_print_player_state(label, player)
	_clear_player_action(player)


func _test_locked_shield_charge() -> void:
	var player := get_first_node_in_group("player")
	_send_key(KEY_V, true)
	await physics_frame
	_send_key(KEY_V, false)
	await physics_frame
	if float(player.get("action_lock")) > 0.0:
		print("shield_charge_locked FAIL action_lock=%.2f" % float(player.get("action_lock")))
		quit(1)
		return
	print("shield_charge_locked ok")


func _unlock_shield_charge() -> void:
	var player := get_first_node_in_group("player")
	player.call("gain_xp", int(player.call("get_xp_to_next_level")))
	if not bool(player.call("unlock_skill", "shield_charge")):
		print("shield_charge_unlock FAIL level=%d points=%d" % [int(player.call("get_level")), int(player.call("get_available_skill_points"))])
		quit(1)
		return
	print("shield_charge_unlock ok")


func _send_mouse(button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = Vector2(640, 360)
	Input.parse_input_event(event)


func _send_key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)


func _print_player_state(label: String, player: Node) -> void:
	if player == null:
		print("%s player=null" % label)
		return
	var sprite := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var animation := StringName("")
	if sprite != null:
		animation = sprite.animation
	print(
		"%s action_lock=%.2f animation=%s action_direction=%s attack_blocked=%s"
		% [
			label,
			float(player.get("action_lock")),
			animation,
			_fmt_vec(player.call("get_action_direction")),
			player.call("is_attack_input_blocked") if player.has_method("is_attack_input_blocked") else "?",
		]
	)
	print(
		"%s pending_hit=%.2f pending_sfx=%.2f"
		% [
			label,
			float(player.get("pending_hit_time")),
			float(player.get("pending_sfx_time")),
		]
	)


func _clear_player_action(player: Node) -> void:
	if player == null:
		return
	player.set("action_lock", 0.0)
	player.set("pending_hit_time", -1.0)
	player.set("pending_second_hit_time", -1.0)
	player.set("pending_sfx_time", -1.0)


func _fmt_vec(value: Vector2) -> String:
	return "(%.1f, %.1f)" % [value.x, value.y]


func _wait_for_scene() -> bool:
	for _i in range(20):
		await physics_frame
		if current_scene != null and get_first_node_in_group("player") != null:
			return true
	return false
