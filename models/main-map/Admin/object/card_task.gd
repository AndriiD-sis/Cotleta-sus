extends Control

signal completed

const CLOSE_DELAY := 3.0

@onready var slot: Control = $Slot
@onready var end_mark: Control = $EndMark
@onready var card: Button = $Card

var start_local := Vector2.ZERO
var dragging := false
var done := false
var run := 0

func _ready() -> void:
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_local = card.position
	card.button_down.connect(func(): dragging = true)
	card.button_up.connect(_on_release)
	hide()

func open() -> void:
	run += 1
	done = false
	dragging = false
	card.disabled = false
	card.position = start_local
	show()

func _max_x() -> float:
	return slot.global_position.x + slot.size.x - card.size.x

func _process(_delta: float) -> void:
	if not dragging or done:
		return
	var x := get_global_mouse_position().x - card.size.x / 2.0
	x = clampf(x, slot.global_position.x, _max_x())
	card.global_position = Vector2(x, card.global_position.y)

func _on_release() -> void:
	dragging = false
	if done:
		return
	if card.global_position.x + card.size.x < end_mark.global_position.x:
		card.position = start_local
		return
	done = true
	card.global_position = Vector2(_max_x(), card.global_position.y)
	card.disabled = true
	var my_run := run
	await get_tree().create_timer(CLOSE_DELAY).timeout
	if my_run != run or not visible:
		return
	hide()
	completed.emit()
