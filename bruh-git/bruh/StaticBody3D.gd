extends StaticBody3D

var opened = false

func interact():
	if get_parent().locked == true &&get_parent().key == null:
		get_parent().locked =false
	if get_parent().locked == false && opened == false:
			$AnimationPlayer.play("open")
			opened = true
			
			

