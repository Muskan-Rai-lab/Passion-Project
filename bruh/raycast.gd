extends RayCast3D


func _process(delta):
	if is_colliding():
		var hit = get_collider()
		if hit.has_method("interact") && Input.is_action_just_pressed("interact"):
			hit.interact()
