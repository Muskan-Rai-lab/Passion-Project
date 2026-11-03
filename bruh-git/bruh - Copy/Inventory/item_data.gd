class_name ItemData
extends Resource

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var consumed_on_use := true      # untick = stays in the hotbar after use
@export var can_drop := true
@export var world_scene: PackedScene     # the pickup scene spawned when dropped
@export var player_flag: StringName      # e.g. has_gloves, set to false when dropped
