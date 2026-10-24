extends Control

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://lobby.tscn")

func _on_binds_pressed() -> void:
	$MeinMenu.hide()
	$BindList.show()

func _on_close_pressed() -> void:
	$BindList.hide()
	$MeinMenu.show()
