# MeleeBlock — hits every enemy within one grid cell on each attack tick.
# No projectile, no cone — pure omnidirectional AOE.
# Damage scales with the number of blocks stacked directly behind the facing direction.
class_name BlockMelee
extends StaticBody3D

## Radius that catches all face-adjacent (d=1.0) and edge-adjacent (d≈1.41) cells.
@export var attack_range: float = 1.5
@export var base_damage: int = 15
@export var damage_per_backer: int = 8   # flat bonus per block in the backing chain
@export var fire_rate: float = 3.0       # attacks per second

@onready var _timer: Timer = $AttackTimer

# Updated by BuildPhase after each placement/removal.
var _backing_count: int = 0

func _ready() -> void:
	_timer.wait_time = 1.0 / fire_rate
	_timer.timeout.connect(_attack)
	_timer.start()

## Called by BuildPhase when the block chain behind this melee block changes.
func update_backing_count(count: int) -> void:
	_backing_count = count

## Returns live combat stats for the inspect panel.
func get_inspect_stats() -> Dictionary:
	var total: int = base_damage + _backing_count * damage_per_backer
	return {
		"Damage":    "%d  (%d base + %d×%d)" % [total, base_damage, _backing_count, damage_per_backer],
		"Backers":   str(_backing_count),
		"Fire Rate": "%.1f / sec" % fire_rate,
		"Range":     "1 cell",
	}

func _attack() -> void:
	var total_damage := base_damage + _backing_count * damage_per_backer
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node3D:
			var dist: float = (enemy as Node3D).global_position.distance_to(global_position)
			if dist <= attack_range and enemy.has_method("take_damage"):
				enemy.call("take_damage", total_damage)
