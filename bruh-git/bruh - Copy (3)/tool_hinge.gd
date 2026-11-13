extends StaticBody3D

@export var required_item: ItemData   # the key item that opens this toolbox

var interactable = true
var opened = false

@onready var door_root = get_parent()

func _ready() -> void:
	if door_root.locked and required_item == null:
		push_warning("Toolbox '%s' is locked but has no Required Item assigned" % name)

func interact():
	if door_root.locked == true:
		if required_item == null:
			door_root.locked = false              # no item set: unlocks, like the old behaviour
		elif Inventory.has_item(required_item.id):
			# Any hotbar slot works, and the key is consumed
			Inventory.use_item(required_item.id)
			door_root.locked = false

	if interactable == true && door_root.locked == false:
		interactable = false
		opened = !opened
		if opened == false:
			$AnimationPlayer.play_backwards("open")
		if opened == true:
			$AnimationPlayer.play("open")
		await get_tree().create_timer(1.0, false).timeout
		interactable = true
