extends "res://task_station.gd"

@export var stand_point: Node3D
@export var beam: Node3D
@export var travel := 0.6

const SCAN_TIME := 15.0

@onready var beam_top: float = beam.position.y
var busy := false

func _open() -> void:
	if busy:
		return
	var p := local_player
	p.set_controls_enabled(false)
	if stand_point:
		p.teleport_to(stand_point.global_position, stand_point.global_rotation.y)
	play_scan.rpc()
	await get_tree().create_timer(SCAN_TIME).timeout
	p.set_controls_enabled(true)
	_set_highlight(false)
	_main().finish_task(task_id)

@rpc("any_peer", "call_local", "reliable")
func play_scan() -> void:
	busy = true
	beam.show()
	var tw := create_tween()
	tw.tween_property(beam, "position:y", beam_top - travel, SCAN_TIME / 2.0)
	tw.tween_property(beam, "position:y", beam_top, SCAN_TIME / 2.0)
	tw.tween_callback(_scan_end)

func _scan_end() -> void:
	beam.hide()
	busy = false
