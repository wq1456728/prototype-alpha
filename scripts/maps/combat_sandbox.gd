extends Node2D

const MUMMY_SCENE := preload("res://scenes/enemy/mummy_enemy.tscn")
const WEAPON_PICKUP_SCENE := preload("res://scenes/items/weapon_pickup.tscn")
const INVENTORY_SLOT_TEXTURE := preload("res://assets/ui/inventory_slot.png")
const EQUIPMENT_SLOT_TEXTURE := preload("res://assets/ui/equipment_weapon_slot.png")
const RESPAWN_DELAY := 4.0
const SLOT_SIZE := Vector2(48, 48)
const ITEM_ICON_SIZE := Vector2(32, 32)
const WORLD_ITEM_CLICK_RADIUS := 36.0
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

@onready var player: Node2D = $KnightPlayer
@onready var enemies_root: Node2D = $Enemies
@onready var debug_canvas: CanvasLayer = $DebugCanvas
@onready var debug_label: Label = $DebugCanvas/DebugLabel

var respawn_pending := false
var inventory_panel: Control
var equipment_slot_highlight: ColorRect
var equipment_icon: TextureRect
var equipment_name_label: Label
var equipment_damage_label: Label
var inventory_slot_icons: Array[TextureRect] = []
var inventory_slot_bonus_labels: Array[Label] = []
var inventory_slot_highlights: Array[ColorRect] = []
var selected_name_label: Label
var selected_rarity_label: Label
var selected_damage_label: Label
var equip_button: Button
var cursor_item_icon: TextureRect
var cursor_status_label: Label
var selected_slot_index := -1
var cursor_item: Dictionary = {}
var icon_cache := {}


func _ready() -> void:
	_build_inventory_ui()
	_spawn_wave()


func _process(_delta: float) -> void:
	_update_debug_label()
	_update_inventory_ui()
	_update_cursor_item_ui()
	if respawn_pending:
		return
	if get_tree().get_nodes_in_group("enemy").is_empty():
		respawn_pending = true
		await get_tree().create_timer(RESPAWN_DELAY).timeout
		_spawn_wave()
		respawn_pending = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_B:
			toggle_inventory_visibility()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if _handle_world_left_click():
				get_viewport().set_input_as_handled()


func toggle_inventory_visibility() -> void:
	if inventory_panel == null:
		return
	inventory_panel.visible = not inventory_panel.visible
	_update_cursor_item_ui()


func is_inventory_visible() -> bool:
	return inventory_panel != null and inventory_panel.visible


func select_inventory_slot(slot_index: int) -> void:
	_select_inventory_slot(slot_index)


func equip_selected_inventory_slot() -> void:
	_equip_selected_slot()


func has_cursor_item() -> bool:
	return not cursor_item.is_empty()


func get_cursor_item() -> Dictionary:
	return cursor_item.duplicate(true)


func click_ground_item(loot: Node) -> bool:
	return _click_ground_item(loot)


func click_inventory_slot(slot_index: int) -> void:
	_click_inventory_slot(slot_index)


func click_equipment_slot() -> void:
	_click_equipment_slot()


func click_empty_world(world_position: Vector2) -> void:
	_drop_cursor_item(world_position)


func _spawn_wave() -> void:
	_clear_enemies()
	_spawn_mummy("MummyScout", $EnemySpawns/DummySpawn.global_position, 35, 42.0, 6, 46.0, 40.0, 1.25, 2.6)
	_spawn_mummy("MummyGrunt", $EnemySpawns/GruntSpawn.global_position, 55, 68.0, 10, 54.0, 46.0, 1.1, 3.0)
	_spawn_mummy("MummyBrute", $EnemySpawns/BruteSpawn.global_position, 95, 48.0, 18, 60.0, 52.0, 1.35, 3.35)


func _clear_enemies() -> void:
	for child in enemies_root.get_children():
		child.queue_free()


func _spawn_mummy(
	enemy_name: String,
	spawn_position: Vector2,
	max_hp: int,
	move_speed: float,
	attack_damage: int,
	attack_range: float,
	preferred_distance: float,
	attack_cooldown: float,
	display_scale: float
) -> void:
	var enemy := MUMMY_SCENE.instantiate()
	enemy.name = enemy_name
	enemy.global_position = spawn_position
	enemy.max_hp = max_hp
	enemy.move_speed = move_speed
	enemy.attack_damage = attack_damage
	enemy.attack_range = attack_range
	enemy.preferred_distance = preferred_distance
	enemy.attack_cooldown = attack_cooldown
	enemy.display_scale = display_scale
	enemies_root.add_child(enemy)


func _update_debug_label() -> void:
	var enemy_count := get_tree().get_nodes_in_group("enemy").size()
	var hp_text := "?"
	var damage_text := "?"
	var weapon_text := "?"
	var facing_text := "?"
	var action_text := "?"
	var cursor_text := "None"
	if is_instance_valid(player):
		var hp_value = player.get("hp")
		hp_text = str(hp_value) if hp_value != null else "?"
		if player.has_method("get_current_attack_damage"):
			damage_text = str(player.get_current_attack_damage())
		if player.has_method("get_equipped_weapon_name"):
			weapon_text = str(player.get_equipped_weapon_name())
		if player.has_method("get_facing_direction"):
			facing_text = _format_vector(player.get_facing_direction())
		if player.has_method("get_action_direction"):
			action_text = _format_vector(player.get_action_direction())
	if not cursor_item.is_empty():
		cursor_text = str(cursor_item.get("name", "Item"))
	debug_label.text = "Enemies: %d\nHP: %s\nDamage: %s\nWeapon: %s\nCursor: %s\nFacing: %s\nAction: %s" % [enemy_count, hp_text, damage_text, weapon_text, cursor_text, facing_text, action_text]


func _build_inventory_ui() -> void:
	inventory_panel = Control.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.position = Vector2(640, 16)
	inventory_panel.size = Vector2(610, 190)
	inventory_panel.visible = false
	debug_canvas.add_child(inventory_panel)

	var background := ColorRect.new()
	background.color = PANEL_COLOR
	background.size = inventory_panel.size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_panel.add_child(background)

	var title := _make_label("Equipment", Vector2(10, 8), Vector2(150, 20), 15, LABEL_COLOR)
	inventory_panel.add_child(title)

	var bag_title := _make_label("Bag", Vector2(10, 72), Vector2(120, 20), 15, LABEL_COLOR)
	inventory_panel.add_child(bag_title)

	var equip_slot := Control.new()
	equip_slot.position = Vector2(10, 30)
	equip_slot.size = SLOT_SIZE
	inventory_panel.add_child(equip_slot)
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
	equip_slot_button.pressed.connect(_click_equipment_slot)
	equip_slot.add_child(equip_slot_button)

	equipment_name_label = _make_label("None", Vector2(68, 31), Vector2(240, 20), 14, LABEL_COLOR)
	inventory_panel.add_child(equipment_name_label)
	equipment_damage_label = _make_label("Damage: ?", Vector2(68, 52), Vector2(180, 20), 14, LABEL_COLOR)
	inventory_panel.add_child(equipment_damage_label)

	var selected_title := _make_label("Selected", Vector2(330, 8), Vector2(120, 20), 15, LABEL_COLOR)
	inventory_panel.add_child(selected_title)
	selected_name_label = _make_label("None", Vector2(330, 31), Vector2(190, 20), 14, LABEL_COLOR)
	inventory_panel.add_child(selected_name_label)
	selected_rarity_label = _make_label("Rarity: -", Vector2(330, 52), Vector2(150, 20), 14, EMPTY_LABEL_COLOR)
	inventory_panel.add_child(selected_rarity_label)
	selected_damage_label = _make_label("Damage Bonus: -", Vector2(330, 73), Vector2(170, 20), 14, LABEL_COLOR)
	inventory_panel.add_child(selected_damage_label)

	equip_button = Button.new()
	equip_button.text = "Equip"
	equip_button.position = Vector2(520, 31)
	equip_button.size = Vector2(72, 28)
	equip_button.disabled = true
	equip_button.pressed.connect(_equip_selected_slot)
	inventory_panel.add_child(equip_button)

	cursor_status_label = _make_label("Cursor: Empty", Vector2(330, 118), Vector2(250, 20), 13, EMPTY_LABEL_COLOR)
	inventory_panel.add_child(cursor_status_label)

	for i in range(10):
		var slot := Control.new()
		slot.position = Vector2(10 + i * 58, 94)
		slot.size = SLOT_SIZE
		inventory_panel.add_child(slot)
		_add_slot_background(slot, INVENTORY_SLOT_TEXTURE)

		var highlight := ColorRect.new()
		highlight.color = SELECTED_SLOT_COLOR
		highlight.size = SLOT_SIZE
		highlight.visible = false
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(highlight)
		inventory_slot_highlights.append(highlight)

		var key_label := _make_label(_slot_key_text(i), Vector2(3, 1), Vector2(18, 16), 11, EMPTY_LABEL_COLOR)
		slot.add_child(key_label)

		var icon := TextureRect.new()
		icon.position = Vector2(8, 8)
		icon.size = ITEM_ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		inventory_slot_icons.append(icon)

		var bonus := _make_label("", Vector2(20, 31), Vector2(28, 16), 11, LABEL_COLOR)
		slot.add_child(bonus)
		inventory_slot_bonus_labels.append(bonus)

		var button := Button.new()
		button.flat = true
		button.text = ""
		button.size = SLOT_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_click_inventory_slot.bind(i))
		slot.add_child(button)

	cursor_item_icon = TextureRect.new()
	cursor_item_icon.name = "CursorItemIcon"
	cursor_item_icon.size = ITEM_ICON_SIZE
	cursor_item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cursor_item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cursor_item_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cursor_item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_item_icon.visible = false
	debug_canvas.add_child(cursor_item_icon)


func _update_inventory_ui() -> void:
	if not is_instance_valid(player):
		return
	if not player.has_method("get_inventory_items"):
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

	var items: Array = player.get_inventory_items()
	if selected_slot_index >= items.size() or (selected_slot_index >= 0 and items[selected_slot_index].is_empty()):
		selected_slot_index = -1
	for i in range(inventory_slot_icons.size()):
		if i < items.size() and not items[i].is_empty():
			var item: Dictionary = items[i]
			inventory_slot_icons[i].texture = _load_icon(str(item.get("icon", "")))
			inventory_slot_bonus_labels[i].text = "+%d" % int(item.get("damage_bonus", 0))
		else:
			inventory_slot_icons[i].texture = null
			inventory_slot_bonus_labels[i].text = ""
		inventory_slot_highlights[i].visible = i == selected_slot_index
	_update_selected_item_details(items)
	equipment_slot_highlight.visible = not cursor_item.is_empty() and str(cursor_item.get("type", "")) == "weapon"


func _add_slot_background(parent: Control, texture: Texture2D) -> void:
	var background := TextureRect.new()
	background.texture = texture
	background.size = SLOT_SIZE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(background)


func _make_label(text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
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


func _select_inventory_slot(slot_index: int) -> void:
	if not is_instance_valid(player) or not player.has_method("get_inventory_items"):
		selected_slot_index = -1
		return
	var items: Array = player.get_inventory_items()
	selected_slot_index = slot_index if slot_index < items.size() and not items[slot_index].is_empty() else -1
	_update_inventory_ui()


func _equip_selected_slot() -> void:
	_suppress_player_attack_input()
	if not cursor_item.is_empty():
		_click_equipment_slot()
		return
	if selected_slot_index < 0:
		return
	if is_instance_valid(player) and player.has_method("equip_bag_slot"):
		player.equip_bag_slot(selected_slot_index)
	selected_slot_index = -1
	_update_inventory_ui()


func _update_selected_item_details(items: Array) -> void:
	if not cursor_item.is_empty():
		_set_item_detail_labels(cursor_item, "Cursor")
		equip_button.disabled = str(cursor_item.get("type", "")) != "weapon"
		cursor_status_label.text = "Cursor: %s" % str(cursor_item.get("name", "Item"))
		cursor_status_label.add_theme_color_override("font_color", _item_color(cursor_item))
		return

	if selected_slot_index < 0 or selected_slot_index >= items.size():
		selected_name_label.text = "None"
		selected_name_label.add_theme_color_override("font_color", LABEL_COLOR)
		selected_rarity_label.text = "Rarity: -"
		selected_rarity_label.add_theme_color_override("font_color", EMPTY_LABEL_COLOR)
		selected_damage_label.text = "Damage Bonus: -"
		equip_button.disabled = true
		cursor_status_label.text = "Cursor: Empty"
		cursor_status_label.add_theme_color_override("font_color", EMPTY_LABEL_COLOR)
		return

	var item: Dictionary = items[selected_slot_index]
	_set_item_detail_labels(item, "Selected")
	equip_button.disabled = false


func _set_item_detail_labels(item: Dictionary, source_label: String) -> void:
	var rarity := str(item.get("rarity", "normal"))
	var rarity_color := _item_color(item)
	selected_name_label.text = "%s: %s" % [source_label, str(item.get("name", "Weapon"))]
	selected_name_label.add_theme_color_override("font_color", rarity_color)
	selected_rarity_label.text = "Rarity: %s" % rarity.capitalize()
	selected_rarity_label.add_theme_color_override("font_color", rarity_color)
	selected_damage_label.text = "Damage Bonus: +%d" % int(item.get("damage_bonus", 0))


func _item_color(item: Dictionary) -> Color:
	var rarity := str(item.get("rarity", "normal"))
	return item.get("color", RARITY_COLORS.get(rarity, LABEL_COLOR))


func _click_inventory_slot(slot_index: int) -> void:
	_suppress_player_attack_input()
	if not is_instance_valid(player):
		return
	if cursor_item.is_empty():
		var item: Dictionary = player.take_bag_slot(slot_index)
		if item.is_empty():
			_select_inventory_slot(slot_index)
			return
		cursor_item = item
		selected_slot_index = -1
	else:
		cursor_item = player.place_bag_slot(slot_index, cursor_item)
		selected_slot_index = slot_index if cursor_item.is_empty() else -1
	_update_inventory_ui()
	_update_cursor_item_ui()


func _click_equipment_slot() -> void:
	_suppress_player_attack_input()
	if not is_instance_valid(player):
		return
	if cursor_item.is_empty():
		cursor_item = player.take_equipped_weapon()
	else:
		cursor_item = player.place_equipped_weapon(cursor_item)
	selected_slot_index = -1
	_update_inventory_ui()
	_update_cursor_item_ui()


func _handle_world_left_click() -> bool:
	var world_position := get_global_mouse_position()
	if not cursor_item.is_empty():
		_drop_cursor_item(world_position)
		return true
	var loot := _find_ground_item_at(world_position)
	if loot != null:
		return _click_ground_item(loot)
	return false


func _click_ground_item(loot: Node) -> bool:
	if loot == null or not is_instance_valid(loot) or not loot.has_method("collect_from_world"):
		return false
	_suppress_player_attack_input()
	var item: Dictionary = loot.get_item_data() if loot.has_method("get_item_data") else {}
	if item.is_empty():
		return false
	if is_inventory_visible():
		cursor_item = loot.collect_from_world()
		selected_slot_index = -1
		_update_inventory_ui()
		_update_cursor_item_ui()
		return true
	if is_instance_valid(player) and player.has_method("pickup_weapon_item") and bool(player.pickup_weapon_item(item)):
		loot.collect_from_world()
		_update_inventory_ui()
		return true
	if loot.has_method("show_reject_feedback"):
		loot.show_reject_feedback("Bag Full")
	return true


func _drop_cursor_item(world_position: Vector2) -> void:
	if cursor_item.is_empty():
		return
	_suppress_player_attack_input()
	var loot := WEAPON_PICKUP_SCENE.instantiate()
	if loot.has_method("setup_item"):
		loot.setup_item(cursor_item)
	loot.global_position = world_position
	var loot_root := get_node_or_null("Loot") as Node2D
	if loot_root == null:
		add_child(loot)
	else:
		loot_root.add_child(loot)
	cursor_item = {}
	selected_slot_index = -1
	_update_inventory_ui()
	_update_cursor_item_ui()


func _find_ground_item_at(world_position: Vector2) -> Node:
	var best: Node = null
	var best_distance := WORLD_ITEM_CLICK_RADIUS
	for loot in get_tree().get_nodes_in_group("loot"):
		var loot_node := loot as Node2D
		if loot_node == null or not is_instance_valid(loot_node):
			continue
		var distance := loot_node.global_position.distance_to(world_position)
		if distance <= best_distance:
			best = loot_node
			best_distance = distance
	return best


func _update_cursor_item_ui() -> void:
	if is_instance_valid(player) and player.has_method("set_item_cursor_blocks_attacks"):
		player.set_item_cursor_blocks_attacks(not cursor_item.is_empty())
	if cursor_item_icon == null:
		return
	if cursor_item.is_empty():
		cursor_item_icon.visible = false
		cursor_item_icon.texture = null
		return
	cursor_item_icon.visible = true
	cursor_item_icon.texture = _load_icon(str(cursor_item.get("icon", "")))
	cursor_item_icon.position = get_viewport().get_mouse_position() + Vector2(16, 16)


func _suppress_player_attack_input() -> void:
	if is_instance_valid(player) and player.has_method("suppress_attack_inputs"):
		player.suppress_attack_inputs()


func _slot_key_text(index: int) -> String:
	if index == 9:
		return "0"
	return str(index + 1)


func _format_vector(value: Vector2) -> String:
	return "(%.2f, %.2f)" % [value.x, value.y]
