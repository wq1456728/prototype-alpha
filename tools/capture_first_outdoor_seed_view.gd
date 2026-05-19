extends SceneTree

const SCENE_PATH := "res://scenes/maps/first_outdoor_generated.tscn"
const OUTPUT_PATH := "res://artifacts/first_outdoor_seed_24001.png"
const PAYLOAD_PATH := "res://artifacts/first_outdoor_seed_24001_payload.json"


func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var error := change_scene_to_file(SCENE_PATH)
	if error != OK:
		print("FirstOutdoorCapture: FAIL scene_load=%s" % error)
		quit(1)
		return
	_run.call_deferred()


func _run() -> void:
	if not await _wait_for_scene():
		print("FirstOutdoorCapture: FAIL scene_not_ready")
		quit(1)
		return
	var player := get_first_node_in_group("player") as Node2D
	if player != null:
		player.global_position = current_scene.call("get_route_marker_position", "RoadFork")
	var camera := root.get_camera_2d()
	if camera != null:
		camera.reset_smoothing()
	for _i in range(8):
		await process_frame
	if DisplayServer.get_name() == "headless":
		if not _save_payload():
			print("FirstOutdoorCapture: FAIL headless_payload")
			quit(1)
			return
		print("FirstOutdoorCapture: PASS payload_only %s" % ProjectSettings.globalize_path(PAYLOAD_PATH))
		quit(0)
		return
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		if not _save_payload():
			print("FirstOutdoorCapture: FAIL empty_image_and_payload")
			quit(1)
			return
		print("FirstOutdoorCapture: PASS payload_only %s" % ProjectSettings.globalize_path(PAYLOAD_PATH))
		quit(0)
		return
	image.crop(1920, 1080)
	var output_absolute := ProjectSettings.globalize_path(OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(output_absolute.get_base_dir())
	var save_error := image.save_png(output_absolute)
	if save_error != OK:
		print("FirstOutdoorCapture: FAIL save=%s path=%s" % [save_error, output_absolute])
		quit(1)
		return
	print("FirstOutdoorCapture: PASS %s %dx%d" % [output_absolute, image.get_width(), image.get_height()])
	quit(0)


func _save_payload() -> bool:
	if current_scene == null or not current_scene.has_method("get_generated_payload"):
		return false
	var payload: Dictionary = current_scene.call("get_generated_payload")
	var output_absolute := ProjectSettings.globalize_path(PAYLOAD_PATH)
	DirAccess.make_dir_recursive_absolute(output_absolute.get_base_dir())
	var file := FileAccess.open(output_absolute, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	return true


func _wait_for_scene() -> bool:
	for _i in range(30):
		await physics_frame
		if current_scene != null and get_first_node_in_group("player") != null:
			return true
	return false
