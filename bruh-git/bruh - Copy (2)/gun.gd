extends RigidBody3D

@export var damage: float = 25.0
@export var fire_rate: float = 5.0   # seconds between shots, infinite ammo, just a cooldown
@export var range: float = 100.0
@export var impulse_force: float = 10.0

@export var pickup_area: Area3D
@export var anim_player: AnimationPlayer   # assign in inspector

var is_equipped: bool = false
var can_fire: bool = true
var camera: Camera3D
var _passthrough_body: PhysicsBody3D       # NEW: the player we ignore while the gun lies on the floor

func _ready() -> void:
	freeze = false
	if pickup_area:
		pickup_area.body_entered.connect(_on_pickup_area_entered)
		pickup_area.body_exited.connect(_on_pickup_area_exited)
	if anim_player == null:
		anim_player = get_node_or_null("AnimationPlayer")

func _on_pickup_area_entered(body: Node3D) -> void:
	if body.has_method("set_nearby_gun"):
		body.set_nearby_gun(self)

func _on_pickup_area_exited(body: Node3D) -> void:
	if body.has_method("clear_nearby_gun"):
		body.clear_nearby_gun(self)

func pickup(hand_node: Node3D, player_camera: Camera3D) -> void:
	is_equipped = true
	camera = player_camera
	add_to_group("held_gun")                       # NEW: lets the inventory know Q belongs to the gun

	# NEW: stop ignoring the player now that it's in the hand
	if _passthrough_body != null and is_instance_valid(_passthrough_body):
		remove_collision_exception_with(_passthrough_body)
		_passthrough_body.remove_collision_exception_with(self)
	_passthrough_body = null

	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	if pickup_area:
		pickup_area.monitoring = false

	call_deferred("_reparent_to_hand", hand_node)

func _reparent_to_hand(hand_node: Node3D) -> void:
	var world_transform = global_transform
	get_parent().remove_child(self)
	hand_node.add_child(self)
	global_transform = world_transform
	position = Vector3.ZERO
	rotation = Vector3.ZERO

func drop(world_parent: Node) -> void:
	if not is_equipped:
		return                                      # already dropped (guards against double calls)
	is_equipped = false
	camera = null
	call_deferred("remove_from_group", "held_gun")  # deferred so the inventory doesn't also drop an item on this same Q press

	var info := _find_drop_spot()                   # NEW: floor below the player's DropPoint
	var world_transform := global_transform
	get_parent().remove_child(self)
	world_parent.add_child(self)
	global_transform = world_transform

	if not info.is_empty():
		# Frozen, upright, resting on the floor, and the player can walk through it
		freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		freeze = true
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO

		var floor_pos: Vector3 = info["pos"]
		global_transform = Transform3D(Basis(Vector3.UP, info["yaw"]), floor_pos)
		global_position = floor_pos + Vector3.UP * (_bottom_offset() + 0.01)

		var player = info["player"]
		if player is PhysicsBody3D:
			add_collision_exception_with(player)
			player.add_collision_exception_with(self)
			_passthrough_body = player
	else:
		# No DropPoint or no floor below: old physics drop, so the gun never stays stuck
		freeze = false
		apply_impulse(-global_transform.basis.z * 1.5 + Vector3.DOWN * 0.5, Vector3.ZERO)

	call_deferred("_reenable_collision")

	if pickup_area:
		pickup_area.monitoring = true

func _reenable_collision() -> void:
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)

# NEW: returns {"pos", "yaw", "player"}, or an empty dictionary if it can't find a spot
func _find_drop_spot() -> Dictionary:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return {}
	var drop_point := player.get_node_or_null("DropPoint") as Node3D
	if drop_point == null:
		push_warning("Player needs a Marker3D child named 'DropPoint' near its feet")
		return {}

	var from := drop_point.global_position + Vector3.UP * 0.5
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 3.0)
	var exclude: Array[RID] = [get_rid()]
	if player is CollisionObject3D:
		exclude.append(player.get_rid())
	query.exclude = exclude

	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {}
	return {"pos": hit.position, "yaw": drop_point.global_rotation.y, "player": player}

# NEW: how far the gun's lowest collision point sits below its origin
func _bottom_offset() -> float:
	var lowest := 0.0
	for cs in find_children("*", "CollisionShape3D", true, false):
		if cs.get_parent() is Area3D or cs.shape == null:
			continue                                # skip the pickup area's big shape
		var aabb: AABB = cs.shape.get_debug_mesh().get_aabb()
		for i in 8:
			var p: Vector3 = cs.global_transform * aabb.get_endpoint(i)
			lowest = minf(lowest, p.y - global_position.y)
	return -lowest

func try_fire() -> void:
	if not is_equipped or not can_fire or camera == null:
		return
	fire()

# fire(), _handle_hit() and _reset_after() stay exactly as you have them

func fire() -> void:
	can_fire = false
	_reset_after(fire_rate)

	if anim_player and anim_player.has_animation("shoot"):
		anim_player.stop()  # in case it's still mid-animation from a rapid re-trigger
		anim_player.play("shoot")

	var space_state = camera.get_world_3d().direct_space_state
	var origin = camera.global_transform.origin
	var forward = -camera.global_transform.basis.z
	var target_point = origin + forward * range

	var query = PhysicsRayQueryParameters3D.create(origin, target_point)
	query.collide_with_bodies = true
	query.exclude = [self]

	var result = space_state.intersect_ray(query)
	if result:
		_handle_hit(result)

func _handle_hit(result: Dictionary) -> void:
	var collider = result.collider
	var hit_point: Vector3 = result.position

	if collider is RigidBody3D and collider.has_method("take_damage"):
		var dir = (hit_point - camera.global_transform.origin).normalized()
		collider.take_damage(damage, hit_point, dir)
	elif collider is RigidBody3D:
		var dir = (hit_point - camera.global_transform.origin).normalized()
		collider.apply_impulse(dir * impulse_force, hit_point - collider.global_transform.origin)
	elif collider.has_method("take_damage"):
		collider.take_damage(damage)

func _reset_after(t: float) -> void:
	await get_tree().create_timer(t).timeout
	can_fire = true




