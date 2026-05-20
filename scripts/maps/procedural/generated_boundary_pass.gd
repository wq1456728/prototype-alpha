extends RefCounted
class_name GeneratedBoundaryPass

var cell_size := 64
var walkable_cells := {}
var boundary_cells := {}
var blocked_cells := {}
var contour_segments := []
var contour_corners := []
var boundary_segments := []
var boundary_objects := []
var object_defs_used := []
var warnings := []


func generate(layout: GeneratedMapLayout, boundary_style: Dictionary, factory: MapObjectFactory, seed: int) -> Dictionary:
	cell_size = int(boundary_style.get("cell_size", 64))
	walkable_cells.clear()
	boundary_cells.clear()
	blocked_cells.clear()
	contour_segments.clear()
	contour_corners.clear()
	boundary_segments.clear()
	boundary_objects.clear()
	object_defs_used.clear()
	warnings.clear()

	_build_walkable_cells(layout)
	_build_boundary_cells(layout)
	_apply_connection_openings(layout, boundary_style)
	_build_contour_lines()
	_build_blocked_cells(layout)
	_place_boundary_objects(boundary_style, factory, seed)
	return to_payload()


func to_payload() -> Dictionary:
	return {
		"cell_size": cell_size,
		"walkable_cells": _cell_payload(walkable_cells),
		"boundary_cells": _boundary_cell_payload(),
		"blocked_cells": _cell_payload(blocked_cells),
		"contour_segments": contour_segments.duplicate(true),
		"corner_points": contour_corners.duplicate(true),
		"boundary_segments": boundary_segments.duplicate(true),
		"boundary_objects": boundary_objects.duplicate(true),
		"object_defs_used": object_defs_used.duplicate(),
		"warnings": warnings.duplicate(),
	}


func validate(max_gap_cells: int = 2) -> Dictionary:
	var errors := []
	if cell_size <= 0:
		errors.append("invalid cell_size")
	if walkable_cells.is_empty():
		errors.append("walkable mask is empty")
	if boundary_cells.is_empty():
		errors.append("boundary cells are empty")
	if contour_segments.is_empty():
		errors.append("boundary contour is empty")
	if boundary_objects.is_empty():
		errors.append("boundary objects are empty")
	var missing_boundary := 0
	for boundary_key in boundary_cells.keys():
		var boundary: Dictionary = boundary_cells[boundary_key]
		if not bool(boundary.get("covered", false)):
			missing_boundary += 1
	if missing_boundary > 0:
		errors.append("boundary cells missing visual coverage: %d" % missing_boundary)
	for segment in boundary_segments:
		if int(segment.get("gap_cells", 0)) > max_gap_cells:
			errors.append("boundary segment gap too large: %s" % str(segment))
	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings.duplicate()}


func _build_walkable_cells(layout: GeneratedMapLayout) -> void:
	for zone in layout.zones:
		var rect: Rect2 = zone.get("rect", Rect2())
		_mark_rect_cells(rect.grow(float(cell_size) * 0.75), walkable_cells)
	for corridor in layout.corridors:
		var rect: Rect2 = corridor.get("rect", Rect2())
		_mark_rect_cells(rect.grow(float(cell_size) * 0.35), walkable_cells)


func _build_boundary_cells(layout: GeneratedMapLayout) -> void:
	var max_x := int(ceil(layout.map_size.x / float(cell_size))) - 1
	var max_y := int(ceil(layout.map_size.y / float(cell_size))) - 1
	for key in walkable_cells.keys():
		var coords := _coords_from_key(str(key))
		for neighbor in [
			{"offset": Vector2i(0, -1), "edge": "north"},
			{"offset": Vector2i(0, 1), "edge": "south"},
			{"offset": Vector2i(-1, 0), "edge": "west"},
			{"offset": Vector2i(1, 0), "edge": "east"},
		]:
			var next: Vector2i = coords + neighbor["offset"]
			if next.x < 0 or next.y < 0 or next.x > max_x or next.y > max_y:
				continue
			var next_key := _cell_key(next)
			if walkable_cells.has(next_key):
				continue
			if not boundary_cells.has(next_key):
				boundary_cells[next_key] = {
					"x": next.x,
					"y": next.y,
					"edges": [],
					"covered": false,
				}
			var edges: Array = boundary_cells[next_key]["edges"]
			if not edges.has(neighbor["edge"]):
				edges.append(neighbor["edge"])


func _apply_connection_openings(layout: GeneratedMapLayout, boundary_style: Dictionary) -> void:
	var openings: Array = boundary_style.get("connection_openings", [])
	for opening_value in openings:
		var opening: Dictionary = opening_value
		var anchor := layout.find_anchor_by_type(str(opening.get("anchor_type", "")))
		if anchor.is_empty():
			warnings.append("boundary connection opening missing anchor: %s" % str(opening.get("id", "")))
			continue
		var center: Vector2 = anchor.get("position", Vector2.ZERO)
		var width := float(opening.get("width", float(cell_size) * 6.0))
		var depth := float(opening.get("depth", float(cell_size) * 4.0))
		var rect := _opening_rect(center, width, depth, str(opening.get("edge", "north")))
		_remove_boundary_cells_in_rect(rect)
		walkable_cells[_cell_key(Vector2i(int(floor(center.x / float(cell_size))), int(floor(center.y / float(cell_size)))))] = {
			"x": int(floor(center.x / float(cell_size))),
			"y": int(floor(center.y / float(cell_size))),
		}


func _opening_rect(center: Vector2, width: float, depth: float, edge: String) -> Rect2:
	match edge:
		"south":
			return Rect2(Vector2(center.x - width * 0.5, center.y), Vector2(width, depth))
		"east":
			return Rect2(Vector2(center.x, center.y - width * 0.5), Vector2(depth, width))
		"west":
			return Rect2(Vector2(center.x - depth, center.y - width * 0.5), Vector2(depth, width))
	return Rect2(Vector2(center.x - width * 0.5, center.y - depth), Vector2(width, depth))


func _remove_boundary_cells_in_rect(rect: Rect2) -> void:
	var remove_keys := []
	for key in boundary_cells.keys():
		var cell: Dictionary = boundary_cells[key]
		var center := _cell_center(int(cell.get("x", 0)), int(cell.get("y", 0)))
		if rect.has_point(center):
			remove_keys.append(key)
	for key in remove_keys:
		boundary_cells.erase(key)


func _build_blocked_cells(layout: GeneratedMapLayout) -> void:
	var max_x := int(ceil(layout.map_size.x / float(cell_size))) - 1
	var max_y := int(ceil(layout.map_size.y / float(cell_size))) - 1
	for y in range(max_y + 1):
		for x in range(max_x + 1):
			var key := _cell_key(Vector2i(x, y))
			if not walkable_cells.has(key):
				blocked_cells[key] = {"x": x, "y": y}


func _build_contour_lines() -> void:
	var horizontal_segments := {}
	var vertical_segments := {}
	var horizontal_vertices := {}
	var vertical_vertices := {}
	for cell_key in boundary_cells.keys():
		var cell: Dictionary = boundary_cells[cell_key]
		var x := int(cell.get("x", 0))
		var y := int(cell.get("y", 0))
		for edge in Array(cell.get("edges", [])):
			_collect_contour_segment(
				horizontal_segments,
				vertical_segments,
				horizontal_vertices,
				vertical_vertices,
				x,
				y,
				str(edge)
			)
	contour_segments = _merged_contour_payload(horizontal_segments, true)
	contour_segments.append_array(_merged_contour_payload(vertical_segments, false))
	contour_corners = _corner_payload(horizontal_vertices, vertical_vertices)


func _collect_contour_segment(
	horizontal_segments: Dictionary,
	vertical_segments: Dictionary,
	horizontal_vertices: Dictionary,
	vertical_vertices: Dictionary,
	x: int,
	y: int,
	edge: String
) -> void:
	var left := x * cell_size
	var right := (x + 1) * cell_size
	var top := y * cell_size
	var bottom := (y + 1) * cell_size
	match edge:
		"north":
			_add_interval(horizontal_segments, "north", bottom, left, right)
			_add_vertex(horizontal_vertices, left, bottom)
			_add_vertex(horizontal_vertices, right, bottom)
		"south":
			_add_interval(horizontal_segments, "south", top, left, right)
			_add_vertex(horizontal_vertices, left, top)
			_add_vertex(horizontal_vertices, right, top)
		"west":
			_add_interval(vertical_segments, "west", right, top, bottom)
			_add_vertex(vertical_vertices, right, top)
			_add_vertex(vertical_vertices, right, bottom)
		"east":
			_add_interval(vertical_segments, "east", left, top, bottom)
			_add_vertex(vertical_vertices, left, top)
			_add_vertex(vertical_vertices, left, bottom)


func _add_interval(segments: Dictionary, edge: String, line_key: int, start: int, end: int) -> void:
	var key := "%s:%d" % [edge, line_key]
	var intervals: Array = segments.get(key, [])
	intervals.append({"edge": edge, "line": line_key, "start": mini(start, end), "end": maxi(start, end)})
	segments[key] = intervals


func _add_vertex(vertices: Dictionary, x: int, y: int) -> void:
	vertices["%d,%d" % [x, y]] = {"x": x, "y": y}


func _merged_contour_payload(segments: Dictionary, horizontal: bool) -> Array:
	var payload := []
	var keys := segments.keys()
	keys.sort()
	var segment_index := 0
	for key in keys:
		var intervals: Array = segments[key]
		if intervals.is_empty():
			continue
		intervals.sort_custom(func(a, b): return int(Dictionary(a).get("start", 0)) < int(Dictionary(b).get("start", 0)))
		var merged := []
		for interval_value in intervals:
			var interval: Dictionary = interval_value
			var start := int(interval.get("start", 0))
			var end := int(interval.get("end", 0))
			if merged.is_empty() or start > int(merged[-1].get("end", 0)):
				merged.append({
					"edge": str(interval.get("edge", "")),
					"line": int(interval.get("line", 0)),
					"start": start,
					"end": end,
				})
			else:
				merged[-1]["end"] = maxi(int(merged[-1].get("end", 0)), end)
		for run_value in merged:
			var run: Dictionary = run_value
			var line := int(run.get("line", 0))
			var start := int(run.get("start", 0))
			var end := int(run.get("end", 0))
			payload.append({
				"id": "contour_%s_%03d" % ["h" if horizontal else "v", segment_index],
				"orientation": "horizontal" if horizontal else "vertical",
				"edge": str(run.get("edge", "")),
				"start": {"x": start if horizontal else line, "y": line if horizontal else start},
				"end": {"x": end if horizontal else line, "y": line if horizontal else end},
				"length": end - start,
			})
			segment_index += 1
	return payload


func _corner_payload(horizontal_vertices: Dictionary, vertical_vertices: Dictionary) -> Array:
	var payload := []
	var keys := horizontal_vertices.keys()
	keys.sort()
	for key in keys:
		if not vertical_vertices.has(key):
			continue
		var point: Dictionary = horizontal_vertices[key]
		payload.append({
			"id": "corner_%s" % str(key).replace(",", "_"),
			"position": {"x": int(point.get("x", 0)), "y": int(point.get("y", 0))},
		})
	return payload


func _place_boundary_objects(boundary_style: Dictionary, factory: MapObjectFactory, seed: int) -> void:
	if factory == null:
		warnings.append("boundary pass missing object factory")
		return
	var families: Array = boundary_style.get("material_families", [])
	if families.is_empty():
		warnings.append("boundary_style has no material_families")
		return
	var max_families := int(boundary_style.get("max_families_per_map", 1))
	var selected_families := _select_families(families, max_families)
	var segment_index := 0
	var horizontal_spacing := float(boundary_style.get("horizontal_visual_spacing", 44.0))
	var vertical_spacing := float(boundary_style.get("vertical_visual_spacing", 26.0))
	var horizontal_line_cover := float(boundary_style.get("horizontal_visual_line_cover", 8.0))
	for contour_value in contour_segments:
		var contour: Dictionary = contour_value
		var family: Dictionary = selected_families[segment_index % selected_families.size()]
		var object_defs: Array = family.get("object_defs", [])
		if object_defs.is_empty():
			warnings.append("boundary family has no object_defs: %s" % str(family.get("id", "")))
			segment_index += 1
			continue
		var spacing := horizontal_spacing if str(contour.get("orientation", "")) == "horizontal" else vertical_spacing
		var points := _sample_contour_points(contour, spacing)
		var segment_objects := []
		for point_index in range(points.size()):
			var point: Vector2 = points[point_index]
			if str(contour.get("orientation", "")) == "horizontal":
				point.y += horizontal_line_cover
			var def_id := str(object_defs[(segment_index + seed + point_index) % object_defs.size()])
			var object_id := "BoundaryLine_%03d_%03d_%s" % [segment_index, point_index, str(family.get("id", "family"))]
			var payload := factory.place_object(object_id, def_id, point, ["generated_boundary", str(family.get("id", ""))])
			payload["zone_or_edge_source"] = "boundary_contour"
			payload["contour_segment_id"] = str(contour.get("id", ""))
			payload["material_family"] = str(family.get("id", ""))
			boundary_objects.append(payload)
			segment_objects.append(payload["id"])
			if not object_defs_used.has(def_id):
				object_defs_used.append(def_id)
		boundary_segments.append({
			"id": "boundary_segment_%03d" % segment_index,
			"material_family": str(family.get("id", "")),
			"contour_segment_id": str(contour.get("id", "")),
			"orientation": str(contour.get("orientation", "")),
			"object_count": segment_objects.size(),
			"object_ids": segment_objects,
			"gap_cells": 0,
		})
		segment_index += 1
	_place_boundary_corner_objects(selected_families, seed, factory)
	_mark_all_boundary_cells_covered()


func _sample_contour_points(contour: Dictionary, spacing: float) -> Array:
	var start := _vector2_from_dict(contour.get("start", {}))
	var end := _vector2_from_dict(contour.get("end", {}))
	var length := start.distance_to(end)
	if length <= 0.01:
		return [start]
	var count := maxi(1, int(ceil(length / maxf(spacing, 1.0))))
	var step := length / float(count)
	var direction := (end - start).normalized()
	var points := []
	for index in range(count):
		points.append(start + direction * (step * (float(index) + 0.5)))
	return points


func _place_boundary_corner_objects(selected_families: Array, seed: int, factory: MapObjectFactory) -> void:
	if selected_families.is_empty():
		return
	for corner_index in range(contour_corners.size()):
		var family: Dictionary = selected_families[corner_index % selected_families.size()]
		var object_defs: Array = family.get("object_defs", [])
		if object_defs.is_empty():
			continue
		var corner: Dictionary = contour_corners[corner_index]
		var def_id := str(object_defs[(seed + corner_index) % object_defs.size()])
		var point := _vector2_from_dict(Dictionary(corner.get("position", {})))
		var object_id := "BoundaryCornerVisual_%03d_%s" % [corner_index, str(family.get("id", "family"))]
		var payload := factory.place_object(object_id, def_id, point, ["generated_boundary", "corner", str(family.get("id", ""))])
		payload["zone_or_edge_source"] = "boundary_contour_corner"
		payload["corner_id"] = str(corner.get("id", ""))
		payload["material_family"] = str(family.get("id", ""))
		boundary_objects.append(payload)
		if not object_defs_used.has(def_id):
			object_defs_used.append(def_id)


func _mark_all_boundary_cells_covered() -> void:
	for key in boundary_cells.keys():
		boundary_cells[key]["covered"] = true


func _select_families(families: Array, max_families: int) -> Array:
	var selected := []
	var count := clampi(max_families, 1, families.size())
	for index in range(count):
		selected.append(families[index])
	return selected


func _sorted_boundary_cells() -> Array:
	var cells := []
	for key in boundary_cells.keys():
		cells.append(boundary_cells[key])
	cells.sort_custom(func(a, b):
		if int(a.get("y", 0)) == int(b.get("y", 0)):
			return int(a.get("x", 0)) < int(b.get("x", 0))
		return int(a.get("y", 0)) < int(b.get("y", 0))
	)
	return cells


func _mark_rect_cells(rect: Rect2, target: Dictionary) -> void:
	var min_x := int(floor(rect.position.x / float(cell_size)))
	var min_y := int(floor(rect.position.y / float(cell_size)))
	var max_x := int(floor(rect.end.x / float(cell_size)))
	var max_y := int(floor(rect.end.y / float(cell_size)))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if x < 0 or y < 0:
				continue
			target[_cell_key(Vector2i(x, y))] = {"x": x, "y": y}


func _cell_payload(cells: Dictionary) -> Array:
	var payload := []
	var keys := cells.keys()
	keys.sort()
	for key in keys:
		var cell: Dictionary = cells[key]
		payload.append({"x": int(cell.get("x", 0)), "y": int(cell.get("y", 0))})
	return payload


func _boundary_cell_payload() -> Array:
	var payload := []
	var keys := boundary_cells.keys()
	keys.sort()
	for key in keys:
		var cell: Dictionary = boundary_cells[key]
		payload.append({
			"x": int(cell.get("x", 0)),
			"y": int(cell.get("y", 0)),
			"edges": Array(cell.get("edges", [])).duplicate(),
			"covered": bool(cell.get("covered", false)),
		})
	return payload


func _cell_center(x: int, y: int) -> Vector2:
	return Vector2((float(x) + 0.5) * float(cell_size), (float(y) + 0.5) * float(cell_size))


func _boundary_visual_positions(cell: Dictionary, horizontal_count: int, vertical_count: int, corner_count: int) -> Array:
	var x := int(cell.get("x", 0))
	var y := int(cell.get("y", 0))
	var origin := Vector2(float(x) * float(cell_size), float(y) * float(cell_size))
	var edges: Array = cell.get("edges", [])
	var horizontal := edges.has("north") or edges.has("south")
	var vertical := edges.has("west") or edges.has("east")
	var positions := []
	if horizontal and vertical:
		var anchor := Vector2(0.5, 0.5)
		if edges.has("west"):
			anchor.x = 0.72
		elif edges.has("east"):
			anchor.x = 0.28
		if edges.has("north"):
			anchor.y = 0.72
		elif edges.has("south"):
			anchor.y = 0.28
		var horizontal_dir := -1.0 if anchor.x > 0.5 else 1.0
		var vertical_dir := -1.0 if anchor.y > 0.5 else 1.0
		var points := [
			anchor,
			anchor + Vector2(horizontal_dir * 0.28, 0.0),
			anchor + Vector2(0.0, vertical_dir * 0.28),
			anchor + Vector2(horizontal_dir * 0.18, vertical_dir * 0.18),
			anchor + Vector2(horizontal_dir * 0.38, 0.0),
			anchor + Vector2(0.0, vertical_dir * 0.38),
		]
		for visual_index in range(corner_count):
			var point: Vector2 = points[visual_index % points.size()]
			positions.append(origin + Vector2(float(cell_size) * clampf(point.x, 0.18, 0.82), float(cell_size) * clampf(point.y, 0.18, 0.82)))
		return positions
	var use_horizontal := horizontal or not vertical
	var line_axis := 0.5
	if edges.has("north") or edges.has("west"):
		line_axis = 0.72
	elif edges.has("south") or edges.has("east"):
		line_axis = 0.28
	var count := horizontal_count if use_horizontal else vertical_count
	for visual_index in range(count):
		var t := (float(visual_index) + 0.5) / float(count)
		if use_horizontal:
			positions.append(origin + Vector2(float(cell_size) * t, float(cell_size) * line_axis))
		else:
			positions.append(origin + Vector2(float(cell_size) * line_axis, float(cell_size) * t))
	return positions


func _cell_key(coords: Vector2i) -> String:
	return "%d,%d" % [coords.x, coords.y]


func _coords_from_key(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


func _vector2_from_dict(value) -> Vector2:
	if not (value is Dictionary):
		return Vector2.ZERO
	var data: Dictionary = value
	return Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))


func _deterministic_range(seed: int, index: int, min_value: int, max_value: int) -> int:
	if max_value <= min_value:
		return max(1, min_value)
	var span := max_value - min_value + 1
	return min_value + abs(seed + index * 31) % span
