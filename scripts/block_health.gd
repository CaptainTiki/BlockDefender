# Per-block health component. Attach as a child of any block scene.
# Call init() after placing to bind the grid position.
# Emits died(grid_pos) when HP hits zero — BuildPhase uses this to trigger collapse.
class_name BlockHealth
extends Node

signal died(grid_pos: Vector3i)

@export var max_hp: int = 3

var hp: int
var armor: float = 0.0  # damage reduction fraction; 0.0 = none, 0.6 = 60% less damage
var _grid_pos: Vector3i

func init(grid_pos: Vector3i) -> void:
	_grid_pos = grid_pos
	hp = max_hp

func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	# Armor reduces damage multiplicatively; always deal at least 1.
	var effective : float = max(1, int(float(amount) * (1.0 - armor)))
	hp -= effective
	if hp <= 0:
		died.emit(_grid_pos)
