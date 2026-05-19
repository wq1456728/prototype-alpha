extends SceneTree

const ConfigScript := preload("res://scripts/maps/procedural/map_generation_config.gd")
const GeneratorScript := preload("res://scripts/maps/procedural/map_generator.gd")
const DebugScript := preload("res://scripts/maps/procedural/map_generation_debug.gd")

const SCENE_PATH := "res://scenes/maps/procedural_map_test.tscn"
const CONFIG_PATH := "res://data/maps/procedural_dummy_config.json"
const TEST_SEEDS := [23001, 23002, 23003]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var config: MapGenerationConfig = ConfigScript.from_json_file(CONFIG_PATH)
	var payloads := []
	var hashes := []

	for seed_value in TEST_SEEDS:
		var seed := int(seed_value)
		var layout_a: GeneratedMapLayout = GeneratorScript.generate(config, seed)
		var validation: Dictionary = DebugScript.validate_layout(layout_a)
		if not bool(validation.get("ok", false)):
			_fail("validate seed=%d errors=%s warnings=%s" % [seed, validation.get("errors", []), validation.get("warnings", [])])
			return

		var payload_a: Dictionary = layout_a.to_payload()
		if not _payload_has_required_core(payload_a):
			_fail("required payload fields missing seed=%d" % seed)
			return
		if not _boundary_pairs_align(payload_a):
			_fail("boundary pair mismatch seed=%d" % seed)
			return

		var payload_string_a := DebugScript.stable_payload_string(layout_a)
		var layout_b: GeneratedMapLayout = GeneratorScript.generate(config, seed)
		var payload_string_b := DebugScript.stable_payload_string(layout_b)
		if payload_string_a != payload_string_b:
			_fail("determinism mismatch seed=%d" % seed)
			return

		payloads.append(payload_a)
		hashes.append(DebugScript.stable_payload_hash(layout_a))

	if not _seed_payloads_differ(payloads):
		_fail("different seeds did not differ in route/template/branch/map_objects")
		return

	var scene_error := change_scene_to_file(SCENE_PATH)
	if scene_error != OK:
		_fail("scene_load=%s" % scene_error)
		return
	if not await _wait_for_scene():
		_fail("scene_not_ready")
		return

	var validation_result: Dictionary = current_scene.call("get_validation_result")
	if not bool(validation_result.get("ok", false)):
		_fail("scene_validation errors=%s" % validation_result.get("errors", []))
		return
	var scene_payload: Dictionary = current_scene.call("get_debug_payload")
	var generated_root := current_scene.get_node_or_null("GeneratedProceduralMap")
	if generated_root == null:
		_fail("generated_root_missing")
		return
	var blocker_root := generated_root.get_node_or_null("Blockers")
	var boundary_root := generated_root.get_node_or_null("BoundaryVisuals")
	if blocker_root == null or boundary_root == null:
		_fail("boundary_or_blocker_root_missing")
		return
	if blocker_root.get_child_count() != Array(scene_payload.get("blockers", [])).size():
		_fail("scene_blocker_count mismatch nodes=%d payload=%d" % [blocker_root.get_child_count(), Array(scene_payload.get("blockers", [])).size()])
		return
	if boundary_root.get_child_count() != Array(scene_payload.get("boundary_visuals", [])).size():
		_fail("scene_boundary_count mismatch nodes=%d payload=%d" % [boundary_root.get_child_count(), Array(scene_payload.get("boundary_visuals", [])).size()])
		return

	print("MapGeneratorCore smoke: PASS seeds=%s hashes=%s scene_zones=%d blockers=%d" % [
		str(TEST_SEEDS),
		str(hashes),
		Array(scene_payload.get("zones", [])).size(),
		Array(scene_payload.get("blockers", [])).size(),
	])
	quit(0)


func _payload_has_required_core(payload: Dictionary) -> bool:
	for key in ["seed", "map_id", "map_name", "size", "zones", "route_connections", "anchors", "objects", "spawn_groups", "boundary_visuals", "blockers"]:
		if not payload.has(key):
			return false
	var required_types := {"start": false, "required_branch": false, "required_exit": false}
	for anchor in payload.get("anchors", []):
		var anchor_type := str(anchor.get("type", ""))
		if required_types.has(anchor_type):
			required_types[anchor_type] = true
	for required_type in required_types.keys():
		if not bool(required_types[required_type]):
			return false
	return true


func _boundary_pairs_align(payload: Dictionary) -> bool:
	var visuals := {}
	var blockers := {}
	for visual in payload.get("boundary_visuals", []):
		visuals[str(visual.get("id", ""))] = visual
	for blocker in payload.get("blockers", []):
		blockers[str(blocker.get("id", ""))] = blocker
	for visual_id in visuals.keys():
		var visual: Dictionary = visuals[visual_id]
		var blocker_id := str(visual.get("blocker_id", ""))
		if not blockers.has(blocker_id):
			return false
		var blocker: Dictionary = blockers[blocker_id]
		if str(blocker.get("visual_id", "")) != visual_id or str(blocker.get("source", "")) != str(visual.get("source", "")):
			return false
	for blocker_id in blockers.keys():
		var blocker: Dictionary = blockers[blocker_id]
		var visual_id := str(blocker.get("visual_id", ""))
		if not visuals.has(visual_id):
			return false
		var visual: Dictionary = visuals[visual_id]
		if str(visual.get("blocker_id", "")) != blocker_id or str(visual.get("source", "")) != str(blocker.get("source", "")):
			return false
	return true


func _seed_payloads_differ(payloads: Array) -> bool:
	if payloads.size() < 2:
		return false
	for index in range(1, payloads.size()):
		var categories := _difference_categories(payloads[0], payloads[index])
		if categories.is_empty():
			return false
	return true


func _difference_categories(left: Dictionary, right: Dictionary) -> Array:
	var categories := []
	if JSON.stringify(left.get("corridors", [])) != JSON.stringify(right.get("corridors", [])):
		categories.append("route")
	if _template_signature(left) != _template_signature(right):
		categories.append("template")
	if _required_branch_signature(left) != _required_branch_signature(right):
		categories.append("branch")
	if JSON.stringify(left.get("objects", [])) != JSON.stringify(right.get("objects", [])):
		categories.append("map_objects")
	return categories


func _template_signature(payload: Dictionary) -> String:
	var signature := []
	for zone in payload.get("zones", []):
		signature.append("%s:%s" % [str(zone.get("id", "")), str(zone.get("template_id", ""))])
	return "|".join(signature)


func _required_branch_signature(payload: Dictionary) -> String:
	for zone in payload.get("zones", []):
		if str(zone.get("type", "")) == "required_branch":
			return JSON.stringify(zone)
	return ""


func _wait_for_scene() -> bool:
	for _i in range(20):
		await process_frame
		if current_scene != null and current_scene.has_method("get_debug_payload"):
			return true
	return false


func _fail(message: String) -> void:
	print("MapGeneratorCore smoke: FAIL %s" % message)
	quit(1)
