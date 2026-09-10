extends RigidBody3D

@export var positions:Array[Node3D]
@onready var rng =RandomNumberGenerator.new()

var pos_obj
var int_text 

func interact():
	int_text.text = "[b][i][font_size=36][center]YOU PICKED UP A KEY"
	
func _on_body_entered(body):
	pos_obj = body
	freeze = true
	
func _physics_process(delta:float) -> void:
	if pos_obj != null:
		global_transform.origin = pos_obj.global_transform.origin
func _ready() -> void:
	var chance = rng.randi_range(0,positions.size() - 1)
	global_transform.origin = positions[chance].global_transform.origin
	int_text = get_node("/root/" + get_tree().current_scene.name + "/key_text")
			


	
