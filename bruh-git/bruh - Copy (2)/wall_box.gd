extends Node3D

var opened = false
var interactable = true
@export var anim: AnimationPlayer
@export var key: RigidBody3D
@export var required_item: ItemData   # optional override, usually leave empty

var _required_id: StringName = &""

func _ready() -> void:
	# Work out which item opens this object
	if required_item != null:
		_required_id = required_item.id
	elif key != null:
		var it = key.get("item")                 # read now, the key node is freed when picked up
		if it != null:
			_required_id = it.id

func interact():
	if interactable == true and not opened:
		# Needs a key: check the hotbar (any slot, no scrolling)
		if _required_id != &"":
			if not Inventory.has_item(_required_id):
				return                           # no key, nothing happens
			Inventory.use_item(required_item.id)  # key disappears from the hotbar

		opened = true
		anim.play("open")
		$hinge/wall_box_lid/CollisionShape3D2.queue_free()
