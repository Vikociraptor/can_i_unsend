extends Node2D

const gridSize = 80
const padding = 5
const blockSceneSize = 40.0 # width and height of block.tscn before scaling

@export var obstacleBlock: PackedScene

@export var camera: Camera2D

# "." is an empty cell. Any other valid character is one straight block.
# "*" is the goal block.
@export var layout: PackedStringArray = [
	"aa..b",
	"c...b",
	"c**..",
	"c.dd.",
	"eee..",
]

var grid = [] # characters, read as grid[y][x]

var exit = [-1, 2] # We define the exit here, where one of the values should be outside the grid.

func _ready() -> void:
	# Read the strings into the grid, collecting the cells of each block.
	var blocks = {}
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

	var lastCell = Vector2(layout[0].length() - 1, layout.size() - 1)
	camera.position = lastCell * step / 2.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell = Vector2i((make_input_local(event).position / (gridSize + padding)).round())
		if is_clickable_cell(cell):
			print("Clicked cell ", cell)

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
