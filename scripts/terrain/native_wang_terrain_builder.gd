extends RefCounted
class_name NativeWangTerrainBuilder

const ATLAS_PATH := "res://assets/sprites/terrain/pixellab_dark_arpg_wang_candidates/wang16_dirt_to_grass_candidate_02.png"
const TILE_SIZE := Vector2i(32, 32)
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

var _tile_set: TileSet


func create_layer(layer_name: String, z_index: int) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.z_index = z_index
	layer.tile_set = get_tile_set()
	layer.rendering_quadrant_size = 256
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.set_meta("native_wang_terrain", true)
	layer.set_meta("atlas", ATLAS_PATH)
	return layer


func paint_rect(layer: TileMapLayer, world_rect: Rect2, dirt_cells: Array[Vector2i]) -> Dictionary:
	var all_cells := cells_for_rect(world_rect)
	layer.clear()
	layer.set_cells_terrain_connect(all_cells, TERRAIN_SET, TERRAIN_GRASS, false)
	layer.set_cells_terrain_connect(dirt_cells, TERRAIN_SET, TERRAIN_DIRT, false)
	var summary := {
		"atlas": ATLAS_PATH,
		"all_cells": all_cells.size(),
		"dirt_cells": dirt_cells.size(),
		"used_cells": layer.get_used_cells().size(),
	}
	layer.set_meta("summary", summary)
	return summary


func cells_for_rect(world_rect: Rect2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var start_x := int(floor(world_rect.position.x / float(TILE_SIZE.x)))
	var start_y := int(floor(world_rect.position.y / float(TILE_SIZE.y)))
	var end_x := int(ceil(world_rect.end.x / float(TILE_SIZE.x)))
	var end_y := int(ceil(world_rect.end.y / float(TILE_SIZE.y)))
	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			cells.append(Vector2i(x, y))
	return cells


func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell * TILE_SIZE) + Vector2(TILE_SIZE) * 0.5


func get_tile_set() -> TileSet:
	if _tile_set == null:
		_tile_set = _build_tile_set()
	return _tile_set


func _build_tile_set() -> TileSet:
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
	tile_set.add_source(source)

	for mask in range(MASK_TO_ATLAS_COORDS.size()):
		var tile_data := source.get_tile_data(MASK_TO_ATLAS_COORDS[mask], 0)
		tile_data.set_terrain_set(TERRAIN_SET)
		tile_data.set_terrain(TERRAIN_DIRT if mask != 0 else TERRAIN_GRASS)
		_set_corner_terrain(tile_data, TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, (mask & 1) != 0)
		_set_corner_terrain(tile_data, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER, (mask & 2) != 0)
		_set_corner_terrain(tile_data, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, (mask & 4) != 0)
		_set_corner_terrain(tile_data, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, (mask & 8) != 0)
	return tile_set


func _set_corner_terrain(tile_data: TileData, peering_bit: TileSet.CellNeighbor, is_dirt: bool) -> void:
	if tile_data.is_valid_terrain_peering_bit(peering_bit):
		tile_data.set_terrain_peering_bit(peering_bit, TERRAIN_DIRT if is_dirt else TERRAIN_GRASS)
