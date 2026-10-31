extends Control

signal completed

const HOLD_TIME := 10.0
const CLOSE_DELAY := 3.0

@onready var button: Button = $CastOut

var held := 0.0
var done := false
var run := 0

func open() -> void:
	run += 1
	held = 0.0
	done = false
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.remove_theme_stylebox_override("normal")
	button.remove_theme_stylebox_override("hover")
	show()

func _ready() -> void:
	hide()

func _process(delta: float) -> void:
	if not visible or done:
		return
	if button.button_pressed:
		held += delta
		if held >= HOLD_TIME:
			_hold_complete()

func _hold_complete() -> void:
	done = true
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pressed_style := button.get_theme_stylebox("pressed")
	button.add_theme_stylebox_override("normal", pressed_style)
	button.add_theme_stylebox_override("hover", pressed_style)
	var my_run := run
	await get_tree().create_timer(CLOSE_DELAY).timeout
	if my_run != run or not visible:
		return
	hide()
	completed.emit()
