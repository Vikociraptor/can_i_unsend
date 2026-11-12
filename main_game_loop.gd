extends Node2D

@export var all_minigames: Array[PackedScene] = []
@export var minigame_count := 2
@export var screen_margin := 16.0
@export var min_scale := 0.6
@export var max_scale := 1.0
@export var intro_duration := 1.0
@export var words: Array[String] = ["apple", "rocket", "banana", "spider", "pickle", "laptop", "cactus", "wizard"]
@export var timer := 20.0;
@export var timerLabel: Label

var timerCount = true

signal code_correct
signal code_wrong

@onready var intro_label : Label = $CanvasLayer/CenterContainer/VBoxContainer/IntroLabel
@onready var code_input : LineEdit = $CanvasLayer/CenterContainer/VBoxContainer/HBoxContainer/LineEdit

var remaining := 0
var available_words: Array[String] = []
var results: Dictionary = {}
var code_order: Array[String] = []
var placed_minigames: Array[Node2D] = []

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
		
func _process(delta: float) -> void:
	if timerCount:
		if timer > 5.0:
			timerLabel.text = str(int(floor(timer)))
		else:
			timerLabel.text = str(max(0.0, timer))
		if timer > 0.0:
			timer -= delta
		else:
			for minigame in placed_minigames:
				if is_instance_valid(minigame):
					minigame.game.levelLost = true
	
func place_minigame(minigame: Node2D) -> void:
	minigame.finished.connect(_on_minigame_finished.bind(minigame), CONNECT_ONE_SHOT)
	add_child(minigame)
	placed_minigames.append(minigame)

	var random_scale := randf_range(min_scale, max_scale)
	minigame.scale = Vector2.ONE * random_scale

	var bounds := _get_content_bounds(minigame)
	var scaled_size := bounds.size * random_scale
	var screen := get_viewport_rect().size
	var max_pos := (screen - scaled_size - Vector2.ONE * screen_margin).max(Vector2.ONE * screen_margin)
	var top_left := Vector2(
		randf_range(screen_margin, max_pos.x),
		randf_range(screen_margin, max_pos.y)
	)
	minigame.position = top_left - bounds.position * random_scale

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_activate_window_at(get_global_mouse_position())

func _activate_window_at(point: Vector2) -> void:
	var clicked: Node2D = null
	var order := placed_minigames.duplicate()
	order.sort_custom(func(a, b): return a.z_index > b.z_index or (a.z_index == b.z_index and a.get_index() > b.get_index()))
	for minigame in order:
		if is_instance_valid(minigame) and minigame.visible and minigame.contains_point(point):
			clicked = minigame
			break

	# Clicking empty space makes every window inactive.
	for minigame in placed_minigames:
		if is_instance_valid(minigame):
			minigame.set_active(minigame == clicked)

	if clicked:
		move_child(clicked, -1)

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

	timer += 5.0

	remaining -= 1
	if remaining == 0:
		print("All minigames solved: ", results)
		timerCount = false

# The words from each minigame, in intro order, e.g. "rocketapple".
func get_expected_code() -> String:
	var parts := PackedStringArray()
	for minigame_name in code_order:
		parts.append(results.get(minigame_name, ""))
	return "".join(parts)

# Lowercase and collapse spaces/newlines
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
