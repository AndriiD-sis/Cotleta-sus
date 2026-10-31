extends Area3D

@export var target: Node3D
@export var task_ui: Control

var task_id := ""
var local_player: CharacterBody3D = null
var active := false
var highlight := StandardMaterial3D.new()

func _ready() -> void:
	add_to_group("tasks")
	task_id = str(get_path())
	if target == null:
		target = get_parent()
	highlight.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight.albedo_color = Color(1, 1, 1, 0.15)
	highlight.emission_enabled = true
	highlight.emission = Color(1, 0.9, 0.3)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _main() -> Node:
	return get_tree().current_scene

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		local_player = body
		_set_highlight(_main().is_my_task(task_id))

func _on_body_exited(body: Node3D) -> void:
	if body == local_player:
		if active:
			_close()
		local_player = null
		_set_highlight(false)

func _input(event: InputEvent) -> void:
	if local_player == null:
		return
	if active:
		if event.is_action_pressed("ui_cancel"):
			_close()
	elif local_player.controls_enabled and event.is_action_pressed("ui_use") and _main().is_my_task(task_id):
		_open()

func _open() -> void:
	active = true
	local_player.set_controls_enabled(false)
	task_ui.completed.connect(_on_completed, CONNECT_ONE_SHOT)
	task_ui.open()

func _close() -> void:
	active = false
	if task_ui.completed.is_connected(_on_completed):
		task_ui.completed.disconnect(_on_completed)
	task_ui.hide()
	local_player.set_controls_enabled(true)

func _on_completed() -> void:
	active = false
	local_player.set_controls_enabled(true)
	_set_highlight(false)
	_main().finish_task(task_id)

func _set_highlight(on: bool) -> void:
	var meshes := target.find_children("*", "MeshInstance3D", true, false)
	if target is MeshInstance3D:
		meshes.append(target)
	for m in meshes:
		m.material_overlay = highlight if on else null
