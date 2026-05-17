extends Control

signal inventory_slot_pressed(slot_index: int)
signal equipment_slot_pressed
signal equip_selected_requested

const INVENTORY_SLOT_TEXTURE := preload("res://assets/ui/inventory_slot.png")
const EQUIPMENT_SLOT_TEXTURE := preload("res://assets/ui/equipment_weapon_slot.png")
const SLOT_SIZE := Vector2(64, 64)
const ITEM_ICON_SIZE := Vector2(48, 48)
const UI_MARGIN := 24.0
const PANEL_COLOR := Color(0.055, 0.058, 0.052, 0.82)
const SELECTED_SLOT_COLOR := Color(0.95, 0.78, 0.24, 0.34)
const CURSOR_SLOT_COLOR := Color(0.36, 0.64, 1.0, 0.24)
const LABEL_COLOR := Color(0.9, 0.88, 0.72, 1.0)
const EMPTY_LABEL_COLOR := Color(0.48, 0.48, 0.42, 1.0)
const RARITY_COLORS := {
	"normal": Color(0.82, 0.78, 0.68, 1.0),
	"magic": Color(0.36, 0.64, 1.0, 1.0),
	"rare": Color(1.0, 0.78, 0.25, 1.0),
}

var background: ColorRect
var equipment_slot_highlight: ColorRect
var equipment_icon: TextureRect
var equipment_name_label: Label
var equipment_damage_label: Label
var equipment_slots_label: Label
var slot_icons: Array[TextureRect] = []
var slot_bonus_labels: Array[Label] = []
var slot_highlights: Array[ColorRect] = []
var selected_name_label: Label
var selected_rarity_label: Label
var selected_type_label: Label
var selected_slot_label: Label
var selected_damage_label: Label
var progression_level_label: Label
var progression_xp_label: Label
var progression_skill_points_label: Label
var equip_button: Button
var cursor_status_label: Label
var selected_slot_index := -1
var icon_cache := {}


func setup() -> void:
	name = "InventoryPanel"
	size = Vector2(780, 390)
	visible = false

	background = ColorRect.new()
	background.color = PANEL_COLOR
	background.size = size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	add_child(_make_label("Equipment", Vector2(22, 18), Vector2(190, 26), 20, LABEL_COLOR))
	add_child(_make_label("Bag", Vector2(22, 238), Vector2(150, 26), 20, LABEL_COLOR))

	var equip_slot := Control.new()
	equip_slot.position = Vector2(22, 54)
	equip_slot.size = SLOT_SIZE
	add_child(equip_slot)
	_add_slot_background(equip_slot, EQUIPMENT_SLOT_TEXTURE)

	equipment_slot_highlight = ColorRect.new()
	equipment_slot_highlight.color = CURSOR_SLOT_COLOR
	equipment_slot_highlight.size = SLOT_SIZE
	equipment_slot_highlight.visible = false
	equipment_slot_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	equip_slot.add_child(equipment_slot_highlight)

	equipment_icon = TextureRect.new()
	equipment_icon.position = Vector2(8, 8)
	equipment_icon.size = ITEM_ICON_SIZE
	equipment_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	equipment_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	equipment_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	equip_slot.add_child(equipment_icon)

	var equip_slot_button := Button.new()
	equip_slot_button.flat = true
	equip_slot_button.text = ""
	equip_slot_button.size = SLOT_SIZE
	equip_slot_button.focus_mode = Control.FOCUS_NONE
	equip_slot_button.pressed.connect(_on_equipment_slot_pressed)
	equip_slot.add_child(equip_slot_button)

	equipment_name_label = _make_label("None", Vector2(104, 56), Vector2(290, 24), 18, LABEL_COLOR)
	add_child(equipment_name_label)
	equipment_damage_label = _make_label("Damage: ?", Vector2(104, 86), Vector2(230, 24), 18, LABEL_COLOR)
	add_child(equipment_damage_label)
	equipment_slots_label = _make_label("Slots: Weapon active, Chest/Accessory locked", Vector2(104, 116), Vector2(330, 24), 15, EMPTY_LABEL_COLOR)
	add_child(equipment_slots_label)

	add_child(_make_label("Selected", Vector2(430, 18), Vector2(150, 26), 20, LABEL_COLOR))
	selected_name_label = _make_label("None", Vector2(430, 52), Vector2(250, 24), 18, LABEL_COLOR)
	add_child(selected_name_label)
	selected_rarity_label = _make_label("Rarity: -", Vector2(430, 82), Vector2(210, 24), 18, EMPTY_LABEL_COLOR)
	add_child(selected_rarity_label)
	selected_type_label = _make_label("Type: -", Vector2(430, 112), Vector2(210, 24), 17, LABEL_COLOR)
	add_child(selected_type_label)
	selected_slot_label = _make_label("Slot: -", Vector2(430, 140), Vector2(210, 24), 17, LABEL_COLOR)
	add_child(selected_slot_label)
	selected_damage_label = _make_label("Stat: -", Vector2(430, 168), Vector2(210, 24), 17, LABEL_COLOR)
	add_child(selected_damage_label)

	add_child(_make_label("Progression", Vector2(430, 210), Vector2(170, 26), 20, LABEL_COLOR))
	progression_level_label = _make_label("Level: 1", Vector2(430, 242), Vector2(170, 24), 18, LABEL_COLOR)
	add_child(progression_level_label)
	progression_xp_label = _make_label("XP: 0 / 40", Vector2(430, 272), Vector2(190, 24), 18, LABEL_COLOR)
	add_child(progression_xp_label)
	progression_skill_points_label = _make_label("Skill Points: 0", Vector2(430, 302), Vector2(210, 24), 17, LABEL_COLOR)
	add_child(progression_skill_points_label)

	equip_button = Button.new()
	equip_button.text = "Equip"
	equip_button.position = Vector2(660, 56)
	equip_button.size = Vector2(96, 38)
	equip_button.disabled = true
	equip_button.pressed.connect(_on_equip_selected_requested)
	add_child(equip_button)

	cursor_status_label = _make_label("Cursor: Empty", Vector2(430, 346), Vector2(310, 24), 17, EMPTY_LABEL_COLOR)
	add_child(cursor_status_label)

	for i in range(10):
		_add_inventory_slot(i)


func layout(viewport_size: Vector2) -> void:
	position = _clamped_panel_position(Vector2(viewport_size.x - size.x - UI_MARGIN, UI_MARGIN), size, viewport_size)
	if background != null:
		background.size = size


func refresh(player: Node, cursor_item: Dictionary) -> void:
	if not is_instance_valid(player) or not player.has_method("get_inventory_items"):
		return

	var equipped: Dictionary = {}
	if player.has_method("get_equipped_weapon"):
		equipped = player.get_equipped_weapon()
	if equipped.is_empty():
		equipment_icon.texture = null
		equipment_name_label.text = "None"
	else:
		equipment_icon.texture = _load_icon(str(equipped.get("icon", "")))
		equipment_name_label.text = str(equipped.get("name", "Weapon"))

	var damage_text := "?"
	if player.has_method("get_current_attack_damage"):
		damage_text = str(player.get_current_attack_damage())
	equipment_damage_label.text = "Damage: %s" % damage_text
	if player.has_method("get_level"):
		progression_level_label.text = "Level: %d" % int(player.get_level())
	if player.has_method("get_current_xp") and player.has_method("get_xp_to_next_level"):
		progression_xp_label.text = "XP: %d / %d" % [int(player.get_current_xp()), int(player.get_xp_to_next_level())]
	if player.has_method("get_available_skill_points"):
		progression_skill_points_label.text = "Skill Points: %d" % int(player.get_available_skill_points())

	var items: Array = player.get_inventory_items()
	if selected_slot_index >= items.size() or (selected_slot_index >= 0 and items[selected_slot_index].is_empty()):
		selected_slot_index = -1
	for i in range(slot_icons.size()):
		if i < items.size() and not items[i].is_empty():
			var item: Dictionary = items[i]
			slot_icons[i].texture = _load_icon(str(item.get("icon", "")))
			slot_bonus_labels[i].text = "+%d" % int(item.get("damage_bonus", 0))
		else:
			slot_icons[i].texture = null
			slot_bonus_labels[i].text = ""
		slot_highlights[i].visible = i == selected_slot_index
	_update_selected_item_details(items, cursor_item)
	equipment_slot_highlight.visible = not cursor_item.is_empty() and str(cursor_item.get("equip_slot", "")) == "weapon"


func select_slot(slot_index: int, player: Node) -> void:
	if not is_instance_valid(player) or not player.has_method("get_inventory_items"):
		selected_slot_index = -1
		return
	var items: Array = player.get_inventory_items()
	selected_slot_index = slot_index if slot_index < items.size() and not items[slot_index].is_empty() else -1


func clear_selection() -> void:
	selected_slot_index = -1


func get_selected_slot_index() -> int:
	return selected_slot_index


func _add_inventory_slot(index: int) -> void:
	var slot := Control.new()
	slot.position = Vector2(22 + index * 70, 270)
	slot.size = SLOT_SIZE
	add_child(slot)
	_add_slot_background(slot, INVENTORY_SLOT_TEXTURE)

	var highlight := ColorRect.new()
	highlight.color = SELECTED_SLOT_COLOR
	highlight.size = SLOT_SIZE
	highlight.visible = false
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(highlight)
	slot_highlights.append(highlight)

	slot.add_child(_make_label(_slot_key_text(index), Vector2(5, 2), Vector2(22, 18), 13, EMPTY_LABEL_COLOR))

	var icon := TextureRect.new()
	icon.position = Vector2(8, 8)
	icon.size = ITEM_ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	slot_icons.append(icon)

	var bonus := _make_label("", Vector2(30, 42), Vector2(34, 18), 13, LABEL_COLOR)
	slot.add_child(bonus)
	slot_bonus_labels.append(bonus)

	var button := Button.new()
	button.flat = true
	button.text = ""
	button.size = SLOT_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_inventory_slot_pressed.bind(index))
	slot.add_child(button)


func _update_selected_item_details(items: Array, cursor_item: Dictionary) -> void:
	if not cursor_item.is_empty():
		_set_item_detail_labels(cursor_item, "Cursor")
		equip_button.disabled = str(cursor_item.get("equip_slot", "")) != "weapon"
		cursor_status_label.text = "Cursor: %s" % str(cursor_item.get("name", "Item"))
		cursor_status_label.add_theme_color_override("font_color", _item_color(cursor_item))
		return

	if selected_slot_index < 0 or selected_slot_index >= items.size():
		selected_name_label.text = "None"
		selected_name_label.add_theme_color_override("font_color", LABEL_COLOR)
		selected_rarity_label.text = "Rarity: -"
		selected_rarity_label.add_theme_color_override("font_color", EMPTY_LABEL_COLOR)
		selected_type_label.text = "Type: -"
		selected_slot_label.text = "Slot: -"
		selected_damage_label.text = "Stat: -"
		equip_button.disabled = true
		cursor_status_label.text = "Cursor: Empty"
		cursor_status_label.add_theme_color_override("font_color", EMPTY_LABEL_COLOR)
		return

	_set_item_detail_labels(items[selected_slot_index], "Selected")
	equip_button.disabled = false


func _set_item_detail_labels(item: Dictionary, source_label: String) -> void:
	var rarity := str(item.get("rarity", "normal"))
	var rarity_color := _item_color(item)
	selected_name_label.text = "%s: %s" % [source_label, str(item.get("name", "Weapon"))]
	selected_name_label.add_theme_color_override("font_color", rarity_color)
	selected_rarity_label.text = "Rarity: %s" % rarity.capitalize()
	selected_rarity_label.add_theme_color_override("font_color", rarity_color)
	selected_type_label.text = "Type: %s" % str(item.get("item_type", item.get("type", "-"))).capitalize()
	selected_slot_label.text = "Slot: %s" % str(item.get("equip_slot", "-")).capitalize()
	selected_damage_label.text = "Stat Damage: +%d" % int(item.get("damage_bonus", 0))


func _add_slot_background(parent: Control, texture: Texture2D) -> void:
	var slot_background := TextureRect.new()
	slot_background.texture = texture
	slot_background.size = SLOT_SIZE
	slot_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(slot_background)


func _make_label(label_text: String, label_position: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = label_text
	label.position = label_position
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _load_icon(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not icon_cache.has(path):
		icon_cache[path] = load(path) as Texture2D
	return icon_cache[path]


func _item_color(item: Dictionary) -> Color:
	var rarity := str(item.get("rarity", "normal"))
	return item.get("color", RARITY_COLORS.get(rarity, LABEL_COLOR))


func _slot_key_text(index: int) -> String:
	if index == 9:
		return "0"
	return str(index + 1)


func _clamped_panel_position(desired_position: Vector2, panel_size: Vector2, viewport_size: Vector2) -> Vector2:
	return Vector2(
		clampf(desired_position.x, UI_MARGIN, maxf(UI_MARGIN, viewport_size.x - panel_size.x - UI_MARGIN)),
		clampf(desired_position.y, UI_MARGIN, maxf(UI_MARGIN, viewport_size.y - panel_size.y - UI_MARGIN))
	)


func _on_inventory_slot_pressed(slot_index: int) -> void:
	inventory_slot_pressed.emit(slot_index)


func _on_equipment_slot_pressed() -> void:
	equipment_slot_pressed.emit()


func _on_equip_selected_requested() -> void:
	equip_selected_requested.emit()
