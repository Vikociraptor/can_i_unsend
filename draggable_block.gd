extends Control
## Lets a main-menu block be dragged around like a desktop window.
## Works on TextureRects (titles) and TextureButtons (mode buttons).

## How far the mouse must move before a press turns into a drag.
## Below this, a button press still counts as a click.
const DRAG_THRESHOLD := 4.0

## True if the last press turned into a drag. main_menu.gd checks this so
## dropping a button after dragging it doesn't also start the game.
var was_dragged := false

var _held := false
var _press_mouse: Vector2
var _drag_offset: Vector2

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_held = true
			was_dragged = false
			_press_mouse = get_global_mouse_position()
			_drag_offset = position - get_parent_control().get_local_mouse_position()
			move_to_front()  # the grabbed block draws on top, like an active window
		else:
			_held = false

	elif event is InputEventMouseMotion and _held:
		if not was_dragged and get_global_mouse_position().distance_to(_press_mouse) > DRAG_THRESHOLD:
			was_dragged = true
		if was_dragged:
			var target := get_parent_control().get_local_mouse_position() + _drag_offset
			# Keep the whole block on screen.
			var max_pos := (get_parent_area_size() - size).max(Vector2.ZERO)
			position = target.clamp(Vector2.ZERO, max_pos)
