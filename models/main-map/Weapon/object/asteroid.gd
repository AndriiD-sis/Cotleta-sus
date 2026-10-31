extends Control

signal completed

const CLOSE_DELAY := 3.0

@onready var meteors: Array = get_children().filter(func(c): return c is BaseButton)

var left := 0
var run := 0

func _ready() -> void:
	for m in meteors:
		m.pressed.connect(_on_meteor.bind(m))
	hide()

func open() -> void:
	run += 1
	left = meteors.size()
	for m in meteors:
		m.show()
	show()

func _on_meteor(m: BaseButton) -> void:
	m.hide()
	left -= 1
	if left > 0:
		return
	var my_run := run
	await get_tree().create_timer(CLOSE_DELAY).timeout
	if my_run != run or not visible:
		return
	hide()
	completed.emit()
