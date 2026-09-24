extends RayCast3D


func _process(delta):
	if is_colliding():
		var hit = get_collider()
		if hit.name == "player" && !get_parent().chasing:
			get_parent().chasing = true
			get_parent().SPEED = 5.0
		
