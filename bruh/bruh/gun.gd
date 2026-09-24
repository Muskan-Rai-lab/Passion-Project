extends RigidBody3D

@export var damage: float = 25.0
@export var fire_rate: float = 5.0   # seconds between shots — infinite ammo, just a cooldown
@export var range: float = 100.0
@export var impulse_force: float = 10.0

@export var pickup_area: Area3D

var is_equipped: bool = false
var can_fire: bool = true
var camera: Camera3D

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

func drop(world_parent: Node3D) -> void:
	is_equipped = false
	camera = null

	var world_transform = global_transform
	get_parent().remove_child(self)
	world_parent.add_child(self)
	global_transform = world_transform

	freeze = false
	call_deferred("_reenable_collision")

	if pickup_area:
		pickup_area.monitoring = true

	apply_impulse(-global_transform.basis.z * 1.5 + Vector3.DOWN * 0.5, Vector3.ZERO)

func _reenable_collision() -> void:
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)

func try_fire() -> void:
	if not is_equipped or not can_fire or camera == null:
		return
	fire()

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

@export var anim_player: AnimationPlayer   # assign in inspector



