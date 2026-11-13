extends Node3D

var player

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node("/root/" + get_tree().current_scene.name + "/player")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_tree().call_group("monster","update_target_location", player.global_transform.origin)
