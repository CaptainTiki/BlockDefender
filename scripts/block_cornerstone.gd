# The Cornerstone — pre-placed by the level designer. Pre-placed, indestructible-feeling
# but has health. Acts as a foundation source (infinite stability budget). If destroyed,
# the run is failed and all blocks grounded only through it will cascade-collapse.
class_name BlockCornerstone
extends StaticBody3D

signal destroyed()

@export var max_hp: int = 10

var hp: int

func _ready() -> void:
	hp = max_hp
	add_to_group("foundation_blocks")
	add_to_group("cornerstone")

func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp -= amount
	if hp <= 0:
		destroyed.emit()
		queue_free()
