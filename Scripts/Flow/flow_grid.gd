class_name FlowGrid

extends Node2D

const gridSize = 80
const padding = 5
const dotRadius = gridSize * 0.35

@export var camera: Camera2D

# "." is an empty cell. Any other character is a dot, and each one must appear exactly twice.
@export var layout: PackedStringArray = [
	"a...b",
	"..c..",
	".....",
	"c...b",
	"a....",
]

var grid = [] # characters, read as grid[y][x]

var dots = {} # each pair's two cells, keyed by its character

var colours = {} # each pair's colour, keyed by its character

func _ready() -> void:
	# Read the strings into the grid, collecting the cells of each dot.
	for y in layout.size():
		var row = []
		for x in layout[y].length():
			var c = layout[y][x]
			row.append(c)
			if c != ".":
				if not dots.has(c):
					dots[c] = []
				dots[c].append(Vector2i(x, y))
		grid.append(row)

	for c in dots:
		if dots[c].size() != 2:
			push_error("Dot '%s' appears %d times in layout, it needs exactly 2" % [c, dots[c].size()])
			grid = []
			dots = {}
			return
		colours[c] = colour_for(c)

	var step = gridSize + padding
	var lastCell = Vector2(layout[0].length() - 1, layout.size() - 1)
	camera.position = lastCell * step / 2.0

# Turns the character's code into a hue, so the same character always gets the same colour.
# Multiplying by the golden ratio spreads neighbouring characters (a, b, c...) far apart on the colour wheel.
func colour_for(c: String) -> Color:
	var hue = fmod(c.unicode_at(0) * 0.618034, 1.0)
	return Color.from_hsv(hue, 0.8, 0.95)

# Draws every cell of the grid, then a circle on each dot.
func _draw() -> void:
	var step = gridSize + padding
	var cellVector = Vector2.ONE * gridSize

	for y in layout.size():
		for x in layout[y].length():
			var center = Vector2(x, y) * step
			draw_rect(Rect2(center - cellVector / 2.0, cellVector), Color.DIM_GRAY)

	for c in dots:
		for cell in dots[c]:
			draw_circle(Vector2(cell) * step, dotRadius, colours[c])
