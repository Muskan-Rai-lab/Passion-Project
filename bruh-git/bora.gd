extends StaticBody3D

@export var required_key: RigidBody3D   # <-- new: drag the matching key here

@onready var zone: Area3D = $LockpickZone
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var bar: TextureProgressBar = $CanvasLayer/TextureProgressBar
@onready var player = get_node("/root/" + get_tree().current_scene.name + "/player")

var key_collected := false
var player_in_zone: Node3D = null
var picking := false
var unlocked := false

func _ready() -> void:
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.step = 0.001   # <-- new: allows smooth fractional values
	bar.value = 0.0
	bar.hide()
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	anim.animation_finished.connect(_on_animation_finished)

	if required_key:   # <-- new
		required_key.collected.connect(_on_key_collected)
	else:
		print("Door has no required_key assigned!")

func _on_key_collected() -> void:   # <-- new
	key_collected = true

func _on_body_entered(body: Node3D) -> void:
	if body == player:
		player_in_zone = body

func _on_body_exited(body: Node3D) -> void:
	if body == player_in_zone:
		player_in_zone = null
		if picking:
			cancel_lockpick()

func interact():
	if picking or unlocked:
		return
	if player_in_zone == null:
		return
	if key_collected:
		start_lockpick()
	else:
		print("The door is locked. You need a key.")

func start_lockpick() -> void:
	picking = true
	bar.value = 0.0
	bar.show()
	anim.play("lockpick")

func cancel_lockpick() -> void:
	picking = false
	anim.stop()
	bar.value = 0.0
	bar.hide()

func _process(_delta: float) -> void:
	if picking:
		bar.value = anim.current_animation_position / anim.current_animation_length

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "lockpick":
		picking = false
		unlocked = true
		bar.hide()
		print("Door unlocked!")
