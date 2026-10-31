extends Control

signal completed

const SNAP_DISTANCE := 20.0
const MIN_START_DISTANCE := 150.0
const CLOSE_DELAY := 3.0

@onready var field: Control = $Field
@onready var center: Control = $Center
@onready var crosshair: Button = $Crosshair

var dragging := false
var done := false
var run := 0

func _ready() -> void:
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair.button_down.connect(func(): dragging = true)
	crosshair.button_up.connect(_on_release)
	hide()

func open() -> void:
	run += 1
	done = false
	dragging = false
	crosshair.disabled = false
	show()
	await get_tree().process_frame
	_place_random()

func _center_of(n: Control) -> Vector2:
	return n.global_position + n.size / 2.0

func _place_random() -> void:
	var c := _center_of(center)
	for _i in 20:
		var p := field.global_position + Vector2(randf() * field.size.x, randf() * field.size.y)
		if p.distance_to(c) >= MIN_START_DISTANCE:
			crosshair.global_position = p - crosshair.size / 2.0
			return

func _process(_delta: float) -> void:
	if not dragging or done:
		return
	var p := get_global_mouse_position()
	p.x = clampf(p.x, field.global_position.x, field.global_position.x + field.size.x)
	p.y = clampf(p.y, field.global_position.y, field.global_position.y + field.size.y)
	crosshair.global_position = p - crosshair.size / 2.0

func _on_release() -> void:
	dragging = false
	if done:
		return
	if _center_of(crosshair).distance_to(_center_of(center)) > SNAP_DISTANCE:
		return
	done = true
	crosshair.global_position = _center_of(center) - crosshair.size / 2.0
	crosshair.disabled = true
	var my_run := run
	await get_tree().create_timer(CLOSE_DELAY).timeout
	if my_run != run or not visible:
		return
	hide()
	completed.emit()
