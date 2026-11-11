extends Node2D

signal finished

@export var display_name := "Minigame"

const Z_INACTIVE := 0
const Z_ACTIVE := 1
const HEADER_ACTIVE := preload("res://assets/RetroWindowsGUI/Window_Header.png")
const HEADER_INACTIVE := preload("res://assets/RetroWindowsGUI/Window_Header_Inactive.png")

@onready var window: NinePatchRect = $Window
# Only the placeholder minigames have a Press button.
@onready var button: Button = get_node_or_null("Button/Button")
@onready var button_holder: Control = get_node_or_null("Button")
@onready var result: Label = $Result

var active := false
var mouseOver: bool
var dragging := false
var drag_offset: Vector2 

func _ready() -> void:
	result.hide()
	set_active(false)  # every window starts inactive

func set_active(value: bool) -> void:
	active = value
	if not active:
		dragging = false
	z_index = Z_ACTIVE if active else Z_INACTIVE
	window.texture = HEADER_ACTIVE if active else HEADER_INACTIVE

func contains_point(global_point: Vector2) -> bool:
	return window.get_global_rect().has_point(global_point)

func _process(_delta: float) -> void:
	var mouse := get_global_mouse_position()

	if Input.is_action_just_pressed("Click") and active and mouseOver:
		dragging = true
		drag_offset = global_position - mouse

	if dragging:
		if Input.is_action_pressed("Click"):
			global_position = mouse + drag_offset
			_clamp_to_screen()
		else:
			dragging = false

func _clamp_to_screen() -> void:
	var rect := window.get_global_rect()          # visible window, already scaled
	var screen := get_viewport_rect().size
	var max_pos := (screen - rect.size).max(Vector2.ZERO)  # if the window is bigger than the screen, pin it to the top-left
	var clamped := rect.position.clamp(Vector2.ZERO, max_pos)
	global_position += clamped - rect.position    # move the whole minigame by however far the window was over

func _on_move_area_mouse_entered() -> void:
	mouseOver = true

func _on_move_area_mouse_exited() -> void:
	mouseOver = false

func _on_button_pressed() -> void:
	print("pressed: ", display_name)
	finished.emit()

func show_result(word: String) -> void:
	# Swap the button out for the result word in the same spot.
	if button:
		button.disabled = true
		button_holder.hide()
	result.text = word
	result.show()
