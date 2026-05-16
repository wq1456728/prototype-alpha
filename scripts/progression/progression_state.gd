extends RefCounted

const CONFIG_PATH := "res://data/progression/progression_config.json"

static var _loaded := false
static var _level_data := {}
static var _level_defaults := {}

var level := 1
var current_xp := 0
var available_skill_points := 0


func gain_xp(amount: int) -> bool:
	if amount <= 0:
		return false
	current_xp += amount
	var leveled_up := false
	while current_xp >= get_xp_to_next_level():
		current_xp -= get_xp_to_next_level()
		level += 1
		available_skill_points += get_skill_points_on_level(level)
		leveled_up = true
	return leveled_up


func get_xp_to_next_level() -> int:
	var data := _get_level_data(level)
	return int(data.get("xp_to_next", 90))


func get_damage_bonus() -> int:
	var data := _get_level_data(level)
	return int(data.get("damage_bonus", 0))


func get_skill_points_on_level(target_level: int) -> int:
	var data := _get_level_data(target_level)
	return int(data.get("skill_points_on_level", 1))


func spend_skill_points(amount: int) -> bool:
	if amount <= 0 or available_skill_points < amount:
		return false
	available_skill_points -= amount
	return true


static func _get_level_data(target_level: int) -> Dictionary:
	_ensure_loaded()
	return _level_data.get(target_level, _level_defaults).duplicate(true)


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_level_data.clear()
	_level_defaults.clear()
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("ProgressionState failed to open %s" % CONFIG_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("ProgressionState failed to parse %s" % CONFIG_PATH)
		return
	_level_defaults = parsed.get("level_defaults", {}).duplicate(true)
	for level_entry in parsed.get("levels", []):
		if level_entry is Dictionary:
			_level_data[int(level_entry.get("level", 1))] = level_entry.duplicate(true)
