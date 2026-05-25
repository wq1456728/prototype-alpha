extends SceneTree

const SCENE_PATH := "res://scenes/dev/terrain_native_terrain_test.tscn"
const OUTPUT_PATH := "res://artifacts/task32_native_terrain_candidate_02_preview.png"
const ATLAS_PATH := "res://assets/sprites/terrain/pixellab_dark_arpg_wang_candidates/wang16_dirt_to_grass_candidate_02.png"
const TILE_SIZE := Vector2i(32, 32)
const MAP_SIZE := Vector2i(72, 44)
const PREVIEW_SCALE := 4


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var error := change_scene_to_file(SCENE_PATH)
	if error != OK:
		_fail("scene_load=%s" % error)
		return
	if not await _wait_for_scene():
		_fail("scene_not_ready")
		return
	var layer := current_scene.get_node("NativeTerrainTileMapLayer") as TileMapLayer
	var atlas_texture := load(ATLAS_PATH) as Texture2D
	if atlas_texture == null:
		_fail("missing_atlas_texture")
		return
	var atlas_image := atlas_texture.get_image()
	var output := Image.create(MAP_SIZE.x * TILE_SIZE.x, MAP_SIZE.y * TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	output.fill(Color(0, 0, 0, 1))
	for cell in layer.get_used_cells():
		var atlas_coords := layer.get_cell_atlas_coords(cell)
		var source_rect := Rect2i(atlas_coords * TILE_SIZE, TILE_SIZE)
		output.blit_rect(atlas_image, source_rect, cell * TILE_SIZE)
	output.resize(output.get_width() / PREVIEW_SCALE, output.get_height() / PREVIEW_SCALE, Image.INTERPOLATE_NEAREST)
	var output_absolute := ProjectSettings.globalize_path(OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(output_absolute.get_base_dir())
	var save_error := output.save_png(output_absolute)
	if save_error != OK:
		_fail("save=%s" % save_error)
		return
	print("Task32NativeTerrainPreview: PASS %s" % output_absolute)
	quit(0)


func _wait_for_scene() -> bool:
	for _i in range(30):
		await process_frame
		if current_scene != null and current_scene.name == "TerrainNativeTerrainTest":
			return true
	return false


func _fail(message: String) -> void:
	print("Task32NativeTerrainPreview: FAIL %s" % message)
	quit(1)
