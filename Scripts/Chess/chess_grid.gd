class_name ChessGrid

extends Node2D

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

func _ready() -> void:
	pass # Replace with function body.

# these functions all pass void for now, but once built out will pass back
# the actual cells a player can move in, and will respect what player is making the move
# these are chess puzzles, so only our player should move, but this allows us to find possible
# pieces to take, so we can have "Get out of check" puzzles too

func getVerticalMoves() -> void:
	pass

func getHorizontalMoves() -> void:
	pass

func getDiagonalMoves() -> void:
	pass

func getHorseyMoves() -> void:
	pass