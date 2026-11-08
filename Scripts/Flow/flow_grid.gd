class_name FlowGrid

extends Node2D

const gridSize = 80
const padding = 5
const dotRadius = gridSize * 0.35
const lineWidth = gridSize * 0.3

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

var lines = {} # each line's cells in order, starting at one of its dots, keyed by character

var drawingLine = "" # the character of the line being dragged, empty when not dragging

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

# Left press on a dot starts a line, dragging extends it, releasing stops. Right click deletes a line.
func _unhandled_input(event: InputEvent) -> void:
	if grid.is_empty():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_line(cell_at(event))
		else:
			finish_line()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		delete_line(cell_at(event))
	elif event is InputEventMouseMotion and drawingLine != "":
		drag_line(cell_at(event))

func cell_at(event: InputEvent) -> Vector2i:
	return Vector2i((make_input_local(event).position / (gridSize + padding)).round())

# Starting from either dot of a pair throws away that pair's old line.
func start_line(cell: Vector2i) -> void:
	if is_inside_grid(cell) and dots.has(grid[cell.y][cell.x]):
		drawingLine = grid[cell.y][cell.x]
		lines[drawingLine] = [cell]
		queue_redraw()

# A line that never left its dot isn't kept.
func finish_line() -> void:
	if drawingLine != "" and lines[drawingLine].size() == 1:
		lines.erase(drawingLine)
		queue_redraw()
	drawingLine = ""

func drag_line(cell: Vector2i) -> void:
	var line = lines[drawingLine]
	var index = line.find(cell)
	if index != -1:
		# Dragging back over the line shortens it to this cell.
		line.resize(index + 1)
	elif can_extend(line, cell):
		line.append(cell)
	queue_redraw()

# The next cell must be directly beside the end of the line, and either empty or this line's other dot.
func can_extend(line: Array, cell: Vector2i) -> bool:
	var offset = (cell - line[-1]).abs()
	if offset.x + offset.y != 1 or not is_inside_grid(cell):
		return false
	if is_complete(drawingLine) or line_at(cell) != "":
		return false
	var c = grid[cell.y][cell.x]
	return c == "." or c == drawingLine

# A line is complete once it has reached the dot it didn't start from.
func is_complete(c: String) -> bool:
	if not lines.has(c) or lines[c].size() < 2:
		return false
	var last = lines[c][-1]
	return grid[last.y][last.x] == c

# Right clicking any cell of a line, or either of its dots, deletes the whole line.
func delete_line(cell: Vector2i) -> void:
	if not is_inside_grid(cell):
		return
	var c = line_at(cell)
	if c == "" and dots.has(grid[cell.y][cell.x]):
		c = grid[cell.y][cell.x]
	if lines.has(c):
		lines.erase(c)
		if drawingLine == c:
			drawingLine = ""
		queue_redraw()

# The character of the line passing through this cell, or empty if there isn't one.
func line_at(cell: Vector2i) -> String:
	for c in lines:
		if lines[c].has(cell):
			return c
	return ""

func is_inside_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < layout[0].length() and cell.y < layout.size()

# Turns the character's code into a hue, so the same character always gets the same colour.
# Multiplying by the golden ratio spreads neighbouring characters (a, b, c...) far apart on the colour wheel.
func colour_for(c: String) -> Color:
	var hue = fmod(c.unicode_at(0) * 0.618034, 1.0)
	return Color.from_hsv(hue, 0.8, 0.95)

# Draws every cell of the grid, then the lines, then a circle on each dot.
func _draw() -> void:
	var step = gridSize + padding
	var cellVector = Vector2.ONE * gridSize

	for y in layout.size():
		for x in layout[y].length():
			var center = Vector2(x, y) * step
			draw_rect(Rect2(center - cellVector / 2.0, cellVector), Color.DIM_GRAY)

	# A circle on every cell of a line rounds off its corners.
	for c in lines:
		var line = lines[c]
		for i in range(1, line.size()):
			draw_line(Vector2(line[i - 1]) * step, Vector2(line[i]) * step, colours[c], lineWidth)
		for cell in line:
			draw_circle(Vector2(cell) * step, lineWidth / 2.0, colours[c])

	for c in dots:
		for cell in dots[c]:
			draw_circle(Vector2(cell) * step, dotRadius, colours[c])
