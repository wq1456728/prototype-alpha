extends Label

const LABEL_COLOR := Color(0.9, 0.88, 0.72, 1.0)


func setup() -> void:
	position = Vector2(16, 16)
	size = Vector2(390, 152)
	add_theme_font_size_override("font_size", 15)
	add_theme_color_override("font_color", LABEL_COLOR)


func refresh(player: Node, enemy_count: int, cursor_item: Dictionary, collision_debug_visible: bool) -> void:
	var hp_text := "?"
	var damage_text := "?"
	var weapon_text := "?"
	var level_text := "?"
	var xp_text := "?/?"
	var skill_points_text := "?"
	var facing_text := "?"
	var action_text := "?"
	var cursor_text := "None"
	var collision_text := "On" if collision_debug_visible else "Off"

	if is_instance_valid(player):
		var hp_value = player.get("hp")
		hp_text = str(hp_value) if hp_value != null else "?"
		if player.has_method("get_current_attack_damage"):
			damage_text = str(player.get_current_attack_damage())
		if player.has_method("get_level"):
			level_text = str(player.get_level())
		if player.has_method("get_current_xp") and player.has_method("get_xp_to_next_level"):
			xp_text = "%d/%d" % [int(player.get_current_xp()), int(player.get_xp_to_next_level())]
		if player.has_method("get_available_skill_points"):
			skill_points_text = str(player.get_available_skill_points())
		if player.has_method("get_equipped_weapon_name"):
			weapon_text = str(player.get_equipped_weapon_name())
		if player.has_method("get_facing_direction"):
			facing_text = _format_vector(player.get_facing_direction())
		if player.has_method("get_action_direction"):
			action_text = _format_vector(player.get_action_direction())
	if not cursor_item.is_empty():
		cursor_text = str(cursor_item.get("name", "Item"))

	text = "Enemies: %d\nHP: %s\nLevel: %s\nXP: %s\nSkill Points: %s\nDamage: %s\nWeapon: %s\nCursor: %s\nCollision: %s\nFacing: %s\nAction: %s" % [
		enemy_count,
		hp_text,
		level_text,
		xp_text,
		skill_points_text,
		damage_text,
		weapon_text,
		cursor_text,
		collision_text,
		facing_text,
		action_text,
	]


func _format_vector(value: Vector2) -> String:
	return "(%.2f, %.2f)" % [value.x, value.y]
