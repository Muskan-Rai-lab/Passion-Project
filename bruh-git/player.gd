extends CharacterBody3D

@export var walk_speed: float = 5.5
@export var sprint_speed: float = 8.5
@export var ground_acceleration: float = 60.0
@export var ground_friction: float = 60.0
@export var air_acceleration: float = 8.0
@export var gravity_multiplier: float = 1.0
@export var mouse_sensitivity: float = 0.003
@export var camera: Camera3D
@export var hand_socket: Marker3D    # empty Marker3D positioned where the gun should sit, child of camera
@export var world_root: Node3D       # reference to the main scene/level node, for reparenting on drop

@export var max_stamina: float = 100.0
@export var stamina_drain_rate: float = 25.0
@export var stamina_regen_rate: float = 15.0
@export var stamina_regen_delay: float = 1.0
@export var min_stamina_to_sprint: float = 10.0

@onready var door = $"../NavigationRegion3D/stairs/stair3/Door/hinge/StaticBody3D"
var open
var nearby_gun: Node = null
var equipped_gun: Node = null

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var stamina: float
var regen_timer: float = 0.0
var is_sprinting: bool = false

signal stamina_changed(current: float, max: float)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	open = false
	stamina = max_stamina

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

	# --- Sprint & stamina logic ---
	var wants_to_sprint: bool = Input.is_action_pressed("sprint") and input_dir != Vector2.ZERO

	if wants_to_sprint and stamina > 0.0 and (is_sprinting or stamina >= min_stamina_to_sprint):
		is_sprinting = true
		stamina -= stamina_drain_rate * delta
		stamina = max(stamina, 0.0)
		regen_timer = stamina_regen_delay
		if stamina <= 0.0:
			is_sprinting = false
	else:
		is_sprinting = false
		if regen_timer > 0.0:
			regen_timer -= delta
		else:
			stamina += stamina_regen_rate * delta
			stamina = min(stamina, max_stamina)

	emit_signal("stamina_changed", stamina, max_stamina)

	var current_speed: float = sprint_speed if is_sprinting else walk_speed
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_accel: float = ground_acceleration if is_on_floor() else air_acceleration

	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * current_speed, current_accel * delta * current_speed)
		velocity.z = move_toward(velocity.z, direction.z * current_speed, current_accel * delta * current_speed)
	else:
		var stop_rate: float = ground_friction if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, 0.0, stop_rate * delta * current_speed)
		velocity.z = move_toward(velocity.z, 0.0, stop_rate * delta * current_speed)

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

func _on_area_3d_body_entered(body): #this is for broken stairs
		if not open:
			if body.name != "player":
				return

		if not door.opened:
			$subtitles.text = "This stair is broken. I need to fix it"
			$subtitles.visible = true
		else:
			open = true
