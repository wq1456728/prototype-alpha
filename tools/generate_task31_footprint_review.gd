extends SceneTree

const FOOTPRINT_TOOL := preload("res://scripts/tools/asset_footprint_draft_tool.gd")

const OUTPUT_JSON := "res://artifacts/task031_footprint_drafts/task031_camp_footprints.json"
const OUTPUT_PREVIEW := "res://artifacts/task031_footprint_drafts/task031_camp_footprints_preview.png"

const CAMP_REVIEW_ASSETS := [
	{
		"asset_id": "camp_wood_fence_straight",
		"image_path": "res://assets/sprites/props/camp_01/prop_camp01_wood_fence_straight_96_a.png",
		"asset_type": "barrier",
		"orientation": "horizontal",
		"intended_behavior": "camp perimeter horizontal fence segment",
	},
	{
		"asset_id": "camp_wood_fence_vertical_rotated",
		"image_path": "res://assets/sprites/props/camp_01/prop_camp01_wood_fence_straight_96_a.png",
		"asset_type": "barrier",
		"orientation": "vertical",
		"intended_behavior": "same sprite rotated in scene for vertical fence placeholder",
	},
	{
		"asset_id": "camp_wood_fence_side_pixellab",
		"image_path": "res://assets/sprites/props/camp_01/prop_camp01_wood_fence_side_pixellab_64.png",
		"asset_type": "barrier",
		"orientation": "vertical",
		"intended_behavior": "PixelLab-generated dedicated side fence segment for camp vertical perimeter",
	},
	{
		"asset_id": "camp_wood_fence_corner",
		"image_path": "res://assets/sprites/props/camp_01/prop_camp01_wood_fence_corner_96_a.png",
		"asset_type": "barrier",
		"orientation": "horizontal",
		"intended_behavior": "camp perimeter fence corner",
	},
	{
		"asset_id": "camp_gate_side_post",
		"image_path": "res://assets/sprites/props/camp_01/prop_camp01_wood_fence_gate_side_96_a.png",
		"asset_type": "entrance",
		"orientation": "horizontal",
		"intended_behavior": "two side posts should leave gate center open",
	},
	{
		"asset_id": "camp_tent",
		"image_path": "res://assets/sprites/props/camp_01/prop_camp01_tent_128_a.png",
		"asset_type": "prop_tall",
		"intended_behavior": "tent blocks near stakes and floor, not whole canopy",
	},
	{
		"asset_id": "camp_stash_chest",
		"image_path": "res://assets/sprites/props/camp_01/prop_camp01_stash_chest_64_a.png",
		"asset_type": "interactable",
		"intended_behavior": "small chest collision plus larger click range",
	},
	{
		"asset_id": "camp_crate_barrel_stack",
		"image_path": "res://assets/sprites/props/camp_01/prop_camp01_crate_barrel_stack_96_a.png",
		"asset_type": "prop_low",
		"intended_behavior": "supply stack should block lower footprint",
	},
	{
		"asset_id": "camp_waypoint",
		"image_path": "res://assets/sprites/props/camp_01/prop_camp01_waypoint_marker_96_a.png",
		"asset_type": "interactable",
		"intended_behavior": "waypoint has small collision and larger interaction",
	},
	{
		"asset_id": "campfire",
		"image_path": "res://assets/sprites/props/camp_01/prop_camp01_campfire_64_a.png",
		"asset_type": "interactable",
		"intended_behavior": "campfire can be inspected but should not create a tall blocker",
	},
	{
		"asset_id": "campfire_pixellab_idle_frame0",
		"image_path": "res://assets/sprites/props/camp_01/campfire_idle_pixellab/frame_0.png",
		"asset_type": "interactable",
		"intended_behavior": "PixelLab campfire idle frame collision draft, stones/flame should not create a tall blocker",
	},
	{
		"asset_id": "camp_quest_giver",
		"image_path": "res://assets/sprites/npc/camp_01/npc_camp01_quest_giver_idle_64_a.png",
		"asset_type": "character",
		"intended_behavior": "neutral NPC standing footprint",
	},
	{
		"asset_id": "camp_quest_giver_pixellab_idle_frame0",
		"image_path": "res://assets/sprites/npc/camp_01/quest_giver_idle_pixellab/frame_0.png",
		"asset_type": "character",
		"intended_behavior": "PixelLab quest giver idle frame standing footprint",
	},
	{
		"asset_id": "dungeon_entrance",
		"image_path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_hollow_128.png",
		"asset_type": "entrance",
		"intended_behavior": "entrance sides block, opening remains usable",
	},
	{
		"asset_id": "dead_tree",
		"image_path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_dead_tree_64_a.png",
		"asset_type": "prop_tall",
		"intended_behavior": "tree blocks trunk/root area, not branches",
	},
	{
		"asset_id": "small_rock",
		"image_path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_rock_small_32_a.png",
		"asset_type": "prop_low",
		"intended_behavior": "rock footprint close to lower visual body",
	},
	{
		"asset_id": "broken_cart",
		"image_path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_broken_cart_96.png",
		"asset_type": "prop_low",
		"intended_behavior": "cart blocks broad lower footprint",
	},
	{
		"asset_id": "road_noise_decal",
		"image_path": "res://assets/sprites/decals/outdoor_01/decal_outdoor01_road_noise_64_a.png",
		"asset_type": "decal",
		"intended_behavior": "road decal should not block",
	},
	{
		"asset_id": "grass_dead_tile",
		"image_path": "res://assets/sprites/tiles/outdoor_01/tile_outdoor01_grass_dead_base_32_a.png",
		"asset_type": "ground_tile",
		"intended_behavior": "ground tile should not block",
	},
	{
		"asset_id": "enemy_mummy",
		"image_path": "res://assets/sprites/enemies/mummy/enemy_mummy_idle_side.png",
		"asset_type": "enemy",
		"intended_behavior": "enemy standing footprint",
	},
]


func _initialize() -> void:
	var tool := FOOTPRINT_TOOL.new()
	var drafts := tool.analyze_batch(CAMP_REVIEW_ASSETS)
	var payload := {
		"schema": "FootprintDraftBatch.v1",
		"generated_for": "TASK-031 Asset Footprint Draft And Collision Preview Tool",
		"drafts": drafts,
		"outputs": {
			"json": OUTPUT_JSON,
			"preview": OUTPUT_PREVIEW,
		},
	}
	var json_error := tool.write_json(OUTPUT_JSON, payload)
	if json_error != OK:
		print("Task31FootprintReview: FAIL json_error=%s" % json_error)
		quit(1)
		return
	var preview_error := tool.write_preview_sheet(OUTPUT_PREVIEW, drafts, 4)
	if preview_error != OK:
		print("Task31FootprintReview: FAIL preview_error=%s" % preview_error)
		quit(1)
		return
	print("Task31FootprintReview: PASS json=%s preview=%s count=%d" % [OUTPUT_JSON, OUTPUT_PREVIEW, drafts.size()])
	quit(0)
