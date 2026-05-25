extends Node2D

const ATLAS_PATH := "res://assets/sprites/terrain/pixellab_dark_arpg_wang_candidates/wang16_dirt_to_grass_candidate_02.png"
const TILE_SIZE := Vector2i(32, 32)
const MAP_SIZE := Vector2i(72, 44)
const TERRAIN_SET := 0
const TERRAIN_GRASS := 0
const TERRAIN_DIRT := 1

const MASK_TO_ATLAS_COORDS := [
	Vector2i(2, 1), # 0: no dirt corners
	Vector2i(1, 1), # 1: top-left
	Vector2i(2, 0), # 2: top-right
	Vector2i(3, 0), # 3: top edge
	Vector2i(2, 2), # 4: bottom-left
	Vector2i(1, 0), # 5: left edge
	Vector2i(0, 1), # 6: top-right + bottom-left
	Vector2i(1, 3), # 7: all except bottom-right
	Vector2i(3, 1), # 8: bottom-right
	Vector2i(2, 3), # 9: top-left + bottom-right
	Vector2i(3, 2), # 10: right edge
	Vector2i(0, 0), # 11: all except bottom-left
	Vector2i(1, 2), # 12: bottom edge
	Vector2i(0, 2), # 13: all except top-right
	Vector2i(3, 3), # 14: all except top-left
	Vector2i(0, 3), # 15: full dirt
]

@onready var terrain_layer: TileMapLayer = $NativeTerrainTileMapLayer
@onready var marker_layer: Node2D = $MarkerLayer
@onready var camera: Camera2D = $Camera2D

var _dirt_cells: Array[Vector2i] = []
var _all_cells: Array[Vector2i] = []
var _source_id := -1
var _native_connect_used := false
var _path_points := [
	Vector2(4.0, 35.0),
	Vector2(13.0, 30.5),
	Vector2(24.0, 27.0),
	Vector2(36.0, 21.0),
	Vector2(50.0, 15.0),
	Vector2(67.0, 8.0),
]


func _ready() -> void:
	name = "TerrainNativeTerrainTest"
	_build_native_terrain_tileset()
	_build_cells()
	terrain_layer.set_cells_terrain_connect(_all_cells, TERRAIN_SET, TERRAIN_GRASS, false)
	terrain_layer.set_cells_terrain_connect(_dirt_cells, TERRAIN_SET, TERRAIN_DIRT, false)
	_native_connect_used = true
	_add_markers()
	_setup_camera()


func get_task32_native_terrain_summary() -> Dictionary:
	var atlas_counts := {}
	for cell in terrain_layer.get_used_cells():
		var atlas := terrain_layer.get_cell_atlas_coords(cell)
		atlas_counts[str(atlas)] = int(atlas_counts.get(str(atlas), 0)) + 1
	return {
		"source": "Godot native TileSet terrain set_cells_terrain_connect prototype",
		"atlas": ATLAS_PATH,
		"tile_size": TILE_SIZE,
		"map_size": MAP_SIZE,
		"terrain_mode": "TERRAIN_MODE_MATCH_CORNERS",
		"native_connect_used": _native_connect_used,
		"all_cells": _all_cells.size(),
		"dirt_cells": _dirt_cells.size(),
		"used_cells": terrain_layer.get_used_cells().size(),
		"distinct_atlas_coords": atlas_counts.size(),
		"atlas_counts": atlas_counts,
	}


func _build_native_terrain_tileset() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = TILE_SIZE
	tile_set.add_terrain_set(TERRAIN_SET)
	tile_set.set_terrain_set_mode(TERRAIN_SET, TileSet.TERRAIN_MODE_MATCH_CORNERS)
	tile_set.add_terrain(TERRAIN_SET, TERRAIN_GRASS)
	tile_set.set_terrain_name(TERRAIN_SET, TERRAIN_GRASS, "Grass")
	tile_set.set_terrain_color(TERRAIN_SET, TERRAIN_GRASS, Color(0.1, 0.35, 0.08, 1.0))
	tile_set.add_terrain(TERRAIN_SET, TERRAIN_DIRT)
	tile_set.set_terrain_name(TERRAIN_SET, TERRAIN_DIRT, "Dirt")
	tile_set.set_terrain_color(TERRAIN_SET, TERRAIN_DIRT, Color(0.55, 0.36, 0.18, 1.0))

	var source := TileSetAtlasSource.new()
	source.texture = load(ATLAS_PATH)
	source.texture_region_size = TILE_SIZE
	for y in range(4):
		for x in range(4):
			source.create_tile(Vector2i(x, y))
	_source_id = tile_set.add_source(source)

	for mask in range(MASK_TO_ATLAS_COORDS.size()):
		var tile_data := source.get_tile_data(MASK_TO_ATLAS_COORDS[mask], 0)
		tile_data.set_terrain_set(TERRAIN_SET)
		tile_data.set_terrain(TERRAIN_DIRT if mask != 0 else TERRAIN_GRASS)
		_set_corner_terrain(tile_data, TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, (mask & 1) != 0)
		_set_corner_terrain(tile_data, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER, (mask & 2) != 0)
		_set_corner_terrain(tile_data, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, (mask & 4) != 0)
		_set_corner_terrain(tile_data, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, (mask & 8) != 0)

	terrain_layer.tile_set = tile_set
	terrain_layer.rendering_quadrant_size = 256


func _set_corner_terrain(tile_data: TileData, peering_bit: TileSet.CellNeighbor, is_dirt: bool) -> void:
	if tile_data.is_valid_terrain_peering_bit(peering_bit):
		tile_data.set_terrain_peering_bit(peering_bit, TERRAIN_DIRT if is_dirt else TERRAIN_GRASS)


func _build_cells() -> void:
	_all_cells.clear()
	_dirt_cells.clear()
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var cell := Vector2i(x, y)
			_all_cells.append(cell)
			if _is_dirt_cell(Vector2(x, y)):
				_dirt_cells.append(cell)


func _is_dirt_cell(point: Vector2) -> bool:
	if _distance_to_polyline(point, _path_points) <= 2.4:
		return true
	if _in_ellipse(point, Vector2(28.0, 31.0), Vector2(8.0, 4.5)):
		return true
	if _in_ellipse(point, Vector2(54.0, 23.0), Vector2(5.0, 3.6)):
		return true
	return false


func _add_markers() -> void:
	for i in range(10):
		var marker := ColorRect.new()
		marker.name = "NativeTerrainMarker%02d" % i
		marker.size = Vector2(TILE_SIZE) * Vector2(0.4, 0.4)
		marker.position = Vector2(6 + i * 6, 10 + int(abs(sin(float(i) * 1.7)) * 24.0)) * Vector2(TILE_SIZE)
		marker.color = Color(0.0, 0.0, 0.0, 0.18)
		marker_layer.add_child(marker)


func _setup_camera() -> void:
	camera.position = Vector2(MAP_SIZE * TILE_SIZE) * 0.5
	camera.zoom = Vector2(0.45, 0.45)
	camera.enabled = true


func _in_ellipse(point: Vector2, center: Vector2, radius: Vector2) -> bool:
	var noise := sin(point.x * 0.73 + point.y * 0.21) * 0.16
	var normalized := Vector2((point.x - center.x) / radius.x, (point.y - center.y) / radius.y)
	return normalized.length_squared() <= 1.0 + noise


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
