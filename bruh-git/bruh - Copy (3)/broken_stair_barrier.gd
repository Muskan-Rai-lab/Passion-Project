extends StaticBody3D

@export var required_item_id: String = "piles"
@export var consume_item: bool = false   # leave false if the item stays in the hotbar
@export var blocked_destinations: Array[Node3D]
@export var unlock_animation: StringName = &"unlock"

@onready var check_area: Area3D = $CheckArea
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var wall_shape: CollisionShape3D = $CollisionShape3D

var unlocked := false

func _ready() -> void:
	add_to_group("barrier")
	check_area.body_entered.connect(_on_body_entered)
	Inventory.changed.connect(_recheck)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_try_unlock()

func _recheck() -> void:
	for body in check_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			_try_unlock()
			return

func _try_unlock() -> void:
	if unlocked:
		return
	var id := StringName(required_item_id)
	if not Inventory.has_item(id):
		return

	unlocked = true                          # set first, so nothing can trigger this twice
	remove_from_group("barrier")             # monster may use the blocked destinations right away
	wall_shape.set_deferred("disabled", true)  # player can walk through during the animation

	if consume_item:
		Inventory.remove_item(id)            # this emits changed, but `unlocked` stops a re-run

	if anim.has_animation(unlock_animation):
		anim.play(unlock_animation)
		await anim.animation_finished

	queue_free()
