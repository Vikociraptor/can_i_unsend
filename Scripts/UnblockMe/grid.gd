class_name GridManager

extends Node2D

const gridSize = 80
const padding = 5
const blockSceneSize = 40.0 # width and height of block.tscn before scaling

@export var obstacleBlock: PackedScene

@export var camera: Camera2D

# "." is an empty cell. Any other valid character is one straight block.
# "*" is the goal block.
@export var layout: PackedStringArray = [
	"kkaab",
	"c..vb",
	"c**v.",
	"...v.",
	"eeev.",
]

var layouts = [
	[
		"kkaab",
		"c..vb",
		"c**v.",
		"...v.",
		"eeev.",
	],
	[
		"daaab",
		"d...b",
		"c**.b",
		"c...b",
		"eeee."
	]
]

var grid = [] # characters, read as grid[y][x]

var exit = [-1, 2] # We define the exit here, where one of the values should be outside the grid.

var blocks = {} # each block's cells, keyed by its character

var blockNodes = {} # each block's node, keyed by its character

var highlightedCells = [] # the cells the selected block can move to

var selectedBlock = "" # the selected block's character, empty when nothing is selected

var levelWon = false
var levelLost = false

# Turned off while this grid sits in a minigame window that isn't the active one.
var interactive = true

func _ready() -> void:

	layout = layouts[randi_range(0, layouts.size())]

	# Read the strings into the grid, collecting the cells of each block.
	for y in layout.size():
		var row = []
		for x in layout[y].length():
			var c = layout[y][x]
			row.append(c)
			if c != ".":
				if not blocks.has(c):
					blocks[c] = []
				blocks[c].append(Vector2i(x, y))
		grid.append(row)

	for c in blocks:
		if not is_valid_character(c) or blocks[c].size() < 2 or not is_straight_line(blocks[c]):
			push_error("Invalid block '%s' in layout" % c)
			grid = []
			return

	var step = gridSize + padding
	for c in blocks:
		var first = blocks[c][0]
		var last = blocks[c][-1]
		var cellCount = last - first + Vector2i.ONE
		var pixelSize = Vector2(cellCount) * gridSize + Vector2(cellCount - Vector2i.ONE) * padding

		var block: RigidBody2D = obstacleBlock.instantiate()
		block.freeze = true
		block.width = cellCount.x
		block.height = cellCount.y
		block.scale = pixelSize / blockSceneSize
		block.position = Vector2(first + last) / 2.0 * step
		if c == "*":
			block.get_node("ColorRect").color = Color.RED
		add_child(block)
		blockNodes[c] = block

	# Inside a minigame window there's no camera, the window positions the grid instead.
	if camera:
		camera.position = get_bounds().get_center()

# The area the grid draws over in local pixels, including the border ring.
func get_bounds() -> Rect2:
	var step = gridSize + padding
	var cells = Vector2(layout[0].length() + 2, layout.size() + 2)
	return Rect2(Vector2.ONE * (-step - gridSize / 2.0), cells * step - Vector2.ONE * padding)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and !levelWon and !levelLost and interactive:
		var cell = Vector2i((make_input_local(event).position / (gridSize + padding)).round())
		if is_clickable_cell(cell):
			print("Clicked cell ", cell)
			if highlightedCells.has(cell):
				move(selectedBlock, cell)
				selectedBlock = ""
			else:
				update_highlights(cell)

# Selects the clicked block and highlights where it can move. Any other click clears them.
func update_highlights(cell: Vector2i) -> void:
	highlightedCells = []
	selectedBlock = ""
	if not grid.is_empty() and [cell.x, cell.y] != exit:
		var c = grid[cell.y][cell.x]
		if blocks.has(c):
			selectedBlock = c
			highlightedCells = find_moves(blocks[c][0], blocks[c][-1], c)
	queue_redraw()

# Scans outward from both ends of a block, stopping at the first cell that isn't free.
func find_moves(first: Vector2i, last: Vector2i, c: String) -> Array:
	var direction = (last - first).sign()
	var moves = []

	var cell = last + direction
	while is_free(cell, c):
		moves.append(cell)
		cell += direction

	cell = first - direction
	while is_free(cell, c):
		moves.append(cell)
		cell -= direction

	return moves

# Checks the exit first, because a negative index would read from the end of a row.
func is_free(cell: Vector2i, c: String) -> bool:
	if [cell.x, cell.y] == exit:
		return c == "*"
	return is_clickable_cell(cell) and grid[cell.y][cell.x] == "."

# True for every cell inside the grid, plus the exit.
func is_clickable_cell(cell: Vector2i) -> bool:
	var insideGrid = cell.x >= 0 and cell.y >= 0 and cell.x < layout[0].length() and cell.y < layout.size()
	return insideGrid or [cell.x, cell.y] == exit

# Draws a ring of cells around the grid, leaving a gap at the exit.
func _draw() -> void:
	var step = gridSize + padding
	var width = layout[0].length()
	var height = layout.size()
	var cellVector = Vector2.ONE * gridSize

	for y in range(-1, height + 1):
		for x in range(-1, width + 1):
			var onBorder = x == -1 or y == -1 or x == width or y == height
			if onBorder and [x, y] != exit:
				var center = Vector2(x, y) * step
				draw_rect(Rect2(center - cellVector / 2.0, cellVector), Color.DIM_GRAY)

	for cell in highlightedCells:
		var center = Vector2(cell) * step
		draw_rect(Rect2(center - cellVector / 2.0, cellVector), Color(1, 1, 0, 0.4))

func is_valid_character(c: String) -> bool:
	return c == "*" or c.is_valid_int() or c.to_lower() != c.to_upper()

# True when the cells form one unbroken line, 1 wide or 1 long.
func is_straight_line(cells: Array) -> bool:
	var direction = (cells[-1] - cells[0]).sign()
	if direction.x != 0 and direction.y != 0:
		return false
	for i in cells.size():
		if cells[i] != cells[0] + direction * i:
			return false
	return true

# Moves block c so that its start or end, whichever faces the way it's moving, lands on targetCell.
func move(c: String, targetCell: Vector2i) -> void:
	var cells = blocks[c]
	var direction = (cells[-1] - cells[0]).sign()

	var offset = targetCell - cells[0]
	if offset.sign() == direction:
		offset = targetCell - cells[-1]

	for cell in cells:
		set_grid_cell(cell, ".")
	for i in cells.size():
		cells[i] += offset
	for cell in cells:
		set_grid_cell(cell, c)

	blockNodes[c].position = Vector2(cells[0] + cells[-1]) / 2.0 * (gridSize + padding)

	highlightedCells = []
	queue_redraw()

	if c == "*" and [targetCell.x, targetCell.y] == exit:
		print("Winner winner chicken dinner")
		levelWon = !levelWon

# The exit isn't in the grid, so it's skipped. A negative index would write to the end of a row.
func set_grid_cell(cell: Vector2i, value: String) -> void:
	if [cell.x, cell.y] != exit:
		grid[cell.y][cell.x] = value
