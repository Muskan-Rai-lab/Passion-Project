extends CharacterBody3D

@export var speed: float = 5.5
@export var ground_acceleration: float = 60.0
@export var ground_friction: float = 60.0
@export var air_acceleration: float = 8.0
@export var gravity_multiplier: float = 1.0
@export var mouse_sensitivity: float = 0.003
@export var camera: Camera3D
@export var hand_socket: Marker3D    # empty Marker3D positioned where the gun should sit, child of camera
@export var world_root: Node3D       # reference to the main scene/level node, for reparenting on drop

var nearby_gun: Node = null
var equipped_gun: Node = null

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

func set_nearby_gun(gun: Node) -> void:
	nearby_gun = gun
	# show an "E to pick up" UI prompt here if you want

func clear_nearby_gun(gun: Node) -> void:
	if nearby_gun == gun:
		nearby_gun = null
		# hide UI prompt here

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		_handle_interact()

	if Input.is_action_pressed("shoot") and equipped_gun:
		equipped_gun.try_fire()

func _handle_interact() -> void:
	if equipped_gun == null and nearby_gun != null:
		equipped_gun = nearby_gun
		nearby_gun = null
		equipped_gun.pickup(hand_socket, camera)
	elif equipped_gun != null:
		var gun_to_drop = equipped_gun
		equipped_gun = null
		gun_to_drop.drop(world_root)


