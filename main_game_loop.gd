extends Node2D

@export var all_minigames: Array[PackedScene] = []
@export var spawn_positions: Array[Vector2] = [
	Vector2(40, 40), Vector2(600, 40), Vector2(40, 330), Vector2(600, 330)
]
@export var minigame_scale := 0.6
@export var intro_duration := 1.3
@export var words: Array[String] = ["apple", "rocket", "banana", "spider", "pickle", "laptop", "cactus", "wizard"]
@export var timer := 21.0;
@export var timerLabel: Label
@export var end_screen_time := 4.0  # seconds the win email stays up before returning to the menu

var timerCount = true

signal code_correct
signal code_wrong

@onready var intro_label : Label = $CanvasLayer/IntroLabel
@onready var code_input : LineEdit = $CanvasLayer/HBoxContainer/LineEdit
@onready var send_email_texture : TextureRect = $BackgroundLayer/SendEmail
@export var input_container : Container


var remaining := 0
var available_words: Array[String] = []
var results: Dictionary = {}
var code_order: Array[String] = []
var placed_minigames: Array[Node2D] = []

func _ready() -> void:
	$BackgroundLayer/BossEmail.hide()
	var minigame_count = GameSettings.minigame_count
	available_words = words.duplicate()
	available_words.shuffle()
	var selected: Array[PackedScene] = all_minigames.duplicate()
	selected.shuffle()
	selected.resize(minigame_count)
	remaining = selected.size()

	#input_container.hide()
	
	var minigames: Array[Node2D] = []
	var names: Array[String] = []
	for scene in selected:
		var minigame := scene.instantiate() as Node2D
		minigames.append(minigame)
		names.append(minigame.display_name)
	
	names.shuffle()
	code_order = names
	intro_label.text = "Type the result of %s to stop the email send." % _join_names(names)
	intro_label.z_index = 10
	
	await get_tree().create_timer(intro_duration).timeout
	
	for minigame in minigames:
		place_minigame(minigame)
		
func _process(delta: float) -> void:
	if timerCount:
		if timer > 5.0:
			timerLabel.text = str(int(floor(timer)))
		else:
			timerLabel.text = "%.1f" % max(0.0, timer)
			timerLabel.add_theme_color_override("font_color", Color.RED)
		if timer > 0.0:
			timer -= delta
		else:
			# Time's up: stop the timer so this only runs once, then lose and hide every minigame.
			timerCount = false
			timerLabel.text = "0.0"
			_clear_desk(true)
			await get_tree().create_timer(1).timeout
			var boss_email: TextureRect = $BackgroundLayer/BossEmail
			await _pop_in(boss_email).finished
			await get_tree().create_timer(end_screen_time).timeout
			get_tree().change_scene_to_file("res://MainMenu.tscn")

# Ends the round: locks the input and hides the email, prompt and every minigame window.
func _clear_desk(lost: bool) -> void:
	code_input.editable = false
	send_email_texture.hide()
	input_container.hide()
	intro_label.hide()
	for minigame in placed_minigames:
		if is_instance_valid(minigame):
			if lost:
				minigame.game.levelLost = true
			minigame.dragging = false
			minigame.hide()

# Correct code before time ran out: clear the desk, pop up the "unsent" email, then back to the menu.
func _play_win_sequence() -> void:
	timerCount = false
	timerLabel.add_theme_color_override("font_color", Color.GREEN)
	_clear_desk(false)

	# Fade the music out over the whole sequence.
	var music: AudioStreamPlayer = $AudioStreamPlayer
	create_tween().tween_property(music, "volume_db", -40.0, end_screen_time + 1.0)

	await get_tree().create_timer(0.5).timeout

	_pop_in($BackgroundLayer/WinEmail)

	await get_tree().create_timer(end_screen_time).timeout
	get_tree().change_scene_to_file("res://MainMenu.tscn")

# Shows a popup by fading it up while it grows slightly from 85% size.
func _pop_in(popup: Control) -> Tween:
	popup.pivot_offset = popup.size / 2.0
	popup.scale = Vector2.ONE * 0.85
	popup.modulate.a = 0.0
	popup.show()
	var pop := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(popup, "scale", Vector2.ONE, 0.4)
	pop.tween_property(popup, "modulate:a", 1.0, 0.25)
	return pop

#Correct wording for label based on number of minigames
func _join_names(names: Array[String]) -> String:
	if names.size() == 1:
		return names[0]
	return ", ".join(PackedStringArray(names.slice(0, -1))) + " and " + names[-1]

func place_minigame(minigame: Node2D) -> void:
	minigame.finished.connect(_on_minigame_finished.bind(minigame), CONNECT_ONE_SHOT)
	add_child(minigame)
	placed_minigames.append(minigame)

	var index := placed_minigames.size() - 1
	if index >= spawn_positions.size():
		push_warning("No spawn position for minigame #%d; add more to spawn_positions." % (index + 1))
	var target: Vector2 = spawn_positions[index] if index < spawn_positions.size() else Vector2.ZERO

	minigame.scale = Vector2.ONE * minigame_scale
	var bounds := _get_content_bounds(minigame)
	minigame.position = target - bounds.position * minigame_scale

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

	# timer += 5.0

	remaining -= 1
	if remaining == 0:
		print("All minigames solved: ", results)
		input_container.show()
		#timerCount = false

# The words from each minigame, in intro order, e.g. "rocketapple".
func get_expected_code() -> String:
	var parts := PackedStringArray()
	for minigame_name in code_order:
		parts.append(results.get(minigame_name, ""))
	return " ".join(parts)

# Lowercase and collapse spaces/newlines
func _normalize(text: String) -> String:
	return " ".join(text.to_lower().replace("\n", " ").split(" ", false))

func _on_submit_button_pressed() -> void:
	# Round already over (time ran out, or already won).
	if not timerCount:
		return
	if remaining > 0:
		print("Not all minigames solved yet")
		code_wrong.emit()
		return

	var typed := _normalize(code_input.text)
	if typed == _normalize(get_expected_code()):
		print("Correct! Email send stopped.")
		code_correct.emit()
		_play_win_sequence()
	else:
		print("Wrong code. Expected: ", get_expected_code(), " got: ", typed)
		code_wrong.emit()
