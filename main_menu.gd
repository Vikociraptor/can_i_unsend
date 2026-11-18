extends Control

func _start_game(mode: String) -> void:
	GameSettings.minigame_count = GameSettings.MODES[mode]
	get_tree().change_scene_to_file("res://MainGameLoop.tscn")

func _on_easy_pressed() -> void:
	_start_game("easy")

func _on_medium_pressed() -> void:
	_start_game("medium")

func _on_hard_pressed() -> void:
	_start_game("hard")
	
func _on_options_button_pressed() -> void:
	$Margin/OptionsPanel.show()


func _on_close_button_pressed() -> void:
	$Margin/OptionsPanel.hide()
