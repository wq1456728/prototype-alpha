extends RefCounted

const ITEM_DEFINITIONS_PATH := "res://data/items/item_definitions.json"
const DEFAULT_RARITY_COLOR := Color(0.82, 0.78, 0.68, 1.0)

static var _loaded := false
static var _definitions := {}
static var _equipment_slots := {}
static var _item_types: Array = []


static func get_definition(definition_id: String) -> Dictionary:
	_ensure_loaded()
	return _definitions.get(definition_id, {}).duplicate(true)


static func get_definition_ids_by_type(item_type: String) -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	for definition_id in _definitions.keys():
		var definition: Dictionary = _definitions[definition_id]
		if str(definition.get("item_type", "")) == item_type:
			ids.append(str(definition_id))
	return ids


static func get_equipment_slot_ids() -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	for slot_id in _equipment_slots.keys():
		ids.append(str(slot_id))
	return ids


static func get_equipment_slot(slot_id: String) -> Dictionary:
	_ensure_loaded()
	return _equipment_slots.get(slot_id, {}).duplicate(true)


static func make_item_instance(definition_id: String, rarity: String = "normal", rolled_modifiers: Dictionary = {}, extra_data: Dictionary = {}) -> Dictionary:
	var definition := get_definition(definition_id)
	if definition.is_empty():
		return {}
	var instance := extra_data.duplicate(true)
	instance["schema"] = "ItemInstance"
	instance["instance_id"] = str(instance.get("instance_id", "%s_%d" % [definition_id, randi()]))
	instance["id"] = str(instance.get("id", instance["instance_id"]))
	instance["definition_id"] = definition_id
	instance["item_type"] = str(definition.get("item_type", ""))
	instance["type"] = instance["item_type"]
	instance["equip_slot"] = str(definition.get("equip_slot", ""))
	instance["rarity"] = rarity
	instance["base_name"] = str(definition.get("name", definition_id))
	instance["name"] = str(instance.get("name", instance["base_name"]))
	instance["icon"] = str(definition.get("icon", ""))
	instance["stat_modifiers"] = _merge_stat_modifiers(definition.get("base_stat_modifiers", {}), rolled_modifiers)
	instance["damage_bonus"] = get_stat_modifier_total(instance, "damage")
	if not instance.has("color"):
		instance["color"] = DEFAULT_RARITY_COLOR
	return instance


static func normalize_item_instance(item_data: Dictionary) -> Dictionary:
	if item_data.is_empty():
		return {}
	var definition_id := str(item_data.get("definition_id", ""))
	if definition_id.is_empty():
		definition_id = _legacy_definition_id(item_data)
	var rarity := str(item_data.get("rarity", "normal"))
	var rolled_modifiers: Dictionary = item_data.get("stat_modifiers", {})
	if rolled_modifiers.is_empty() and item_data.has("damage_bonus"):
		rolled_modifiers = {"damage": int(item_data.get("damage_bonus", 0))}
	var normalized := make_item_instance(definition_id, rarity, rolled_modifiers, item_data)
	if normalized.is_empty():
		return item_data.duplicate(true)
	if item_data.has("name"):
		normalized["name"] = str(item_data["name"])
	if item_data.has("color"):
		normalized["color"] = item_data["color"]
	normalized["damage_bonus"] = get_stat_modifier_total(normalized, "damage")
	return normalized


static func can_equip_in_slot(item_data: Dictionary, slot_id: String) -> bool:
	var item: Dictionary = normalize_item_instance(item_data)
	if item.is_empty():
		return false
	var slot := get_equipment_slot(slot_id)
	if slot.is_empty() or not bool(slot.get("active", false)):
		return false
	if str(item.get("equip_slot", "")) == slot_id:
		return true
	var accepted: Array = slot.get("accepted_item_types", [])
	return accepted.has(str(item.get("item_type", item.get("type", ""))))


static func get_stat_modifier_total(item_data: Dictionary, stat_id: String) -> int:
	var modifiers = item_data.get("stat_modifiers", {})
	if modifiers is Dictionary:
		return int(modifiers.get(stat_id, 0))
	return 0


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_definitions.clear()
	_equipment_slots.clear()
	_item_types.clear()
	var file := FileAccess.open(ITEM_DEFINITIONS_PATH, FileAccess.READ)
	if file == null:
		push_error("ItemDatabase failed to open %s" % ITEM_DEFINITIONS_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("ItemDatabase failed to parse %s" % ITEM_DEFINITIONS_PATH)
		return
	for item_type in parsed.get("item_types", []):
		_item_types.append(str(item_type))
	for slot in parsed.get("equipment_slots", []):
		if slot is Dictionary:
			_equipment_slots[str(slot.get("id", ""))] = slot.duplicate(true)
	for definition in parsed.get("definitions", []):
		if definition is Dictionary:
			_definitions[str(definition.get("id", ""))] = definition.duplicate(true)


static func _merge_stat_modifiers(base_modifiers, rolled_modifiers: Dictionary) -> Dictionary:
	var merged := {}
	if base_modifiers is Dictionary:
		for stat_id in base_modifiers.keys():
			merged[str(stat_id)] = int(base_modifiers[stat_id])
	for stat_id in rolled_modifiers.keys():
		merged[str(stat_id)] = int(merged.get(str(stat_id), 0)) + int(rolled_modifiers[stat_id])
	return merged


static func _legacy_definition_id(item_data: Dictionary) -> String:
	var legacy_id := str(item_data.get("id", ""))
	var candidates := {
		"rusty_short_sword": "weapon_rusty_short_sword",
		"iron_sword": "weapon_iron_sword",
		"bone_axe": "weapon_bone_axe",
		"crystal_sword": "weapon_crystal_sword",
		"flame_sword": "weapon_flame_sword",
	}
	for key in candidates.keys():
		if legacy_id.contains(str(key)):
			return str(candidates[key])
	return "weapon_rusty_short_sword"
