extends SceneTree

const COLLISION_LAYERS := preload("res://scripts/physics/collision_layers.gd")

const SCENE_PATH := "res://scenes/world/main_world.tscn"


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

	var scene := current_scene
	if not _validate_nodes(scene):
		return
	if not _validate_fence_orientation(scene):
		return
	if not _validate_interaction_placeholder(scene):
		return
	if not _validate_gate_and_bounds_motion(scene):
		return

	print("Task30CampAssembly smoke: PASS gate=%s props=%d" % [
		str(scene.call("get_town_exit_socket_position")),
		scene.get_node("FixedTown/Props").get_child_count(),
	])
	quit(0)


func _validate_nodes(scene: Node) -> bool:
	for path in [
		"FixedTown",
		"FixedTown/Ground/CampTrampledGroundCenter",
		"FixedTown/Props/NorthFence00",
		"FixedTown/Props/WestSideFence00",
		"FixedTown/Props/EastSideFence00",
		"FixedTown/Props/CampGateLeftPost",
		"FixedTown/Props/CampGateRightPost",
		"FixedTown/Props/CampTentNorthWest",
		"FixedTown/Props/CampSupplyStack",
		"FixedTown/Props/CampPalisadeStorage",
		"FixedTown/NPCPlaceholders/QuestGiverPlaceholder",
		"FixedTown/NPCPlaceholders/QuestGiverPlaceholder/AnimatedSprite2D",
		"FixedTown/NPCPlaceholders/QuestGiverPlaceholder/InteractionArea",
		"FixedTown/NPCPlaceholders/QuestGiverPlaceholder/QuestHintLabel",
		"FixedTown/Interactables/StashPlaceholder",
		"FixedTown/Interactables/WaypointPlaceholder",
		"FixedTown/Interactables/CampfireIdle",
		"FixedTown/Interactables/CampfireIdle/AnimatedSprite2D",
		"FixedTown/TownBounds",
		"FixedTown/TownSpawn",
		"FixedTown/TownExitSocket",
		"GeneratedRegion/TransitionChunk/WildernessStartSocket",
	]:
		if scene.get_node_or_null(path) == null:
			_fail("missing_node=%s" % path)
			return false
	for removed_path in [
		"FixedTown/Props/FenceCornerNorthWest",
		"FixedTown/Props/FenceCornerSouthEast",
		"FixedTown/Props/WestVerticalFence00",
		"FixedTown/Props/EastVerticalFence00",
		"FixedTown/Interactables/CampfirePlaceholder",
	]:
		if scene.get_node_or_null(removed_path) != null:
			_fail("legacy_node_still_present=%s" % removed_path)
			return false
	return true


func _validate_fence_orientation(scene: Node) -> bool:
	var north_sprite := scene.get_node("FixedTown/Props/NorthFence00/Sprite2D") as Sprite2D
	var west_sprite := scene.get_node("FixedTown/Props/WestSideFence00/Sprite2D") as Sprite2D
	if north_sprite == null or west_sprite == null:
		_fail("missing_fence_sprite")
		return false
	if absf(west_sprite.rotation) > 0.01:
		_fail("side_fence_should_not_be_rotated rotation=%.2f" % west_sprite.rotation)
		return false
	if west_sprite.texture == null or not west_sprite.texture.resource_path.contains("wood_fence_side_pixellab"):
		_fail("side_fence_not_using_pixellab_asset path=%s" % (west_sprite.texture.resource_path if west_sprite.texture != null else "<null>"))
		return false
	if north_sprite.texture == west_sprite.texture:
		_fail("side_fence_reused_front_fence_texture")
		return false
	return true


func _validate_interaction_placeholder(scene: Node) -> bool:
	var area := scene.get_node("FixedTown/NPCPlaceholders/QuestGiverPlaceholder/InteractionArea") as Area2D
	if area == null:
		_fail("missing_interaction_area")
		return false
	if area.collision_layer != 0 or area.collision_mask != COLLISION_LAYERS.PLAYER:
		_fail("interaction_collision layer=%d mask=%d" % [area.collision_layer, area.collision_mask])
		return false
	var label := scene.get_node("FixedTown/NPCPlaceholders/QuestGiverPlaceholder/QuestHintLabel") as Label
	if label == null or not label.text.contains("Clear the den"):
		_fail("quest_hint_label_bad")
		return false
	var npc_idle := scene.get_node("FixedTown/NPCPlaceholders/QuestGiverPlaceholder/AnimatedSprite2D") as AnimatedSprite2D
	if npc_idle == null or npc_idle.sprite_frames == null or npc_idle.sprite_frames.get_frame_count("idle") < 4:
		_fail("npc_idle_animation_missing")
		return false
	var campfire_idle := scene.get_node("FixedTown/Interactables/CampfireIdle/AnimatedSprite2D") as AnimatedSprite2D
	if campfire_idle == null or campfire_idle.sprite_frames == null or campfire_idle.sprite_frames.get_frame_count("idle") < 5:
		_fail("campfire_idle_animation_missing")
		return false
	return true


func _validate_gate_and_bounds_motion(scene: Node) -> bool:
	var player := scene.get_node_or_null("WorldEntities/KnightPlayer") as CharacterBody2D
	if player == null:
		_fail("missing_player")
		return false
	var exit: Vector2 = scene.call("get_town_exit_socket_position")
	var interior := exit + Vector2(0, -150)
	var outside := exit + Vector2(0, 270)
	if not _motion_is_clear(player, interior, outside - interior):
		_fail("gate_middle_blocked from=%s to=%s" % [str(interior), str(outside)])
		return false
	if _motion_is_clear(player, exit + Vector2(-360, -70), Vector2(0, 290)):
		_fail("south_left_fence_not_blocking")
		return false
	if _motion_is_clear(player, exit + Vector2(360, -70), Vector2(0, 290)):
		_fail("south_right_fence_not_blocking")
		return false
	if _motion_is_clear(player, scene.call("get_town_spawn_position"), Vector2(-900, 0)):
		_fail("west_bounds_not_blocking")
		return false
	if _motion_is_clear(player, scene.call("get_town_spawn_position"), Vector2(900, 0)):
		_fail("east_bounds_not_blocking")
		return false
	return true


func _motion_is_clear(player: CharacterBody2D, from_position: Vector2, motion: Vector2) -> bool:
	var original := player.global_transform
	var params := PhysicsTestMotionParameters2D.new()
	params.from = Transform2D(player.global_rotation, from_position)
	params.motion = motion
	var result := PhysicsTestMotionResult2D.new()
	var blocked := PhysicsServer2D.body_test_motion(player.get_rid(), params, result)
	player.global_transform = original
	return not blocked


func _wait_for_scene() -> bool:
	for _i in range(40):
		await process_frame
		if current_scene != null and current_scene.name == "MainWorld":
			return true
	return false


func _fail(message: String) -> void:
	print("Task30CampAssembly smoke: FAIL %s" % message)
	quit(1)
