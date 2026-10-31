extends Control

signal completed

const FILL_TIME := 30.0
const CLOSE_DELAY := 3.0

@onready var bar: ProgressBar = $ProgressDownload
@onready var start_button: Button = $Download

var tween: Tween

func _ready() -> void:
	bar.min_value = 0
	bar.max_value = 100
	start_button.pressed.connect(_on_download_pressed)
	visibility_changed.connect(_on_visibility_changed)
	hide()

func open() -> void:
	_reset()
	show()

func _reset() -> void:
	if tween:
		tween.kill()
	bar.value = 0
	start_button.disabled = false

func _on_visibility_changed() -> void:
	if not visible:
		_reset()

func _on_download_pressed() -> void:
	start_button.disabled = true
	tween = create_tween()
	tween.tween_property(bar, "value", 100.0, FILL_TIME)
	tween.tween_interval(CLOSE_DELAY)
	tween.tween_callback(_finish)

func _finish() -> void:
	hide()
	completed.emit()
