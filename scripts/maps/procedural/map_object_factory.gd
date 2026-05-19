extends RefCounted
class_name MapObjectFactory

const OUTDOOR_COLLISION := preload("res://scripts/physics/outdoor_collision.gd")

var catalog: MapObjectDefinitionCatalog
var props_root: Node2D
var blocker_root: Node
var placed_objects := []
var object_defs_used := []
var warnings := []


func setup(p_catalog: MapObjectDefinitionCatalog, p_props_root: Node2D, p_blocker_root: Node) -> void:
	catalog = p_catalog
	props_root = p_props_root
	blocker_root = p_blocker_root


func place_object(object_id: String, definition_id: String, foot_position: Vector2, extra_tags: Array = []) -> Dictionary:
	if catalog == null or not catalog.has_definition(definition_id):
		warnings.append("missing object definition: %s" % definition_id)
		return _place_fallback(object_id, definition_id, foot_position, extra_tags)
	var definition := catalog.get_definition(definition_id)
	var object_root := Node2D.new()
	object_root.name = object_id
	object_root.position = foot_position
	object_root.y_sort_enabled = true
	object_root.set_meta("object_def", definition_id)
	object_root.set_meta("sort_y", _collision_sort_y(foot_position, definition))
	props_root.add_child(object_root)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = load(str(definition.get("texture", ""))) as Texture2D
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(float(definition.get("scale", 1.0)), float(definition.get("scale", 1.0)))
	sprite.position = _vector2_from_dict(definition.get("sprite_offset", {}), Vector2.ZERO)
	object_root.add_child(sprite)

	var blocker_id := ""
	if bool(definition.get("blocks_player", false)):
		blocker_id = "%sBlocker" % object_id
		OUTDOOR_COLLISION.add_collision_shape_from_definition(blocker_root, blocker_id, definition_id, definition, foot_position)

	if not object_defs_used.has(definition_id):
		object_defs_used.append(definition_id)
	var payload := _object_payload(object_id, definition_id, foot_position, definition, sprite, blocker_id, extra_tags, false)
	placed_objects.append(payload)
	return payload


func get_payload() -> Array:
	return placed_objects.duplicate(true)


func get_object_defs_used() -> Array:
	return object_defs_used.duplicate()


func get_warnings() -> Array:
	return warnings.duplicate()


func _place_fallback(object_id: String, definition_id: String, foot_position: Vector2, extra_tags: Array) -> Dictionary:
	var object_root := Node2D.new()
	object_root.name = object_id
	object_root.position = foot_position
	var fallback_definition := {
		"scale": 1.0,
		"sprite_offset": {"x": 0, "y": -24},
		"y_sort_origin": {"x": 0, "y": 0},
		"collision": {"shape": "rect", "offset": {"x": 0, "y": -12}, "size": {"w": 32, "h": 24}},
		"blocks_player": true,
		"tags": ["fallback"],
	}
	object_root.set_meta("sort_y", _collision_sort_y(foot_position, fallback_definition))
	props_root.add_child(object_root)
	var blocker_id := "%sBlocker" % object_id
	OUTDOOR_COLLISION.add_collision_shape_from_definition(blocker_root, blocker_id, definition_id, fallback_definition, foot_position)
	var payload := _object_payload(object_id, definition_id, foot_position, fallback_definition, null, blocker_id, extra_tags, true)
	placed_objects.append(payload)
	return payload


func _object_payload(
	object_id: String,
	definition_id: String,
	foot_position: Vector2,
	definition: Dictionary,
	sprite: Sprite2D,
	blocker_id: String,
	extra_tags: Array,
	uses_fallback: bool
) -> Dictionary:
	var tags := Array(definition.get("tags", [])).duplicate()
	for tag in extra_tags:
		if not tags.has(tag):
			tags.append(tag)
	var visual_rect := _visual_rect(foot_position, definition, sprite)
	return {
		"id": object_id,
		"object_def": definition_id,
		"position": _vector_payload(foot_position),
		"sprite_offset": definition.get("sprite_offset", {}),
		"y_sort_origin": definition.get("y_sort_origin", {}),
		"collision_shape": definition.get("collision", {}),
		"sort_y": round(_collision_sort_y(foot_position, definition) * 100.0) / 100.0,
		"visual_rect": _rect_payload(visual_rect),
		"blocker_id": blocker_id,
		"blocks_player": bool(definition.get("blocks_player", false)),
		"tags": tags,
		"uses_fallback": uses_fallback,
	}


func _visual_rect(foot_position: Vector2, definition: Dictionary, sprite: Sprite2D) -> Rect2:
	var texture_size := Vector2(64, 64)
	if sprite != null and sprite.texture != null:
		texture_size = sprite.texture.get_size()
	var scale := float(definition.get("scale", 1.0))
	var sprite_offset := _vector2_from_dict(definition.get("sprite_offset", {}), Vector2.ZERO)
	var size := texture_size * scale
	var center := foot_position + sprite_offset
	return Rect2(center - size * 0.5, size)


func _collision_sort_y(foot_position: Vector2, definition: Dictionary) -> float:
	var collision: Dictionary = definition.get("collision", {})
	var offset := _vector2_from_dict(collision.get("offset", {}), Vector2.ZERO)
	var center := foot_position + offset
	match str(collision.get("shape", "")):
		"rect":
			var size := _size_from_dict(collision.get("size", {}), Vector2(32, 24))
			return center.y + size.y * 0.5
		"circle":
			return center.y + float(collision.get("radius", 16.0))
		"capsule":
			var radius := float(collision.get("radius", 12.0))
			var height := float(collision.get("height", 36.0))
			if str(collision.get("orientation", "vertical")) == "horizontal":
				return center.y + radius
			return center.y + height * 0.5
	return foot_position.y


func _vector2_from_dict(value, fallback: Vector2) -> Vector2:
	if not (value is Dictionary):
		return fallback
	var data: Dictionary = value
	return Vector2(float(data.get("x", fallback.x)), float(data.get("y", fallback.y)))


func _size_from_dict(value, fallback: Vector2) -> Vector2:
	if not (value is Dictionary):
		return fallback
	var data: Dictionary = value
	return Vector2(float(data.get("w", fallback.x)), float(data.get("h", fallback.y)))


func _vector_payload(value: Vector2) -> Dictionary:
	return {"x": round(value.x * 100.0) / 100.0, "y": round(value.y * 100.0) / 100.0}


func _rect_payload(value: Rect2) -> Dictionary:
	return {
		"x": round(value.position.x * 100.0) / 100.0,
		"y": round(value.position.y * 100.0) / 100.0,
		"w": round(value.size.x * 100.0) / 100.0,
		"h": round(value.size.y * 100.0) / 100.0,
	}
