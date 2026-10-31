extends Control

signal completed

const CLOSE_DELAY := 3.0

@onready var button: Button = $Redirect

var run := 0

func _ready() -> void:
	button.toggle_mode = true
	button.toggled.connect(_on_toggled)
	hide()

func open() -> void:
	run += 1
	button.set_pressed_no_signal(false)
	show()

func _on_toggled(on: bool) -> void:
	if not on:
		button.set_pressed_no_signal(true)
		return
	var my_run := run
	await get_tree().create_timer(CLOSE_DELAY).timeout
	if my_run != run or not visible:
		return
	hide()
	completed.emit()
