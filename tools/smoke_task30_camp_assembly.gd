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
	if not _validate_gate_fence_joins(scene):
		return
	if not _validate_interaction_placeholder(scene):
		return
	if not _validate_visible_foot_alignment(scene):
		return
	if not _validate_fixed_town_z_sort(scene):
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
		"FixedTown/Props/SouthWestFenceGateJoin",
		"FixedTown/Props/SouthEastFenceGateJoin",
		"FixedTown/Props/SouthEastFenceCornerJoin",
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
	var right_gate := scene.get_node("FixedTown/Props/CampGateRightPost/Sprite2D") as Sprite2D
	if right_gate == null or not right_gate.flip_h or absf(right_gate.rotation) > 0.01:
		_fail("right_gate_should_be_mirrored_not_rotated")
		return false
	var north_shape := scene.get_node("FixedTown/Props/NorthFence00/CollisionShape2D") as CollisionShape2D
	if north_shape == null or not (north_shape.shape is CapsuleShape2D):
		_fail("north_fence_collision_missing_capsule")
		return false
	var north_capsule := north_shape.shape as CapsuleShape2D
	if north_capsule.height > 82.0:
		_fail("north_fence_collision_too_long=%.2f" % north_capsule.height)
		return false
	return true


func _validate_gate_fence_joins(scene: Node) -> bool:
	var left_gate := scene.get_node("FixedTown/Props/CampGateLeftPost") as Node2D
	var right_gate := scene.get_node("FixedTown/Props/CampGateRightPost") as Node2D
	var left_join := scene.get_node("FixedTown/Props/SouthWestFenceGateJoin") as Node2D
	var right_join := scene.get_node("FixedTown/Props/SouthEastFenceGateJoin") as Node2D
	var right_corner_join := scene.get_node("FixedTown/Props/SouthEastFenceCornerJoin") as Node2D
	if left_gate == null or right_gate == null or left_join == null or right_join == null or right_corner_join == null:
		_fail("missing_gate_join_node")
		return false
	var left_spacing := left_gate.global_position.x - left_join.global_position.x
	var right_spacing := right_join.global_position.x - right_gate.global_position.x
	if absf(left_spacing - right_spacing) > 4.0:
		_fail("gate_join_asymmetry left=%.2f right=%.2f" % [left_spacing, right_spacing])
		return false
	if absf(left_gate.global_position.y - right_gate.global_position.y) > 1.0:
		_fail("gate_posts_not_level")
		return false
	if absf(left_join.global_position.y - right_join.global_position.y) > 1.0:
		_fail("gate_joins_not_level")
		return false
	if right_corner_join.global_position.x <= right_join.global_position.x:
		_fail("south_east_corner_join_not_after_gate_join")
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
	var stash_shape := scene.get_node("FixedTown/Interactables/StashPlaceholder/CollisionShape2D") as CollisionShape2D
	if stash_shape == null or not (stash_shape.shape is RectangleShape2D):
		_fail("stash_collision_missing_rect")
		return false
	var stash_rect := stash_shape.shape as RectangleShape2D
	if stash_shape.position.y >= -2.0 or stash_rect.size.x > 58.0 or stash_rect.size.y > 28.0:
		_fail("stash_collision_not_using_footprint size=%s offset=%s" % [str(stash_rect.size), str(stash_shape.position)])
		return false
	var campfire_shape := scene.get_node("FixedTown/Interactables/CampfireIdle/CollisionShape2D") as CollisionShape2D
	if campfire_shape == null or not (campfire_shape.shape is RectangleShape2D):
		_fail("campfire_collision_missing_rect")
		return false
	var campfire_rect := campfire_shape.shape as RectangleShape2D
	if campfire_shape.position.y >= -2.0 or campfire_rect.size.x > 42.0 or campfire_rect.size.y > 26.0:
		_fail("campfire_collision_not_using_footprint size=%s offset=%s" % [str(campfire_rect.size), str(campfire_shape.position)])
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


func _validate_fixed_town_z_sort(scene: Node) -> bool:
	var stash := scene.get_node("FixedTown/Interactables/StashPlaceholder") as CanvasItem
	var campfire := scene.get_node("FixedTown/Interactables/CampfireIdle") as CanvasItem
	var npc := scene.get_node("FixedTown/NPCPlaceholders/QuestGiverPlaceholder") as CanvasItem
	if stash == null or campfire == null or npc == null:
		_fail("missing_z_sort_targets")
		return false
	if stash.z_as_relative or campfire.z_as_relative or npc.z_as_relative:
		_fail("fixed_town_dynamic_items_should_use_absolute_z")
		return false
	var stash_body := stash as Node2D
	var campfire_body := campfire as Node2D
	if stash_body != null and campfire_body != null and stash_body.global_position.y < campfire_body.global_position.y and stash.z_index >= campfire.z_index:
		_fail("fixed_town_z_order_not_collision_bottom_based stash=%d campfire=%d" % [stash.z_index, campfire.z_index])
		return false
	return true


func _validate_visible_foot_alignment(scene: Node) -> bool:
	for path in [
		"FixedTown/Interactables/StashPlaceholder",
		"FixedTown/Interactables/WaypointPlaceholder",
		"FixedTown/Interactables/CampfireIdle",
		"FixedTown/Props/CampSupplyStack",
	]:
		var body := scene.get_node(path) as Node2D
		if body == null:
			_fail("missing_alignment_target=%s" % path)
			return false
		var visual_bottom := _visual_bottom_y(body)
		var collision_bottom := _collision_bottom_y(body)
		if absf(visual_bottom - collision_bottom) > 2.0:
			_fail("visible_collision_foot_mismatch path=%s visual=%.2f collision=%.2f" % [path, visual_bottom, collision_bottom])
			return false
	return true


func _visual_bottom_y(body: Node2D) -> float:
	var sprite := body.get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null and sprite.texture != null:
		return _sprite_visible_bottom_y(sprite, sprite.texture)
	var animated := body.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated != null and animated.sprite_frames != null:
		var texture := animated.sprite_frames.get_frame_texture("idle", 0)
		if texture != null:
			return _sprite_visible_bottom_y(animated, texture)
	return body.global_position.y


func _sprite_visible_bottom_y(item: Node2D, texture: Texture2D) -> float:
	var visible := _texture_visible_bounds(texture)
	var half_size := texture.get_size() * 0.5
	var local_bottom := Vector2(visible.position.x + visible.size.x * 0.5, visible.end.y) - half_size
	return (item.global_transform * local_bottom).y


func _texture_visible_bounds(texture: Texture2D) -> Rect2:
	var image := texture.get_image()
	if image == null:
		return Rect2(Vector2.ZERO, texture.get_size())
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.05:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2(Vector2.ZERO, texture.get_size())
	return Rect2(float(min_x), float(min_y), float(max_x - min_x + 1), float(max_y - min_y + 1))


func _collision_bottom_y(body: Node2D) -> float:
	var bottom := -INF
	for child in body.get_children():
		var shape_node := child as CollisionShape2D
		if shape_node != null and shape_node.shape != null:
			bottom = maxf(bottom, _shape_bottom_y(shape_node))
	return bottom if bottom > -INF else body.global_position.y


func _shape_bottom_y(shape_node: CollisionShape2D) -> float:
	if shape_node.shape is RectangleShape2D:
		var rectangle := shape_node.shape as RectangleShape2D
		return shape_node.global_position.y + rectangle.size.y * 0.5
	if shape_node.shape is CircleShape2D:
		var circle := shape_node.shape as CircleShape2D
		return shape_node.global_position.y + circle.radius
	if shape_node.shape is CapsuleShape2D:
		var capsule := shape_node.shape as CapsuleShape2D
		if absf(shape_node.global_rotation) > 0.5:
			return shape_node.global_position.y + capsule.radius
		return shape_node.global_position.y + capsule.height * 0.5
	return shape_node.global_position.y


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
