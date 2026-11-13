extends TextureProgressBar

@export var player_path: NodePath
@export var hide_when_full: bool = true
@export var fade_speed: float = 5.0

var player: Node

func _ready() -> void:
	player = get_node(player_path)
	player.stamina_changed.connect(_on_stamina_changed)
	value = max_value  # start full

func _on_stamina_changed(current: float, max_val: float) -> void:
	value = current

	if hide_when_full:
		var target_alpha: float = 0.0 if current >= max_val else 1.0
		modulate.a = move_toward(modulate.a, target_alpha, fade_speed * get_process_delta_time())
