extends Node2D

@export var all_minigames: Array[PackedScene] = []
@export var minigame_count := 2
@export var screen_margin := 16.0
@export var min_scale := 0.6
@export var max_scale := 1.0
@export var intro_duration := 3.0
@export var words: Array[String] = ["apple", "rocket", "banana", "spider", "pickle", "laptop", "cactus", "wizard"]

signal code_correct
signal code_wrong

@onready var intro_label : Label = $CanvasLayer/CenterContainer/VBoxContainer/IntroLabel
@onready var code_input : LineEdit = $CanvasLayer/CenterContainer/VBoxContainer/HBoxContainer/LineEdit

var remaining := 0
var available_words: Array[String] = []
var results: Dictionary = {}
var code_order: Array[String] = []

func _ready() -> void:
	available_words = words.duplicate()
	available_words.shuffle()
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
	code_order = names
	intro_label.text = "Type the result of %s and %s to stop the email send." % [
		", ".join(PackedStringArray(names.slice(0, -1))), names[-1]
	]
	intro_label.z_index = 10
	
	await get_tree().create_timer(intro_duration).timeout
	
	for minigame in minigames:
		place_minigame(minigame)
	
func place_minigame(minigame: Node2D) -> void:
	minigame.finished.connect(_on_minigame_finished.bind(minigame), CONNECT_ONE_SHOT)
	add_child(minigame)

	var random_scale := randf_range(min_scale, max_scale)
	minigame.scale = Vector2.ONE * random_scale

	# The minigame's content isn't drawn at its origin (it sits a few hundred px in),
	# so measure where it really is and place that box, not the origin.
	var bounds := _get_content_bounds(minigame)
	var scaled_size := bounds.size * random_scale
	var screen := get_viewport_rect().size
	var max_pos := (screen - scaled_size - Vector2.ONE * screen_margin).max(Vector2.ONE * screen_margin)
	var top_left := Vector2(
		randf_range(screen_margin, max_pos.x),
		randf_range(screen_margin, max_pos.y)
	)
	minigame.position = top_left - bounds.position * random_scale

# Union of the rects of the minigame's visible Control children, in its local (unscaled) space.
func _get_content_bounds(minigame: Node2D) -> Rect2:
	var bounds := Rect2()
	var first := true
	for child in minigame.get_children():
		if child is Control and child.visible:
			var rect: Rect2 = child.get_rect()
			bounds = rect if first else bounds.merge(rect)
			first = false
	return bounds
	
func _on_minigame_finished(minigame: Node2D) -> void:
	var word: String = available_words.pop_back()
	results[minigame.display_name] = word
	minigame.show_result(word)

	remaining -= 1
	if remaining == 0:
		print("All minigames solved: ", results)

# The words from each minigame, in intro order, separated by spaces, e.g. "rocket apple".
func get_expected_code() -> String:
	var parts := PackedStringArray()
	for minigame_name in code_order:
		parts.append(results.get(minigame_name, ""))
	return " ".join(parts)

# Lowercase and collapse spaces/newlines so "Rocket   apple\n" still matches "rocket apple".
func _normalize(text: String) -> String:
	return " ".join(text.to_lower().replace("\n", " ").split(" ", false))

func _on_submit_button_pressed() -> void:
	if remaining > 0:
		print("Not all minigames solved yet")
		code_wrong.emit()
		return

	var typed := _normalize(code_input.text)
	if typed == _normalize(get_expected_code()):
		print("Correct! Email send stopped.")
		code_correct.emit()
	else:
		print("Wrong code. Expected: ", get_expected_code(), " got: ", typed)
		code_wrong.emit()
