extends SceneTree


const ASSET_CHECKS := [
	{"id": "grass_dead_base", "path": "res://assets/sprites/tiles/outdoor_01/tile_outdoor01_grass_dead_base_32_a.png", "w": 32, "h": 32, "alpha": false},
	{"id": "dirt_road_center_a", "path": "res://assets/sprites/tiles/outdoor_01/tile_outdoor01_dirt_road_center_32_a.png", "w": 32, "h": 32, "alpha": false},
	{"id": "dirt_road_center_b", "path": "res://assets/sprites/tiles/outdoor_01/tile_outdoor01_dirt_road_center_32_b.png", "w": 32, "h": 32, "alpha": false},
	{"id": "dirt_road_edge_a", "path": "res://assets/sprites/tiles/outdoor_01/tile_outdoor01_dirt_road_edge_32_a.png", "w": 32, "h": 32, "alpha": false},
	{"id": "dirt_road_edge_b", "path": "res://assets/sprites/tiles/outdoor_01/tile_outdoor01_dirt_road_edge_32_b.png", "w": 32, "h": 32, "alpha": false},
	{"id": "dirt_road_corner_a", "path": "res://assets/sprites/tiles/outdoor_01/tile_outdoor01_dirt_road_corner_32_a.png", "w": 32, "h": 32, "alpha": false},
	{"id": "dirt_road_corner_b", "path": "res://assets/sprites/tiles/outdoor_01/tile_outdoor01_dirt_road_corner_32_b.png", "w": 32, "h": 32, "alpha": false},
	{"id": "dirt_road_end_fade", "path": "res://assets/sprites/tiles/outdoor_01/tile_outdoor01_dirt_road_end_fade_32_a.png", "w": 32, "h": 32, "alpha": false},
	{"id": "grass_to_dirt_blend", "path": "res://assets/sprites/tiles/outdoor_01/tile_outdoor01_grass_to_dirt_blend_32_a.png", "w": 32, "h": 32, "alpha": false},
	{"id": "dirt_to_corruption_blend", "path": "res://assets/sprites/tiles/outdoor_01/tile_outdoor01_dirt_to_corruption_blend_32_a.png", "w": 32, "h": 32, "alpha": false},
	{"id": "corruption_edge_blend", "path": "res://assets/sprites/tiles/outdoor_01/tile_outdoor01_corruption_edge_blend_32_a.png", "w": 32, "h": 32, "alpha": false},
	{"id": "road_noise_decal", "path": "res://assets/sprites/decals/outdoor_01/decal_outdoor01_road_noise_64_a.png", "w": 64, "h": 64, "alpha": true},
	{"id": "root_stain_decal", "path": "res://assets/sprites/decals/outdoor_01/decal_outdoor01_root_stain_64_a.png", "w": 64, "h": 64, "alpha": true},
	{"id": "dark_crack_decal", "path": "res://assets/sprites/decals/outdoor_01/decal_outdoor01_dark_crack_64_a.png", "w": 64, "h": 64, "alpha": true},
	{"id": "thorn_weed_decal", "path": "res://assets/sprites/decals/outdoor_01/decal_outdoor01_thorn_weed_32_a.png", "w": 32, "h": 32, "alpha": true},
	{"id": "camp_trampled_ground_decal", "path": "res://assets/sprites/decals/outdoor_01/decal_camp01_trampled_ground_64_a.png", "w": 64, "h": 64, "alpha": true},
	{"id": "camp_wood_fence_straight", "path": "res://assets/sprites/props/camp_01/prop_camp01_wood_fence_straight_96_a.png", "w": 96, "h": 64, "alpha": true},
	{"id": "camp_wood_fence_corner", "path": "res://assets/sprites/props/camp_01/prop_camp01_wood_fence_corner_96_a.png", "w": 96, "h": 96, "alpha": true},
	{"id": "camp_wood_fence_broken", "path": "res://assets/sprites/props/camp_01/prop_camp01_wood_fence_broken_96_a.png", "w": 96, "h": 64, "alpha": true},
	{"id": "camp_wood_fence_gate_side", "path": "res://assets/sprites/props/camp_01/prop_camp01_wood_fence_gate_side_96_a.png", "w": 96, "h": 96, "alpha": true},
	{"id": "camp_palisade_wall", "path": "res://assets/sprites/props/camp_01/prop_camp01_palisade_wall_96_a.png", "w": 96, "h": 96, "alpha": true},
	{"id": "camp_tent", "path": "res://assets/sprites/props/camp_01/prop_camp01_tent_128_a.png", "w": 128, "h": 128, "alpha": true},
	{"id": "campfire", "path": "res://assets/sprites/props/camp_01/prop_camp01_campfire_64_a.png", "w": 64, "h": 64, "alpha": true},
	{"id": "stash_chest", "path": "res://assets/sprites/props/camp_01/prop_camp01_stash_chest_64_a.png", "w": 64, "h": 64, "alpha": true},
	{"id": "crate_barrel_stack", "path": "res://assets/sprites/props/camp_01/prop_camp01_crate_barrel_stack_96_a.png", "w": 96, "h": 96, "alpha": true},
	{"id": "waypoint_marker", "path": "res://assets/sprites/props/camp_01/prop_camp01_waypoint_marker_96_a.png", "w": 96, "h": 96, "alpha": true},
	{"id": "npc_placeholder", "path": "res://assets/sprites/npc/camp_01/npc_camp01_quest_giver_idle_64_a.png", "w": 64, "h": 96, "alpha": true},
	{"id": "rock_small_a", "path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_rock_small_32_a.png", "w": 32, "h": 32, "alpha": true},
	{"id": "rock_small_b", "path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_rock_small_32_b.png", "w": 32, "h": 32, "alpha": true},
	{"id": "dead_tree_a", "path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_dead_tree_64_a.png", "w": 64, "h": 64, "alpha": true},
	{"id": "dead_tree_b", "path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_dead_tree_64_b.png", "w": 64, "h": 64, "alpha": true},
	{"id": "broken_fence_a", "path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_broken_fence_64_a.png", "w": 64, "h": 64, "alpha": true},
	{"id": "broken_fence_b", "path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_broken_fence_64_b.png", "w": 64, "h": 64, "alpha": true},
	{"id": "corrupted_root_wall_a", "path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_roots_64_a.png", "w": 64, "h": 64, "alpha": true},
	{"id": "corrupted_root_wall_b", "path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_roots_64_b.png", "w": 64, "h": 64, "alpha": true},
	{"id": "camp_gate", "path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_camp_gate_128.png", "w": 128, "h": 128, "alpha": true},
	{"id": "dungeon_entrance", "path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_hollow_128.png", "w": 128, "h": 128, "alpha": true},
	{"id": "next_area_marker", "path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_signpost_64.png", "w": 64, "h": 64, "alpha": true},
	{"id": "shrine_or_loot_marker", "path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_shrine_96.png", "w": 96, "h": 96, "alpha": true},
]


func _initialize() -> void:
	for check in ASSET_CHECKS:
		if not _validate_asset(check):
			quit(1)
			return
	print("Task29AssetInventory smoke: PASS count=%d" % ASSET_CHECKS.size())
	quit(0)


func _validate_asset(check: Dictionary) -> bool:
	var path := str(check["path"])
	if not FileAccess.file_exists(path):
		_fail("%s missing path=%s" % [check["id"], path])
		return false
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		_fail("%s image_load_error=%s path=%s" % [check["id"], error, path])
		return false
	if image.get_width() != int(check["w"]) or image.get_height() != int(check["h"]):
		_fail("%s bad_size=%dx%d expected=%dx%d" % [
			check["id"],
			image.get_width(),
			image.get_height(),
			check["w"],
			check["h"],
		])
		return false
	if bool(check["alpha"]) and image.detect_alpha() == Image.ALPHA_NONE:
		_fail("%s missing_alpha path=%s" % [check["id"], path])
		return false
	if not FileAccess.file_exists("%s.import" % path):
		print("Task29AssetInventory smoke: WARN %s import_missing path=%s" % [check["id"], path])
	return true


func _fail(message: String) -> void:
	print("Task29AssetInventory smoke: FAIL %s" % message)
