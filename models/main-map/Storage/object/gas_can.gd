extends Control

signal completed

const POUR_TIME := 10.0
const CLOSE_DELAY := 3.0

@onready var left: ProgressBar = $LeftFlask
@onready var right: ProgressBar = $RightFlask
@onready var pour_button: Button = $Pour

var poured := 0.0
var done := false
var run := 0

func _ready() -> void:
	left.max_value = 100
	right.max_value = 100
	hide()

func open() -> void:
	run += 1
	poured = 0.0
	done = false
	pour_button.disabled = false
	_update_bars()
	show()

func _process(delta: float) -> void:
	if not visible or done or not pour_button.button_pressed:
		return
	poured += delta / POUR_TIME * 100.0
	_update_bars()
	if poured >= 100.0:
		_finish()

func _update_bars() -> void:
	left.value = poured
	right.value = 100.0 - poured

func _finish() -> void:
	done = true
	pour_button.disabled = true
	var my_run := run
	await get_tree().create_timer(CLOSE_DELAY).timeout
	if my_run != run or not visible:
		return
	hide()
	completed.emit()
