extends StaticBody3D

@export var key_items: Array[ItemData]            # NEW: replaces `keys`, one ItemData per key
@export var key_animations: Array[StringName]     # one per key, same order as key_items
@export var locked: bool
@export var shock_damage: int = 20
@export var shock_dialogue_id := ""
@export var no_need :bool


func _get_player() -> Node:
	return get_tree().get_first_node_in_group("player")


func _shock_player(player: Node) -> void:
	player.take_damage(shock_damage)
	if shock_dialogue_id != "":
		DialogueManager.say(shock_dialogue_id)

var key_players: Array[AnimationPlayer] = []      # filled in _ready: key 0 -> anim1, key 1 -> anim2
var opened := false

var _played: Array[bool] = []      # key was used and its animation handled
var _busy := false                 # key animations are running

@onready var animation_player: AnimationPlayer = $anim1


func _ready() -> void:
	key_players = [$anim1, $anim2]
	_played.resize(key_items.size())
	_played.fill(false)

	# Helpful setup warnings
	if key_animations.size() != key_items.size():
		push_warning("Win condition: key_items (%d) and key_animations (%d) should be the same size" % [key_items.size(), key_animations.size()])
	for i in key_items.size():
		if key_items[i] == null:
			push_warning("Win condition: key_items[%d] is empty" % i)


func interact() -> void:
	if _busy or opened:
		return

	# Glove check: no gloves = shock, and nothing else happens
	var player := _get_player()
	if player == null:
		return
	if no_need == false:
		if not player.has_gloves:
			_shock_player(player)
			return

	var queue := _collect_new_key_animations()
	if not queue.is_empty():
		_busy = true
		for entry in queue:
			var anim_player: AnimationPlayer = entry["player"]
			anim_player.play(entry["anim"])
			await anim_player.animation_finished
		_busy = false

	_try_unlock()
	if locked:
		return

	_open_and_win()


func _open_and_win() -> void:
	opened = true
	animation_player.play("open")
	await animation_player.animation_finished
	get_tree().change_scene_to_file("res://win.tscn")


func _collect_new_key_animations() -> Array:
	var queue := []
	for i in key_items.size():
		if _played[i]:
			continue

		# Only keys the player is carrying (in any slot) get used
		var key_item: ItemData = key_items[i]
		if key_item == null or not Inventory.has_item(key_item.id):
			continue

		Inventory.use_item(key_item.id)     # key disappears from the hotbar
		_played[i] = true

		var player: AnimationPlayer = key_players[i] if i < key_players.size() else null
		var anim: StringName = key_animations[i] if i < key_animations.size() else &""

		if player == null or not player.has_animation(anim):
			push_warning("Door: key %d has no valid player or animation" % i)
			continue

		queue.append({"player": player, "anim": anim})
	return queue


func _try_unlock() -> void:
	if locked and not key_items.is_empty() and not _played.has(false):
		locked = false
