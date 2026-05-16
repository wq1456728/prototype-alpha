extends RefCounted

const CONFIG_PATH := "res://data/skills/knight_skills.json"

static var _loaded := false
static var _skills := {}
static var _skill_order: Array[String] = []

var ranks := {}


func get_skill_definition(skill_id: String) -> Dictionary:
	_ensure_loaded()
	return _skills.get(skill_id, {}).duplicate(true)


func get_skill_ids() -> Array[String]:
	_ensure_loaded()
	return _skill_order.duplicate()


func get_rank(skill_id: String) -> int:
	return int(ranks.get(skill_id, 0))


func is_unlocked(skill_id: String) -> bool:
	return get_rank(skill_id) > 0


func can_unlock(skill_id: String, player_level: int, available_skill_points: int) -> bool:
	var skill := get_skill_definition(skill_id)
	if skill.is_empty():
		return false
	if get_rank(skill_id) >= int(skill.get("max_rank", 1)):
		return false
	if player_level < int(skill.get("required_level", 1)):
		return false
	if available_skill_points < int(skill.get("unlock_cost", 1)):
		return false
	for required_id in skill.get("required_skill_ids", []):
		if not is_unlocked(str(required_id)):
			return false
	return true


func unlock(skill_id: String, player_level: int, available_skill_points: int) -> Dictionary:
	if not can_unlock(skill_id, player_level, available_skill_points):
		return {"ok": false, "cost": 0}
	var skill := get_skill_definition(skill_id)
	var cost := int(skill.get("unlock_cost", 1))
	ranks[skill_id] = get_rank(skill_id) + 1
	return {"ok": true, "cost": cost}


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_skills.clear()
	_skill_order.clear()
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("SkillTreeState failed to open %s" % CONFIG_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("SkillTreeState failed to parse %s" % CONFIG_PATH)
		return
	for skill in parsed.get("skills", []):
		if skill is Dictionary:
			var skill_id := str(skill.get("id", ""))
			_skills[skill_id] = skill.duplicate(true)
			_skill_order.append(skill_id)
