extends Node2D

@export var all_minigames: Array[PackedScene] = []
@export var minigame_count := 2
@export var base_size := Vector2(400, 300)
@export var min_scale := 0.6
@export var max_scale := 1.0
@export var intro_duration := 3.0

@onready var intro_label : Label = $IntroLabel

var remaining := 0

func _ready() -> void:
	var selected: Array[PackedScene] = all_minigames.duplicate()
	selected.shuffle()
	selected.resize(minigame_count)
	remaining = selected.size()
	
	var minigames: Array[Node2D] = []
	var names: Array[String] = []
	for scene in selected:
		var minigame := scene.instantiate() as Node2D
		minigames.append(minigame)
		names.append(minigame.display_name)
	
	names.shuffle()
	intro_label.text = "Type the result of %s and %s to stop the email send." % [
		", ".join(PackedStringArray(names.slice(0, -1))), names[-1]
	]
	intro_label.z_index = 10
	
	await get_tree().create_timer(intro_duration).timeout
	
	for minigame in minigames:
		place_minigame(minigame)
	
func place_minigame(minigame: Node2D) -> void:
	var random_scale := randf_range(min_scale, max_scale)
	minigame.scale = Vector2.ONE * random_scale

	var scaled_size := base_size * random_scale
	var max_offset := base_size * min_scale * 0.4
	var offset := Vector2(
		randf_range(-max_offset.x, max_offset.x),
		randf_range(-max_offset.y, max_offset.y)
	)
	var screen_centre := get_viewport_rect().size / 2
	minigame.position = screen_centre + offset - scaled_size / 2

	minigame.finished.connect(_on_minigame_finished.bind(minigame), CONNECT_ONE_SHOT)
	add_child(minigame)
	
func _on_minigame_finished(minigame: Node2D) -> void:
	minigame.queue_free()
	remaining -= 1
	
	if remaining == 0:
		print("All minigames finished")
	
	
