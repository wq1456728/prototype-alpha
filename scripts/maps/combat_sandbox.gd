extends Node2D

const MUMMY_SCENE := preload("res://scenes/enemy/mummy_enemy.tscn")
const INVENTORY_SLOT_TEXTURE := preload("res://assets/ui/inventory_slot.png")
const EQUIPMENT_SLOT_TEXTURE := preload("res://assets/ui/equipment_weapon_slot.png")
const RESPAWN_DELAY := 4.0
const SLOT_SIZE := Vector2(48, 48)
const ITEM_ICON_SIZE := Vector2(32, 32)
const PANEL_COLOR := Color(0.055, 0.058, 0.052, 0.82)
const LABEL_COLOR := Color(0.9, 0.88, 0.72, 1.0)
const EMPTY_LABEL_COLOR := Color(0.48, 0.48, 0.42, 1.0)

@onready var player: Node2D = $KnightPlayer
@onready var enemies_root: Node2D = $Enemies
@onready var debug_canvas: CanvasLayer = $DebugCanvas
@onready var debug_label: Label = $DebugCanvas/DebugLabel

var respawn_pending := false
var equipment_icon: TextureRect
var equipment_name_label: Label
var equipment_damage_label: Label
var inventory_slot_icons: Array[TextureRect] = []
var inventory_slot_bonus_labels: Array[Label] = []
var icon_cache := {}


func _ready() -> void:
	_build_inventory_ui()
	_spawn_wave()


func _process(_delta: float) -> void:
	_update_debug_label()
	_update_inventory_ui()
	if respawn_pending:
		return
	if get_tree().get_nodes_in_group("enemy").is_empty():
		respawn_pending = true
		await get_tree().create_timer(RESPAWN_DELAY).timeout
		_spawn_wave()
		respawn_pending = false


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
	debug_label.text = "Enemies: %d\nHP: %s\nDamage: %s\nWeapon: %s\nFacing: %s\nAction: %s" % [enemy_count, hp_text, damage_text, weapon_text, facing_text, action_text]


func _build_inventory_ui() -> void:
	var panel := Control.new()
	panel.name = "InventoryPanel"
	panel.position = Vector2(640, 16)
	panel.size = Vector2(610, 138)
	debug_canvas.add_child(panel)

	var background := ColorRect.new()
	background.color = PANEL_COLOR
	background.size = panel.size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(background)

	var title := _make_label("Equipment", Vector2(10, 8), Vector2(150, 20), 15, LABEL_COLOR)
	panel.add_child(title)

	var bag_title := _make_label("Bag", Vector2(10, 72), Vector2(120, 20), 15, LABEL_COLOR)
	panel.add_child(bag_title)

	var equip_slot := Control.new()
	equip_slot.position = Vector2(10, 30)
	equip_slot.size = SLOT_SIZE
	panel.add_child(equip_slot)
	_add_slot_background(equip_slot, EQUIPMENT_SLOT_TEXTURE)

	equipment_icon = TextureRect.new()
	equipment_icon.position = Vector2(8, 8)
	equipment_icon.size = ITEM_ICON_SIZE
	equipment_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	equipment_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	equipment_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	equip_slot.add_child(equipment_icon)

	equipment_name_label = _make_label("None", Vector2(68, 31), Vector2(240, 20), 14, LABEL_COLOR)
	panel.add_child(equipment_name_label)
	equipment_damage_label = _make_label("Damage: ?", Vector2(68, 52), Vector2(180, 20), 14, LABEL_COLOR)
	panel.add_child(equipment_damage_label)

	for i in range(10):
		var slot := Control.new()
		slot.position = Vector2(10 + i * 58, 94)
		slot.size = SLOT_SIZE
		panel.add_child(slot)
		_add_slot_background(slot, INVENTORY_SLOT_TEXTURE)

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
	for i in range(inventory_slot_icons.size()):
		if i < items.size():
			var item: Dictionary = items[i]
			inventory_slot_icons[i].texture = _load_icon(str(item.get("icon", "")))
			inventory_slot_bonus_labels[i].text = "+%d" % int(item.get("damage_bonus", 0))
		else:
			inventory_slot_icons[i].texture = null
			inventory_slot_bonus_labels[i].text = ""


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


func _slot_key_text(index: int) -> String:
	if index == 9:
		return "0"
	return str(index + 1)


func _format_vector(value: Vector2) -> String:
	return "(%.2f, %.2f)" % [value.x, value.y]
