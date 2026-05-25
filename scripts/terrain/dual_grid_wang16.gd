extends RefCounted
class_name DualGridWang16

const DEFAULT_TILE_SIZE := Vector2i(16, 16)
const ATLAS_COLUMNS := 4
const ATLAS_ROWS := 4

const CORNER_NW := 1
const CORNER_NE := 2
const CORNER_SW := 4
const CORNER_SE := 8


func assign_atlas_tile_set(
	layer: TileMapLayer,
	texture_path: String,
	tile_size: Vector2i = DEFAULT_TILE_SIZE
) -> int:
	var tile_set := TileSet.new()
	tile_set.tile_size = tile_size
	var source := TileSetAtlasSource.new()
	source.texture = load(texture_path)
	source.texture_region_size = tile_size
	for y in range(ATLAS_ROWS):
		for x in range(ATLAS_COLUMNS):
			source.create_tile(Vector2i(x, y))
	var source_id := tile_set.add_source(source)
	layer.tile_set = tile_set
	layer.rendering_quadrant_size = 256
	return source_id


func paint_lower_base(
	layer: TileMapLayer,
	source_id: int,
	world_size: Vector2i,
	lower_mask: int = 0
) -> void:
	var atlas_coords := mask_to_atlas_coords(lower_mask)
	for y in range(world_size.y):
		for x in range(world_size.x):
			layer.set_cell(Vector2i(x, y), source_id, atlas_coords)


func paint_display_from_world(
	layer: TileMapLayer,
	source_id: int,
	field,
	upper_layer_id: String,
	world_size: Vector2i,
	tile_size: Vector2i = DEFAULT_TILE_SIZE,
	skip_lower_only_tiles: bool = true
) -> Dictionary:
	layer.position = Vector2(-tile_size.x * 0.5, -tile_size.y * 0.5)
	var painted := 0
	var transition := 0
	var full := 0
	for y in range(world_size.y + 1):
		for x in range(world_size.x + 1):
			var display_cell := Vector2i(x, y)
			var mask := display_mask_for_cell(field, upper_layer_id, display_cell)
			if skip_lower_only_tiles and mask == 0:
				continue
			layer.set_cell(display_cell, source_id, mask_to_atlas_coords(mask))
			painted += 1
			if mask == 15:
				full += 1
			else:
				transition += 1
	return {
		"painted": painted,
		"transition": transition,
		"full": full,
	}


func display_mask_for_cell(field, upper_layer_id: String, display_cell: Vector2i) -> int:
	var mask := 0
	if field.has_cell(upper_layer_id, display_cell + Vector2i(-1, -1)):
		mask += CORNER_NW
	if field.has_cell(upper_layer_id, display_cell + Vector2i(0, -1)):
		mask += CORNER_NE
	if field.has_cell(upper_layer_id, display_cell + Vector2i(-1, 0)):
		mask += CORNER_SW
	if field.has_cell(upper_layer_id, display_cell):
		mask += CORNER_SE
	return mask


func mask_to_atlas_coords(mask: int) -> Vector2i:
	var normalized := clampi(mask, 0, 15)
	return Vector2i(normalized % ATLAS_COLUMNS, normalized / ATLAS_COLUMNS)


func mask_to_region_rect(mask: int, tile_size: Vector2i = DEFAULT_TILE_SIZE) -> Rect2:
	var atlas := mask_to_atlas_coords(mask)
	return Rect2(Vector2(atlas * tile_size), Vector2(tile_size))
