extends Node2D

signal finished

@export var display_name := "Minigame"

@onready var button: Button = $Button/Button
@onready var result: Label = $Result

func _ready() -> void:
	result.hide()


func _on_button_pressed() -> void:
	print("pressed: ", display_name)
	finished.emit()

func show_result(word: String) -> void:
	result.text = word
	result.show()
	button.disabled = true
