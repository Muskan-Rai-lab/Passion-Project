extends RigidBody3D

signal collected

@export var item: ItemData                  # NEW: gloves item + icon for the hotbar
@export var dialogue_id := ""

var pos_obj
var is_ready := false

func interact():
	if item == null:
		push_error("Key '%s' has no ItemData assigned!" % name)
		return
	if not Inventory.add_item(item):
		DialogueManager.say('full')
		return                            
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.has_gloves = true
	collected.emit()
	DialogueManager.say(dialogue_id)
	queue_free()
