extends Control

signal completed

const CLOSE_DELAY := 3.0

@onready var leaves: Array = get_children().filter(func(c): return c is BaseButton)

var left := 0
var run := 0

func _ready() -> void:
	for l in leaves:
		l.pressed.connect(_on_leaf.bind(l))
	hide()

func open() -> void:
	run += 1
	left = leaves.size()
	for l in leaves:
		l.show()
	show()

func _on_leaf(l: BaseButton) -> void:
	l.hide()
	left -= 1
	if left > 0:
		return
	var my_run := run
	await get_tree().create_timer(CLOSE_DELAY).timeout
	if my_run != run or not visible:
		return
	hide()
	completed.emit()
