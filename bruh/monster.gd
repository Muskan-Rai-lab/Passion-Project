extends CharacterBody3D

var SPEED = 5
var jumpscare_timer = 1
var player
var caught = false
var distance: float
@export var destinations: Array[Node3D]
@onready var vision_raycast = $RayCast3D
var rng
var current_destination
var chasing = false
var able_to_pick = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	rng = RandomNumberGenerator.new()
	player = get_node("/root/" + get_tree().current_scene.name + "/player")
	var random_dest = rng.randi_range(0, destinations.size() - 1)
	current_destination = destinations[random_dest]
func pick_new_destination():
	if chasing == false && able_to_pick == false && distance <= 1:
		able_to_pick = true
		var wait_time = rng.randf_range(3.0,10.0)
		await get_tree().create_timer(wait_time, false).timeout
		if distance <= 1:
			var random_dest = rng.randi_range(0, destinations.size() - 1)
			print(str(random_dest))
			current_destination = destinations[random_dest]
		able_to_pick = false
func _process(delta):
	if chasing == false:
		distance = current_destination.global_transform.origin.distance_to(global_transform.origin)
		update_target_location(current_destination.global_transform.origin)
	if chasing == true:
		distance = player.global_transform.origin.distance_to(global_transform.origin) 
		update_target_location(player.global_transform.origin)
func  _physics_process(delta):
	check_player_visibility()
	if visible:
		if not is_on_floor():
			velocity.y -= gravity* delta
		var current_location = global_transform.origin
		var next_location = $NavigationAgent3D.get_next_path_position()
		var new_velocity = (next_location - current_location).normalized() * SPEED
		$NavigationAgent3D.set_velocity(new_velocity)
		var look_dir = atan2(-velocity.x,-velocity.z)
		rotation.y = look_dir
		if chasing == true:
			distance = player.global_transform.origin.distance_to(global_transform.origin) 
			if distance <= 2 && caught == false:
				player.visible = false
				SPEED = 0
				caught = true
				$jumpscare_camera.current = true
				await get_tree().create_timer(jumpscare_timer, false).timeout
				get_tree().change_scene_to_file("res://level.tscn")
		
			
func update_target_location(target_location):
	$NavigationAgent3D.target_position = target_location

func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = velocity.move_toward(safe_velocity, 0.25)
	move_and_slide()
func check_player_visibility():
	# 1. Aim the RayCast directly at the player. 
	# We use to_local() because target_position is relative to the enemy, not global space.
	# We add + 1.0 to the Y axis so the raycast aims at the player's chest/head, not their feet.
	vision_raycast.target_position = to_local(player.global_position + Vector3(0, 1.0, 0))
	
	# 2. Force the raycast to update instantly for this frame
	vision_raycast.force_raycast_update()
	
	# 3. Check what the raycast is hitting
	if vision_raycast.is_colliding():
		var collider = vision_raycast.get_collider()
		
		# If the raycast hits the player, start chasing
		if collider == player: 
			chasing = true
		else:
			# If it hits a wall, a door, or anything else, stop chasing
			chasing = false
	else:
		# If the raycast hits absolutely nothing, stop chasing
		chasing = false
