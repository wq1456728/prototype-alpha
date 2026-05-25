extends RefCounted
class_name BlobTile47

const DEFAULT_TILE_SIZE := Vector2i(24, 24)
const DEFAULT_ATLAS_COLUMNS := 3
const DEFAULT_ATLAS_ROWS := 24
const CENTER_TILE_INDEX := 4

const MASK_TO_INDEX := {
	0: 13,
	208: 0,
	248: 1,
	104: 2,
	214: 3,
	255: 4,
	107: 5,
	22: 6,
	31: 7,
	11: 8,
	80: 9,
	24: 10,
	72: 11,
	66: 12,
	18: 15,
	10: 17,
	64: 19,
	16: 21,
	90: 22,
	8: 23,
	2: 25,
	88: 28,
	82: 30,
	74: 32,
	26: 34,
	95: 37,
	123: 39,
	222: 41,
	250: 43,
	127: 45,
	223: 46,
	251: 48,
	254: 49,
	86: 51,
	75: 52,
	210: 54,
	106: 55,
	120: 57,
	216: 58,
	27: 60,
	30: 61,
	218: 63,
	122: 64,
	94: 66,
	91: 67,
	126: 69,
	219: 70,
}


func assign_atlas_tile_set(
	layer: TileMapLayer,
	texture_path: String,
	tile_size: Vector2i = DEFAULT_TILE_SIZE,
	atlas_columns: int = DEFAULT_ATLAS_COLUMNS,
	atlas_rows: int = DEFAULT_ATLAS_ROWS
) -> int:
	var tile_set := TileSet.new()
	tile_set.tile_size = tile_size
	var source := TileSetAtlasSource.new()
	source.texture = load(texture_path)
	source.texture_region_size = tile_size
	for y in range(atlas_rows):
		for x in range(atlas_columns):
			source.create_tile(Vector2i(x, y))
	var source_id := tile_set.add_source(source)
	layer.tile_set = tile_set
	layer.rendering_quadrant_size = 256
	return source_id


func paint_center_fill(
	layer: TileMapLayer,
	source_id: int,
	map_size: Vector2i,
	center_index: int = CENTER_TILE_INDEX,
	atlas_columns: int = DEFAULT_ATLAS_COLUMNS
) -> void:
	var center_coords := index_to_atlas_coords(center_index, atlas_columns)
	for y in range(map_size.y):
		for x in range(map_size.x):
			layer.set_cell(Vector2i(x, y), source_id, center_coords)


func paint_mask_cells(
	layer: TileMapLayer,
	source_id: int,
	field,
	layer_id: String,
	atlas_columns: int = DEFAULT_ATLAS_COLUMNS
) -> void:
	for cell in field.get_cells(layer_id):
		var mask: int = field.compute_blob_mask(cell, layer_id)
		layer.set_cell(cell, source_id, index_to_atlas_coords(nearest_tile_index(mask), atlas_columns))


func nearest_tile_index(mask: int) -> int:
	mask &= 255
	if MASK_TO_INDEX.has(mask):
		return int(MASK_TO_INDEX[mask])
	var best_key := 0
	var best_distance := 99
	for key in MASK_TO_INDEX.keys():
		var distance := _pop8(mask ^ int(key))
		if distance < best_distance:
			best_distance = distance
			best_key = int(key)
	return int(MASK_TO_INDEX.get(best_key, CENTER_TILE_INDEX))


func index_to_atlas_coords(index: int, atlas_columns: int = DEFAULT_ATLAS_COLUMNS) -> Vector2i:
	return Vector2i(index % atlas_columns, index / atlas_columns)


func index_to_region_rect(
	index: int,
	tile_size: Vector2i = DEFAULT_TILE_SIZE,
	atlas_columns: int = DEFAULT_ATLAS_COLUMNS
) -> Rect2:
	var atlas := index_to_atlas_coords(index, atlas_columns)
	return Rect2(Vector2(atlas * tile_size), Vector2(tile_size))


func _pop8(value: int) -> int:
	var count := 0
	value &= 255
	while value > 0:
		count += value & 1
		value = value >> 1
	return count
