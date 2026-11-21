class_name MemoryGrid

extends Node2D

const gridSize = 80
const padding = 5

@export var camera: Camera2D

@export var pairs := 4
@export var card_textures: Array[Texture2D] = []
# Art for face-down cards
@export var card_back: Texture2D

var layout = []

var possibleChar := "abcdefghijklmnopqrstuvwxyz"

var grid = []

var cards = {}

var matches = []
var allCharacters = []

var firstSelectedCard = ""
var firstSelectedCardCell := Vector2i(-1, -1)

var levelWon = false
var levelLost = false

var interactive = true

func _ready() -> void:
	pairs = mini(pairs, card_textures.size())

	create_layout()

	for y in layout.size():
		var row = []
		for x in layout[y].size():
			var c = layout[y][x]
			row.append(c)
			if not allCharacters.has(c):
				allCharacters.append(c)
			if not cards.has(c):
				cards[c] = []
			cards[c].append(Vector2i(x, y))
		grid.append(row)
	
	if camera:
		camera.position = get_bounds().get_center()

func create_layout() -> void:
	var availChar = possibleChar.substr(0, pairs)
	var usedChars = []
	for i in 2:
		var row = []
		for j in pairs:
			var hasPlaced = false
			
			while not hasPlaced:
				var c = availChar[randi_range(0, pairs - 1)]
				if not usedChars.has(c) or usedChars.count(c) < 2:
					usedChars.append(c)
					row.append(c)
					hasPlaced = true
		layout.append(row)
	print(layout)

	

func get_bounds() -> Rect2:
	var step = gridSize + padding
	var cells = Vector2(layout[0].size(), layout.size())
	return Rect2(Vector2.ONE * -gridSize / 2.0, cells * step - Vector2.ONE * padding)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and !levelWon and !levelLost and interactive:
		var cell = Vector2i((make_input_local(event).position / (gridSize + padding)).round())
		if is_clickable_cell(cell):
			queue_redraw()
			if matches.has(grid[cell.y][cell.x]):
				return
			print("Clicked cell ", grid[cell.y][cell.x])
			if firstSelectedCard == "":
				firstSelectedCard = grid[cell.y][cell.x]
				firstSelectedCardCell = cell
			elif firstSelectedCard == grid[cell.y][cell.x] and not firstSelectedCardCell == cell:
				print("Match!")
				matches.append(firstSelectedCard)
				firstSelectedCard = ""
				firstSelectedCardCell = Vector2i(-1, -1)

				var w = true

				for c in allCharacters:
					if not matches.has(c):
						w = false
				
				levelWon = w


			else:
				print("Not a match!!")
				firstSelectedCard = ""
				firstSelectedCardCell = Vector2i(-1, -1)

func is_clickable_cell(cell: Vector2i) -> bool:
	var insideGrid = cell.x >= 0 and cell.y >= 0 and cell.x < layout[0].size() and cell.y < layout.size()
	return insideGrid
	
func colour_for(c: String) -> Color:
	var hue = fmod(c.unicode_at(0) * 0.618034, 1.0)
	return Color.from_hsv(hue, 0.8, 0.95)

func _draw() -> void:
	var step = gridSize + padding
	var cellVector = Vector2.ONE * gridSize

	for y in layout.size():
		for x in layout[y].size():
			var center = Vector2(x, y) * step
			draw_rect(Rect2(center - cellVector / 2.0, cellVector), Color.DIM_GRAY)

	for c in cards:
		var index := possibleChar.find(c)
		var tex: Texture2D = card_textures[index] if index < card_textures.size() else null
		for cell in cards[c]:
			var center: Vector2 = Vector2(cell) * step
			var face_up: bool = matches.has(c) or cell == firstSelectedCardCell
			if face_up and tex:
				draw_texture_rect(tex, _fit_rect(tex, center), false)
			elif face_up:
				draw_circle(center, 25, colour_for(c))  # fallback when a card has no art
			elif card_back:
				draw_texture_rect(card_back, _fit_rect(card_back, center), false)

func _fit_rect(tex: Texture2D, center: Vector2) -> Rect2:
	var s := tex.get_size()
	var fit := minf(gridSize / s.x, gridSize / s.y)
	var draw_size := s * fit
	return Rect2(center - draw_size / 2.0, draw_size)
