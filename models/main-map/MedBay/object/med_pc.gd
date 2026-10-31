extends Control

signal completed

const CLOSE_DELAY := 3.0
const WAIT_TIME := 60.0

@onready var start_button: Button = $Start
@onready var time_label: Label = $TimeLabel
@onready var buttons: Array = [$B1, $B2, $B3, $B4]

var time_left := 0.0
var counting := false
var red: Button = null
var run := 0

func _ready() -> void:
	start_button.pressed.connect(_on_start)
	for b in buttons:
		b.pressed.connect(_on_button.bind(b))
	hide()

func open() -> void:
	run += 1
	counting = false
	red = null
	time_left = WAIT_TIME
	time_label.text = str(int(WAIT_TIME))
	start_button.disabled = false
	for b in buttons:
		b.disabled = true
		b.modulate = Color.WHITE
	show()

func _on_start() -> void:
	start_button.disabled = true
	counting = true

func _process(delta: float) -> void:
	if not counting or not visible:
		return
	time_left -= delta
	time_label.text = str(ceili(time_left))
	if time_left <= 0.0:
		counting = false
		time_label.text = "0"
		red = buttons.pick_random()
		red.modulate = Color.RED
		red.disabled = false

func _on_button(b: Button) -> void:
	if b != red:
		return
	red.disabled = true
	var my_run := run
	await get_tree().create_timer(CLOSE_DELAY).timeout
	if my_run != run or not visible:
		return
	hide()
	completed.emit()
