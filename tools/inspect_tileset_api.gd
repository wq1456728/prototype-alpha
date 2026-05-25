extends SceneTree


func _initialize() -> void:
	for constant_name in ClassDB.class_get_integer_constant_list("TileSet"):
		if str(constant_name).contains("TERRAIN") or str(constant_name).contains("CELL_NEIGHBOR"):
			print("TileSet constant ", constant_name, "=", ClassDB.class_get_integer_constant("TileSet", constant_name))
	for method in ClassDB.class_get_method_list("TileSet"):
		var method_name := str(method.get("name", ""))
		if method_name.contains("terrain"):
			print("TileSet method ", method)
	for method in ClassDB.class_get_method_list("TileData"):
		var method_name := str(method.get("name", ""))
		if method_name.contains("terrain") or method_name.contains("peering"):
			print("TileData method ", method)
	for method in ClassDB.class_get_method_list("TileMapLayer"):
		var method_name := str(method.get("name", ""))
		if method_name.contains("terrain"):
			print("TileMapLayer method ", method)
	quit(0)
