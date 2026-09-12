extends RayCast3D

@onready var E = $"../../../E"
@onready var pick = $"../../../picked_up"
func _ready():
	E.visible = false
	pick.visible = false
	
func _process(delta):
	if is_colliding():
		var hit = get_collider()
		if hit.has_method("interact"):
			E.visible = true
			

		if hit.has_method("interact") && Input.is_action_just_pressed("interact"):
			hit.interact()
	else:
		E.visible = false


func _on_picked_up_visibility_changed():
	await get_tree().create_timer(1.5, false).timeout
	pick.visible = false
