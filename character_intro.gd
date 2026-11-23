extends Control
## First scene of the game: plays the character loop once, then loads the main menu. Clicks and keys are ignored.

@export var frames: Array[Texture2D] = []
@export var fps := 8.0
@export_file("*.tscn") var next_scene := "res://MainMenu.tscn"
@onready var picture: TextureRect = $Picture

var _frame := 0
var _time := 0.0
var _done := false

func _ready() -> void:
	if frames.is_empty():
		_finish()
		return
	picture.texture = frames[0]

func _process(delta: float) -> void:
	if _done:
		return
	_time += delta
	var frame := int(_time * fps)
	if frame >= frames.size():
		_finish()
	elif frame != _frame:
		_frame = frame
		picture.texture = frames[frame]

func _finish() -> void:
	if _done:
		return
	_done = true
	# Deferred so the scene isn't swapped in the middle of input or process handling.
	get_tree().call_deferred("change_scene_to_file", next_scene)
