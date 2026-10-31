extends Control

signal completed

const CLOSE_DELAY := 3.0

@onready var ship: Control = $Ship
@onready var points: Array = get_children().filter(func(c): return c is BaseButton)

var start_pos := Vector2.ZERO
var step := 0
var run := 0

func _ready() -> void:
	ship.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_pos = ship.position
	for i in points.size():
		points[i].pressed.connect(_on_point.bind(i))
	hide()

func open() -> void:
	run += 1
	step = 0
	ship.position = start_pos
	_refresh()
	show()

func _refresh() -> void:
	for i in points.size():
		points[i].disabled = i != step
		if i == step:
			points[i].modulate = Color.YELLOW
		elif i < step:
			points[i].modulate = Color(0.5, 1.0, 0.5)
		else:
			points[i].modulate = Color.WHITE

func _on_point(i: int) -> void:
	ship.position = points[i].position + points[i].size / 2.0 - ship.size / 2.0
	step += 1
	_refresh()
	if step < points.size():
		return
	var my_run := run
	await get_tree().create_timer(CLOSE_DELAY).timeout
	if my_run != run or not visible:
		return
	hide()
	completed.emit()
