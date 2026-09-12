extends RigidBody3D

@export var positions:Array[Node3D]
@onready var rng = RandomNumberGenerator.new()

var pos_obj
@onready var int_text = get_node("/root/" + get_tree().current_scene.name + "/player/picked_up")
var is_ready := false   # <-- guard flag

func interact():
	int_text.visible = true
	queue_free()

func _on_body_entered(body):
	if not is_ready:
		pos_obj = body
		freeze = true

func _physics_process(delta:float) -> void:
	if pos_obj != null:
		global_position = pos_obj.global_transform.origin

func _ready() -> void:
	rng.randomize()
	if positions.is_empty():
		push_error("No positions assigned!")
		return

	var chance = rng.randi_range(0, positions.size() - 1)
	print("Chose index: ", chance, " -> ", positions[chance].global_position)
	global_position = positions[chance].global_position


	is_ready = true
