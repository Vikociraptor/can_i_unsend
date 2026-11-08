extends Node

@export var timeToWin = 20.0

@export var grid: GridManager

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if timeToWin > 0 and !grid.levelWon:
		timeToWin -= delta
		if timeToWin > 5:
			print(round(timeToWin))
		else:
			print(clamp(timeToWin, 0.0, 20.0))
	elif !grid.levelLost and !grid.levelWon:
		grid.levelLost = true
		print("You suck balls")
	
	
