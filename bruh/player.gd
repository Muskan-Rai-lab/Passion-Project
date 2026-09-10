extends CharacterBody3D

@export var speed: float = 5.5
@export var ground_acceleration: float = 60.0
@export var ground_friction: float = 60.0
@export var air_acceleration: float = 8.0
@export var gravity_multiplier: float = 1.0
@export var mouse_sensitivity: float = 0.003

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * gravity_multiplier * delta

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var current_accel: float = ground_acceleration if is_on_floor() else air_acceleration

	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * speed, current_accel * delta * speed)
		velocity.z = move_toward(velocity.z, direction.z * speed, current_accel * delta * speed)
	else:
		var stop_rate: float = ground_friction if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, 0.0, stop_rate * delta * speed)
		velocity.z = move_toward(velocity.z, 0.0, stop_rate * delta * speed)

	move_and_slide()
