extends Node3D

signal child_door_spotted

@export var key: RigidBody3D
@export var locked: bool
@export var monster: Node3D  # drag your monster node into this field in the Inspector

@onready var child_node = $hinge/StaticBody3D

func _ready():
	if monster:
		monster.door_spotted.connect(_on_monster_door_spotted)
	child_door_spotted.connect(child_node._on_door_parent_spotted)

func _on_monster_door_spotted(door):
	if door == self:
		child_door_spotted.emit()
