extends StaticBody3D


var interactable = true
var opened = false
func _ready():
	visible = false
	
	
func interact():
	if get_parent().locked == true && get_parent().key == null:
		get_parent().locked =false
	if interactable ==true && get_parent().locked == false:
		interactable = false
		opened =!opened
		if opened ==true:
			visible = true
			get_node("CollisionShape3D").disabled = false
		await get_tree().create_timer(1.0, false).timeout
		interactable = true
			
