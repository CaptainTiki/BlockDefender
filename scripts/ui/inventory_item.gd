# Single inventory slot — icon button with count badge and radio-select behaviour.
class_name InventoryItem
extends TextureButton

signal item_selected(block_type: String)

@export var block_type: String = ""

@onready var _count_label: Label = $CountLabel


func _ready() -> void:
	toggled.connect(_on_toggled)


func set_count(count: int) -> void:
	_count_label.text = str(count)
	# Dim when empty so the player knows they're out, but never disable —
	# a disabled TextureButton swallows no input, so the detail panel can't open.
	self_modulate.a = 0.5 if count <= 0 else 1.0


func _on_toggled(is_pressed: bool) -> void:
	if is_pressed:
		item_selected.emit(block_type)
	# Tint gold when selected, white when idle.
	self_modulate = Color(1.0, 0.82, 0.25) if is_pressed else Color.WHITE
