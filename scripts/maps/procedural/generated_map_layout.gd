extends RefCounted
class_name GeneratedMapLayout

var seed := 0
var map_id := ""
var map_name := ""
var map_size := Vector2.ZERO
var map_offset := Vector2.ZERO

var zones: Array = []
var anchors: Array = []
var route_connections: Array = []
var corridors: Array = []
var map_objects: Array = []
var spawn_groups: Array = []
var boundary_visuals: Array = []
var blockers: Array = []


func setup(p_seed: int, p_map_id: String, p_map_name: String, p_map_size: Vector2, p_map_offset: Vector2 = Vector2.ZERO) -> void:
	seed = p_seed
	map_id = p_map_id
	map_name = p_map_name
	map_size = p_map_size
	map_offset = p_map_offset


func add_zone(zone_id: String, zone_type: String, template_id: String, rect: Rect2, label: String = "") -> Dictionary:
	var zone := {
		"id": zone_id,
		"type": zone_type,
		"template_id": template_id,
		"rect": rect,
		"anchors": [],
		"label": label if not label.is_empty() else zone_type,
	}
	zones.append(zone)
	return zone


func add_anchor(anchor_id: String, anchor_type: String, position: Vector2, required: bool, zone_id: String) -> Dictionary:
	var anchor := {
		"id": anchor_id,
		"type": anchor_type,
		"position": position,
		"required": required,
		"zone_id": zone_id,
	}
	anchors.append(anchor)
	var zone := find_zone(zone_id)
	if not zone.is_empty():
		zone["anchors"].append(anchor_id)
	return anchor


func add_route_connection(connection_id: String, from_zone_id: String, to_zone_id: String, kind: String, bend: String, corridor_ids: Array) -> Dictionary:
	var connection := {
		"id": connection_id,
		"from": from_zone_id,
		"to": to_zone_id,
		"kind": kind,
		"bend": bend,
		"corridor_ids": corridor_ids.duplicate(),
	}
	route_connections.append(connection)
	return connection


func add_corridor(corridor_id: String, rect: Rect2, connection_id: String) -> Dictionary:
	var corridor := {
		"id": corridor_id,
		"rect": rect,
		"connection_id": connection_id,
	}
	corridors.append(corridor)
	return corridor


func add_map_object(object_id: String, object_type: String, zone_id: String, position: Vector2) -> Dictionary:
	var map_object := {
		"id": object_id,
		"type": object_type,
		"zone_id": zone_id,
		"position": position,
	}
	map_objects.append(map_object)
	return map_object


func add_spawn_group(group_id: String, zone_id: String, spawn_type: String, count: int, budget: int) -> Dictionary:
	var spawn_group := {
		"id": group_id,
		"zone_id": zone_id,
		"type": spawn_type,
		"count": count,
		"budget": budget,
	}
	spawn_groups.append(spawn_group)
	return spawn_group


func add_boundary_pair(source: String, visual_rect: Rect2, blocker_rect: Rect2) -> void:
	var visual_id := "boundary_visual_%s" % source
	var blocker_id := "blocker_%s" % source
	boundary_visuals.append({
		"id": visual_id,
		"rect": visual_rect,
		"source": source,
		"blocker_id": blocker_id,
	})
	blockers.append({
		"id": blocker_id,
		"rect": blocker_rect,
		"source": source,
		"visual_id": visual_id,
	})


func find_zone(zone_id: String) -> Dictionary:
	for zone in zones:
		if str(zone.get("id", "")) == zone_id:
			return zone
	return {}


func find_anchor(anchor_id: String) -> Dictionary:
	for anchor in anchors:
		if str(anchor.get("id", "")) == anchor_id:
			return anchor
	return {}


func find_anchor_by_type(anchor_type: String) -> Dictionary:
	for anchor in anchors:
		if str(anchor.get("type", "")) == anchor_type:
			return anchor
	return {}


func find_corridor(corridor_id: String) -> Dictionary:
	for corridor in corridors:
		if str(corridor.get("id", "")) == corridor_id:
			return corridor
	return {}


func find_boundary_visual(visual_id: String) -> Dictionary:
	for visual in boundary_visuals:
		if str(visual.get("id", "")) == visual_id:
			return visual
	return {}


func find_blocker(blocker_id: String) -> Dictionary:
	for blocker in blockers:
		if str(blocker.get("id", "")) == blocker_id:
			return blocker
	return {}


func get_main_path_zone_ids() -> Array:
	var ids := []
	if zones.is_empty():
		return ids
	ids.append(str(zones[0].get("id", "")))
	for connection in route_connections:
		if str(connection.get("kind", "")) == "main":
			var to_id := str(connection.get("to", ""))
			if not ids.has(to_id):
				ids.append(to_id)
	return ids


func to_payload() -> Dictionary:
	return {
		"seed": seed,
		"map_id": map_id,
		"map_name": map_name,
		"offset": _vector_to_payload(map_offset),
		"size": _vector_to_payload(map_size),
		"zones": _zones_payload(),
		"route_connections": _route_connections_payload(),
		"corridors": _corridors_payload(),
		"anchors": _anchors_payload(),
		"objects": _map_objects_payload(),
		"spawn_groups": _spawn_groups_payload(),
		"boundary_visuals": _boundary_visuals_payload(),
		"blockers": _blockers_payload(),
	}


func _zones_payload() -> Array:
	var payload := []
	for zone in zones:
		var zone_anchors := []
		for anchor_id in zone.get("anchors", []):
			var anchor := find_anchor(str(anchor_id))
			if not anchor.is_empty():
				zone_anchors.append(_anchor_to_payload(anchor))
		payload.append({
			"id": str(zone.get("id", "")),
			"type": str(zone.get("type", "")),
			"template_id": str(zone.get("template_id", "")),
			"label": str(zone.get("label", "")),
			"rect": _rect_to_payload(zone.get("rect", Rect2())),
			"anchors": zone_anchors,
		})
	return payload


func _route_connections_payload() -> Array:
	var payload := []
	for connection in route_connections:
		payload.append({
			"id": str(connection.get("id", "")),
			"from": str(connection.get("from", "")),
			"to": str(connection.get("to", "")),
			"kind": str(connection.get("kind", "")),
			"bend": str(connection.get("bend", "")),
			"corridor_ids": Array(connection.get("corridor_ids", [])).duplicate(),
		})
	return payload


func _corridors_payload() -> Array:
	var payload := []
	for corridor in corridors:
		payload.append({
			"id": str(corridor.get("id", "")),
			"rect": _rect_to_payload(corridor.get("rect", Rect2())),
			"connection_id": str(corridor.get("connection_id", "")),
		})
	return payload


func _anchors_payload() -> Array:
	var payload := []
	for anchor in anchors:
		payload.append(_anchor_to_payload(anchor))
	return payload


func _map_objects_payload() -> Array:
	var payload := []
	for map_object in map_objects:
		payload.append({
			"id": str(map_object.get("id", "")),
			"type": str(map_object.get("type", "")),
			"zone_id": str(map_object.get("zone_id", "")),
			"position": _vector_to_payload(map_object.get("position", Vector2.ZERO)),
		})
	return payload


func _spawn_groups_payload() -> Array:
	var payload := []
	for spawn_group in spawn_groups:
		payload.append({
			"id": str(spawn_group.get("id", "")),
			"zone_id": str(spawn_group.get("zone_id", "")),
			"type": str(spawn_group.get("type", "")),
			"count": int(spawn_group.get("count", 0)),
			"budget": int(spawn_group.get("budget", 0)),
		})
	return payload


func _boundary_visuals_payload() -> Array:
	var payload := []
	for visual in boundary_visuals:
		payload.append({
			"id": str(visual.get("id", "")),
			"rect": _rect_to_payload(visual.get("rect", Rect2())),
			"source": str(visual.get("source", "")),
			"blocker_id": str(visual.get("blocker_id", "")),
		})
	return payload


func _blockers_payload() -> Array:
	var payload := []
	for blocker in blockers:
		payload.append({
			"id": str(blocker.get("id", "")),
			"rect": _rect_to_payload(blocker.get("rect", Rect2())),
			"source": str(blocker.get("source", "")),
			"visual_id": str(blocker.get("visual_id", "")),
		})
	return payload


func _anchor_to_payload(anchor: Dictionary) -> Dictionary:
	return {
		"id": str(anchor.get("id", "")),
		"type": str(anchor.get("type", "")),
		"position": _vector_to_payload(anchor.get("position", Vector2.ZERO)),
		"required": bool(anchor.get("required", false)),
		"zone_id": str(anchor.get("zone_id", "")),
	}


func _vector_to_payload(value: Vector2) -> Dictionary:
	return {
		"x": _stable_float(value.x),
		"y": _stable_float(value.y),
	}


func _rect_to_payload(value: Rect2) -> Dictionary:
	return {
		"x": _stable_float(value.position.x),
		"y": _stable_float(value.position.y),
		"w": _stable_float(value.size.x),
		"h": _stable_float(value.size.y),
	}


func _stable_float(value: float) -> float:
	return round(value * 100.0) / 100.0
