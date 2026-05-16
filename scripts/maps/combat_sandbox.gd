extends Node2D

const MUMMY_SCENE := preload("res://scenes/enemy/mummy_enemy.tscn")
const RESPAWN_DELAY := 4.0

@onready var player: Node2D = $KnightPlayer
@onready var enemies_root: Node2D = $Enemies
@onready var debug_label: Label = $DebugCanvas/DebugLabel

var respawn_pending := false


func _ready() -> void:
	_spawn_wave()


func _process(_delta: float) -> void:
	_update_debug_label()
	if respawn_pending:
		return
	if get_tree().get_nodes_in_group("enemy").is_empty():
		respawn_pending = true
		await get_tree().create_timer(RESPAWN_DELAY).timeout
		_spawn_wave()
		respawn_pending = false


func _spawn_wave() -> void:
	_clear_enemies()
	_spawn_mummy("MummyDummy", $EnemySpawns/DummySpawn.global_position, 25, 0.0, 0, 42.0, 36.0, 2.0, 2.6)
	_spawn_mummy("MummyGrunt", $EnemySpawns/GruntSpawn.global_position, 55, 68.0, 10, 54.0, 46.0, 1.1, 3.0)
	_spawn_mummy("MummyBrute", $EnemySpawns/BruteSpawn.global_position, 95, 48.0, 18, 60.0, 52.0, 1.35, 3.35)


func _clear_enemies() -> void:
	for child in enemies_root.get_children():
		child.queue_free()


func _spawn_mummy(
	enemy_name: String,
	spawn_position: Vector2,
	max_hp: int,
	move_speed: float,
	attack_damage: int,
	attack_range: float,
	preferred_distance: float,
	attack_cooldown: float,
	display_scale: float
) -> void:
	var enemy := MUMMY_SCENE.instantiate()
	enemy.name = enemy_name
	enemy.global_position = spawn_position
	enemy.max_hp = max_hp
	enemy.move_speed = move_speed
	enemy.attack_damage = attack_damage
	enemy.attack_range = attack_range
	enemy.preferred_distance = preferred_distance
	enemy.attack_cooldown = attack_cooldown
	enemy.display_scale = display_scale
	enemies_root.add_child(enemy)


func _update_debug_label() -> void:
	var enemy_count := get_tree().get_nodes_in_group("enemy").size()
	var hp_text := "?"
	var damage_text := "?"
	var facing_text := "?"
	var action_text := "?"
	if is_instance_valid(player):
		var hp_value = player.get("hp")
		hp_text = str(hp_value) if hp_value != null else "?"
		if player.has_method("get_current_attack_damage"):
			damage_text = str(player.get_current_attack_damage())
		if player.has_method("get_facing_direction"):
			facing_text = _format_vector(player.get_facing_direction())
		if player.has_method("get_action_direction"):
			action_text = _format_vector(player.get_action_direction())
	debug_label.text = "Enemies: %d\nHP: %s\nDamage: %s\nFacing: %s\nAction: %s" % [enemy_count, hp_text, damage_text, facing_text, action_text]


func _format_vector(value: Vector2) -> String:
	return "(%.2f, %.2f)" % [value.x, value.y]
