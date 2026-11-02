extends RayCast3D

@onready var E = $"../../../E"

func _ready():
	E.visible = false

func _process(delta):
	if is_colliding():
		var target = find_interactable(get_collider())
		if target:
			E.visible = true
			if Input.is_action_just_pressed("interact"):
				target.interact()
	else:
		E.visible = false

# Walks up from the hit node until it finds one with interact()
func find_interactable(node):
	while node and not node.has_method("interact"):
		node = node.get_parent()
	return node 
