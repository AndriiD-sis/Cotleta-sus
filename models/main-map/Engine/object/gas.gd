extends Control

signal completed

const FILL_TIME := 10.0
const DRAIN_RATE := 0.3
const CLOSE_DELAY := 3.0

@onready var bar: ProgressBar = $ProgressBar
@onready var fill_button: Button = $Fill

var level := 0.0
var done := false
var run := 0

func _ready() -> void:
	bar.min_value = 0
	bar.max_value = 100
	hide()

func open() -> void:
	run += 1
	level = 0.0
	done = false
	bar.value = 0
	fill_button.disabled = false
	show()

func _process(delta: float) -> void:
	if not visible or done:
		return
	if fill_button.button_pressed:
		level += delta / FILL_TIME * 100.0
	else:
		level -= delta / FILL_TIME * 100.0 * DRAIN_RATE
	level = clampf(level, 0.0, 100.0)
	bar.value = level
	if level >= 100.0:
		_finish()

func _finish() -> void:
	done = true
	fill_button.disabled = true
	var my_run := run
	await get_tree().create_timer(CLOSE_DELAY).timeout
	if my_run != run or not visible:
		return
	hide()
	completed.emit()
