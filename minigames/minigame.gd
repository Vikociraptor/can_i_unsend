extends Node2D

signal finished

@onready var button: Button = $Button/Button

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	finished.emit()
