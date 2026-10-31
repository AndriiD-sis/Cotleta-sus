extends Control

signal completed

const TARGET := 50.0
const TOLERANCE := 5.0
const CLOSE_DELAY := 3.0

@onready var slider: VSlider = $VSlider

var run := 0

func _ready() -> void:
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 0.1
	slider.drag_ended.connect(_on_drag_ended)
	hide()

func open() -> void:
	run += 1
	slider.editable = true
	slider.value = randf_range(0.0, 30.0) if randf() < 0.5 else randf_range(70.0, 100.0)
	show()

func _on_drag_ended(_changed: bool) -> void:
	if absf(slider.value - TARGET) > TOLERANCE:
		return
	slider.editable = false
	slider.value = TARGET
	var my_run := run
	await get_tree().create_timer(CLOSE_DELAY).timeout
	if my_run != run or not visible:
		return
	hide()
	completed.emit()
