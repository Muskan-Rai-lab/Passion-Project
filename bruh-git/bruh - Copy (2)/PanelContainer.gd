extends PanelContainer

@export var seconds_per_line := 2.5

@onready var label: Label = $Label
@onready var timer: Timer = $Timer

var lines: Array = []
var index := 0

func _ready() -> void:
	hide()		
	timer.one_shot = true
	timer.timeout.connect(_next_line)
	DialogueManager.dialogue_requested.connect(_on_dialogue_requested)

func _on_dialogue_requested(new_lines: Array) -> void:
	lines = new_lines
	index = 0
	show()
	_show_line()

func _show_line() -> void:
	label.text = lines[index]
	timer.start(seconds_per_line)

func _next_line() -> void:
	index += 1
	if index >= lines.size():
		hide()
	else:
		_show_line()
