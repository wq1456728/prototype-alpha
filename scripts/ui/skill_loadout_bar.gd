extends Control

signal slot_pressed(slot_id: String)
signal skill_selected(skill_id: String, slot_id: String)

const HOTBAR_SLOT_SIZE := Vector2(78, 78)
const HOTBAR_SLOT_GAP := 10.0
const SKILL_ICON_SIZE := Vector2(52, 52)
const UI_MARGIN := 24.0
const UI_BOTTOM_MARGIN := 18.0
const HOTBAR_SLOT_COLOR := Color(0.085, 0.082, 0.072, 0.92)
const HOTBAR_PICKER_COLOR := Color(0.045, 0.045, 0.04, 0.95)
const LABEL_COLOR := Color(0.9, 0.88, 0.72, 1.0)
const EMPTY_LABEL_COLOR := Color(0.48, 0.48, 0.42, 1.0)

var slot_controls := {}
var slot_buttons := {}
var slot_icons := {}
var slot_labels := {}
var slot_skill_labels := {}
var picker_panel: Control
var picker_background: ColorRect
var picker_slot_id := ""
var picker_buttons := {}
var icon_cache := {}
var skill_icon_cache := {}


func setup(player: Node) -> void:
	name = "SkillLoadoutBar"
	size = Vector2(6 * HOTBAR_SLOT_SIZE.x + 5 * HOTBAR_SLOT_GAP, HOTBAR_SLOT_SIZE.y)
	if not is_instance_valid(player) or not player.has_method("get_loadout_slots"):
		return
	var slots: Array = player.get_loadout_slots()
	for i in range(slots.size()):
		_add_slot(i, slots[i])
	_create_picker_panel()


func layout(viewport_size: Vector2) -> void:
	position = Vector2(
		maxf(UI_MARGIN, (viewport_size.x - size.x) * 0.5),
		maxf(UI_MARGIN, viewport_size.y - HOTBAR_SLOT_SIZE.y - UI_BOTTOM_MARGIN)
	)
	position_picker(viewport_size)


func refresh(player: Node) -> void:
	if not is_instance_valid(player) or not player.has_method("get_loadout_slots"):
		return
	var slots: Array = player.get_loadout_slots()
	for slot in slots:
		var slot_id := str(slot.get("id", ""))
		var button: Button = slot_buttons.get(slot_id, null)
		var skill_id := str(player.get_loadout_skill(slot_id))
		var skill: Dictionary = player.get_skill_definition(skill_id) if not skill_id.is_empty() and player.has_method("get_skill_definition") else {}
		var skill_name := "-" if skill_id.is_empty() else str(skill.get("name", skill_id))
		var icon: TextureRect = slot_icons.get(slot_id, null)
		if icon != null:
			icon.texture = _skill_icon_texture(skill_id, skill) if not skill_id.is_empty() else null
		var skill_label: Label = slot_skill_labels.get(slot_id, null)
		if skill_label != null:
			skill_label.text = _short_skill_name(skill_name)
		if button != null:
			button.tooltip_text = "%s\n%s" % [
				str(slot.get("label", slot_id)).to_upper(),
				_format_skill_tooltip(skill_id, skill) if not skill_id.is_empty() else "Click to assign a learned active skill.",
			]


func show_picker(player: Node, slot_id: String, viewport_size: Vector2) -> void:
	if picker_panel == null:
		return
	picker_slot_id = slot_id
	_rebuild_picker(player, slot_id)
	picker_panel.visible = true
	position_picker(viewport_size)


func hide_picker() -> void:
	if picker_panel == null:
		return
	picker_panel.visible = false
	picker_slot_id = ""


func is_picker_visible() -> bool:
	return picker_panel != null and picker_panel.visible


func is_picker_for_slot(slot_id: String) -> bool:
	return is_picker_visible() and picker_slot_id == slot_id


func get_picker_option_count() -> int:
	return picker_buttons.size()


func get_picker_tooltip(skill_id: String) -> String:
	var button: Button = picker_buttons.get(skill_id, null)
	return button.tooltip_text if button != null else ""


func select_picker_skill(skill_id: String) -> bool:
	if picker_slot_id.is_empty():
		return false
	skill_selected.emit(skill_id, picker_slot_id)
	return true


func contains_screen_point(screen_position: Vector2) -> bool:
	if get_global_rect().has_point(screen_position):
		return true
	return picker_panel != null and picker_panel.visible and picker_panel.get_global_rect().has_point(screen_position)


func position_picker(viewport_size: Vector2) -> void:
	if picker_panel == null or not picker_panel.visible:
		return
	var slot_root: Control = slot_controls.get(picker_slot_id, null)
	if slot_root == null:
		return
	var slot_rect := slot_root.get_global_rect()
	var desired := Vector2(slot_rect.position.x + slot_rect.size.x * 0.5 - picker_panel.size.x * 0.5, slot_rect.position.y - picker_panel.size.y - 12.0)
	picker_panel.position = _clamped_panel_position(desired, picker_panel.size, viewport_size)
	if picker_background != null:
		picker_background.size = picker_panel.size


func rebuild_picker_if_visible(player: Node, viewport_size: Vector2) -> void:
	if is_picker_visible():
		_rebuild_picker(player, picker_slot_id)
		position_picker(viewport_size)


func _add_slot(index: int, slot: Dictionary) -> void:
	var slot_id := str(slot.get("id", ""))
	var slot_root := Control.new()
	slot_root.position = Vector2(index * (HOTBAR_SLOT_SIZE.x + HOTBAR_SLOT_GAP), 0)
	slot_root.size = HOTBAR_SLOT_SIZE
	add_child(slot_root)
	slot_controls[slot_id] = slot_root

	var background := ColorRect.new()
	background.color = HOTBAR_SLOT_COLOR
	background.size = HOTBAR_SLOT_SIZE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_root.add_child(background)

	var icon := TextureRect.new()
	icon.position = Vector2(13, 8)
	icon.size = SKILL_ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_root.add_child(icon)
	slot_icons[slot_id] = icon

	var slot_label := _make_label(str(slot.get("label", slot_id)).to_upper(), Vector2(4, 2), Vector2(42, 18), 13, EMPTY_LABEL_COLOR)
	slot_root.add_child(slot_label)
	slot_labels[slot_id] = slot_label

	var skill_label := _make_label("-", Vector2(4, 61), Vector2(70, 16), 12, LABEL_COLOR)
	skill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_root.add_child(skill_label)
	slot_skill_labels[slot_id] = skill_label

	var button := Button.new()
	button.flat = true
	button.text = ""
	button.size = HOTBAR_SLOT_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_slot_pressed.bind(slot_id))
	slot_root.add_child(button)
	slot_buttons[slot_id] = button


func _create_picker_panel() -> void:
	picker_panel = Control.new()
	picker_panel.name = "SkillLoadoutPicker"
	picker_panel.size = Vector2(360, 94)
	picker_panel.visible = false
	get_parent().add_child(picker_panel)

	picker_background = ColorRect.new()
	picker_background.color = HOTBAR_PICKER_COLOR
	picker_background.size = picker_panel.size
	picker_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picker_panel.add_child(picker_background)


func _rebuild_picker(player: Node, slot_id: String) -> void:
	if picker_panel == null:
		return
	for child in picker_panel.get_children():
		if child != picker_background:
			picker_panel.remove_child(child)
			child.queue_free()
	picker_buttons.clear()

	var skills := _assignable_active_skills(player, slot_id)
	var option_count := maxi(skills.size(), 1)
	picker_panel.size = Vector2(22 + option_count * 70, 98)
	if picker_background != null:
		picker_background.size = picker_panel.size

	if skills.is_empty():
		picker_panel.add_child(_make_label("No learned active skills", Vector2(14, 36), Vector2(220, 24), 16, EMPTY_LABEL_COLOR))
		return

	for i in range(skills.size()):
		var skill: Dictionary = skills[i]
		var skill_id := str(skill.get("id", ""))
		var button := Button.new()
		button.position = Vector2(14 + i * 70, 14)
		button.size = Vector2(58, 70)
		button.text = ""
		button.icon = _skill_icon_texture(skill_id, skill)
		button.expand_icon = true
		button.tooltip_text = _format_skill_tooltip(skill_id, skill)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_picker_skill_pressed.bind(skill_id))
		picker_panel.add_child(button)
		picker_buttons[skill_id] = button


func _assignable_active_skills(player: Node, slot_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not is_instance_valid(player):
		return result
	var seen := {}
	var current_skill_id := str(player.get_loadout_skill(slot_id)) if player.has_method("get_loadout_skill") else ""
	for skill_id in _all_loadout_candidate_skill_ids(player):
		if seen.has(skill_id):
			continue
		seen[skill_id] = true
		if current_skill_id == skill_id:
			continue
		if not player.has_method("can_assign_skill_to_slot") or not bool(player.can_assign_skill_to_slot(skill_id, slot_id)):
			continue
		var skill: Dictionary = player.get_skill_definition(skill_id) if player.has_method("get_skill_definition") else {}
		if skill.is_empty() or str(skill.get("skill_type", "")) != "active":
			continue
		skill["id"] = skill_id
		result.append(skill)
	return result


func _all_loadout_candidate_skill_ids(player: Node) -> Array[String]:
	var ids: Array[String] = ["light_attack"]
	if is_instance_valid(player) and player.has_method("get_skill_tree_skill_ids"):
		for skill_id in player.get_skill_tree_skill_ids():
			ids.append(str(skill_id))
	return ids


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


func _short_skill_name(skill_name: String) -> String:
	if skill_name == "-" or skill_name.is_empty():
		return "-"
	var parts := skill_name.split(" ", false)
	if parts.size() <= 1:
		return skill_name.substr(0, 8)
	return str(parts[0]).substr(0, 6)


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


func _on_slot_pressed(slot_id: String) -> void:
	slot_pressed.emit(slot_id)


func _on_picker_skill_pressed(skill_id: String) -> void:
	select_picker_skill(skill_id)
