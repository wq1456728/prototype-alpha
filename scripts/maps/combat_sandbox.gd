extends Node2D

const MUMMY_SCENE := preload("res://scenes/enemy/mummy_enemy.tscn")
const WEAPON_PICKUP_SCENE := preload("res://scenes/items/weapon_pickup.tscn")
const COLLISION_DEBUG_OVERLAY_SCRIPT := preload("res://scripts/debug/collision_debug_overlay.gd")
const DEBUG_HUD_SCRIPT := preload("res://scripts/ui/sandbox_debug_hud.gd")
const INVENTORY_PANEL_SCRIPT := preload("res://scripts/ui/inventory_panel.gd")
const SKILL_TREE_PANEL_SCRIPT := preload("res://scripts/ui/skill_tree_panel.gd")
const SKILL_LOADOUT_BAR_SCRIPT := preload("res://scripts/ui/skill_loadout_bar.gd")
const OBJECTIVE_PANEL_SCRIPT := preload("res://scripts/ui/objective_panel.gd")

const RESPAWN_DELAY := 4.0
const WORLD_ITEM_CLICK_RADIUS := 36.0
const CURSOR_DROP_DISTANCE := 42.0
const UI_MARGIN := 24.0

@onready var world_entities_root: Node2D = $WorldEntities
@onready var player: Node2D = $WorldEntities/KnightPlayer
@onready var debug_canvas: CanvasLayer = $DebugCanvas
@onready var debug_label: Label = $DebugCanvas/DebugLabel

var respawn_pending := false
var inventory_panel: Control
var skill_tree_panel: Control
var loadout_bar: Control
var objective_panel: Control
var cursor_item_icon: TextureRect
var collision_debug_overlay: Node2D
var cursor_item: Dictionary = {}
var icon_cache := {}
var last_viewport_size := Vector2.ZERO


func _ready() -> void:
	_setup_collision_debug_overlay()
	_setup_debug_hud()
	_build_inventory_ui()
	_build_skill_tree_ui()
	_build_loadout_ui()
	_build_objective_ui()
	_build_cursor_item_ui()
	_layout_ui(true)
	_spawn_wave()


func _process(_delta: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size != last_viewport_size:
		_layout_ui()
	_update_debug_label()
	_update_inventory_ui()
	_update_skill_tree_ui()
	_update_loadout_ui()
	_update_objective_flow()
	_update_cursor_item_ui()
	if respawn_pending:
		return
	if get_tree().get_nodes_in_group("enemy").is_empty():
		respawn_pending = true
		await get_tree().create_timer(RESPAWN_DELAY).timeout
		_spawn_wave()
		respawn_pending = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if _is_screen_point_in_inventory(mouse_event.position) or _is_screen_point_in_skill_tree(mouse_event.position) or _is_screen_point_in_loadout(mouse_event.position):
				_suppress_player_attack_input()
				return
			if is_loadout_picker_visible():
				_hide_loadout_picker()
				_suppress_player_attack_input()
				get_viewport().set_input_as_handled()
				return
			if _handle_world_left_click():
				get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_P:
			toggle_collision_debug_visibility()
			get_viewport().set_input_as_handled()
		elif key_event.pressed and not key_event.echo and key_event.keycode == KEY_K:
			toggle_skill_tree_visibility()
			get_viewport().set_input_as_handled()
		elif key_event.pressed and not key_event.echo and key_event.keycode == KEY_B:
			toggle_inventory_visibility()
			get_viewport().set_input_as_handled()


func toggle_inventory_visibility() -> void:
	if inventory_panel == null:
		return
	var should_show := not inventory_panel.visible
	inventory_panel.visible = should_show
	if should_show:
		if skill_tree_panel != null:
			skill_tree_panel.visible = false
		_hide_loadout_picker()
	_update_large_panel_focus_ui()
	_update_skill_tree_ui()
	_update_cursor_item_ui()


func is_inventory_visible() -> bool:
	return inventory_panel != null and inventory_panel.visible


func toggle_skill_tree_visibility() -> void:
	if skill_tree_panel == null:
		return
	var should_show := not skill_tree_panel.visible
	skill_tree_panel.visible = should_show
	if should_show:
		if inventory_panel != null:
			inventory_panel.visible = false
		_hide_loadout_picker()
	_update_large_panel_focus_ui()
	_update_inventory_ui()
	_update_skill_tree_ui()


func is_skill_tree_visible() -> bool:
	return skill_tree_panel != null and skill_tree_panel.visible


func toggle_collision_debug_visibility() -> void:
	if collision_debug_overlay == null:
		return
	var should_show := not collision_debug_overlay.visible
	collision_debug_overlay.visible = should_show
	_set_player_attack_debug_visible(should_show)


func is_collision_debug_visible() -> bool:
	return collision_debug_overlay != null and collision_debug_overlay.visible


func _set_player_attack_debug_visible(should_show: bool) -> void:
	for player_node in get_tree().get_nodes_in_group("player"):
		player_node.set("show_attack_debug", should_show)
		if player_node is CanvasItem:
			(player_node as CanvasItem).queue_redraw()


func select_inventory_slot(slot_index: int) -> void:
	if inventory_panel != null:
		inventory_panel.call("select_slot", slot_index, player)
	_update_inventory_ui()


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


func assign_skill_to_loadout(skill_id: String, slot_id: String) -> bool:
	if not is_instance_valid(player) or not player.has_method("assign_skill_to_slot"):
		return false
	var assigned := bool(player.assign_skill_to_slot(skill_id, slot_id))
	_update_loadout_ui()
	_update_skill_tree_ui()
	if assigned:
		_hide_loadout_picker()
	return assigned


func get_objective_stage() -> int:
	return int(objective_panel.call("get_stage")) if objective_panel != null else 0


func is_objective_complete() -> bool:
	return bool(objective_panel.call("is_complete")) if objective_panel != null else false


func get_world_item_parent() -> Node2D:
	return world_entities_root if is_instance_valid(world_entities_root) else self


func is_loadout_picker_visible() -> bool:
	return bool(loadout_bar.call("is_picker_visible")) if loadout_bar != null else false


func get_loadout_picker_option_count() -> int:
	return int(loadout_bar.call("get_picker_option_count")) if loadout_bar != null else 0


func get_loadout_picker_tooltip(skill_id: String) -> String:
	return str(loadout_bar.call("get_picker_tooltip", skill_id)) if loadout_bar != null else ""


func click_loadout_slot(slot_id: String) -> void:
	_click_loadout_slot(slot_id)


func click_loadout_picker_skill(skill_id: String) -> bool:
	return bool(loadout_bar.call("select_picker_skill", skill_id)) if loadout_bar != null else false


func _spawn_wave() -> void:
	_clear_enemies()
	_spawn_mummy("MummyScout", $EnemySpawns/DummySpawn.global_position, 35, 42.0, 6, 46.0, 40.0, 1.25, 2.6, 20)
	_spawn_mummy("MummyGrunt", $EnemySpawns/GruntSpawn.global_position, 55, 68.0, 10, 54.0, 46.0, 1.1, 3.0, 30)
	_spawn_mummy("MummyBrute", $EnemySpawns/BruteSpawn.global_position, 95, 48.0, 18, 60.0, 52.0, 1.35, 3.35, 45)


func _clear_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()


func _spawn_mummy(
	enemy_name: String,
	spawn_position: Vector2,
	max_hp: int,
	move_speed: float,
	attack_damage: int,
	attack_range: float,
	preferred_distance: float,
	attack_cooldown: float,
	display_scale: float,
	xp_reward: int
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
	enemy.xp_reward = xp_reward
	get_world_item_parent().add_child(enemy)


func _setup_collision_debug_overlay() -> void:
	collision_debug_overlay = COLLISION_DEBUG_OVERLAY_SCRIPT.new()
	collision_debug_overlay.name = "CollisionDebugOverlay"
	add_child(collision_debug_overlay)


func _setup_debug_hud() -> void:
	debug_label.set_script(DEBUG_HUD_SCRIPT)
	debug_label.call("setup")


func _build_inventory_ui() -> void:
	inventory_panel = INVENTORY_PANEL_SCRIPT.new()
	debug_canvas.add_child(inventory_panel)
	inventory_panel.call("setup")
	inventory_panel.connect("inventory_slot_pressed", Callable(self, "_click_inventory_slot"))
	inventory_panel.connect("equipment_slot_pressed", Callable(self, "_click_equipment_slot"))
	inventory_panel.connect("equip_selected_requested", Callable(self, "_equip_selected_slot"))


func _build_skill_tree_ui() -> void:
	skill_tree_panel = SKILL_TREE_PANEL_SCRIPT.new()
	debug_canvas.add_child(skill_tree_panel)
	skill_tree_panel.call("setup")
	skill_tree_panel.connect("unlock_requested", Callable(self, "_unlock_skill_from_panel"))


func _build_loadout_ui() -> void:
	loadout_bar = SKILL_LOADOUT_BAR_SCRIPT.new()
	debug_canvas.add_child(loadout_bar)
	loadout_bar.call("setup", player)
	loadout_bar.connect("slot_pressed", Callable(self, "_click_loadout_slot"))
	loadout_bar.connect("skill_selected", Callable(self, "_on_loadout_skill_selected"))


func _build_objective_ui() -> void:
	objective_panel = OBJECTIVE_PANEL_SCRIPT.new()
	debug_canvas.add_child(objective_panel)
	objective_panel.call("setup")


func _build_cursor_item_ui() -> void:
	cursor_item_icon = TextureRect.new()
	cursor_item_icon.name = "CursorItemIcon"
	cursor_item_icon.size = Vector2(48, 48)
	cursor_item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cursor_item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cursor_item_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cursor_item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_item_icon.visible = false
	debug_canvas.add_child(cursor_item_icon)


func _layout_ui(force: bool = false) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1280, 720)
	if not force and viewport_size == last_viewport_size:
		return
	last_viewport_size = viewport_size

	if debug_label != null:
		debug_label.call("setup")
	if inventory_panel != null:
		inventory_panel.call("layout", viewport_size)
	if skill_tree_panel != null:
		skill_tree_panel.call("layout", viewport_size)
	if objective_panel != null:
		objective_panel.call("layout", viewport_size)
	if loadout_bar != null:
		loadout_bar.call("layout", viewport_size)
	_update_large_panel_focus_ui()


func _update_large_panel_focus_ui() -> void:
	var large_panel_visible := is_inventory_visible() or is_skill_tree_visible()
	if debug_label != null:
		debug_label.visible = not large_panel_visible
	if objective_panel != null:
		objective_panel.visible = not large_panel_visible


func _update_debug_label() -> void:
	if debug_label == null:
		return
	debug_label.call("refresh", player, get_tree().get_nodes_in_group("enemy").size(), cursor_item, is_collision_debug_visible())


func _update_inventory_ui() -> void:
	if inventory_panel != null:
		inventory_panel.call("refresh", player, cursor_item)


func _update_skill_tree_ui() -> void:
	if skill_tree_panel != null:
		skill_tree_panel.call("refresh", player)


func _update_loadout_ui() -> void:
	if loadout_bar != null:
		loadout_bar.call("refresh", player)


func _update_objective_flow() -> void:
	if objective_panel != null:
		objective_panel.call("update_flow", player, cursor_item)


func _unlock_skill_from_panel(skill_id: String) -> void:
	_suppress_player_attack_input()
	if is_instance_valid(player) and player.has_method("unlock_skill"):
		player.unlock_skill(skill_id)
	_update_skill_tree_ui()
	_update_loadout_ui()
	if loadout_bar != null:
		loadout_bar.call("rebuild_picker_if_visible", player, get_viewport().get_visible_rect().size)


func _click_loadout_slot(slot_id: String) -> void:
	_suppress_player_attack_input()
	if loadout_bar == null:
		return
	if bool(loadout_bar.call("is_picker_for_slot", slot_id)):
		_hide_loadout_picker()
		return
	loadout_bar.call("show_picker", player, slot_id, get_viewport().get_visible_rect().size)


func _on_loadout_skill_selected(skill_id: String, slot_id: String) -> void:
	_suppress_player_attack_input()
	assign_skill_to_loadout(skill_id, slot_id)


func _hide_loadout_picker() -> void:
	if loadout_bar != null:
		loadout_bar.call("hide_picker")


func _click_inventory_slot(slot_index: int) -> void:
	_suppress_player_attack_input()
	if not is_instance_valid(player):
		return
	if cursor_item.is_empty():
		var item: Dictionary = player.take_bag_slot(slot_index)
		if item.is_empty():
			inventory_panel.call("select_slot", slot_index, player)
			_update_inventory_ui()
			return
		cursor_item = item
		inventory_panel.call("clear_selection")
	else:
		cursor_item = player.place_bag_slot(slot_index, cursor_item)
		if cursor_item.is_empty():
			inventory_panel.call("select_slot", slot_index, player)
		else:
			inventory_panel.call("clear_selection")
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
	inventory_panel.call("clear_selection")
	_update_inventory_ui()
	_update_cursor_item_ui()


func _equip_selected_slot() -> void:
	_suppress_player_attack_input()
	if not cursor_item.is_empty():
		_click_equipment_slot()
		return
	var selected_slot_index := int(inventory_panel.call("get_selected_slot_index")) if inventory_panel != null else -1
	if selected_slot_index < 0:
		return
	if is_instance_valid(player) and player.has_method("equip_bag_slot"):
		player.equip_bag_slot(selected_slot_index)
	inventory_panel.call("clear_selection")
	_update_inventory_ui()


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
		inventory_panel.call("clear_selection")
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
	loot.global_position = _cursor_drop_position(world_position)
	get_world_item_parent().add_child(loot)
	cursor_item = {}
	if inventory_panel != null:
		inventory_panel.call("clear_selection")
	_update_inventory_ui()
	_update_cursor_item_ui()


func _cursor_drop_position(target_position: Vector2) -> Vector2:
	if not is_instance_valid(player):
		return target_position
	var origin := player.global_position
	var direction := target_position - origin
	if direction.length_squared() <= 0.01:
		if player.has_method("get_facing_direction"):
			direction = player.get_facing_direction()
		else:
			direction = Vector2.RIGHT
	return origin + direction.normalized() * CURSOR_DROP_DISTANCE


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


func _is_screen_point_in_inventory(screen_position: Vector2) -> bool:
	return inventory_panel != null and inventory_panel.visible and inventory_panel.get_global_rect().has_point(screen_position)


func _is_screen_point_in_skill_tree(screen_position: Vector2) -> bool:
	return skill_tree_panel != null and skill_tree_panel.visible and skill_tree_panel.get_global_rect().has_point(screen_position)


func _is_screen_point_in_loadout(screen_position: Vector2) -> bool:
	return bool(loadout_bar.call("contains_screen_point", screen_position)) if loadout_bar != null else false


func _load_icon(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not icon_cache.has(path):
		icon_cache[path] = load(path) as Texture2D
	return icon_cache[path]
