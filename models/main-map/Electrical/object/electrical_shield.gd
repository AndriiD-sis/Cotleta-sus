extends Control

signal completed

const CLOSE_DELAY := 3.0

@onready var sliders: Array = [$HSlider, $HSlider2, $HSlider3]
@onready var greens: Array = [$Green, $Green2, $Green3]

var zones: Array = []
var run := 0

func _ready() -> void:
	for i in sliders.size():
		var s: HSlider = sliders[i]
		s.min_value = 0
		s.max_value = 100
		s.step = 0.1
		s.value_changed.connect(_on_value_changed)
		greens[i].mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func open() -> void:
	run += 1
	show()
	await get_tree().process_frame
	_calc_zones()
	for i in sliders.size():
		var mid: float = (zones[i].x + zones[i].y) / 2.0
		sliders[i].editable = true
		sliders[i].set_value_no_signal(100.0 if mid < 50.0 else 0.0)

func _calc_zones() -> void:
	zones.clear()
	for i in sliders.size():
		var s: HSlider = sliders[i]
		var g: Control = greens[i]
		var grab := float(s.get_theme_icon("grabber").get_width())
		var track := s.size.x - grab
		var left := g.global_position.x - s.global_position.x - grab * 0.5
		zones.append(Vector2(
			clampf(left / track * 100.0, 0.0, 100.0),
			clampf((left + g.size.x) / track * 100.0, 0.0, 100.0)))

func _on_value_changed(_v: float) -> void:
	if zones.is_empty():
		return
	for i in sliders.size():
		var v: float = sliders[i].value
		if v < zones[i].x or v > zones[i].y:
			return
	_finish()

func _finish() -> void:
	for s in sliders:
		s.editable = false
	var my_run := run
	await get_tree().create_timer(CLOSE_DELAY).timeout
	if my_run != run or not visible:
		return
	hide()
	completed.emit()
