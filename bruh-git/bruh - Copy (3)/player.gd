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

@export_group("View Bob")
@export var bob_enabled: bool = true
@export var bob_frequency: float = 1.8        # full left-right cycles per second at walk speed
@export var bob_amplitude_y: float = 0.05    # vertical bounce
@export var bob_amplitude_x: float = 0.05     # side-to-side sway
@export var bob_roll_deg: float = .6        # slight camera tilt per step
@export var sprint_bob_multiplier: float = 1.4
@export var bob_smoothing: float = 10.0       # higher = snappier return to rest

var bob_phase: float = 0.0
#@onready var door = $"../NavigationRegion3D/stairs/stair3/Door/hinge/StaticBody3D"
@onready var ray: RayCast3D =$head/SpringArm3D/RayCast3D
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
	health = max_health
	add_to_group("player")
	_update_health_label()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Q: if a gun is held, drop the gun first (even if the hotbar has items)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q:
		if equipped_gun != null:
			var gun_to_drop = equipped_gun
			equipped_gun = null
			gun_to_drop.drop(world_root if world_root != null else get_tree().current_scene)
			get_viewport().set_input_as_handled()   # stops the Inventory from dropping an item on this same press

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
	if ray.is_colliding():
		var hit = ray.get_collider()
		if hit and hit.has_method("on_look"):
			hit.on_look()

func set_nearby_gun(gun: Node) -> void:
	nearby_gun = gun
	# show an "E to pick up" UI prompt here if you want

func clear_nearby_gun(gun: Node) -> void:
	if nearby_gun == gun:
		nearby_gun = null
		# hide UI prompt here

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		_handle_interact()

	if Input.is_action_pressed("shoot") and equipped_gun:
		equipped_gun.try_fire()
	_update_view_bob(delta)
	
	
func _handle_interact() -> void:
	# E only picks the gun up now
	if equipped_gun == null and nearby_gun != null:
		equipped_gun = nearby_gun
		nearby_gun = null
		equipped_gun.pickup(hand_socket, camera)

func _on_area_3d_body_entered(body): #this is for broken stairs
		if not open:
			if body.name != "player":
				return

		#if not door.opened:
			#print('print')
			#DialogueManager.say("piles")
		else:
			open = true
func _update_view_bob(delta: float) -> void:
	if camera == null or not bob_enabled:
		return

	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	var moving: bool = is_on_floor() and horizontal_speed > 0.5

	var target_x: float = 0.0
	var target_y: float = 0.0
	var target_roll: float = 0.0

	if moving:
		var intensity: float = sprint_bob_multiplier if is_sprinting else 1.0
		var speed_ratio: float = horizontal_speed / walk_speed

		# Bob speeds up with movement speed, so sprinting steps faster automatically
		bob_phase += delta * TAU * bob_frequency * speed_ratio

		# Vertical bounces twice per cycle (once per footstep), sway and roll once per cycle
		target_y = sin(bob_phase * 2.0) * bob_amplitude_y * intensity
		target_x = sin(bob_phase) * bob_amplitude_x * intensity
		target_roll = sin(bob_phase) * deg_to_rad(bob_roll_deg) * intensity

	# Frame-rate independent smoothing; eases back to rest when you stop or leave the ground
	var t: float = 1.0 - exp(-bob_smoothing * delta)
	camera.v_offset = lerp(camera.v_offset, target_y, t)
	camera.h_offset = lerp(camera.h_offset, target_x, t)
	camera.rotation.z = lerp(camera.rotation.z, target_roll, t)
	
signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 100
var health: int
var has_gloves: bool = false

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = max(health - amount, 0)
	health_changed.emit(health, max_health)
	_update_health_label()
	if health == 0:
		die()

func die() -> void:
	died.emit()
	get_tree().reload_current_scene.call_deferred()
@onready var health_label: Label =$CanvasLayer/HealthLabel

func _update_health_label() -> void:
	health_label.text = "Health: %d / %d" % [health, max_health]



