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

var grid = []

func _ready() -> void:
	for i in layout.size():
		var row = []
		for j in layout[i].length():
			row.append(layout[i][j])
		grid.append(row)

# these functions all pass void for now, but once built out will pass back
# the actual cells a player can move in, and will respect what player is making the move
# these are chess puzzles, so only our player should move, but this allows us to find possible
# pieces to take, so we can have "Get out of check" puzzles too

func getVerticalMoves(pos: Vector2i, moveAmount) -> Array[Vector2i]:
	var tempMoves = []
	var foundPiece = false
	for j in grid[pos.x].size():
		if !foundPiece:
			if grid[pos.x][j] == ".":
				tempMoves.append(Vector2i(pos.x, j))
			elif grid[pos.x][j] != "." and Vector2i(pos.x, j) != pos:
				tempMoves = []
			elif Vector2i(pos.x, j) == pos:
				foundPiece = true
		else:
			if grid[pos.x][j] == ".":
				tempMoves.append(Vector2i(pos.x, j))
			else:
				break
	return tempMoves
		
	
func getForwardMoves(pos, moveAmount) -> void:
	pass

func getHorizontalMoves(pos, moveAmount) -> void:
	pass

func getDiagonalMoves(pos, moveAmount) -> void:
	pass

func getHorseyMoves(pos) -> void:
	pass

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
				
