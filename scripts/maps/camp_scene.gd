extends Node2D

const OUTDOOR_COLLISION := preload("res://scripts/physics/outdoor_collision.gd")
const COLLISION_LAYERS := preload("res://scripts/physics/collision_layers.gd")

const DEFAULT_OUTDOOR_SCENE_PATH := "res://scenes/maps/first_outdoor_generated.tscn"
const CAMP_CAMERA_ZOOM := Vector2(1.45, 1.45)
const CAMP_BOUNDS := Rect2(Vector2(160, 140), Vector2(1600, 900))

@export_file("*.tscn") var transition_target_path := DEFAULT_OUTDOOR_SCENE_PATH
@export var target_spawn_marker := "CampEntranceSpawn"
@export_file("*.tscn") var return_scene_path := "res://scenes/maps/camp_scene.tscn"
@export var return_spawn_marker := "CampSpawn"
@export var auto_transition_on_exit := true

@onready var player: CharacterBody2D = $WorldEntities/KnightPlayer
@onready var camp_spawn: Marker2D = $CampSpawn
@onready var camp_exit_to_outdoor: Area2D = $CampExitToOutdoor
@onready var camp_bounds: StaticBody2D = $CampBounds

var transition_requested := false


func _ready() -> void:
	_apply_player_contract()
	_place_player_at_spawn()
	_setup_exit_area()


func _apply_player_contract() -> void:
	if player == null:
		return
	OUTDOOR_COLLISION.apply_player_body(player)
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.zoom = CAMP_CAMERA_ZOOM
		camera.limit_left = int(CAMP_BOUNDS.position.x)
		camera.limit_top = int(CAMP_BOUNDS.position.y)
		camera.limit_right = int(CAMP_BOUNDS.end.x)
		camera.limit_bottom = int(CAMP_BOUNDS.end.y)


func _place_player_at_spawn() -> void:
	if player == null or camp_spawn == null:
		return
	player.global_position = camp_spawn.global_position


func _setup_exit_area() -> void:
	if camp_exit_to_outdoor == null:
		return
	camp_exit_to_outdoor.collision_layer = 0
	camp_exit_to_outdoor.collision_mask = COLLISION_LAYERS.PLAYER
	if not camp_exit_to_outdoor.body_entered.is_connected(_on_camp_exit_body_entered):
		camp_exit_to_outdoor.body_entered.connect(_on_camp_exit_body_entered)


func _on_camp_exit_body_entered(body: Node2D) -> void:
	if not auto_transition_on_exit:
		return
	if body == player or body.is_in_group("player"):
		transition_to_outdoor()


func transition_to_outdoor() -> Error:
	transition_requested = true
	if transition_target_path.is_empty() or not ResourceLoader.exists(transition_target_path):
		push_error("CampScene transition target missing: %s" % transition_target_path)
		return ERR_FILE_NOT_FOUND
	return get_tree().change_scene_to_file(transition_target_path)


func get_transition_target_path() -> String:
	return transition_target_path


func get_transition_payload() -> Dictionary:
	return {
		"target_scene": transition_target_path,
		"target_spawn_anchor": target_spawn_marker,
		"return_scene": return_scene_path,
		"return_spawn_anchor": return_spawn_marker,
	}


func get_spawn_position() -> Vector2:
	return camp_spawn.global_position if camp_spawn != null else Vector2.ZERO


func get_exit_position() -> Vector2:
	return camp_exit_to_outdoor.global_position if camp_exit_to_outdoor != null else Vector2.ZERO


func get_camp_bounds_rect() -> Rect2:
	return CAMP_BOUNDS


func get_contract_node_names() -> Array[String]:
	return [
		"CampSpawn",
		"CampExitToOutdoor",
		"CampBounds",
		"WorldEntities/KnightPlayer",
		"NPCPlaceholders/QuestGiverPlaceholder",
		"Interactables/StashPlaceholder",
		"Interactables/WaypointPlaceholder",
	]


func get_camp_bounds_shape_count() -> int:
	if camp_bounds == null:
		return 0
	var count := 0
	for child in camp_bounds.get_children():
		if child is CollisionShape2D:
			count += 1
	return count
