class_name ChessGrid

extends Node2D

const gridSize = 80
const padding = 5

var possibleMoves = []

# p = Pawn
# k = King
# n = Knight
# b = Bishop
# r = Rook
# q = Queen
# . = Empty space
# Capitilized versions are the opponent. Or lowercase is white and Capitol is black

enum players {White, Black}

@export var player = players.White

@export var layout = [
	'.K.',
	'...',
	'...',
	'k.r',
]

var levelLost = false
var levelWon = false

var interactive = true

var grid = []

var selectedPiece := Vector2i(-1, -1)

func _ready() -> void:
	for i in layout.size():
		var row = []
		for j in layout[i].length():
			row.append(layout[i][j])
		grid.append(row)

func is_clickable_cell(cell: Vector2i) -> bool:
	var insideGrid = cell.x >= 0 and cell.y >= 0 and cell.x < layout[0].length() and cell.y < layout.size()
	return insideGrid

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and !levelWon and !levelLost and interactive:
		var cell = Vector2i((make_input_local(event).position / (gridSize + padding)).round())
		if is_clickable_cell(cell):
			queue_redraw()
			if grid[cell.y][cell.x] != ".":
				if possibleMoves.has(cell) and selectedPiece != Vector2i(-1, -1):
					grid[cell.y][cell.x] = grid[selectedPiece.y][selectedPiece.x]
					grid[selectedPiece.y][selectedPiece.x] = "."
					possibleMoves = []
					selectedPiece = Vector2i(-1, -1)
				elif owner_of(cell) == player:
					possibleMoves = getPossibleMoves(cell)
					selectedPiece = cell
				else:
					possibleMoves = []
					selectedPiece = Vector2i(-1, -1)
			else:
				if possibleMoves.has(cell) and selectedPiece != Vector2i(-1, -1):
					var temp = grid[cell.y][cell.x]
					grid[cell.y][cell.x] = grid[selectedPiece.y][selectedPiece.x]
					grid[selectedPiece.y][selectedPiece.x] = temp
				possibleMoves = []
				selectedPiece = Vector2i(-1, -1)

			

# Move generation. Each function returns the cells the piece at `pos` can move to,
# including captures of the opposing side. The side is worked out from the piece itself
# (lowercase = White, uppercase = Black), so this works for opponent pieces too, which lets
# us find attacked squares for "get out of check" puzzles.
# moveAmount is the max number of squares to travel; 0 or less means unlimited.

func is_empty(cell: Vector2i) -> bool:
	return grid[cell.y][cell.x] == "."

func is_white(piece: String) -> bool:
	return piece == piece.to_lower()

func owner_of(cell: Vector2i) -> players:
	return players.White if is_white(grid[cell.y][cell.x]) else players.Black

func is_enemy(cell: Vector2i, side: players) -> bool:
	return !is_empty(cell) and owner_of(cell) != side

# Walks from pos in dir until it hits the edge, a piece, or runs out of steps.
# Stops on an enemy piece (a capture) and stops before a friendly one.
func castRay(pos: Vector2i, dir: Vector2i, moveAmount: int) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var side = owner_of(pos)
	var cell = pos + dir
	var steps = 0
	while is_clickable_cell(cell) and (moveAmount <= 0 or steps < moveAmount):
		if is_empty(cell):
			moves.append(cell)
		else:
			if owner_of(cell) != side:
				moves.append(cell)
			break
		cell += dir
		steps += 1
	return moves

func castRays(pos: Vector2i, dirs: Array[Vector2i], moveAmount: int) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for dir in dirs:
		moves.append_array(castRay(pos, dir, moveAmount))
	return moves

func getVerticalMoves(pos: Vector2i, moveAmount: int) -> Array[Vector2i]:
	return castRays(pos, [Vector2i.UP, Vector2i.DOWN], moveAmount)

func getHorizontalMoves(pos: Vector2i, moveAmount: int) -> Array[Vector2i]:
	return castRays(pos, [Vector2i.LEFT, Vector2i.RIGHT], moveAmount)

func getDiagonalMoves(pos: Vector2i, moveAmount: int) -> Array[Vector2i]:
	return castRays(pos, [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)], moveAmount)

# Pawn moves. White moves up the screen (-y), Black moves down (+y).
# Forward moves can't capture; the two forward diagonals can only capture.
func getForwardMoves(pos: Vector2i, moveAmount: int) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var side = owner_of(pos)
	var forward = Vector2i.UP if side == players.White else Vector2i.DOWN
	for move in castRay(pos, forward, moveAmount):
		if is_empty(move):
			moves.append(move)
	for sideStep in [Vector2i.LEFT, Vector2i.RIGHT]:
		var cell = pos + forward + sideStep
		if is_clickable_cell(cell) and is_enemy(cell, side):
			moves.append(cell)
	return moves

func getHorseyMoves(pos: Vector2i) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var side = owner_of(pos)
	for offset in [Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2),
			Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2)]:
		var cell = pos + offset
		if is_clickable_cell(cell) and (is_empty(cell) or is_enemy(cell, side)):
			moves.append(cell)
	return moves

func getPossibleMoves(pos: Vector2i) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	match grid[pos.y][pos.x].to_lower():
		"p":
			moves.append_array(getForwardMoves(pos, 1))
		"n":
			moves.append_array(getHorseyMoves(pos))
		"b":
			moves.append_array(getDiagonalMoves(pos, 0))
		"r":
			moves.append_array(getVerticalMoves(pos, 0))
			moves.append_array(getHorizontalMoves(pos, 0))
		"q":
			moves.append_array(getVerticalMoves(pos, 0))
			moves.append_array(getHorizontalMoves(pos, 0))
			moves.append_array(getDiagonalMoves(pos, 0))
		"k":
			moves.append_array(getVerticalMoves(pos, 1))
			moves.append_array(getHorizontalMoves(pos, 1))
			moves.append_array(getDiagonalMoves(pos, 1))
	return moves

func colour_for(c: String) -> Color:
	var hue = fmod(c.unicode_at(0) * 0.618034, 1.0)
	return Color.from_hsv(hue, 0.8, 0.95)

func _draw() -> void:
	var step = gridSize + padding
	var cellVector = Vector2.ONE * gridSize

	for y in layout.size():
		for x in layout[y].length():
			var center = Vector2(x, y) * step
			if possibleMoves.has(Vector2i(x, y)):
				draw_rect(Rect2(center - cellVector / 2.0, cellVector), Color.YELLOW)
			else:
				draw_rect(Rect2(center - cellVector / 2.0, cellVector), Color.DIM_GRAY)

	for i in grid.size():
		for j in grid[i].size():
			if grid[i][j] != ".":
				draw_circle(Vector2(j, i) * step, 25, colour_for(grid[i][j]))
				
