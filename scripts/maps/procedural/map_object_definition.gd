extends RefCounted
class_name MapObjectDefinitionCatalog

const DEFAULT_PATH := "res://data/maps/map_object_defs.json"

var definitions := {}
var warnings := []


static func load_from_file(path: String = DEFAULT_PATH) -> MapObjectDefinitionCatalog:
	var catalog := MapObjectDefinitionCatalog.new()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		catalog.warnings.append("missing object definition file: %s" % path)
		return catalog
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		catalog.warnings.append("invalid object definition json: %s" % path)
		return catalog
	catalog.definitions = parsed.duplicate(true)
	return catalog


func has_definition(def_id: String) -> bool:
	return definitions.has(def_id)


func get_definition(def_id: String) -> Dictionary:
	return definitions.get(def_id, {}).duplicate(true)


func get_definition_ids() -> Array:
	var ids := []
	for id in definitions.keys():
		ids.append(str(id))
	ids.sort()
	return ids


func validate() -> Dictionary:
	var errors := []
	var validation_warnings := warnings.duplicate()
	for def_id in definitions.keys():
		var definition: Dictionary = definitions[def_id]
		if str(definition.get("texture", "")).is_empty():
			errors.append("%s missing texture" % def_id)
		if not definition.has("sprite_offset"):
			errors.append("%s missing sprite_offset" % def_id)
		if not definition.has("y_sort_origin"):
			errors.append("%s missing y_sort_origin" % def_id)
		if not definition.has("collision"):
			errors.append("%s missing collision" % def_id)
			continue
		var collision: Dictionary = definition.get("collision", {})
		var shape := str(collision.get("shape", ""))
		if not ["rect", "circle", "capsule"].has(shape):
			errors.append("%s invalid collision shape: %s" % [def_id, shape])
		if shape == "rect" and not collision.has("size"):
			errors.append("%s rect collision missing size" % def_id)
		if shape == "circle" and not collision.has("radius"):
			errors.append("%s circle collision missing radius" % def_id)
		if shape == "capsule":
			if not ["vertical", "horizontal"].has(str(collision.get("orientation", ""))):
				errors.append("%s capsule collision must declare vertical or horizontal orientation" % def_id)
			if not collision.has("radius") or not collision.has("height"):
				errors.append("%s capsule collision missing radius or height" % def_id)
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"warnings": validation_warnings,
		"count": definitions.size(),
	}


func to_payload_used(ids: Array) -> Array:
	var unique := {}
	for id in ids:
		unique[str(id)] = true
	var payload := []
	var sorted_ids := unique.keys()
	sorted_ids.sort()
	for id in sorted_ids:
		var definition := get_definition(str(id))
		if definition.is_empty():
			continue
		payload.append({
			"id": str(id),
			"texture": str(definition.get("texture", "")),
			"scale": float(definition.get("scale", 1.0)),
			"sprite_offset": definition.get("sprite_offset", {}),
			"y_sort_origin": definition.get("y_sort_origin", {}),
			"collision": definition.get("collision", {}),
			"blocks_player": bool(definition.get("blocks_player", false)),
			"tags": Array(definition.get("tags", [])).duplicate(),
		})
	return payload
