extends Area3D

signal triggered

@export var ghost: Node3D
@export var scare_sound: AudioStreamPlayer3D
@export var anim_player: AnimationPlayer
@export var anim_name := &"scare"
@export var fallback_duration := 1.5   # used only if no animation is set

var _done := false

func on_looked_at() -> void:
	if _done:
		return
	_done = true
	triggered.emit()
	if ghost:
		ghost.show()
	if scare_sound:
		scare_sound.play()

	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
		await anim_player.animation_finished
	else:
		await get_tree().create_timer(fallback_duration).timeout
	queue_free()
