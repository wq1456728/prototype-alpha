extends Control

signal unlock_requested(skill_id: String)

const SKILL_TREE_ICON_SIZE := Vector2(70, 70)
const UI_MARGIN := 24.0
const UI_BOTTOM_MARGIN := 18.0
const HOTBAR_SLOT_SIZE := Vector2(78, 78)
const PANEL_COLOR := Color(0.055, 0.058, 0.052, 0.82)
const SKILL_NODE_COLOR := Color(0.075, 0.07, 0.058, 0.92)
const SKILL_NODE_LOCKED_COLOR := Color(0.038, 0.038, 0.035, 0.9)
const LABEL_COLOR := Color(0.9, 0.88, 0.72, 1.0)
const EMPTY_LABEL_COLOR := Color(0.48, 0.48, 0.42, 1.0)

var background: ColorRect
var skill_points_label: Label
var skill_node_labels := {}
var skill_node_cards := {}
var skill_node_icons := {}
var skill_unlock_buttons := {}
var icon_cache := {}
var skill_icon_cache := {}


func setup() -> void:
	name = "SkillTreePanel"
	size = Vector2(660, 560)
	visible = false

	background = ColorRect.new()
	background.color = PANEL_COLOR
	background.size = size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	add_child(_make_label("Skill Tree", Vector2(24, 20), Vector2(230, 32), 28, LABEL_COLOR))
	skill_points_label = _make_label("Skill Points: 0", Vector2(430, 26), Vector2(210, 28), 20, LABEL_COLOR)
	add_child(skill_points_label)

	_add_skill_dependency_line(Vector2(326, 188), Vector2(326, 244))
	_add_skill_dependency_line(Vector2(326, 350), Vector2(326, 390))
	_add_skill_node("heavy_strike", Vector2(80, 82))
	_add_skill_node("shield_charge", Vector2(80, 244))
	_add_skill_node("shield_training", Vector2(80, 390))


func layout(viewport_size: Vector2) -> void:
	var hotbar_top := viewport_size.y - HOTBAR_SLOT_SIZE.y - UI_BOTTOM_MARGIN
	var desired_y := maxf(UI_MARGIN, minf((viewport_size.y - size.y) * 0.5, hotbar_top - size.y - 14.0))
	position = _clamped_panel_position(Vector2((viewport_size.x - size.x) * 0.5, desired_y), size, viewport_size)
	if background != null:
		background.size = size


func refresh(player: Node) -> void:
	if not is_instance_valid(player):
		return
	if player.has_method("get_available_skill_points"):
		skill_points_label.text = "Skill Points: %d" % int(player.get_available_skill_points())
	for skill_id in skill_node_labels.keys():
		var skill: Dictionary = player.get_skill_definition(str(skill_id)) if player.has_method("get_skill_definition") else {}
		var rank := int(player.get_skill_rank(str(skill_id))) if player.has_method("get_skill_rank") else 0
		var can_unlock := bool(player.can_unlock_skill(str(skill_id))) if player.has_method("can_unlock_skill") else false
		var unlocked := rank > 0
		var required_level := int(skill.get("required_level", 1))
		var cost := int(skill.get("unlock_cost", 1))
		var prereq_text := _prerequisite_text(player, skill)
		var tooltip := _format_skill_tooltip(str(skill_id), skill)
		var label: Label = skill_node_labels[skill_id]
		label.text = "%s\nRank %d/%d | Cost %d | Level %d\nPrereq: %s\n%s" % [
			str(skill.get("name", skill_id)),
			rank,
			int(skill.get("max_rank", 1)),
			cost,
			required_level,
			prereq_text,
			str(skill.get("description", "")),
		]
		label.add_theme_color_override("font_color", LABEL_COLOR if unlocked or can_unlock else EMPTY_LABEL_COLOR)
		label.tooltip_text = tooltip
		var card: ColorRect = skill_node_cards.get(skill_id, null)
		if card != null:
			card.color = SKILL_NODE_COLOR if unlocked or can_unlock else SKILL_NODE_LOCKED_COLOR
		var icon: TextureRect = skill_node_icons.get(skill_id, null)
		if icon != null:
			icon.texture = _skill_icon_texture(str(skill_id), skill)
			icon.modulate = Color.WHITE if unlocked or can_unlock else Color(0.5, 0.5, 0.5, 1.0)
			icon.tooltip_text = tooltip
		var unlock_button: Button = skill_unlock_buttons[skill_id]
		unlock_button.text = "Ranked" if unlocked else "Unlock"
		unlock_button.disabled = unlocked or not can_unlock
		unlock_button.tooltip_text = tooltip


func _add_skill_dependency_line(start: Vector2, end: Vector2) -> void:
	var line := ColorRect.new()
	line.color = Color(0.62, 0.52, 0.28, 0.72)
	line.position = Vector2(start.x - 3.0, start.y)
	line.size = Vector2(6, maxf(end.y - start.y, 1.0))
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)


func _add_skill_node(skill_id: String, node_position: Vector2) -> void:
	var card := Control.new()
	card.position = node_position
	card.size = Vector2(500, 116)
	add_child(card)

	var card_background := ColorRect.new()
	card_background.color = SKILL_NODE_COLOR
	card_background.size = card.size
	card_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(card_background)
	skill_node_cards[skill_id] = card_background

	var icon := TextureRect.new()
	icon.position = Vector2(18, 22)
	icon.size = SKILL_TREE_ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(icon)
	skill_node_icons[skill_id] = icon

	var label := _make_label("", Vector2(106, 14), Vector2(265, 90), 16, LABEL_COLOR)
	card.add_child(label)
	skill_node_labels[skill_id] = label

	var unlock_button := Button.new()
	unlock_button.text = "Unlock"
	unlock_button.position = Vector2(390, 38)
	unlock_button.size = Vector2(88, 40)
	unlock_button.focus_mode = Control.FOCUS_NONE
	unlock_button.pressed.connect(_on_unlock_pressed.bind(skill_id))
	card.add_child(unlock_button)
	skill_unlock_buttons[skill_id] = unlock_button


func _prerequisite_text(player: Node, skill: Dictionary) -> String:
	var prereqs: Array = skill.get("required_skill_ids", [])
	if prereqs.is_empty():
		return "None"
	var prereq_names := PackedStringArray()
	for prereq in prereqs:
		var prereq_skill: Dictionary = player.get_skill_definition(str(prereq)) if player.has_method("get_skill_definition") else {}
		prereq_names.append(str(prereq_skill.get("name", prereq)))
	return ", ".join(prereq_names)


func _format_skill_tooltip(skill_id: String, skill: Dictionary) -> String:
	if skill_id.is_empty() or skill.is_empty():
		return "No skill assigned."
	var lines := PackedStringArray()
	lines.append(str(skill.get("name", skill_id)))
	lines.append(str(skill.get("description", "")))
	var skill_type := str(skill.get("skill_type", "active"))
	if bool(skill.get("baseline", false)):
		lines.append("Baseline action. Not part of the Skill Tree.")
	else:
		lines.append("%s | Level %d | Cost %d" % [skill_type.capitalize(), int(skill.get("required_level", 1)), int(skill.get("unlock_cost", 1))])
	return "\n".join(lines)


func _skill_icon_texture(skill_id: String, skill: Dictionary) -> Texture2D:
	if skill_id.is_empty():
		return null
	var icon_path := str(skill.get("icon", ""))
	if not icon_path.is_empty():
		return _load_icon(icon_path)
	if skill_icon_cache.has(skill_id):
		return skill_icon_cache[skill_id]

	var base_color := _skill_icon_color(skill_id, skill)
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(base_color)
	var edge_color := Color(0.08, 0.075, 0.06, 1.0)
	var inner_color := Color(minf(base_color.r + 0.22, 1.0), minf(base_color.g + 0.22, 1.0), minf(base_color.b + 0.22, 1.0), 1.0)
	for x in range(64):
		for y in range(64):
			if x < 3 or y < 3 or x >= 61 or y >= 61:
				image.set_pixel(x, y, edge_color)
			elif x < 7 or y < 7 or x >= 57 or y >= 57:
				image.set_pixel(x, y, inner_color)
	for i in range(18, 46):
		image.set_pixel(i, i, inner_color)
		image.set_pixel(63 - i, i, Color(0.02, 0.02, 0.018, 1.0))
	var texture := ImageTexture.create_from_image(image)
	skill_icon_cache[skill_id] = texture
	return texture


func _skill_icon_color(skill_id: String, skill: Dictionary) -> Color:
	var values: Array = skill.get("icon_color", [])
	if values.size() >= 3:
		return Color(float(values[0]), float(values[1]), float(values[2]), 1.0)
	match skill_id:
		"light_attack":
			return Color(0.78, 0.72, 0.48, 1.0)
		"heavy_strike":
			return Color(0.72, 0.33, 0.18, 1.0)
		"shield_charge":
			return Color(0.26, 0.48, 0.82, 1.0)
		"shield_training":
			return Color(0.36, 0.62, 0.42, 1.0)
	return Color(0.55, 0.52, 0.42, 1.0)


func _load_icon(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not icon_cache.has(path):
		icon_cache[path] = load(path) as Texture2D
	return icon_cache[path]


func _make_label(label_text: String, label_position: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = label_text
	label.position = label_position
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _clamped_panel_position(desired_position: Vector2, panel_size: Vector2, viewport_size: Vector2) -> Vector2:
	return Vector2(
		clampf(desired_position.x, UI_MARGIN, maxf(UI_MARGIN, viewport_size.x - panel_size.x - UI_MARGIN)),
		clampf(desired_position.y, UI_MARGIN, maxf(UI_MARGIN, viewport_size.y - panel_size.y - UI_MARGIN))
	)


func _on_unlock_pressed(skill_id: String) -> void:
	unlock_requested.emit(skill_id)
