extends Control

const UI_MARGIN := 24.0
const PANEL_COLOR := Color(0.055, 0.058, 0.052, 0.82)
const LABEL_COLOR := Color(0.9, 0.88, 0.72, 1.0)
const EMPTY_LABEL_COLOR := Color(0.48, 0.48, 0.42, 1.0)
const OBJECTIVE_STEPS := [
	"Follow the road beyond camp",
	"Clear Training Verge",
	"Claim the weapon at the broken road",
	"Push toward the corrupted shrine",
	"Spend your first skill point",
	"Prepare a mobility skill",
	"Ready Shield Charge",
	"Test Shield Charge",
	"Break the hollow guard",
	"Reach the corrupted hollow"
]

var background: ColorRect
var title_label: Label
var step_label: Label
var detail_label: Label
var objective_stage := 0
var objective_complete := false


func setup() -> void:
	name = "ObjectivePanel"
	size = Vector2(440, 132)

	background = ColorRect.new()
	background.color = PANEL_COLOR
	background.size = size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	title_label = _make_label("Road to the Hollow", Vector2(14, 12), Vector2(280, 24), 19, LABEL_COLOR)
	add_child(title_label)
	step_label = _make_label("", Vector2(14, 44), Vector2(400, 24), 17, LABEL_COLOR)
	add_child(step_label)
	detail_label = _make_label("", Vector2(14, 76), Vector2(410, 50), 14, EMPTY_LABEL_COLOR)
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


func _is_objective_stage_done(player: Node, _cursor_item: Dictionary, stage: int) -> bool:
	var scene := get_tree().current_scene
	match stage:
		0:
			return scene != null and scene.has_method("has_player_left_camp") and bool(scene.call("has_player_left_camp"))
		1:
			return scene != null and scene.has_method("is_encounter_group_cleared") and bool(scene.call("is_encounter_group_cleared", "outdoor_training"))
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
			return scene != null and scene.has_method("is_encounter_group_cleared") and bool(scene.call("is_encounter_group_cleared", "outdoor_entrance"))
		9:
			return scene != null and scene.has_method("is_dungeon_entrance_reached") and bool(scene.call("is_dungeon_entrance_reached"))
	return false


func _refresh() -> void:
	if step_label == null:
		return
	if objective_complete:
		title_label.text = "Outdoor Route Complete"
		step_label.text = "Dungeon entrance reached"
		detail_label.text = "Outdoor combat, loot, equipment, XP, skills, Hotbar assignment, and pressure fight passed."
		return
	var step_text := str(OBJECTIVE_STEPS[clampi(objective_stage, 0, OBJECTIVE_STEPS.size() - 1)])
	title_label.text = "Road to the Hollow"
	step_label.text = step_text
	detail_label.text = _objective_detail_text(objective_stage)


func _objective_detail_text(stage: int) -> String:
	match stage:
		0:
			return "Leave the safe camp and follow the wider road south."
		1:
			return "Clear the weak enemies without getting surrounded."
		2:
			return "The captain near the broken cart carries a useful weapon."
		3:
			return "You should be stronger before pushing toward the entrance."
		4:
			return "Open the skill tree and commit your first point."
		5:
			return "Shield Charge opens after your first combat skill."
		6:
			return "Click a Hotbar slot and choose the new active skill."
		7:
			return "Line up enemies near the hollow and charge through."
		8:
			return "The hollow guard is meant to pressure your movement."
		9:
			return "Move into the hollow marker. Dungeon interior comes later."
	return ""


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
