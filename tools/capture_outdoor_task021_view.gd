extends SceneTree

const SCENE_PATH := "res://scenes/maps/outdoor_greybox.tscn"
const OUTPUT_PATH := "res://artifacts/task021_outdoor_1920x1080.png"


func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var error := change_scene_to_file(SCENE_PATH)
	if error != OK:
		print("OutdoorCapture: FAIL scene_load=%s" % error)
		quit(1)
		return
	_run.call_deferred()


func _run() -> void:
	if not await _wait_for_scene():
		print("OutdoorCapture: FAIL scene_not_ready")
		quit(1)
		return
	var player := get_first_node_in_group("player") as Node2D
	if player != null:
		player.global_position = current_scene.call("get_route_marker_position", "TrainingVerge")
	var camera := root.get_camera_2d()
	if camera != null:
		camera.reset_smoothing()
	for _i in range(8):
		await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		print("OutdoorCapture: FAIL empty_image")
		quit(1)
		return
	if image.get_width() < 1920 or image.get_height() < 1080:
		print("OutdoorCapture: FAIL image_too_small=%dx%d" % [image.get_width(), image.get_height()])
		quit(1)
		return
	image.crop(1920, 1080)
	var output_absolute := ProjectSettings.globalize_path(OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(output_absolute.get_base_dir())
	var save_error := image.save_png(output_absolute)
	if save_error != OK:
		print("OutdoorCapture: FAIL save=%s path=%s" % [save_error, output_absolute])
		quit(1)
		return
	print("OutdoorCapture: PASS %s %dx%d" % [output_absolute, image.get_width(), image.get_height()])
	quit(0)


func _wait_for_scene() -> bool:
	for _i in range(30):
		await physics_frame
		if current_scene != null and get_first_node_in_group("player") != null:
			return true
	return false
