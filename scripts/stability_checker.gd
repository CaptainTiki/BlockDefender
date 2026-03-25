# Budget-propagation stability model.
#
# Foundation provides infinite budget. Each block type caps the budget flowing through it.
# Budget formula at each step: budget[next] = min(budget[current], next.max_stability) - step_cost
#   Vertical step cost   = 1  (up or down)
#   Horizontal step cost = 2  (any lateral direction)
#
# budget > 0  → GROUNDED  (healthy)
# budget == 0 → WOBBLE    (collapses on any hit)
# budget < 0  → FALLING   (collapses immediately, no hit needed)
class_name StabilityChecker
extends Node

enum State { GROUNDED, WOBBLE, FLOATING, FALLING }

# Max stability per block type — caps the budget that can flow through that block.
# Strong blocks only help when placed early in a chain (before budget is squeezed down).
const BLOCK_MAX_STABILITY: Dictionary = {
	"basic":  6,
	"strong": 10,
}
const DEFAULT_MAX_STABILITY: int = 6
const FOUNDATION_BUDGET:     int = 999  # Effectively infinite.

const FACE_OFFSETS: Array[Vector3i] = [
	Vector3i( 1,  0,  0),
	Vector3i(-1,  0,  0),
	Vector3i( 0,  1,  0),
	Vector3i( 0, -1,  0),
	Vector3i( 0,  0,  1),
	Vector3i( 0,  0, -1),
]

var _foundation_cells: Dictionary = {}  # Vector3i → true
var _last_budgets: Dictionary = {}      # Vector3i → int, updated by check()

func rebuild_foundation_cells() -> void:
	_foundation_cells.clear()
	for node in get_tree().get_nodes_in_group("foundation_blocks"):
		_foundation_cells[_world_to_grid(node.global_position)] = true

# Returns Dictionary[Vector3i, State] for every cell in grid.
# grid_types maps Vector3i → block type string, used to look up max_stability per block.
func check(grid: Dictionary, grid_types: Dictionary) -> Dictionary:
	# Initialise all blocks as unreachable.
	var budget: Dictionary = {}
	for pos in grid.keys():
		budget[pos] = -FOUNDATION_BUDGET

	# Seed: blocks with a face touching a foundation cell.
	for pos: Vector3i in grid.keys():
		var max_stab: int = BLOCK_MAX_STABILITY.get(grid_types.get(pos, ""), DEFAULT_MAX_STABILITY)
		for offset in FACE_OFFSETS:
			if _foundation_cells.has(pos + offset):
				var step_cost: int = 1 if offset.y != 0 else 2
				var init: int = min(FOUNDATION_BUDGET, max_stab) - step_cost
				if init > budget[pos]:
					budget[pos] = init

	# Bellman-Ford: repeatedly relax edges until no budget improves.
	# Converges in at most max_stability iterations (~6-10 passes) for any realistic structure.
	var changed := true
	while changed:
		changed = false
		for pos: Vector3i in grid.keys():
			if budget[pos] <= -FOUNDATION_BUDGET:
				continue
			for offset in FACE_OFFSETS:
				var n: Vector3i = pos + offset
				if not grid.has(n):
					continue
				var n_max_stab: int = BLOCK_MAX_STABILITY.get(grid_types.get(n, ""), DEFAULT_MAX_STABILITY)
				var step_cost:   int = 1 if offset.y != 0 else 2
				var proposed:    int = min(budget[pos], n_max_stab) - step_cost
				if proposed > budget[n]:
					budget[n] = proposed
					changed = true

	# Convert budget values to states.
	_last_budgets = budget.duplicate()
	var states: Dictionary = {}
	for pos: Vector3i in grid.keys():
		var b: int = budget[pos]
		if b > 0:
			states[pos] = State.GROUNDED
		elif b == 0:
			states[pos] = State.WOBBLE
		else:
			states[pos] = State.FALLING
	return states

## Returns the raw budget values from the most recent check() call.
## Budget > 0 means grounded; 0 = wobble; < 0 = falling.
func get_last_budgets() -> Dictionary:
	return _last_budgets

func _world_to_grid(world_pos: Vector3) -> Vector3i:
	return Vector3i(floori(world_pos.x), floori(world_pos.y), floori(world_pos.z))
