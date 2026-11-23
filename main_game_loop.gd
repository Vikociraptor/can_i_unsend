extends Node2D

@export var all_minigames: Array[PackedScene] = []
# Top-left corner of each window, in spawn order: 1 top-left, 2 bottom-left, 3 right of 1, (4 right of 2).
@export var spawn_positions: Array[Vector2] = [
	Vector2(20, 20), Vector2(20, 418), Vector2(305, 20), Vector2(305, 418)
]
@export var minigame_scale := 0.6
@export var intro_duration := 1.3
@export var words: Array[String] = ["apple", "rocket", "banana", "spider", "pickle", "laptop", "cactus", "wizard"]
@export var timer := 21.0;
@export var timerLabel: Label
@export var end_screen_time := 4.0
@export var success_time := 2.5  # seconds the success message shows before returning to the menu
@export var menu_music_fade_time := 0.5  # seconds the menu track takes to fade out once this scene loads
@export var cursor_move_time := 0.8  # seconds the intro cursor takes to glide onto Send
@export var loading_spin_speed := 0.4  # full turns per second for the loading icon

var timerCount = false
@onready var send_button: TextureRect = $BackgroundLayer/SendEmail/SendButton
@onready var warning: TextureRect = $CanvasLayer/Warning

signal code_correct
signal code_wrong

@onready var intro_label : Label = $CanvasLayer/Warning/IntroLabel
@onready var code_input : LineEdit = $CanvasLayer/Warning/LineEdit
@onready var music : AudioStreamPlayer = $AudioStreamPlayer
@onready var send_email_texture : TextureRect = $BackgroundLayer/SendEmail
# Holds the warning box, intro text, timer, code input and Submit button.
@onready var warning_layer : CanvasLayer = $CanvasLayer
@onready var loading : TextureRect = $CanvasLayer/Warning/Loading
@onready var success_message : Label = $CanvasLayer/Warning/SuccessMessage
@onready var incorrect_label : Label = $CanvasLayer/Warning/IncorrectLabel


var remaining := 0
var available_words: Array[String] = []
var results: Dictionary = {}
var code_order: Array[String] = []
var placed_minigames: Array[Node2D] = []

func _ready() -> void:
	_fade_out_menu_music()  # menu track carried over from MainMenu fades as soon as the game loads
	$BackgroundLayer/BossEmail.hide()
	$BackgroundLayer/EmailAfter.hide()
	send_button.hide()
	incorrect_label.hide()
	code_input.text_changed.connect(_on_code_input_text_changed)
	var minigame_count = GameSettings.minigame_count
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
	intro_label.text = "Type result of %s to stop email before time runs out." % _join_names(names)
	intro_label.z_index = 10

	## Start Animation Sequence
	warning_layer.hide()
	# 1. Send button gets "clicked"
	await _play_send_click()

	# 2. Warning pops up and the music kicks in
	warning_layer.show()
	$CanvasLayer/Warning/SuccessMessage.hide()
	_pop_in(warning)
	music.play()

	# 3. Minigames appear 1.3 s later, and the countdown starts with them
	await get_tree().create_timer(intro_duration).timeout
	for minigame in minigames:
		place_minigame(minigame)
	timerCount = true

func _process(delta: float) -> void:
	# Loading icon spins only while the countdown is running.
	loading.visible = timerCount
	if timerCount:
		loading.pivot_offset = loading.size / 2.0  # spin around its centre
		loading.rotation += TAU * loading_spin_speed * delta
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
			$BackgroundLayer/EmailAfter.show()
			var boss_email: TextureRect = $BackgroundLayer/BossEmail
			await _pop_in(boss_email).finished
			await get_tree().create_timer(end_screen_time).timeout
			get_tree().change_scene_to_file("res://MainMenu.tscn")

# Intro: a copy of the player's cursor glides onto Send, the blue button lights up, and it gets clicked.
func _play_send_click() -> void:
	# The real mouse is hidden and a look-alike (same images as GameSettings) is drawn on top of everything.
	var cursor_layer := CanvasLayer.new()
	cursor_layer.layer = 128
	add_child(cursor_layer)
	var fake_cursor := TextureRect.new()
	fake_cursor.texture = GameSettings.HAND_CURSOR
	fake_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_layer.add_child(fake_cursor)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	# Start where the player's mouse actually is, so it feels like the cursor got taken over.
	var screen := get_viewport().get_visible_rect()
	var start := get_viewport().get_mouse_position().clamp(screen.position, screen.end)
	var target := send_button.get_global_rect().get_center()
	fake_cursor.position = start - GameSettings.HAND_HOTSPOT

	await get_tree().create_timer(0.5).timeout  # short pause so the player sees the email first

	# Glide to Send
	var move := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	move.tween_property(fake_cursor, "position", target - GameSettings.HAND_HOTSPOT, cursor_move_time)
	await move.finished

	# Hover: the blue send button appears
	send_button.pivot_offset = send_button.size / 2.0
	send_button.show()
	await get_tree().create_timer(0.25).timeout

	# Press down (fist cursor)
	fake_cursor.texture = GameSettings.GRAB_CURSOR
	fake_cursor.position = target - GameSettings.GRAB_HOTSPOT
	var press := create_tween()
	press.tween_property(send_button, "scale", Vector2.ONE * 0.85, 0.08)
	press.parallel().tween_property(send_button, "modulate", Color(0.7, 0.7, 0.7), 0.08)
	await press.finished

	# Release with a little bounce (back to the hand)
	fake_cursor.texture = GameSettings.HAND_CURSOR
	fake_cursor.position = target - GameSettings.HAND_HOTSPOT
	var release := create_tween()
	release.tween_property(send_button, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	release.parallel().tween_property(send_button, "modulate", Color.WHITE, 0.2)
	await release.finished

	await get_tree().create_timer(0.3).timeout

	# Hand control back: put the real mouse where the fake one ended, then swap them.
	get_viewport().warp_mouse(target)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	cursor_layer.queue_free()

# Ends the round: locks the input and hides the email, warning box and every minigame window.
func _clear_desk(lost: bool) -> void:
	code_input.editable = false
	send_email_texture.hide()
	if lost:
		warning_layer.hide()  # a win keeps the box up to show the success message
	for minigame in placed_minigames:
		if is_instance_valid(minigame):
			if lost:
				minigame.game.levelLost = true
			minigame.dragging = false
			minigame.hide()

# Correct code before time ran out: empty the warning box, show the success message in it, then back to the menu.
func _play_win_sequence() -> void:
	timerCount = false  # also hides the spinning loading icon
	_clear_desk(false)

	# Swap the warning's contents for the success message.
	for child in warning.get_children():
		if child is CanvasItem:
			child.hide()
	_pop_in(success_message)

	# Fade the music out while the message is up, then straight back to the menu.
	create_tween().tween_property(music, "volume_db", -40.0, success_time)
	await get_tree().create_timer(success_time).timeout
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
		_show_incorrect()
		return

	var typed := _normalize(code_input.text)
	if typed == _normalize(get_expected_code()):
		print("Correct! Email send stopped.")
		code_correct.emit()
		_play_win_sequence()
	else:
		print("Wrong code. Expected: ", get_expected_code(), " got: ", typed)
		_show_incorrect()

# Red "Incorrect code" under Submit; it pops in again on every wrong try and clears once the player edits.
func _show_incorrect() -> void:
	code_wrong.emit()
	incorrect_label.show()
	_pop_in(incorrect_label)

func _on_code_input_text_changed(_new_text: String) -> void:
	incorrect_label.hide()

# main_menu.gd keeps the menu track playing on the root across the scene change.
# Fade it out, then free it.
func _fade_out_menu_music() -> void:
	var carried := get_tree().root.get_node_or_null("MenuMusic") as AudioStreamPlayer
	if carried == null:
		return
	var fade := carried.create_tween()
	fade.tween_property(carried, "volume_db", -40.0, menu_music_fade_time)
	fade.tween_callback(carried.queue_free)
