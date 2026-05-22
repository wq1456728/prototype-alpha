extends SceneTree

const FOOTPRINT_TOOL := preload("res://scripts/tools/asset_footprint_draft_tool.gd")

const OUTPUT_JSON := "res://artifacts/task031_footprint_drafts/smoke_footprints.json"
const OUTPUT_PREVIEW := "res://artifacts/task031_footprint_drafts/smoke_footprints_preview.png"

const FIXTURES := [
	{
		"asset_id": "smoke_character",
		"image_path": "res://assets/sprites/npc/camp_01/npc_camp01_quest_giver_idle_64_a.png",
		"asset_type": "character",
		"intended_behavior": "standing character footprint",
	},
	{
		"asset_id": "smoke_enemy",
		"image_path": "res://assets/sprites/enemies/mummy/enemy_mummy_idle_side.png",
		"asset_type": "enemy",
		"intended_behavior": "standing enemy footprint",
	},
	{
		"asset_id": "smoke_prop_low",
		"image_path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_rock_small_32_a.png",
		"asset_type": "prop_low",
		"intended_behavior": "low rock footprint",
	},
	{
		"asset_id": "smoke_prop_tall",
		"image_path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_dead_tree_64_a.png",
		"asset_type": "prop_tall",
		"intended_behavior": "tall tree lower support footprint",
	},
	{
		"asset_id": "smoke_barrier",
		"image_path": "res://assets/sprites/props/camp_01/prop_camp01_wood_fence_straight_96_a.png",
		"asset_type": "barrier",
		"orientation": "horizontal",
		"intended_behavior": "continuous fence blocker",
	},
	{
		"asset_id": "smoke_entrance",
		"image_path": "res://assets/sprites/props/outdoor_01/prop_outdoor01_corrupted_hollow_128.png",
		"asset_type": "entrance",
		"intended_behavior": "side blockers with central opening",
	},
	{
		"asset_id": "smoke_interactable",
		"image_path": "res://assets/sprites/props/camp_01/prop_camp01_stash_chest_64_a.png",
		"asset_type": "interactable",
		"intended_behavior": "physical chest footprint plus click range",
	},
	{
		"asset_id": "smoke_decal",
		"image_path": "res://assets/sprites/decals/outdoor_01/decal_outdoor01_road_noise_64_a.png",
		"asset_type": "decal",
		"intended_behavior": "visual-only road decal",
	},
	{
		"asset_id": "smoke_ground_tile",
		"image_path": "res://assets/sprites/tiles/outdoor_01/tile_outdoor01_grass_dead_base_32_a.png",
		"asset_type": "ground_tile",
		"intended_behavior": "visual-only ground tile",
	},
]


func _initialize() -> void:
	var tool := FOOTPRINT_TOOL.new()
	var drafts := tool.analyze_batch(FIXTURES)
	var failures := []
	for draft in drafts:
		_validate_draft(draft, failures)
	var payload := {"schema": "FootprintDraftSmoke.v1", "drafts": drafts}
	var json_error := tool.write_json(OUTPUT_JSON, payload)
	if json_error != OK:
		failures.append("write_json failed: %s" % json_error)
	var preview_error := tool.write_preview_sheet(OUTPUT_PREVIEW, drafts, 3)
	if preview_error != OK:
		failures.append("write_preview_sheet failed: %s" % preview_error)
	if not failures.is_empty():
		for failure in failures:
			print("Task31FootprintSmoke: FAIL %s" % failure)
		quit(1)
		return
	print("Task31FootprintSmoke: PASS count=%d json=%s preview=%s" % [drafts.size(), OUTPUT_JSON, OUTPUT_PREVIEW])
	quit(0)


func _validate_draft(draft: Dictionary, failures: Array) -> void:
	var asset_id := str(draft.get("asset_id", "<missing>"))
	for key in ["asset_id", "image_path", "asset_type", "image_size", "sprite", "collision", "interaction", "analysis"]:
		if not draft.has(key):
			failures.append("%s missing key %s" % [asset_id, key])
	var sprite: Dictionary = draft.get("sprite", {})
	for key in ["visual_bounds", "foot_point", "sprite_offset", "sort_y_offset"]:
		if not sprite.has(key):
			failures.append("%s missing sprite.%s" % [asset_id, key])
	var image_size: Dictionary = draft.get("image_size", {})
	if not image_size.has("w") or not image_size.has("h"):
		failures.append("%s image_size should use w/h keys" % asset_id)
	var analysis: Dictionary = draft.get("analysis", {})
	for key in ["confidence", "needs_review", "reason", "warnings"]:
		if not analysis.has(key):
			failures.append("%s missing analysis.%s" % [asset_id, key])
	var asset_type := str(draft.get("asset_type", ""))
	var collision: Dictionary = draft.get("collision", {})
	var interaction: Dictionary = draft.get("interaction", {})
	match asset_type:
		"decal", "ground_tile":
			if bool(collision.get("enabled", true)):
				failures.append("%s should not have collision" % asset_id)
		"entrance":
			if not bool(collision.get("enabled", false)):
				failures.append("%s entrance collision disabled" % asset_id)
			if str(collision.get("shape", "")) != "parts":
				failures.append("%s entrance collision should use parts" % asset_id)
			if not collision.has("opening"):
				failures.append("%s entrance missing opening" % asset_id)
			if _part_ids(collision).find("left_blocker") == -1 or _part_ids(collision).find("right_blocker") == -1:
				failures.append("%s entrance missing side blockers" % asset_id)
			if not bool(interaction.get("enabled", false)):
				failures.append("%s entrance interaction disabled" % asset_id)
		"interactable":
			if not bool(collision.get("enabled", false)):
				failures.append("%s interactable collision disabled" % asset_id)
			if not bool(interaction.get("enabled", false)):
				failures.append("%s interactable interaction disabled" % asset_id)
		_:
			if not bool(collision.get("enabled", false)):
				failures.append("%s should have collision" % asset_id)


func _part_ids(collision: Dictionary) -> Array:
	var ids := []
	for part in collision.get("parts", []):
		var data: Dictionary = part
		ids.append(str(data.get("id", "")))
	return ids
