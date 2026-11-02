# res://inventory/hotbar.gd
extends CanvasLayer

@onready var slots_box: HBoxContainer = $MarginContainer/Slots

const SLOT_SIZE := Vector2(64, 64)
var panels: Array[Panel] = []
var icons: Array[TextureRect] = []

func _ready() -> void:
	for i in Inventory.SLOT_COUNT:
		var panel := Panel.new()
		panel.custom_minimum_size = SLOT_SIZE
		slots_box.add_child(panel)

		var icon := TextureRect.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(icon)

		panels.append(panel)
		icons.append(icon)

	Inventory.changed.connect(_refresh)
	Inventory.selected_changed.connect(_highlight)
	_refresh()
	_highlight(Inventory.selected)

func _refresh() -> void:
	for i in Inventory.SLOT_COUNT:
		var item := Inventory.slots[i]
		icons[i].texture = item.icon if item else null   # empty slot = no image

func _highlight(index: int) -> void:
	for i in panels.size():
		panels[i].modulate = Color.WHITE if i == index else Color(0.6, 0.6, 0.6)
