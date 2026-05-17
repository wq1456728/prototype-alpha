extends Control

const UI_MARGIN := 24.0
const PANEL_COLOR := Color(0.055, 0.058, 0.052, 0.82)
const LABEL_COLOR := Color(0.9, 0.88, 0.72, 1.0)
const EMPTY_LABEL_COLOR := Color(0.48, 0.48, 0.42, 1.0)
const OBJECTIVE_STEPS := [
	"Kill a mummy",
	"Pick up a dropped item",
	"Equip a weapon",
	"Reach level 2",
	"Unlock Heavy Strike",
	"Unlock Shield Charge",
	"Assign Shield Charge from Hotbar",
	"Use Shield Charge from the loadout",
	"Defeat the brute"
]

var background: ColorRect
var title_label: Label
var step_label: Label
var detail_label: Label
var objective_stage := 0
var objective_complete := false


func setup() -> void:
	name = "ObjectivePanel"
	size = Vector2(410, 124)

	background = ColorRect.new()
	background.color = PANEL_COLOR
	background.size = size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	title_label = _make_label("Objective", Vector2(14, 12), Vector2(240, 24), 19, LABEL_COLOR)
	add_child(title_label)
	step_label = _make_label("", Vector2(14, 44), Vector2(370, 24), 17, LABEL_COLOR)
	add_child(step_label)
	detail_label = _make_label("", Vector2(14, 76), Vector2(382, 42), 14, EMPTY_LABEL_COLOR)
	add_child(detail_label)


func layout(viewport_size: Vector2) -> void:
	position = _clamped_panel_position(Vector2(viewport_size.x - size.x - UI_MARGIN, UI_MARGIN), size, viewport_size)
	if background != null:
		background.size = size


func update_flow(player: Node, cursor_item: Dictionary) -> void:
	if objective_complete or not is_instance_valid(player):
		_refresh()
		return
	var advanced := true
	while advanced and not objective_complete:
		advanced = false
		if _is_objective_stage_done(player, cursor_item, objective_stage):
			objective_stage += 1
			advanced = true
			if objective_stage >= OBJECTIVE_STEPS.size():
				objective_complete = true
	_refresh()


func get_stage() -> int:
	return objective_stage


func is_complete() -> bool:
	return objective_complete


func _is_objective_stage_done(player: Node, cursor_item: Dictionary, stage: int) -> bool:
	match stage:
		0:
			return get_tree().get_nodes_in_group("enemy").size() < 3 or int(player.get_current_xp()) > 0
		1:
			return _player_has_any_item(player, cursor_item)
		2:
			return player.has_method("get_equipped_weapon") and not player.get_equipped_weapon().is_empty()
		3:
			return player.has_method("get_level") and int(player.get_level()) >= 2
		4:
			return player.has_method("is_skill_unlocked") and bool(player.is_skill_unlocked("heavy_strike"))
		5:
			return player.has_method("is_skill_unlocked") and bool(player.is_skill_unlocked("shield_charge"))
		6:
			return player.has_method("get_loadout_skill") and str(player.get_loadout_skill("v")) == "shield_charge"
		7:
			return player.has_method("get_skill_use_count") and int(player.get_skill_use_count("shield_charge")) > 0
		8:
			return not _is_enemy_named_alive("MummyBrute")
	return false


func _refresh() -> void:
	if step_label == null:
		return
	if objective_complete:
		title_label.text = "Objective Complete"
		step_label.text = "Vertical sandbox loop complete"
		detail_label.text = "Combat, loot, equip, XP, skill unlock, loadout, and skill use passed."
		return
	var step_text := str(OBJECTIVE_STEPS[clampi(objective_stage, 0, OBJECTIVE_STEPS.size() - 1)])
	title_label.text = "Objective %d/%d" % [objective_stage + 1, OBJECTIVE_STEPS.size()]
	step_label.text = step_text
	detail_label.text = _objective_detail_text(objective_stage)


func _objective_detail_text(stage: int) -> String:
	match stage:
		0:
			return "Defeat any mummy to start the growth loop."
		1:
			return "Click the dropped item; inventory-open pickup may hold it on cursor."
		2:
			return "Place a weapon into the active weapon slot."
		3:
			return "Earn XP until level 2."
		4:
			return "Open K and unlock Heavy Strike first."
		5:
			return "Unlock Shield Charge after Heavy Strike."
		6:
			return "Click a Hotbar slot and choose Shield Charge."
		7:
			return "Press V after assignment to use Shield Charge."
		8:
			return "Finish by defeating MummyBrute."
	return ""


func _player_has_any_item(player: Node, cursor_item: Dictionary) -> bool:
	if not cursor_item.is_empty():
		return true
	if player.has_method("get_equipped_weapon") and not player.get_equipped_weapon().is_empty():
		return true
	if player.has_method("get_inventory_items"):
		for item in player.get_inventory_items():
			if item is Dictionary and not item.is_empty():
				return true
	return false


func _is_enemy_named_alive(enemy_name: String) -> bool:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy) and enemy.name == enemy_name:
			return true
	return false


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
