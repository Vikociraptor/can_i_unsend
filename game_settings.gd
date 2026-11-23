extends Node

#Number of minigames per round
const MODES := {
	"easy": 1,
	"medium": 2,
	"hard": 3,
}

var minigame_count := 2 #default for isolated scene testing

# Open hand is the normal cursor
# Fist replaces it while the left mouse button is held.
const HAND_CURSOR := preload("res://assets/cursor/Cursor.png")
const HAND_HOTSPOT := Vector2(14, 7)
const GRAB_CURSOR := preload("res://assets/cursor/Cursor Grab.png")
const GRAB_HOTSPOT := Vector2(21, 26)

var _grabbing := false

# Autoload, so this sees every click in every scene before any node handles it.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		set_grab_cursor(event.pressed)

func _notification(what: int) -> void:
	# A release outside the game window never arrives, so reset when focus is lost.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		set_grab_cursor(false)

func set_grab_cursor(grabbing: bool) -> void:
	if grabbing == _grabbing:
		return
	_grabbing = grabbing
	if grabbing:
		Input.set_custom_mouse_cursor(GRAB_CURSOR, Input.CURSOR_ARROW, GRAB_HOTSPOT)
	else:
		Input.set_custom_mouse_cursor(HAND_CURSOR, Input.CURSOR_ARROW, HAND_HOTSPOT)
