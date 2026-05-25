extends RefCounted
class_name DualGridTerrainPainter

const TERRAIN_GRASS := 0
const TERRAIN_DIRT := 1

const FINAL_ATLAS_PATH := "res://assets/sprites/terrain/pixellab_dark_arpg_wang/tileset_dark_grass_dirt_wang16_32.png"
const DEFAULT_DEBUG_ATLAS_PATH := "res://assets/sprites/terrain/debug/dual_grid_wang16_debug_1.png"
const CANDIDATE_07_ATLAS_PATH := "res://assets/sprites/terrain/pixellab_dark_arpg_wang_candidates/wang16_dirt_to_grass_candidate_07.png"
const PLACEHOLDER_ATLAS_PATH := "res://assets/sprites/terrain/debug/dual_grid_wang16_placeholder_16.png"

const BIT_TOP_LEFT := 1
const BIT_TOP_RIGHT := 2
const BIT_BOTTOM_LEFT := 4
const BIT_BOTTOM_RIGHT := 8

const DEBUG_1_MASK_TO_ATLAS_COORDS := [
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

const CANDIDATE_07_MASK_TO_ATLAS_COORDS := [
	Vector2i(0, 3), # 0: no dirt corners
	Vector2i(3, 3), # 1: top-left
	Vector2i(0, 2), # 2: top-right
	Vector2i(1, 2), # 3: top edge
	Vector2i(0, 0), # 4: bottom-left
	Vector2i(3, 2), # 5: left edge
	Vector2i(2, 3), # 6: top-right + bottom-left
	Vector2i(3, 1), # 7: all except bottom-right
	Vector2i(1, 3), # 8: bottom-right
	Vector2i(0, 1), # 9: top-left + bottom-right, approximate in this atlas
	Vector2i(1, 0), # 10: right edge
	Vector2i(2, 2), # 11: all except bottom-left
	Vector2i(3, 0), # 12: bottom edge
	Vector2i(2, 0), # 13: all except top-right
	Vector2i(2, 1), # 14: all except top-left, approximate in this atlas
	Vector2i(2, 1), # 15: full dirt
]

var terrain_grid := {}
var map_size := Vector2i.ZERO
var tile_size := Vector2i(16, 16)
var atlas_path := CANDIDATE_07_ATLAS_PATH

var _display_layer: TileMapLayer
var _source_id := -1
var _last_rebuild_summary := {}
var _mask_mapping := DEBUG_1_MASK_TO_ATLAS_COORDS


func configure(
	display_layer: TileMapLayer,
	initial_map_size: Vector2i,
	preferred_atlas_path: String = CANDIDATE_07_ATLAS_PATH,
	atlas_tile_size: Vector2i = Vector2i(32, 32)
) -> void:
	_display_layer = display_layer
	map_size = initial_map_size
	atlas_path = _resolve_atlas_path(preferred_atlas_path)
	tile_size = atlas_tile_size if atlas_path != PLACEHOLDER_ATLAS_PATH else Vector2i(16, 16)
	_mask_mapping = _resolve_mask_mapping(atlas_path)
	_source_id = _assign_tile_set(_display_layer, atlas_path, tile_size)


func set_terrain_point(cell: Vector2i, terrain: int) -> void:
	if not _is_inside_point(cell):
		return
	terrain_grid[cell] = terrain


func get_terrain_point(cell: Vector2i) -> int:
	return int(terrain_grid.get(cell, TERRAIN_GRASS))


func paint_dirt_rect(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			set_terrain_point(Vector2i(x, y), TERRAIN_DIRT)


func paint_dirt_path(points: Array, radius: float) -> int:
	var painted := 0
	for y in range(map_size.y):
		for x in range(map_size.x):
			var cell := Vector2i(x, y)
			if _distance_to_polyline(Vector2(x, y), points) <= radius:
				set_terrain_point(cell, TERRAIN_DIRT)
				painted += 1
	return painted


func rebuild() -> Dictionary:
	if _display_layer == null or _source_id < 0:
		return {}
	_display_layer.clear()
	_display_layer.position = Vector2(-tile_size.x * 0.5, -tile_size.y * 0.5)
	var painted := 0
	var transitions := 0
	var full := 0
	for y in range(map_size.y + 1):
		for x in range(map_size.x + 1):
			var mask := _get_corner_mask(x, y)
			_display_layer.set_cell(Vector2i(x, y), _source_id, _mask_to_atlas_coords(mask))
			painted += 1
			if mask == 15:
				full += 1
			elif mask != 0:
				transitions += 1
	_last_rebuild_summary = {
		"painted_tiles": painted,
		"transition_tiles": transitions,
		"full_dirt_tiles": full,
	}
	return _last_rebuild_summary


func get_mask_mapping() -> Array:
	return _mask_mapping.duplicate()


func get_summary() -> Dictionary:
	var dirt_points := 0
	for value in terrain_grid.values():
		if int(value) == TERRAIN_DIRT:
			dirt_points += 1
	return {
		"atlas": atlas_path,
		"tile_size": tile_size,
		"map_size": map_size,
		"terrain_points": terrain_grid.size(),
		"dirt_points": dirt_points,
		"mask_mapping_count": _mask_mapping.size(),
		"last_rebuild": _last_rebuild_summary,
	}


func _get_corner_mask(x: int, y: int) -> int:
	var mask := 0
	if get_terrain_point(Vector2i(x - 1, y - 1)) == TERRAIN_DIRT:
		mask += BIT_TOP_LEFT
	if get_terrain_point(Vector2i(x, y - 1)) == TERRAIN_DIRT:
		mask += BIT_TOP_RIGHT
	if get_terrain_point(Vector2i(x - 1, y)) == TERRAIN_DIRT:
		mask += BIT_BOTTOM_LEFT
	if get_terrain_point(Vector2i(x, y)) == TERRAIN_DIRT:
		mask += BIT_BOTTOM_RIGHT
	return mask


func _mask_to_atlas_coords(mask: int) -> Vector2i:
	return _mask_mapping[clampi(mask, 0, _mask_mapping.size() - 1)]


func _assign_tile_set(layer: TileMapLayer, texture_path: String, atlas_tile_size: Vector2i) -> int:
	var tile_set := TileSet.new()
	tile_set.tile_size = atlas_tile_size
	var source := TileSetAtlasSource.new()
	source.texture = load(texture_path)
	source.texture_region_size = atlas_tile_size
	for atlas_y in range(4):
		for atlas_x in range(4):
			source.create_tile(Vector2i(atlas_x, atlas_y))
	var source_id := tile_set.add_source(source)
	layer.tile_set = tile_set
	layer.rendering_quadrant_size = 256
	return source_id


func _resolve_atlas_path(preferred_atlas_path: String) -> String:
	if ResourceLoader.exists(preferred_atlas_path):
		return preferred_atlas_path
	if ResourceLoader.exists(CANDIDATE_07_ATLAS_PATH):
		return CANDIDATE_07_ATLAS_PATH
	if ResourceLoader.exists(DEFAULT_DEBUG_ATLAS_PATH):
		return DEFAULT_DEBUG_ATLAS_PATH
	return PLACEHOLDER_ATLAS_PATH


func _resolve_mask_mapping(resolved_atlas_path: String) -> Array:
	if resolved_atlas_path == CANDIDATE_07_ATLAS_PATH:
		return CANDIDATE_07_MASK_TO_ATLAS_COORDS.duplicate()
	return DEBUG_1_MASK_TO_ATLAS_COORDS.duplicate()


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


func _is_inside_point(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < map_size.x and cell.y >= 0 and cell.y < map_size.y
