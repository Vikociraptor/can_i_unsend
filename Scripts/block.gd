extends Node

var width: int
var height: int
var dir: Direction

enum Direction {
	Vertical,
	Horizontal,
	Invalid
}

func _ready() -> void:
	if width > 1 and height > 1 or width == height:
		dir = Direction.Invalid
	elif width == 1:
		dir = Direction.Vertical
	else:
		dir = Direction.Horizontal
