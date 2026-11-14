extends Node2D

@export var camera: Camera2D

@export var lowerCaseAmount := 0
@export var upperCaseAmount := 0
@export var digitAmount := 0
@export var symbolAmount := 0
@export var targetLength := 0

@onready var rules: Label = $Rules
@onready var input: LineEdit = $Input
@onready var submitButton: Button = $Submit
@onready var feedback: Label = $Feedback

var levelWon = false
var levelLost = false

# The minigame window toggles this when it becomes active/inactive.
var interactive = true:
	set(value):
		interactive = value
		if is_node_ready():
			updateControls()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	targetLength = randi_range(6, 16)
	upperCaseAmount = randi_range(1, 5)
	lowerCaseAmount = randi_range(0, 3)
	symbolAmount = randi_range(0, 6)
	digitAmount = randi_range(1, 4)
	
	
	rules.text = getRulesText()
	feedback.text = ""

	submitButton.pressed.connect(_on_submit_pressed)
	input.text_submitted.connect(_on_input_submitted)
	updateControls()

	if camera:
		camera.position = get_bounds().get_center()

func _process(_delta: float) -> void:
	# levelLost is set from outside (the main loop's timer), so keep checking.
	updateControls()
	if levelLost and not levelWon:
		feedback.text = "Out of time!"

func updateControls() -> void:
	var canPlay = interactive and !levelWon and !levelLost
	input.editable = canPlay
	submitButton.disabled = not canPlay
	if not canPlay and input.has_focus():
		input.release_focus()

func get_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(400, 240))

func getRulesText() -> String:
	var lines := PackedStringArray(["Password must contain at least:"])
	if targetLength > 0:
		lines.append("%d characters" % targetLength)
	if lowerCaseAmount > 0:
		lines.append("%d lowercase letter(s)" % lowerCaseAmount)
	if upperCaseAmount > 0:
		lines.append("%d uppercase letter(s)" % upperCaseAmount)
	if digitAmount > 0:
		lines.append("%d digit(s)" % digitAmount)
	if symbolAmount > 0:
		lines.append("%d symbol(s) from !@#$%%^&*()" % symbolAmount)
	return "\n".join(lines)

func _on_input_submitted(_text: String) -> void:
	_on_submit_pressed()

func _on_submit_pressed() -> void:
	if levelWon or levelLost or not interactive:
		return
	if checkPassword(input.text):
		levelWon = true
		feedback.text = "Password accepted!"
	else:
		feedback.text = "Password doesn't meet the requirements"

func checkPassword(s: String) -> bool:

	var lowerCaseCount := 0
	var upperCaseCount := 0
	var digitCount := 0
	var symbolCount := 0
	var lengthCount := 0

	for c in s:
		if c >= "A" and c <= "Z":
			upperCaseCount += 1
		elif c >= "a" and c <= "z":
			lowerCaseCount += 1
		elif c >= "0" and c <= "9":
			digitCount += 1
		elif c in "!@#$%^&*()":
			symbolCount += 1
		if c != " ":
			lengthCount += 1

	return upperCaseCount >= upperCaseAmount and lowerCaseCount >= lowerCaseAmount and digitCount >= digitAmount and symbolCount >= symbolAmount and lengthCount >= targetLength
