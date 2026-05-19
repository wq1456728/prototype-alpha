extends SceneTree

const CATALOG_SCRIPT := preload("res://scripts/maps/procedural/map_object_definition.gd")


func _initialize() -> void:
	var catalog = CATALOG_SCRIPT.load_from_file()
	var validation: Dictionary = catalog.validate()
	if not bool(validation.get("ok", false)):
		print("MapObjectDefinitions smoke: FAIL errors=%s warnings=%s" % [validation.get("errors", []), validation.get("warnings", [])])
		quit(1)
		return
	var required := {
		"dead_tree_a": "capsule",
		"dead_tree_b": "capsule",
		"rock_a": "capsule",
		"rock_b": "capsule",
		"broken_fence_a": "capsule",
		"broken_fence_b": "capsule",
		"camp_gate": "capsule",
		"dungeon_entrance": "capsule",
	}
	for def_id in required.keys():
		if not catalog.has_definition(def_id):
			print("MapObjectDefinitions smoke: FAIL missing=%s" % def_id)
			quit(1)
			return
		var definition: Dictionary = catalog.get_definition(def_id)
		var shape := str(Dictionary(definition.get("collision", {})).get("shape", ""))
		if shape != str(required[def_id]):
			print("MapObjectDefinitions smoke: FAIL shape=%s expected=%s actual=%s" % [def_id, required[def_id], shape])
			quit(1)
			return
		var orientation := str(Dictionary(definition.get("collision", {})).get("orientation", ""))
		if shape == "capsule" and not ["vertical", "horizontal"].has(orientation):
			print("MapObjectDefinitions smoke: FAIL capsule_bad_orientation=%s orientation=%s" % [def_id, orientation])
			quit(1)
			return
	print("MapObjectDefinitions smoke: PASS count=%d" % int(validation.get("count", 0)))
	quit(0)
