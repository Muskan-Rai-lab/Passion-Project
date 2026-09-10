extends StaticBody3D

var opened = false

func interact():
	if $AnimationPlayer.current_animation != "open":
		opened =! opened
		if !opened:
			$AnimationPlayer.play_backwards("open")
		if opened:
			$AnimationPlayer.play("open")
