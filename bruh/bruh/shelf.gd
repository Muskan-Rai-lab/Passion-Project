extends StaticBody3D

var opened = false

func _on_door_parent_spotted():
	if not opened:
		interact()

func interact():
	if $AnimationPlayer.current_animation != "open":
		opened =! opened
		if !opened:
			$AnimationPlayer.play_backwards("open")
		if opened:
			$AnimationPlayer.play("open")
