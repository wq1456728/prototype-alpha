extends RefCounted
class_name TerrainCellField

const MASK_DIRECTIONS := [
	{"offset": Vector2i(0, -1), "bit": 2, "requires": []},
	{"offset": Vector2i(0, 1), "bit": 64, "requires": []},
	{"offset": Vector2i(-1, 0), "bit": 8, "requires": []},
	{"offset": Vector2i(1, 0), "bit": 16, "requires": []},
	{"offset": Vector2i(-1, -1), "bit": 1, "requires": [Vector2i(0, -1), Vector2i(-1, 0)]},
	{"offset": Vector2i(1, -1), "bit": 4, "requires": [Vector2i(0, -1), Vector2i(1, 0)]},
	{"offset": Vector2i(-1, 1), "bit": 32, "requires": [Vector2i(0, 1), Vector2i(-1, 0)]},
	{"offset": Vector2i(1, 1), "bit": 128, "requires": [Vector2i(0, 1), Vector2i(1, 0)]},
]

var map_size := Vector2i.ZERO
var _layers := {}


func _init(initial_map_size: Vector2i) -> void:
	map_size = initial_map_size


func clear() -> void:
	_layers.clear()


func add_cell(layer_id: String, cell: Vector2i) -> void:
	if not is_inside(cell):
		return
	if not _layers.has(layer_id):
		_layers[layer_id] = {}
	_layers[layer_id][cell] = true


func remove_cell(layer_id: String, cell: Vector2i) -> void:
	if not _layers.has(layer_id):
		return
	_layers[layer_id].erase(cell)


func set_cell(layer_id: String, cell: Vector2i, enabled: bool) -> void:
	if enabled:
		add_cell(layer_id, cell)
	else:
		remove_cell(layer_id, cell)


func add_cells(layer_id: String, cells: Array) -> void:
	for cell in cells:
		add_cell(layer_id, cell)


func has_cell(layer_id: String, cell: Vector2i) -> bool:
	return is_inside(cell) and _layers.has(layer_id) and _layers[layer_id].has(cell)


func get_cells(layer_id: String) -> Array:
	if not _layers.has(layer_id):
		return []
	return _layers[layer_id].keys()


func get_cell_count(layer_id: String) -> int:
	if not _layers.has(layer_id):
		return 0
	return _layers[layer_id].size()


func build_neighbor_ring(source_layer_id: String, target_layer_id: String, radius: int = 1) -> void:
	for cell in get_cells(source_layer_id):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var around := Vector2i(cell.x + dx, cell.y + dy)
				if is_inside(around) and not has_cell(source_layer_id, around):
					add_cell(target_layer_id, around)


func compute_blob_mask(cell: Vector2i, layer_id: String) -> int:
	var mask := 0
	for entry in MASK_DIRECTIONS:
		var offset: Vector2i = entry["offset"]
		var neighbor := cell + offset
		if not has_cell(layer_id, neighbor):
			continue
		var required_offsets: Array = entry["requires"]
		var allowed := true
		for required_offset in required_offsets:
			if not has_cell(layer_id, cell + required_offset):
				allowed = false
				break
		if allowed:
			mask += int(entry["bit"])
	return mask


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < map_size.x and cell.y >= 0 and cell.y < map_size.y
