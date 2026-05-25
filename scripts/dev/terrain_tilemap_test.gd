extends Node2D

const DualGridWang16Script := preload("res://scripts/terrain/dual_grid_wang16.gd")
const TerrainCellFieldScript := preload("res://scripts/terrain/terrain_cell_field.gd")

const TILE_SIZE := Vector2i(16, 16)
const MAP_WIDTH := 78
const MAP_HEIGHT := 48

const WANG16_ATLAS := "res://assets/sprites/terrain/debug/dual_grid_wang16_placeholder_16.png"
const ROCK_PROP := "res://assets/sprites/props/outdoor_01/prop_outdoor01_rock_small_32_a.png"
const ROOT_PROP := "res://assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_roots_64_a.png"
const SIGN_PROP := "res://assets/sprites/props/outdoor_01/prop_outdoor01_signpost_64.png"

const GRASS_LAYER_ID := "grass"
const DIRT_LAYER_ID := "dirt"
const ROAD_LAYER_ID := "road"

@onready var ground_layer: TileMapLayer = $GroundBaseTileMapLayer
@onready var road_layer: TileMapLayer = $DirtRoadTileMapLayer
@onready var overlay_layer: TileMapLayer = $TerrainOverlayTileMapLayer
@onready var decal_layer: Node2D = $DecalPreviewLayer
@onready var prop_layer: Node2D = $PropPreviewLayer

var _ground_source_id := -1
var _overlay_source_id := -1
var _dual_grid = DualGridWang16Script.new()
var _field = TerrainCellFieldScript.new(Vector2i(MAP_WIDTH, MAP_HEIGHT))
var _dual_grid_payload := {}
var _road_points := [
	Vector2(4.0, 38.0),
	Vector2(13.0, 33.0),
	Vector2(24.0, 30.0),
	Vector2(35.0, 25.0),
	Vector2(47.0, 21.0),
	Vector2(58.0, 17.0),
	Vector2(73.0, 10.0),
]


func _ready() -> void:
	name = "TerrainTilemapTest"
	_build_tile_sets()
	_build_world_field()
	_paint_dual_grid()
	_add_road_preview()
	_add_decal_preview()
	_add_prop_preview()
	_add_camera()


func get_task32_tilemap_summary() -> Dictionary:
	return {
		"source": "dual-grid Wang16 algorithm prototype; atlas placeholder until user supplies final art",
		"format": "dual-grid Wang16, 4-bit corner mask, display layer offset by half a tile",
		"atlas": WANG16_ATLAS,
		"map_size": Vector2i(MAP_WIDTH, MAP_HEIGHT),
		"tile_size": TILE_SIZE,
		"grass_world_cells": _field.get_cell_count(GRASS_LAYER_ID),
		"dirt_world_cells": _field.get_cell_count(DIRT_LAYER_ID),
		"road_world_cells": _field.get_cell_count(ROAD_LAYER_ID),
		"display_tiles": int(_dual_grid_payload.get("painted", 0)),
		"display_transition_tiles": int(_dual_grid_payload.get("transition", 0)),
		"display_full_tiles": int(_dual_grid_payload.get("full", 0)),
		"road_ribbon_children": _count_named_children(road_layer, "DirtRoadRibbon"),
		"decal_count": decal_layer.get_child_count(),
		"prop_count": prop_layer.get_child_count(),
	}


func _build_tile_sets() -> void:
	_ground_source_id = _dual_grid.assign_atlas_tile_set(ground_layer, WANG16_ATLAS, TILE_SIZE)
	_overlay_source_id = _dual_grid.assign_atlas_tile_set(overlay_layer, WANG16_ATLAS, TILE_SIZE)
	ground_layer.modulate = Color(0.62, 0.48, 0.34, 1.0)
	overlay_layer.modulate = Color(0.72, 0.84, 0.56, 1.0)


func _build_world_field() -> void:
	_field.clear()
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var cell := Vector2i(x, y)
			var p := Vector2(x, y)
			var road_distance := _distance_to_polyline(p, _road_points)
			var road_width := 2.05 + 0.45 * sin(float(x) * 0.47 + float(y) * 0.29)
			var in_road := road_distance <= road_width
			var in_clearing := _in_ellipse(p, Vector2(30.0, 31.0), Vector2(8.5, 5.0))
			var in_dirt_patch := _in_ellipse(p, Vector2(55.0, 18.0), Vector2(5.5, 3.8))
			var is_dirt := in_road or in_clearing or in_dirt_patch
			if is_dirt:
				_field.add_cell(DIRT_LAYER_ID, cell)
				if in_road:
					_field.add_cell(ROAD_LAYER_ID, cell)
			else:
				_field.add_cell(GRASS_LAYER_ID, cell)


func _paint_dual_grid() -> void:
	_dual_grid.paint_lower_base(ground_layer, _ground_source_id, Vector2i(MAP_WIDTH, MAP_HEIGHT), 0)
	_dual_grid_payload = _dual_grid.paint_display_from_world(
		overlay_layer,
		_overlay_source_id,
		_field,
		GRASS_LAYER_ID,
		Vector2i(MAP_WIDTH, MAP_HEIGHT),
		TILE_SIZE,
		true
	)


func _add_road_preview() -> void:
	var pixel_points := []
	for point in _road_points:
		pixel_points.append(point * Vector2(TILE_SIZE) + Vector2(TILE_SIZE) * 0.5)
	var soft_edge := Line2D.new()
	soft_edge.name = "DirtRoadRibbonSoftEdge"
	soft_edge.points = PackedVector2Array(pixel_points)
	soft_edge.width = 44.0
	soft_edge.joint_mode = Line2D.LINE_JOINT_ROUND
	soft_edge.begin_cap_mode = Line2D.LINE_CAP_ROUND
	soft_edge.end_cap_mode = Line2D.LINE_CAP_ROUND
	soft_edge.default_color = Color(0.22, 0.14, 0.08, 0.10)
	road_layer.add_child(soft_edge)
	var wear := Line2D.new()
	wear.name = "DirtRoadRibbonWear"
	wear.points = PackedVector2Array(pixel_points)
	wear.width = 24.0
	wear.joint_mode = Line2D.LINE_JOINT_ROUND
	wear.begin_cap_mode = Line2D.LINE_CAP_ROUND
	wear.end_cap_mode = Line2D.LINE_CAP_ROUND
	wear.default_color = Color(0.42, 0.28, 0.16, 0.16)
	road_layer.add_child(wear)


func _add_decal_preview() -> void:
	var positions := [
		Vector2i(9, 13),
		Vector2i(18, 25),
		Vector2i(28, 34),
		Vector2i(39, 18),
		Vector2i(51, 28),
		Vector2i(62, 11),
		Vector2i(68, 34),
		Vector2i(73, 22),
	]
	for i in range(positions.size()):
		var mark := ColorRect.new()
		mark.name = "DualGridDecal%02d" % i
		mark.size = Vector2(TILE_SIZE) * 0.75
		mark.position = Vector2(positions[i] * TILE_SIZE) + Vector2(TILE_SIZE) * 0.125
		mark.color = Color(0.12, 0.18, 0.08, 0.18)
		decal_layer.add_child(mark)


func _add_prop_preview() -> void:
	_add_prop(ROCK_PROP, Vector2(9.5, 34.0), 0.7)
	_add_prop(ROCK_PROP, Vector2(63.0, 12.5), 0.65)
	_add_prop(ROOT_PROP, Vector2(49.0, 35.0), 0.75)
	_add_prop(SIGN_PROP, Vector2(20.0, 27.0), 0.62)


func _add_prop(texture_path: String, tile_position: Vector2, prop_scale: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(texture_path)
	sprite.position = tile_position * Vector2(TILE_SIZE)
	sprite.scale = Vector2(prop_scale, prop_scale)
	sprite.z_index = int(sprite.position.y)
	prop_layer.add_child(sprite)


func _add_camera() -> void:
	var camera := Camera2D.new()
	camera.name = "PreviewCamera"
	camera.position = Vector2(MAP_WIDTH * TILE_SIZE.x, MAP_HEIGHT * TILE_SIZE.y) * 0.5
	camera.zoom = Vector2(0.82, 0.82)
	camera.enabled = true
	add_child(camera)


func _count_named_children(parent: Node, prefix: String) -> int:
	var count := 0
	for child in parent.get_children():
		if str(child.name).begins_with(prefix):
			count += 1
	return count


func _in_ellipse(point: Vector2, center: Vector2, radius: Vector2) -> bool:
	var normalized := Vector2((point.x - center.x) / radius.x, (point.y - center.y) / radius.y)
	return normalized.length_squared() <= 1.0


func _distance_to_polyline(point: Vector2, points: Array) -> float:
	var best := INF
	for i in range(points.size() - 1):
		best = minf(best, _distance_to_segment(point, points[i], points[i + 1]))
	return best


func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)
