extends Node2D

const DualGridTerrainPainterScript := preload("res://scripts/terrain/dual_grid_terrain_painter.gd")

const MAP_SIZE := Vector2i(72, 44)

@export_file("*.png") var wang16_atlas_path := "res://assets/sprites/terrain/pixellab_dark_arpg_wang_candidates/wang16_dirt_to_grass_candidate_07.png"
@export var wang16_tile_size := Vector2i(32, 32)

@onready var ground_display_layer: TileMapLayer = $GroundDisplayTileMapLayer
@onready var decal_preview_layer: Node2D = $DecalPreviewLayer
@onready var debug_overlay_layer: Node2D = $DebugOverlayLayer
@onready var camera: Camera2D = $Camera2D

var _painter = DualGridTerrainPainterScript.new()
var _path_points := [
	Vector2(4.0, 35.0),
	Vector2(13.0, 30.5),
	Vector2(24.0, 27.0),
	Vector2(36.0, 21.0),
	Vector2(50.0, 15.0),
	Vector2(67.0, 8.0),
]
var _road_points_painted := 0
var _patch_count := 0


func _ready() -> void:
	name = "TerrainDualGridWangTest"
	_painter.configure(ground_display_layer, MAP_SIZE, wang16_atlas_path, wang16_tile_size)
	_paint_test_map()
	_painter.rebuild()
	_add_decal_preview()
	_setup_camera()


func get_task32_dual_grid_summary() -> Dictionary:
	var painter_summary := _painter.get_summary()
	return {
		"source": "dual-grid Wang16 algorithm prototype",
		"atlas": painter_summary.get("atlas", ""),
		"tile_size": painter_summary.get("tile_size", Vector2i.ZERO),
		"map_size": MAP_SIZE,
		"mask_mapping_count": painter_summary.get("mask_mapping_count", 0),
		"mask_mapping": _painter.get_mask_mapping(),
		"dirt_points": painter_summary.get("dirt_points", 0),
		"road_points_painted": _road_points_painted,
		"patch_count": _patch_count,
		"display_tiles": int(painter_summary.get("last_rebuild", {}).get("painted_tiles", 0)),
		"transition_tiles": int(painter_summary.get("last_rebuild", {}).get("transition_tiles", 0)),
		"full_dirt_tiles": int(painter_summary.get("last_rebuild", {}).get("full_dirt_tiles", 0)),
		"decal_count": decal_preview_layer.get_child_count(),
	}


func _paint_test_map() -> void:
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			_painter.set_terrain_point(Vector2i(x, y), DualGridTerrainPainter.TERRAIN_GRASS)
	_road_points_painted = _painter.paint_dirt_path(_path_points, 2.4)
	_paint_irregular_patch(Vector2(28.0, 31.0), Vector2(8.0, 4.5))
	_paint_irregular_patch(Vector2(54.0, 23.0), Vector2(5.0, 3.6))


func _paint_irregular_patch(center: Vector2, radius: Vector2) -> void:
	_patch_count += 1
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var point := Vector2(x, y)
			var noise := sin(float(x) * 0.73 + float(y) * 0.21) * 0.16
			var normalized := Vector2((point.x - center.x) / radius.x, (point.y - center.y) / radius.y)
			if normalized.length_squared() <= 1.0 + noise:
				_painter.set_terrain_point(Vector2i(x, y), DualGridTerrainPainter.TERRAIN_DIRT)


func _add_decal_preview() -> void:
	for i in range(10):
		var mark := ColorRect.new()
		mark.name = "GroundBreakup%02d" % i
		mark.size = Vector2(_painter.tile_size) * Vector2(0.9, 0.55)
		var x := 6 + i * 6
		var y := 10 + int(abs(sin(float(i) * 1.7)) * 24.0)
		mark.position = Vector2(x, y) * Vector2(_painter.tile_size)
		mark.color = Color(0.09, 0.06, 0.03, 0.16)
		decal_preview_layer.add_child(mark)


func _setup_camera() -> void:
	camera.position = Vector2(MAP_SIZE * _painter.tile_size) * 0.5
	camera.zoom = Vector2(0.82, 0.82)
	camera.enabled = true
