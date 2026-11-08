extends MarginContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://MainGameLoop.tscn")


func _on_options_button_pressed() -> void:
	$OptionsPanel.show()


func _on_close_button_pressed() -> void:
	$OptionsPanel.hide()
