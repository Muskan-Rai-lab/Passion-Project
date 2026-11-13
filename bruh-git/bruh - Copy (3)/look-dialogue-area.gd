extends Area3D

@export var look_id: String = ""

var has_spoken := false

func on_look() -> void:
	if has_spoken:
		return
	has_spoken = true
	DialogueManager.say(look_id)  # swap in your real function name
