extends Node

signal changed
signal selected_changed(index: int)

const SLOT_COUNT := 5
const DROP_RAY_LENGTH := 3.0

var slots: Array[ItemData] = []
var selected := 0

func _ready() -> void:
	slots.resize(SLOT_COUNT)

func add_item(item: ItemData) -> bool:
	for i in SLOT_COUNT:
		if slots[i] == null:
			slots[i] = item
			changed.emit()
			return true
	return false

func has_item(id: StringName) -> bool:
	for item in slots:
		if item != null and item.id == id:
			return true
	return false

func remove_item(id: StringName) -> void:
	for i in SLOT_COUNT:
		if slots[i] != null and slots[i].id == id:
			slots[i] = null
			changed.emit()
			return

# Use this when an item is USED on something. It only removes the item
# if "Consumed On Use" is ticked on its ItemData.
func use_item(id: StringName) -> void:
	for i in SLOT_COUNT:
		if slots[i] != null and slots[i].id == id:
			print("use_item: ", id, " consumed_on_use = ", slots[i].consumed_on_use)
			if slots[i].consumed_on_use:
				slots[i] = null
				changed.emit()
			return

func replace_item(old_id: StringName, new_item: ItemData) -> bool:
	for i in SLOT_COUNT:
		if slots[i] != null and slots[i].id == old_id:
			slots[i] = new_item
			changed.emit()
			return true
	return false

func get_selected() -> ItemData:
	return slots[selected]

func select(index: int) -> void:
	selected = clampi(index, 0, SLOT_COUNT - 1)
	selected_changed.emit(selected)

func drop_selected() -> void:
	var item := slots[selected]
	if item == null or not item.can_drop:
		return
	if item.world_scene == null:
		push_warning("Item '%s' has no World Scene assigned, can't drop it" % item.id)
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var drop_point := player.get_node_or_null("DropPoint") as Node3D
	if drop_point == null:
		push_warning("Player needs a Marker3D child named 'DropPoint' near its feet")
		return

	# 1. Find the floor below the drop point
	var from := drop_point.global_position + Vector3.UP * 0.5
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * DROP_RAY_LENGTH)
	if player is CollisionObject3D:
		query.exclude = [player.get_rid()]
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return                                   # nothing below (mid-air), so don't drop

	# 2. Create the pickup, frozen BEFORE it enters the scene so physics never touches it
	var node = item.world_scene.instantiate()
	node.set("item", item)                       # picking it up gives the same item back
	node.set("use_random_position", false)       # don't teleport to a random key spot
	if node is RigidBody3D:
		node.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		node.freeze = true
	get_tree().current_scene.add_child(node)
		# 2. Create the pickup, frozen BEFORE it enters the scene so physics never touches it
	node.set("item", item)
	node.set("use_random_position", false)
	if node is RigidBody3D:
		node.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		node.freeze = true
	get_tree().current_scene.add_child(node)

	# Let the player walk through it (the interact ray can still hit it, so it can be picked up)
	if node is PhysicsBody3D and player is PhysicsBody3D:
		node.add_collision_exception_with(player)
		player.add_collision_exception_with(node)

	# 3. Stand it upright on the floor, using its collision shape to find its bottom
	var floor_pos: Vector3 = hit.position
	node.global_transform = Transform3D(Basis.IDENTITY, floor_pos)
	node.global_position = floor_pos + Vector3.UP * (_bottom_offset(node) + 0.01)

	# 4. Remove it from the hotbar
	slots[selected] = null
	changed.emit()
	if item.player_flag != &"":
		player.set(item.player_flag, false)

func _bottom_offset(body: Node3D) -> float:
	var lowest := 0.0
	for cs in body.find_children("*", "CollisionShape3D", true, false):
		if cs.shape == null:
			continue
		var aabb: AABB = cs.shape.get_debug_mesh().get_aabb()
		for i in 8:
			var p: Vector3 = cs.global_transform * aabb.get_endpoint(i)
			lowest = minf(lowest, p.y - body.global_position.y)
	return -lowest

func _unhandled_input(event: InputEvent) -> void:
	# Keys 1-5
	for i in SLOT_COUNT:
		if event is InputEventKey and event.pressed and event.keycode == KEY_1 + i:
			select(i)
	# Mouse wheel
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			select((selected - 1 + SLOT_COUNT) % SLOT_COUNT)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select((selected + 1) % SLOT_COUNT)
	# Q drops the highlighted item
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q:
		drop_selected()
