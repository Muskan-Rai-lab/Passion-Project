extends RigidBody3D

signal collected

@export var item: ItemData                  # NEW: this key's inventory item + icon
@export var positions: Array[Node3D]
@export var use_random_position := true
@export var dialogue_id := ""

@onready var rng = RandomNumberGenerator.new()

var pos_obj
var is_ready := false

func interact():
	if item == null:
		push_error("Key '%s' has no ItemData assigned!" % name)
		return
	if not Inventory.add_item(item):
		DialogueManager.say('full')
		return                              # inventory full: key stays in the world
	collected.emit()
	DialogueManager.say(dialogue_id)
	queue_free()

func _on_body_entered(body):
	if not is_ready:
		pos_obj = body
		freeze = true

func _physics_process(delta: float) -> void:
	if pos_obj != null and is_instance_valid(pos_obj):   # guard added: avoids a crash if that body gets freed
		global_position = pos_obj.global_transform.origin

func _ready() -> void:
	if not use_random_position:
		is_ready = true
		return

	# Only consider positions that no other key has claimed yet
	var free_positions: Array[Node3D] = []
	for p in positions:
		if not p.has_meta("key_claimed"):
			free_positions.append(p)

	if free_positions.is_empty():
		push_error("No free positions left for this key!")
		return

	rng.randomize()
	var chosen: Node3D = free_positions[rng.randi_range(0, free_positions.size() - 1)]
	chosen.set_meta("key_claimed", true)   # claim it so other keys skip it

	print("Chose ", chosen.name, " -> ", chosen.global_position)
	global_position = chosen.global_position

	is_ready = true
