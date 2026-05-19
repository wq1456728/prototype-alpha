extends RefCounted
class_name MapGenerationDebug


static func validate_layout(layout: GeneratedMapLayout) -> Dictionary:
	var errors := []
	var warnings := []
	if layout == null:
		return {"ok": false, "errors": ["layout is null"], "warnings": warnings}

	_validate_required_counts(layout, errors, warnings)
	_validate_zones_and_anchors(layout, errors)
	_validate_graph_reachability(layout, errors)
	_validate_corridor_overlap(layout, errors)
	_validate_boundary_pairs(layout, errors)
	_validate_plain_payload(layout.to_payload(), errors)

	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"counts": {
			"zones": layout.zones.size(),
			"route_connections": layout.route_connections.size(),
			"corridors": layout.corridors.size(),
			"anchors": layout.anchors.size(),
			"objects": layout.map_objects.size(),
			"spawn_groups": layout.spawn_groups.size(),
			"boundary_visuals": layout.boundary_visuals.size(),
			"blockers": layout.blockers.size(),
		},
	}


static func stable_payload_string(layout: GeneratedMapLayout) -> String:
	return JSON.stringify(layout.to_payload())


static func stable_payload_hash(layout: GeneratedMapLayout) -> int:
	return stable_payload_string(layout).hash()


static func build_scene(parent: Node, layout: GeneratedMapLayout) -> Node2D:
	var existing := parent.get_node_or_null("GeneratedProceduralMap")
	if existing != null:
		parent.remove_child(existing)
		existing.free()

	var root := Node2D.new()
	root.name = "GeneratedProceduralMap"
	root.set_meta("payload", layout.to_payload())
	root.set_meta("payload_hash", stable_payload_hash(layout))
	parent.add_child(root)

	var ground_root := _add_node(root, "Ground")
	var corridor_root := _add_node(root, "RouteCorridors")
	var zone_root := _add_node(root, "Zones")
	var anchor_root := _add_node(root, "Anchors")
	var object_root := _add_node(root, "MapObjects")
	var spawn_root := _add_node(root, "SpawnGroups")
	var boundary_root := _add_node(root, "BoundaryVisuals")
	var blocker_root := _add_node(root, "Blockers")
	var label_root := _add_node(root, "DebugLabels")

	_add_color_rect(ground_root, "MapBounds", Rect2(Vector2.ZERO, layout.map_size), Color(0.075, 0.09, 0.075, 1.0), -120)
	for corridor in layout.corridors:
		var corridor_rect: Rect2 = corridor.get("rect", Rect2())
		_add_color_rect(corridor_root, str(corridor.get("id", "")), corridor_rect, Color(0.18, 0.16, 0.105, 0.92), -90)
		_add_label(label_root, "label_%s" % str(corridor.get("id", "")), "corridor\n%s" % str(corridor.get("connection_id", "")), corridor_rect.get_center() - Vector2(90.0, 26.0), 22, Color(0.84, 0.72, 0.48, 1.0), 90)
	for zone in layout.zones:
		_add_zone_rect(zone_root, zone)
		_add_zone_label(label_root, zone)
	for anchor in layout.anchors:
		_add_marker_rect(anchor_root, str(anchor.get("id", "")), anchor.get("position", Vector2.ZERO), Color(0.95, 0.8, 0.2, 1.0), 20.0, -30)
		_add_label(label_root, "label_%s" % str(anchor.get("id", "")), "anchor\n%s" % str(anchor.get("type", "")), anchor.get("position", Vector2.ZERO) + Vector2(16.0, -22.0), 20, Color(1.0, 0.92, 0.48, 1.0), 110)
	for map_object in layout.map_objects:
		_add_marker_rect(object_root, str(map_object.get("id", "")), map_object.get("position", Vector2.ZERO), Color(0.3, 0.82, 0.95, 1.0), 30.0, -20)
		_add_label(label_root, "label_%s" % str(map_object.get("id", "")), "object\n%s" % _pretty_token(str(map_object.get("type", ""))), map_object.get("position", Vector2.ZERO) + Vector2(22.0, -18.0), 24, Color(0.58, 0.9, 1.0, 1.0), 120)
	for spawn_group in layout.spawn_groups:
		var zone := layout.find_zone(str(spawn_group.get("zone_id", "")))
		if not zone.is_empty():
			var rect: Rect2 = zone.get("rect", Rect2())
			var spawn_position := rect.get_center() + Vector2(34.0, -34.0)
			_add_marker_rect(spawn_root, str(spawn_group.get("id", "")), spawn_position, Color(0.88, 0.28, 0.24, 1.0), 26.0, -10)
			_add_label(label_root, "label_%s" % str(spawn_group.get("id", "")), "monster group\n%s\ncount %d / budget %d" % [
				_pretty_token(str(spawn_group.get("type", ""))),
				int(spawn_group.get("count", 0)),
				int(spawn_group.get("budget", 0)),
			], spawn_position + Vector2(24.0, 4.0), 24, Color(1.0, 0.56, 0.48, 1.0), 120)
	for visual in layout.boundary_visuals:
		var visual_rect: Rect2 = visual.get("rect", Rect2())
		var boundary_visual := _add_color_rect(boundary_root, str(visual.get("id", "")), visual_rect, Color(0.055, 0.07, 0.055, 1.0), -80)
		boundary_visual.set_meta("source", str(visual.get("source", "")))
		boundary_visual.set_meta("blocker_id", str(visual.get("blocker_id", "")))
	for blocker in layout.blockers:
		_add_blocker(blocker_root, blocker)

	return root


static func _validate_required_counts(layout: GeneratedMapLayout, errors: Array, warnings: Array) -> void:
	var main_ids := layout.get_main_path_zone_ids()
	if main_ids.size() < 4 or main_ids.size() > 6:
		errors.append("main path zone count out of range: %d" % main_ids.size())
	if _count_zones_by_type(layout, "required_branch") != 1:
		errors.append("required branch zone count must be 1")
	if _count_zones_by_type(layout, "optional_pocket") > 1:
		errors.append("optional pocket zone count must be 0 or 1")
	if _count_zones_by_type(layout, "optional_pocket") == 0:
		warnings.append("optional pocket not generated for this seed")
	for anchor_type in ["start", "required_branch", "required_exit"]:
		var anchor := layout.find_anchor_by_type(anchor_type)
		if anchor.is_empty():
			errors.append("missing required anchor type: %s" % anchor_type)


static func _validate_zones_and_anchors(layout: GeneratedMapLayout, errors: Array) -> void:
	var zone_ids := {}
	for zone in layout.zones:
		var zone_id := str(zone.get("id", ""))
		var rect: Rect2 = zone.get("rect", Rect2())
		if zone_id.is_empty():
			errors.append("zone has empty id")
		if zone_ids.has(zone_id):
			errors.append("duplicate zone id: %s" % zone_id)
		zone_ids[zone_id] = true
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			errors.append("zone has invalid rect: %s" % zone_id)
		if str(zone.get("template_id", "")).is_empty():
			errors.append("zone has empty template_id: %s" % zone_id)
		if Array(zone.get("anchors", [])).is_empty():
			errors.append("zone has no anchors: %s" % zone_id)

	for anchor in layout.anchors:
		var zone_id := str(anchor.get("zone_id", ""))
		var zone := layout.find_zone(zone_id)
		if zone.is_empty():
			errors.append("anchor references missing zone: %s -> %s" % [str(anchor.get("id", "")), zone_id])
			continue
		var rect: Rect2 = zone.get("rect", Rect2())
		var position: Vector2 = anchor.get("position", Vector2.ZERO)
		if not rect.has_point(position):
			errors.append("anchor outside zone: %s zone=%s position=%s" % [str(anchor.get("id", "")), zone_id, position])

	for map_object in layout.map_objects:
		var zone := layout.find_zone(str(map_object.get("zone_id", "")))
		if zone.is_empty():
			errors.append("map_object references missing zone: %s" % str(map_object.get("id", "")))
			continue
		var zone_rect: Rect2 = zone.get("rect", Rect2())
		if not zone_rect.has_point(map_object.get("position", Vector2.ZERO)):
			errors.append("map_object outside zone: %s" % str(map_object.get("id", "")))

	for spawn_group in layout.spawn_groups:
		if layout.find_zone(str(spawn_group.get("zone_id", ""))).is_empty():
			errors.append("spawn_group references missing zone: %s" % str(spawn_group.get("id", "")))
		if int(spawn_group.get("count", 0)) < 0 or int(spawn_group.get("budget", 0)) < 0:
			errors.append("spawn_group has negative count or budget: %s" % str(spawn_group.get("id", "")))


static func _validate_graph_reachability(layout: GeneratedMapLayout, errors: Array) -> void:
	var graph := {}
	for zone in layout.zones:
		graph[str(zone.get("id", ""))] = []
	for connection in layout.route_connections:
		var from_id := str(connection.get("from", ""))
		var to_id := str(connection.get("to", ""))
		if not graph.has(from_id):
			errors.append("route connection missing from zone: %s" % from_id)
			continue
		if not graph.has(to_id):
			errors.append("route connection missing to zone: %s" % to_id)
			continue
		graph[from_id].append(to_id)
		graph[to_id].append(from_id)

	var start_anchor := layout.find_anchor_by_type("start")
	var branch_anchor := layout.find_anchor_by_type("required_branch")
	var exit_anchor := layout.find_anchor_by_type("required_exit")
	if start_anchor.is_empty() or branch_anchor.is_empty() or exit_anchor.is_empty():
		return
	var start_zone := str(start_anchor.get("zone_id", ""))
	var branch_zone := str(branch_anchor.get("zone_id", ""))
	var exit_zone := str(exit_anchor.get("zone_id", ""))
	if not _is_reachable(graph, start_zone, exit_zone):
		errors.append("required exit not reachable from start")
	if not _is_reachable(graph, start_zone, branch_zone):
		errors.append("required branch not reachable from start")


static func _validate_corridor_overlap(layout: GeneratedMapLayout, errors: Array) -> void:
	for connection in layout.route_connections:
		var from_zone := layout.find_zone(str(connection.get("from", "")))
		var to_zone := layout.find_zone(str(connection.get("to", "")))
		if from_zone.is_empty() or to_zone.is_empty():
			continue
		var from_rect: Rect2 = from_zone.get("rect", Rect2())
		var to_rect: Rect2 = to_zone.get("rect", Rect2())
		var corridor_ids: Array = connection.get("corridor_ids", [])
		if corridor_ids.is_empty():
			errors.append("route connection has no corridors: %s" % str(connection.get("id", "")))
			continue

		var touches_from := false
		var touches_to := false
		var corridor_rects := []
		for corridor_id in corridor_ids:
			var corridor := layout.find_corridor(str(corridor_id))
			if corridor.is_empty():
				errors.append("route connection references missing corridor: %s" % str(corridor_id))
				continue
			var rect: Rect2 = corridor.get("rect", Rect2())
			corridor_rects.append(rect)
			touches_from = touches_from or rect.intersects(from_rect, true)
			touches_to = touches_to or rect.intersects(to_rect, true)
		if not touches_from or not touches_to:
			errors.append("corridors do not overlap both endpoint zones: %s" % str(connection.get("id", "")))
		for index in range(max(corridor_rects.size() - 1, 0)):
			var corridor_rect: Rect2 = corridor_rects[index]
			if not corridor_rect.intersects(corridor_rects[index + 1], true):
				errors.append("corridor segments do not overlap: %s index=%d" % [str(connection.get("id", "")), index])


static func _validate_boundary_pairs(layout: GeneratedMapLayout, errors: Array) -> void:
	if layout.boundary_visuals.is_empty() or layout.blockers.is_empty():
		errors.append("boundary visuals and blockers must both exist")
	for visual in layout.boundary_visuals:
		var visual_id := str(visual.get("id", ""))
		var blocker_id := str(visual.get("blocker_id", ""))
		var source := str(visual.get("source", ""))
		if blocker_id.is_empty() or source.is_empty():
			errors.append("boundary visual missing blocker_id or source: %s" % visual_id)
			continue
		var blocker := layout.find_blocker(blocker_id)
		if blocker.is_empty():
			errors.append("boundary visual missing blocker pair: %s -> %s" % [visual_id, blocker_id])
			continue
		if str(blocker.get("visual_id", "")) != visual_id or str(blocker.get("source", "")) != source:
			errors.append("boundary visual/blocker mismatch: %s -> %s" % [visual_id, blocker_id])
	for blocker in layout.blockers:
		var blocker_id := str(blocker.get("id", ""))
		var visual_id := str(blocker.get("visual_id", ""))
		var source := str(blocker.get("source", ""))
		if visual_id.is_empty() or source.is_empty():
			errors.append("blocker missing visual_id or source: %s" % blocker_id)
			continue
		var visual := layout.find_boundary_visual(visual_id)
		if visual.is_empty():
			errors.append("blocker missing visual pair: %s -> %s" % [blocker_id, visual_id])
			continue
		if str(visual.get("blocker_id", "")) != blocker_id or str(visual.get("source", "")) != source:
			errors.append("blocker/visual mismatch: %s -> %s" % [blocker_id, visual_id])


static func _validate_plain_payload(value, errors: Array, path: String = "payload") -> void:
	match typeof(value):
		TYPE_DICTIONARY:
			for key in value.keys():
				_validate_plain_payload(value[key], errors, "%s.%s" % [path, str(key)])
		TYPE_ARRAY:
			for index in range(value.size()):
				_validate_plain_payload(value[index], errors, "%s[%d]" % [path, index])
		TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_RECT2, TYPE_RECT2I, TYPE_OBJECT, TYPE_NODE_PATH:
			errors.append("payload contains non-plain value at %s" % path)


static func _is_reachable(graph: Dictionary, start_id: String, target_id: String) -> bool:
	if not graph.has(start_id) or not graph.has(target_id):
		return false
	var queue := [start_id]
	var visited := {start_id: true}
	while not queue.is_empty():
		var current := str(queue.pop_front())
		if current == target_id:
			return true
		for next_id in graph.get(current, []):
			var next_key := str(next_id)
			if not visited.has(next_key):
				visited[next_key] = true
				queue.append(next_key)
	return false


static func _count_zones_by_type(layout: GeneratedMapLayout, zone_type: String) -> int:
	var count := 0
	for zone in layout.zones:
		if str(zone.get("type", "")) == zone_type:
			count += 1
	return count


static func _add_node(parent: Node, node_name: String) -> Node2D:
	var node := Node2D.new()
	node.name = node_name
	parent.add_child(node)
	return node


static func _add_zone_rect(parent: Node, zone: Dictionary) -> void:
	var zone_type := str(zone.get("type", ""))
	var color := Color(0.18, 0.2, 0.14, 0.58)
	match zone_type:
		"start":
			color = Color(0.18, 0.28, 0.18, 0.68)
		"first_contact":
			color = Color(0.28, 0.22, 0.14, 0.66)
		"fork":
			color = Color(0.22, 0.2, 0.34, 0.68)
		"elite_pressure":
			color = Color(0.34, 0.16, 0.16, 0.68)
		"required_exit":
			color = Color(0.14, 0.24, 0.34, 0.68)
		"required_branch":
			color = Color(0.32, 0.18, 0.3, 0.68)
		"optional_pocket":
			color = Color(0.28, 0.27, 0.13, 0.66)
	var rect := _add_color_rect(parent, str(zone.get("id", "")), zone.get("rect", Rect2()), color, -60)
	rect.set_meta("zone_type", zone_type)
	rect.set_meta("template_id", str(zone.get("template_id", "")))


static func _add_zone_label(parent: Node, zone: Dictionary) -> void:
	var rect: Rect2 = zone.get("rect", Rect2())
	var zone_type := str(zone.get("type", ""))
	var text := "%s\n%s\ntemplate: %s" % [
		zone_type,
		str(zone.get("label", zone_type)),
		str(zone.get("template_id", "")),
	]
	_add_label(parent, "label_%s" % str(zone.get("id", "")), text, rect.position + Vector2(18.0, 16.0), 32, Color(0.92, 0.92, 0.78, 1.0), 100)


static func _add_marker_rect(parent: Node, marker_name: String, position: Vector2, color: Color, size: float, z_index: int) -> ColorRect:
	return _add_color_rect(parent, marker_name, Rect2(position - Vector2(size, size) * 0.5, Vector2(size, size)), color, z_index)


static func _add_label(parent: Node, label_name: String, text: String, position: Vector2, font_size: int, font_color: Color, z_index: int) -> Label:
	var label := Label.new()
	label.name = label_name
	label.text = text
	label.position = position
	label.z_index = z_index
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
	return label


static func _add_color_rect(parent: Node, rect_name: String, rect: Rect2, color: Color, z_index: int) -> ColorRect:
	var color_rect := ColorRect.new()
	color_rect.name = rect_name
	color_rect.position = rect.position
	color_rect.size = rect.size
	color_rect.color = color
	color_rect.z_index = z_index
	parent.add_child(color_rect)
	return color_rect


static func _add_blocker(parent: Node, blocker: Dictionary) -> StaticBody2D:
	var rect: Rect2 = blocker.get("rect", Rect2())
	var body := StaticBody2D.new()
	body.name = str(blocker.get("id", ""))
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.position + rect.size * 0.5
	body.set_meta("source", str(blocker.get("source", "")))
	body.set_meta("visual_id", str(blocker.get("visual_id", "")))
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	body.add_child(shape)
	parent.add_child(body)
	return body


static func _pretty_token(value: String) -> String:
	return value.replace("_placeholder", "").replace("_", " ")
