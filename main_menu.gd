extends Control

func _ready() -> void:
	$OptionsPanel.hide()
	$OptionsPanel/MusicSlide.value = _bus_volume("Music")
	$OptionsPanel/SoundSlide.value = _bus_volume("Sound")

func _start_game(mode: String) -> void:
	GameSettings.minigame_count = GameSettings.MODES[mode]
	_carry_music_over()
	get_tree().change_scene_to_file("res://MainGameLoop.tscn")

# The menu's player is freed with this scene, so start an identical one on the root
# (which survives scene changes) at the same point in the track. MainGameLoop fades it out.
func _carry_music_over() -> void:
	var music: AudioStreamPlayer = $AudioStreamPlayer
	var carried := AudioStreamPlayer.new()
	carried.name = "MenuMusic"
	carried.stream = music.stream
	carried.bus = music.bus
	carried.volume_db = music.volume_db
	get_tree().root.add_child(carried)
	carried.play(music.get_playback_position() + AudioServer.get_time_since_last_mix())
	music.stop()

# Ignore press if tab dragged
func _was_dragged(block: String) -> bool:
	return get_node(block).was_dragged

func _on_easy_pressed() -> void:
	if not _was_dragged("Easy"):
		_start_game("easy")

func _on_medium_pressed() -> void:
	if not _was_dragged("Medium"):
		_start_game("medium")

func _on_hard_pressed() -> void:
	if not _was_dragged("Hard"):
		_start_game("hard")

func _on_options_button_pressed() -> void:
	if not _was_dragged("Options"):
		$Options.hide()
		# Open the panel on option tab current position
		var panel: Control = $OptionsPanel
		var tab_center: Vector2 = $Options.position + $Options.size / 2
		var max_pos := (size - panel.size).max(Vector2.ZERO)
		panel.position = (tab_center - panel.size / 2).clamp(Vector2.ZERO, max_pos)
		panel.show()
		$OptionsPanel.move_to_front()


func _on_close_button_pressed() -> void:
	$OptionsPanel.hide()
	$Options.show()

func _bus_volume(bus_name: String) -> float:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1 or AudioServer.is_bus_mute(bus_idx):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))

func _on_music_slide_value_changed(value: float) -> void:
	set_bus_volume("Music", value)

func _on_sound_slide_value_changed(value: float) -> void:
	set_bus_volume("Sound", value)

func set_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return
	
	if linear_value <= 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_value))
