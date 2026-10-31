extends Area3D

@export var stand_point: Node3D

func _ready() -> void:
	add_to_group("vents")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func spot() -> Vector3:
	return (stand_point if stand_point else self).global_position

func _on_enter(body: Node3D) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		body.near_vent = self

func _on_exit(body: Node3D) -> void:
	if body is CharacterBody3D and body.near_vent == self:
		body.near_vent = null
