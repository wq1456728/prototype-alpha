extends Node2D

const FILL_COLOR := Color(0.2, 0.75, 1.0, 0.18)
const OUTLINE_COLOR := Color(0.2, 0.85, 1.0, 0.9)
const DISABLED_FILL_COLOR := Color(1.0, 0.35, 0.28, 0.12)
const DISABLED_OUTLINE_COLOR := Color(1.0, 0.35, 0.28, 0.65)
const BOUNDARY_EDGE_FILL_COLOR := Color(0.15, 1.0, 0.35, 0.10)
const BOUNDARY_EDGE_OUTLINE_COLOR := Color(0.15, 1.0, 0.35, 0.55)
const OUTLINE_WIDTH := 2.0


func _ready() -> void:
	z_index = 4096
	top_level = true
	visible = false


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	_draw_collision_shapes(root)


func _draw_collision_shapes(node: Node) -> void:
	for child in node.get_children():
		if child is CollisionShape2D:
			_draw_collision_shape(child as CollisionShape2D)
		_draw_collision_shapes(child)


func _draw_collision_shape(shape_node: CollisionShape2D) -> void:
	if shape_node.shape == null:
		return
	var fill_color := DISABLED_FILL_COLOR if shape_node.disabled else FILL_COLOR
	var outline_color := DISABLED_OUTLINE_COLOR if shape_node.disabled else OUTLINE_COLOR
	var parent := shape_node.get_parent()
	if parent != null and str(parent.get_meta("source", "")) == "boundary_edge":
		fill_color = BOUNDARY_EDGE_FILL_COLOR
		outline_color = BOUNDARY_EDGE_OUTLINE_COLOR
	if shape_node.shape is RectangleShape2D:
		_draw_rectangle(shape_node, shape_node.shape as RectangleShape2D, fill_color, outline_color)
	elif shape_node.shape is CircleShape2D:
		_draw_circle(shape_node, shape_node.shape as CircleShape2D, fill_color, outline_color)
	elif shape_node.shape is CapsuleShape2D:
		_draw_capsule(shape_node, shape_node.shape as CapsuleShape2D, fill_color, outline_color)


func _draw_rectangle(shape_node: CollisionShape2D, rectangle: RectangleShape2D, fill_color: Color, outline_color: Color) -> void:
	var half_size := rectangle.size * 0.5
	var points := PackedVector2Array([
		shape_node.global_transform * Vector2(-half_size.x, -half_size.y),
		shape_node.global_transform * Vector2(half_size.x, -half_size.y),
		shape_node.global_transform * Vector2(half_size.x, half_size.y),
		shape_node.global_transform * Vector2(-half_size.x, half_size.y),
	])
	draw_colored_polygon(points, fill_color)
	var outline := PackedVector2Array(points)
	outline.append(points[0])
	draw_polyline(outline, outline_color, OUTLINE_WIDTH)


func _draw_circle(shape_node: CollisionShape2D, circle: CircleShape2D, fill_color: Color, outline_color: Color) -> void:
	var radius := circle.radius * maxf(absf(shape_node.global_scale.x), absf(shape_node.global_scale.y))
	draw_circle(shape_node.global_position, radius, fill_color)
	draw_arc(shape_node.global_position, radius, 0.0, TAU, 48, outline_color, OUTLINE_WIDTH)


func _draw_capsule(shape_node: CollisionShape2D, capsule: CapsuleShape2D, fill_color: Color, outline_color: Color) -> void:
	var half_height := capsule.height * 0.5
	var radius := capsule.radius
	var straight := maxf(0.0, half_height - radius)
	var points := PackedVector2Array()
	var steps := 16
	for i in range(steps + 1):
		var angle := PI + PI * float(i) / float(steps)
		points.append(shape_node.global_transform * (Vector2(0.0, -straight) + Vector2(cos(angle), sin(angle)) * radius))
	for i in range(steps + 1):
		var angle := PI * float(i) / float(steps)
		points.append(shape_node.global_transform * (Vector2(0.0, straight) + Vector2(cos(angle), sin(angle)) * radius))
	draw_colored_polygon(points, fill_color)
	var outline := PackedVector2Array(points)
	outline.append(points[0])
	draw_polyline(outline, outline_color, OUTLINE_WIDTH)
