extends MarginContainer

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://MainGameLoop.tscn")


func _on_options_button_pressed() -> void:
	$OptionsPanel.show()


func _on_close_button_pressed() -> void:
	$OptionsPanel.hide()
