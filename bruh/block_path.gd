extends StaticBody3D


func interact():
	if get_parent().key == null:
		$CollisionShape3D.queue_free()
	
