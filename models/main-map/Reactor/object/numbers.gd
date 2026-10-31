extends Control

signal completed

const CLOSE_DELAY := 3.0

@onready var buttons: Array = find_children("*", "Button", true, false)

var next_number := 1
var run := 0

func _ready() -> void:
	for b in buttons:
		b.toggle_mode = true
		b.toggled.connect(_on_toggled.bind(b))
	hide()

func open() -> void:
	run += 1
	var numbers := range(1, buttons.size() + 1)
	numbers.shuffle()
	for i in buttons.size():
		buttons[i].set_meta("n", numbers[i])
		buttons[i].text = str(numbers[i])
	_reset_buttons()
	show()

func _reset_buttons() -> void:
	next_number = 1
	for b in buttons:
		b.set_pressed_no_signal(false)

func _on_toggled(on: bool, b: Button) -> void:
	if not on:
		b.set_pressed_no_signal(true)
		return
	if b.get_meta("n") != next_number:
		_reset_buttons()
		return
	next_number += 1
	if next_number <= buttons.size():
		return
	var my_run := run
	await get_tree().create_timer(CLOSE_DELAY).timeout
	if my_run != run or not visible:
		return
	hide()
	completed.emit()
