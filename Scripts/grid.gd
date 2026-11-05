extends Node2D

const gridX = 5
const gridY = 5
const gridSize = 80
const padding = 5

@export var obstacleBlock: PackedScene

@export var camera: Camera2D

var grid = []

func _ready() -> void:
	for i in gridX:
		var column = []
		for j in gridY:
			if i == ceil(gridX / 2.0) and j == ceil(gridY / 2.0):
				camera.position = Vector2(i - 1, j - 1) * (gridSize + padding)
			var block: RigidBody2D = obstacleBlock.instantiate()
			block.freeze = true
			block.scale *= gridSize / 40.0
			block.position = Vector2(i, j) * (gridSize + padding)
			add_child(block)
			column.append(block)
		grid.append(column)
