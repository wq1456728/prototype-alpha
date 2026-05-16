extends Area2D

@export var damage_bonus := 8

var picked_up := false


func _ready() -> void:
	add_to_group("loot")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if picked_up:
		return
	if not body.has_method("add_damage_bonus"):
		return
	picked_up = true
	body.add_damage_bonus(damage_bonus)
	queue_free()
