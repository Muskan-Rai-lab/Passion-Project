extends Node3D

@export var mouse_sensitivity: float = 0.003
@export var min_pitch_deg: float = -40
@export var max_pitch_deg: float = 40

var pitch: float = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
		rotation.x = pitch
