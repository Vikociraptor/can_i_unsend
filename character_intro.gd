extends Control
## Plays the character loop once, then loads the email game. Clicks and keys are ignored.

@export var frames: Array[Texture2D] = []
@export var fps := 8.0
@export_file("*.tscn") var next_scene := "res://MainGameLoop.tscn"
@export var music_fade_time := 1.0  # seconds the menu music takes to fade once the animation ends

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
	_fade_out_menu_music()
	# Deferred so the scene isn't swapped in the middle of input or process handling.
	get_tree().call_deferred("change_scene_to_file", next_scene)

# The menu music was moved onto the root by main_menu.gd so it plays through the animation.
# The tween belongs to the music node itself, so the fade keeps going after this scene is gone.
func _fade_out_menu_music() -> void:
	var carried := get_tree().root.get_node_or_null("MenuMusic") as AudioStreamPlayer
	if carried == null:
		return
	var fade := carried.create_tween()
	fade.tween_property(carried, "volume_db", -40.0, music_fade_time)
	fade.tween_callback(carried.queue_free)
