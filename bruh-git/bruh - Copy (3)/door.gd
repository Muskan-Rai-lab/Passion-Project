extends StaticBody3D

@export var dialogue_id := ""
@export var look_id := ""
@export var required_item: ItemData   # optional override, usually leave empty

var interactable = true
var opened = false
var _required_id: StringName = &""

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var door_root = get_parent().get_parent()   # the door parent (Node3D)

func _ready() -> void:
	# Work out which item opens this door
	if required_item != null:
		_required_id = required_item.id
	else:
		var k = door_root.get("key")                  # the key assigned on the door parent
		if k != null and is_instance_valid(k):
			var it = k.get("item")
			if it != null:
				_required_id = it.id

func _on_door_parent_spotted():
	pass

func interact():
	if door_root.locked == true:
		if _required_id != &"":
			# Locked with a key: needs the item in the inventory, then consumes it
			if Inventory.has_item(_required_id):
				Inventory.use_item(required_item.id)
				door_root.locked = false
		elif door_root.key == null:
			door_root.locked = false                  # old behaviour for doors with no key

	if interactable == true && door_root.locked == false:
		interactable = false
		opened = !opened

		# Collision off while the door is moving
		collision_shape.set_deferred("disabled", true)
		if opened == false && door_root.not_need == false:
			$AnimationPlayer.play_backwards("open")
		if opened == true:
			$AnimationPlayer.play("open")

		await get_tree().create_timer(1.0, false).timeout

		collision_shape.set_deferred("disabled", false)
		if door_root.not_need == false:
			interactable = true
	else:
		DialogueManager.say(dialogue_id)

func _on_door_child_door_spotted():
	# Safety: never let an automatic open eat the player's key
	if door_root.locked and _required_id != &"":
		return
	if interactable and not opened:
		interact()
