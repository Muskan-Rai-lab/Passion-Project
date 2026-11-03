# --- SpringArmController.gd (attach to SpringArm3D) ---
extends SpringArm3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spring_length = 0.15
	margin = 0.05
	collision_mask = 1

# pitch handling, if this script is also doing that:
@export var mouse_sensitivity: float = 0.003
@export var min_pitch_deg: float = -40
@export var max_pitch_deg: float = 40

var pitch: float = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
		rotation.x = pitch
