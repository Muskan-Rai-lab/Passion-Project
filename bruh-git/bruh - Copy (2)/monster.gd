extends CharacterBody3D

signal door_spotted(door)

var SPEED = 5
var jumpscare_timer = 1
var player
var caught = false
var distance_sq: float
@export var destinations: Array[Node3D]
@export var view_angle_degrees = 70.0   # total cone width, in front of the monster
@export var view_distance = 15.0        # how far the monster can notice the player at all
@export var door_open_distance = 2.0
@onready var vision_raycast = $RayCast3D
@onready var nav_agent = $NavigationAgent3D
@onready var jumpscare_cam = $jumpscare_camera
@onready var vision_timer = $VisionTimer  # add a Timer node named "VisionTimer" in the editor, wait_time ~0.1-0.15, autostart on
@onready var door_raycast = $DoorRayCast3D  # add a second RayCast3D node named "DoorRayCast3D", pointing forward (-Z), enabled
var player_spawn: Transform3D
var monster_spawn: Transform3D
var start_speed: float
var player_cam: Camera3D
var rng
var current_destination
var chasing = false
var able_to_pick = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Squared thresholds so we can compare with distance_squared_to() and skip the sqrt
const CATCH_DIST_SQ = 4.0     # was distance <= 2
const DEST_DIST_SQ = 1.0      # was distance <= 1

func _ready():
	rng = RandomNumberGenerator.new()
	player = get_node("/root/" + get_tree().current_scene.name + "/player")
	player_spawn = player.global_transform     # the player's initial spawn point
	monster_spawn = global_transform
	start_speed = SPEED
	current_destination = pick_random_destination()
	vision_timer.timeout.connect(check_player_visibility)

# Picks a random destination, skipping any that sit behind a barrier that still exists.
func pick_random_destination() -> Node3D:
	var blocked: Array[Node3D] = []
	for barrier in get_tree().get_nodes_in_group("barrier"):
		if barrier.is_queued_for_deletion():
			continue
		blocked.append_array(barrier.blocked_destinations)

	var options: Array[Node3D] = []
	for d in destinations:
		if d not in blocked and d != current_destination:   # skip the one we're already at
			options.append(d)

	if options.is_empty():
		# Only the current destination is reachable (or nothing is), so keep it
		return current_destination
	return options[rng.randi_range(0, options.size() - 1)]

func pick_new_destination():
	if chasing == false && able_to_pick == false && distance_sq <= DEST_DIST_SQ:
		able_to_pick = true
		var wait_time = rng.randf_range(3.0, 10.0)
		await get_tree().create_timer(wait_time, false).timeout
		if distance_sq <= DEST_DIST_SQ:
			current_destination = pick_random_destination()
		able_to_pick = false

func _process(delta):
	if chasing == false:
		distance_sq = current_destination.global_transform.origin.distance_squared_to(global_transform.origin)
		update_target_location(current_destination.global_transform.origin)
		pick_new_destination()
	else:
		distance_sq = player.global_transform.origin.distance_squared_to(global_transform.origin)
		update_target_location(player.global_transform.origin)

func _physics_process(delta):
	if visible:
		if not is_on_floor():
			velocity.y -= gravity * delta
		var current_location = global_transform.origin
		var next_location = nav_agent.get_next_path_position()
		var direction = next_location - current_location
		direction.y = 0  # let gravity own the Y axis; nav only steers horizontally
		var new_velocity = direction.normalized() * SPEED
		new_velocity.y = velocity.y  # preserve current fall/rise speed
		nav_agent.set_velocity(new_velocity)
		var look_dir = atan2(-velocity.x, -velocity.z)
		rotation.y = look_dir
		check_for_doors()
		if chasing == true and caught == false:
			distance_sq = player.global_transform.origin.distance_squared_to(global_transform.origin)
			if distance_sq <= CATCH_DIST_SQ:
				player.visible = false
				SPEED = 0
				caught = true
				player_cam = get_viewport().get_camera_3d()   # remember which camera to give back
				jumpscare_cam.current = true
				$AudioStreamPlayer3D.play()
				await get_tree().create_timer(jumpscare_timer, false).timeout
				respawn_player()

func update_target_location(target_location):
	nav_agent.target_position = target_location

func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = velocity.move_toward(safe_velocity, 0.25)
	move_and_slide()

func check_for_doors():
	var to_next = nav_agent.get_next_path_position() - global_transform.origin
	to_next.y = 0
	if to_next.length() < 0.01:
		return  # no meaningful direction to check yet
	var target_point = global_transform.origin + to_next.normalized() * door_open_distance
	door_raycast.target_position = door_raycast.to_local(target_point)
	door_raycast.force_raycast_update()
	if door_raycast.is_colliding():
		var hit = door_raycast.get_collider()
		# hit is the door's StaticBody3D (Door -> hinge -> StaticBody3D) —
		# the Door parent (door_parent.gd, with locked/key) is two levels up.
		var door_parent = hit.get_parent().get_parent()
		door_spotted.emit(door_parent)

func check_player_visibility():
	var to_player = player.global_position - global_position
	var flat_to_player = Vector3(to_player.x, 0, to_player.z)
	var dist_to_player = flat_to_player.length()

	# Out of range entirely — don't even bother raycasting.
	if dist_to_player > view_distance:
		chasing = false
		return

	# Outside the forward view cone (e.g. behind or to the side) — can't see them.
	var forward = -global_transform.basis.z
	var angle = rad_to_deg(forward.signed_angle_to(flat_to_player.normalized(), Vector3.UP))
	if abs(angle) > view_angle_degrees / 2.0:
		chasing = false
		return

	# In range and in the cone — now confirm nothing (a wall/door) is blocking line of sight.
	vision_raycast.target_position = vision_raycast.to_local(player.global_position + Vector3(0, 1.0, 0))
	vision_raycast.force_raycast_update()

	if vision_raycast.is_colliding():
		var collider = vision_raycast.get_collider()
		chasing = (collider == player)
	else:
		chasing = false
func respawn_player():
	# Player back to the initial spawn point
	player.global_transform = player_spawn
	player.velocity = Vector3.ZERO
	player.visible = true
	if player_cam:
		player_cam.current = true

	# Monster back to its start and calm again
	global_transform = monster_spawn
	velocity = Vector3.ZERO
	SPEED = start_speed
	chasing = false
	able_to_pick = false
	current_destination = pick_random_destination()
	caught = false
