extends StaticBody3D


var interactable = true
var opened = false

func interact():
	if get_parent().get_parent().locked == true &&get_parent().get_parent().key == null:
		get_parent().get_parent().locked =false
	if interactable ==true && get_parent().get_parent().locked == false:
		interactable = false
		opened =!opened
		if opened == false:
			$AnimationPlayer.play("close")
		if opened ==true:
			$AnimationPlayer.play("open")
		await get_tree().create_timer(1.0, false).timeout
		interactable = true
			
