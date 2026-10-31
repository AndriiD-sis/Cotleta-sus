extends Area3D

@export var target: Node3D
@export var button: Button

var local_player: CharacterBody3D = null
var highlight := StandardMaterial3D.new()

func _ready() -> void:
	highlight.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight.albedo_color = Color(1, 1, 1, 0.15)
	highlight.emission_enabled = true
	highlight.emission = Color(1, 0.9, 0.3)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	button.pressed.connect(_on_button_pressed)
	button.hide()

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		local_player = body
		_set_highlight(true)

func _on_body_exited(body: Node3D) -> void:
	if body == local_player:
		local_player = null
		_set_highlight(false)

func _input(event: InputEvent) -> void:
	if local_player and local_player.controls_enabled and event.is_action_pressed("ui_use"):
		local_player.set_controls_enabled(false)
		button.show()

func _on_button_pressed() -> void:
	button.hide()
	get_tree().current_scene.request_teleport.rpc_id(1)

func _set_highlight(on: bool) -> void:
	var meshes := target.find_children("*", "MeshInstance3D", true, false)
	if target is MeshInstance3D:
		meshes.append(target)
	for m in meshes:
		m.material_overlay = highlight if on else null
