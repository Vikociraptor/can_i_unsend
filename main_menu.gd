extends Control

func _ready() -> void:
	$OptionsPanel.hide()

func _start_game(mode: String) -> void:
	GameSettings.minigame_count = GameSettings.MODES[mode]
	get_tree().change_scene_to_file("res://MainGameLoop.tscn")

# Ignore press if tab dragged
func _was_dragged(block: String) -> bool:
	return get_node(block).was_dragged

func _on_easy_pressed() -> void:
	if not _was_dragged("Easy"):
		_start_game("easy")

func _on_medium_pressed() -> void:
	if not _was_dragged("Medium"):
		_start_game("medium")

func _on_hard_pressed() -> void:
	if not _was_dragged("Hard"):
		_start_game("hard")

func _on_options_button_pressed() -> void:
	if not _was_dragged("Options"):
		$Options.hide()
		# Open the panel on option tab current position
		var panel: Control = $OptionsPanel
		var tab_center: Vector2 = $Options.position + $Options.size / 2
		var max_pos := (size - panel.size).max(Vector2.ZERO)
		panel.position = (tab_center - panel.size / 2).clamp(Vector2.ZERO, max_pos)
		panel.show()
		$OptionsPanel.move_to_front()


func _on_close_button_pressed() -> void:
	$OptionsPanel.hide()
	$Options.show()
