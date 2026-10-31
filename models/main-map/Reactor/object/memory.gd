extends Control

signal completed

const ROUNDS := 4
const START_DELAY := 1.0
const FLASH_TIME := 0.5
const GAP_TIME := 0.3
const ROUND_PAUSE := 0.8
const CLOSE_DELAY := 3.0
const LIT := Color(0.3, 0.5, 1.0)

@onready var buttons: Array = get_children().filter(func(c): return c is BaseButton)

var sequence: Array = []
var round_num := 1
var step := 0
var accepting := false
var run := 0

func _ready() -> void:
	for i in buttons.size():
		buttons[i].pressed.connect(_on_pressed.bind(i))
	hide()

func open() -> void:
	run += 1
	for b in buttons:
		b.modulate = Color.WHITE
	show()
	await _start_game()

func _start_game() -> void:
	var my_run := run
	accepting = false
	var order := range(buttons.size())
	order.shuffle()
	sequence = order.slice(0, ROUNDS)
	round_num = 1
	await get_tree().create_timer(START_DELAY).timeout
	if my_run != run:
		return
	await _play_round(my_run)

func _play_round(my_run: int) -> void:
	accepting = false
	step = 0
	for i in round_num:
		var b: BaseButton = buttons[sequence[i]]
		b.modulate = LIT
		await get_tree().create_timer(FLASH_TIME).timeout
		b.modulate = Color.WHITE
		if my_run != run:
			return
		await get_tree().create_timer(GAP_TIME).timeout
		if my_run != run:
			return
	accepting = true

func _on_pressed(i: int) -> void:
	if not accepting:
		return
	if i != sequence[step]:
		await _start_game()
		return
	step += 1
	if step < round_num:
		return
	accepting = false
	var my_run := run
	if round_num < ROUNDS:
		round_num += 1
		await get_tree().create_timer(ROUND_PAUSE).timeout
		if my_run != run:
			return
		await _play_round(my_run)
		return
	await get_tree().create_timer(CLOSE_DELAY).timeout
	if my_run != run or not visible:
		return
	hide()
	completed.emit()
