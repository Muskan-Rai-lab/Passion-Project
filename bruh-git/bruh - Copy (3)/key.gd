extends RigidBody3D

signal collected

@export var item: ItemData                  # NEW: this key's inventory item + icon
@export var positions: Array[Node3D]
@export var use_random_position := true
@export var dialogue_id := ""

@onready var rng = RandomNumberGenerator.new()
@export var spawn_on_pickup: PackedScene      # drag jumpscare.tscn here
@export var spawn_marker: Node3D              # a Marker3D placed where the scare should appear
var pos_obj
var is_ready := false

func interact():
	if item == null:
			push_error("Key '%s' has no ItemData assigned!" % name)
			return
	if not Inventory.add_item(item):
		DialogueManager.say('full')
		return
	collected.emit()
	DialogueManager.say(dialogue_id)
	_spawn_jumpscare()
	queue_free()

func _spawn_jumpscare() -> void:
	if spawn_on_pickup == null or spawn_marker == null:
		return
	var scare := spawn_on_pickup.instantiate()
	get_tree().current_scene.add_child(scare)   # not a child of the key, since the key is about to be freed
	scare.global_transform = spawn_marker.global_transform
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
