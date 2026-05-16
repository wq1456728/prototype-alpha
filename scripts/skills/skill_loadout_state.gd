extends RefCounted

const CONFIG_PATH := "res://data/skills/skill_loadout_defaults.json"

static var _loaded := false
static var _slots: Array[Dictionary] = []
static var _basic_skills := {}

var assigned_skills := {}


func _init() -> void:
	_ensure_loaded()
	for slot in _slots:
		var slot_id := str(slot.get("id", ""))
		assigned_skills[slot_id] = str(slot.get("default_skill_id", ""))


func get_slots() -> Array[Dictionary]:
	_ensure_loaded()
	var result: Array[Dictionary] = []
	for slot in _slots:
		result.append(slot.duplicate(true))
	return result


func has_slot(slot_id: String) -> bool:
	_ensure_loaded()
	for slot in _slots:
		if str(slot.get("id", "")) == slot_id:
			return true
	return false


func get_assigned_skill(slot_id: String) -> String:
	return str(assigned_skills.get(slot_id, ""))


func assign_skill(slot_id: String, skill_id: String) -> bool:
	if not has_slot(slot_id):
		return false
	assigned_skills[slot_id] = skill_id
	return true


func get_basic_skill(skill_id: String) -> Dictionary:
	_ensure_loaded()
	return _basic_skills.get(skill_id, {}).duplicate(true)


func is_basic_skill(skill_id: String) -> bool:
	return not get_basic_skill(skill_id).is_empty()


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_slots.clear()
	_basic_skills.clear()
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("SkillLoadoutState failed to open %s" % CONFIG_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("SkillLoadoutState failed to parse %s" % CONFIG_PATH)
		return
	for skill in parsed.get("basic_skills", []):
		if skill is Dictionary:
			_basic_skills[str(skill.get("id", ""))] = skill.duplicate(true)
	for slot in parsed.get("slots", []):
		if slot is Dictionary:
			_slots.append(slot.duplicate(true))
