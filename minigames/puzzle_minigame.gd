# A minigame window that hosts a puzzle grid (FlowGrid, GridManager, ...).
# The grid is scaled to fit Window/GameArea, only takes input while this window
# is the active one, and the window finishes once the grid's levelWon turns true.
extends "res://minigames/minigame.gd"

# Any grid with levelWon, interactive and get_bounds().
@export var game: Node2D

@onready var game_area: Control = $Window/GameArea

var solved := false

func _ready() -> void:
	super()
	_fit_game_to_area()

func _process(delta: float) -> void:
	super(delta)
	if not solved and game.levelWon:
		solved = true
		game.interactive = false
		finished.emit()

func set_active(value: bool) -> void:
	super(value)
	if game:
		game.interactive = value and not solved

# Scales the grid to the largest size that fits GameArea, centred in it.
func _fit_game_to_area() -> void:
	var area := Rect2(window.position + game_area.position, game_area.size)
	var bounds: Rect2 = game.get_bounds()
	var fit := minf(area.size.x / bounds.size.x, area.size.y / bounds.size.y)
	game.scale = Vector2.ONE * fit
	game.position = area.get_center() - bounds.get_center() * fit
