extends RefCounted

const COLLISION_LAYERS := preload("res://scripts/physics/collision_layers.gd")

const READABLE_BOUNDARY_THICKNESS := 172.0
const DEFAULT_VISUAL_SIZE := Vector2(64, 64)
const PROP_COLLISION_PROFILES := {
	"dead_tree": {"width": 0.42, "height": 0.30, "bottom": 0.92},
	"rock": {"width": 0.76, "height": 0.44, "bottom": 0.84},
	"broken_fence": {"width": 0.88, "height": 0.34, "bottom": 0.78},
	"camp_gate": {"width": 0.82, "height": 0.30, "bottom": 0.80},
	"route_sign": {"width": 0.34, "height": 0.32, "bottom": 0.92},
	"broken_cart": {"width": 0.74, "height": 0.46, "bottom": 0.84},
	"shrine": {"width": 0.62, "height": 0.42, "bottom": 0.86},
	"dungeon_entrance": {"width": 0.82, "height": 0.38, "bottom": 0.86},
	"corrupted_root": {"width": 0.84, "height": 0.36, "bottom": 0.82},
	"soft_gate_sign": {"width": 0.34, "height": 0.32, "bottom": 0.92},
	"soft_gate_roots": {"width": 0.84, "height": 0.36, "bottom": 0.82},
}


static func apply_player_body(player: CollisionObject2D) -> void:
	if player == null:
		return
	player.collision_layer = COLLISION_LAYERS.PLAYER
	player.collision_mask = COLLISION_LAYERS.WORLD


static func apply_enemy_body(enemy: CollisionObject2D) -> void:
	if enemy == null:
		return
	enemy.collision_layer = COLLISION_LAYERS.ENEMY
	enemy.collision_mask = COLLISION_LAYERS.WORLD


static func apply_loot_area(loot: CollisionObject2D) -> void:
	if loot == null:
		return
	loot.collision_layer = COLLISION_LAYERS.LOOT
	loot.collision_mask = COLLISION_LAYERS.PLAYER


static func add_blocker_rect(parent: Node, blocker_name: String, rect: Rect2, source: String = "") -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = blocker_name
	body.collision_layer = COLLISION_LAYERS.WORLD
	body.collision_mask = 0
	body.position = rect.position + rect.size * 0.5
	if not source.is_empty():
		body.set_meta("source", source)

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	body.add_child(shape)

	parent.add_child(body)
	return body


static func add_collision_shape_from_definition(parent: Node, blocker_name: String, definition_id: String, definition: Dictionary, foot_position: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = blocker_name
	body.collision_layer = COLLISION_LAYERS.WORLD
	body.collision_mask = 0
	body.position = foot_position
	body.set_meta("object_def", definition_id)
	body.set_meta("source", "object_definition")

	var collision: Dictionary = definition.get("collision", {})
	var shape_node := CollisionShape2D.new()
	shape_node.position = _vector2_from_dict(collision.get("offset", {}), Vector2.ZERO)
	match str(collision.get("shape", "")):
		"rect":
			var rectangle := RectangleShape2D.new()
			rectangle.size = _size_from_dict(collision.get("size", {}), Vector2(32, 24))
			shape_node.shape = rectangle
		"circle":
			var circle := CircleShape2D.new()
			circle.radius = float(collision.get("radius", 16.0))
			shape_node.shape = circle
		"capsule":
			var capsule := CapsuleShape2D.new()
			capsule.radius = float(collision.get("radius", 12.0))
			capsule.height = float(collision.get("height", 36.0))
			if str(collision.get("orientation", "vertical")) == "horizontal":
				shape_node.rotation = PI * 0.5
			shape_node.shape = capsule
		_:
			var fallback := RectangleShape2D.new()
			fallback.size = Vector2(32, 24)
			shape_node.shape = fallback
	body.add_child(shape_node)
	parent.add_child(body)
	return body


static func readable_boundary_specs(bounds: Rect2, thickness: float = READABLE_BOUNDARY_THICKNESS) -> Array:
	return [
		{"name": "ReadableBoundaryTop", "rect": Rect2(bounds.position.x, bounds.position.y, bounds.size.x, thickness), "source": "readable_boundary"},
		{"name": "ReadableBoundaryBottom", "rect": Rect2(bounds.position.x, bounds.end.y - thickness, bounds.size.x, thickness), "source": "readable_boundary"},
		{"name": "ReadableBoundaryLeft", "rect": Rect2(bounds.position.x, bounds.position.y, thickness, bounds.size.y), "source": "readable_boundary"},
		{"name": "ReadableBoundaryRight", "rect": Rect2(bounds.end.x - thickness, bounds.position.y, thickness, bounds.size.y), "source": "readable_boundary"},
	]


static func prop_collision_rects(
	texture: Texture2D,
	prop_position: Vector2,
	prop_scale: float,
	asset_key: String,
	blocker_source: String,
	fallback_ratio: float
) -> Dictionary:
	var visual_size := DEFAULT_VISUAL_SIZE * prop_scale
	if texture != null:
		visual_size = texture.get_size() * prop_scale
	var visual_rect := Rect2(prop_position - visual_size * 0.5, visual_size)
	var profile := prop_collision_profile(asset_key, blocker_source, fallback_ratio)
	var blocker_size := Vector2(
		maxf(18.0, visual_size.x * float(profile.get("width", fallback_ratio))),
		maxf(16.0, visual_size.y * float(profile.get("height", minf(fallback_ratio, 0.55))))
	)
	var blocker_bottom_y := visual_rect.position.y + visual_rect.size.y * clampf(float(profile.get("bottom", 0.84)), 0.55, 1.0)
	var blocker_rect := Rect2(Vector2(prop_position.x - blocker_size.x * 0.5, blocker_bottom_y - blocker_size.y), blocker_size)
	return {"visual_rect": visual_rect, "blocker_rect": blocker_rect}


static func prop_collision_profile(asset_key: String, blocker_source: String, fallback_ratio: float) -> Dictionary:
	var profile_key := blocker_source
	if blocker_source == "boundary_prop":
		if asset_key.begins_with("dead_tree"):
			profile_key = "dead_tree"
		elif asset_key.begins_with("rock"):
			profile_key = "rock"
		elif asset_key.begins_with("broken_fence"):
			profile_key = "broken_fence"
		elif asset_key.begins_with("corrupted_root"):
			profile_key = "corrupted_root"
	var fallback := clampf(fallback_ratio, 0.45, 1.0)
	return PROP_COLLISION_PROFILES.get(profile_key, {"width": fallback, "height": minf(fallback, 0.55), "bottom": 0.84})


static func _vector2_from_dict(value, fallback: Vector2) -> Vector2:
	if not (value is Dictionary):
		return fallback
	var data: Dictionary = value
	return Vector2(float(data.get("x", fallback.x)), float(data.get("y", fallback.y)))


static func _size_from_dict(value, fallback: Vector2) -> Vector2:
	if not (value is Dictionary):
		return fallback
	var data: Dictionary = value
	return Vector2(float(data.get("w", fallback.x)), float(data.get("h", fallback.y)))
