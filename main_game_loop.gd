extends Node2D

@export var all_minigames: Array[PackedScene] = []
@export var minigame_count := 3
@export var base_size := Vector2(400, 300)
@export var min_scale := 0.6
@export var max_scale := 1.0

var remaining := 0

func _ready() -> void:
	var selected: Array[PackedScene] = all_minigames.duplicate()
	selected.shuffle()
	selected.resize(minigame_count)
	remaining = selected.size()
	
	for scene in selected:
		spawn_minigame(scene)

func spawn_minigame(scene: PackedScene) -> void:
	var minigame := scene.instantiate() as Node2D
	
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
	
	
