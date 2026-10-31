extends Control

signal completed

const CLOSE_DELAY := 3.0

@onready var buttons: Array = $HBoxContainer.get_children()

var run := 0

func _ready() -> void:
	for b in buttons:
		b.toggle_mode = true
		b.toggled.connect(_on_toggled.bind(b))
	hide()

func open() -> void:
	run += 1
	for b in buttons:
		b.set_pressed_no_signal(false)
	show()

func _on_toggled(on: bool, b: Button) -> void:
	if not on:
		b.set_pressed_no_signal(true)
		return
	if not buttons.all(func(x): return x.button_pressed):
		return
	var my_run := run
	await get_tree().create_timer(CLOSE_DELAY).timeout
	if my_run != run or not visible:
		return
	hide()
	completed.emit()
