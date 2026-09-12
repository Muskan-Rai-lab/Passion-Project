extends RigidBody3D

@export var max_health: float = 100.0
@export var fall_impulse_multiplier: float = 1.0
@export var respawn_after_seconds: float = 5.0   # set to 0 to disable respawn
@export var respawn_height_check: float = -10.0  # if it falls below this, respawn

var health: float
var start_transform: Transform3D
var is_knocked: bool = false

func _ready() -> void:
	health = max_health
	start_transform = global_transform

	# Start "asleep"/locked in place until hit
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC

func take_damage(amount: float, hit_point: Vector3 = global_transform.origin, hit_dir: Vector3 = Vector3.ZERO) -> void:
	health -= amount

	if not is_knocked:
		_knock_down(hit_point, hit_dir)

	if health <= 0 and respawn_after_seconds > 0:
		await get_tree().create_timer(respawn_after_seconds).timeout
		_respawn()

func _knock_down(hit_point: Vector3, hit_dir: Vector3) -> void:
	is_knocked = true
	freeze = false  # now real physics applies — gravity, collisions, etc.

	# give it a shove in the direction it was hit, so it doesn't just fall straight down
	var impulse = hit_dir.normalized() * fall_impulse_multiplier
	apply_impulse(impulse, hit_point - global_transform.origin)

func _process(_delta: float) -> void:
	if is_knocked and global_transform.origin.y < respawn_height_check:
		_respawn()

func _respawn() -> void:
	health = max_health
	is_knocked = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = start_transform
	freeze = true
