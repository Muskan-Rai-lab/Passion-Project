extends StaticBody3D

@export var empty_bowl: ItemData                 # NEW: the bowl the player must carry
@export var filled_bowl: ItemData                # NEW: the bowl with rice
@export var fill_animation: StringName = &"lockpick"   # name of your animation in the AnimationPlayer
@export var no_bowl_dialogue_id := ""            # optional: "you need a bowl"
@export var already_filled_dialogue_id := ""     # optional: bowl is already full

@onready var zone: Area3D = $LockpickZone
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var bar: TextureProgressBar = $CanvasLayer/TextureProgressBar
@onready var player = get_node("/root/" + get_tree().current_scene.name + "/player")

var player_in_zone: Node3D = null
var picking := false      # true while the fill animation is running

func _ready() -> void:
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.step = 0.001
	bar.value = 0.0
	bar.hide()
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	anim.animation_finished.connect(_on_animation_finished)

	if empty_bowl == null or filled_bowl == null:
		push_error("Rice sack '%s' needs Empty Bowl and Filled Bowl assigned!" % name)

func _on_body_entered(body: Node3D) -> void:
	if body == player:
		player_in_zone = body

func _on_body_exited(body: Node3D) -> void:
	if body == player_in_zone:
		player_in_zone = null
		if picking:
			cancel_fill()

func interact():
	if picking or player_in_zone == null:
		return
	if empty_bowl == null or filled_bowl == null:
		return

	if Inventory.has_item(empty_bowl.id):
		start_fill()
	elif Inventory.has_item(filled_bowl.id):
		if already_filled_dialogue_id != "":
			DialogueManager.say(already_filled_dialogue_id)
	else:
		if no_bowl_dialogue_id != "":
			DialogueManager.say(no_bowl_dialogue_id)

func start_fill() -> void:
	if not anim.has_animation(fill_animation):
		push_warning("Rice sack: animation '%s' not found" % fill_animation)
		return
	picking = true
	bar.value = 0.0
	bar.show()
	anim.play(fill_animation)

func cancel_fill() -> void:
	picking = false
	anim.stop()
	bar.value = 0.0
	bar.hide()

func _process(_delta: float) -> void:
	if picking:
		bar.value = anim.current_animation_position / anim.current_animation_length

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name != fill_animation or not picking:
		return
	picking = false
	bar.hide()
	# Fill finished: the bowl's icon in the hotbar changes now
	if not Inventory.replace_item(empty_bowl.id, filled_bowl):
		push_warning("Rice sack: the empty bowl was no longer in the inventory")
