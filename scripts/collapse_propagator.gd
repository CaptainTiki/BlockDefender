# Handles collapse: finds floating connected groups, warns, then spawns falling physics blocks.
# In build phase, blocks return to inventory. In defense phase, they're destroyed permanently.
class_name CollapsePropagator
extends Node

signal collapse_started(block_count: int)

@export var fall_warning_duration: float = 0.5
@export var falling_block_scene: PackedScene

# Tracks blocks already queued to fall, preventing double-processing during cascade.
var _pending_fall: Dictionary = {}  # Vector3i → true

func propagate(grid: Dictionary, states: Dictionary, placement: BlockPlacement, checker: StabilityChecker, return_to_inventory: bool) -> void:
	# Collect falling blocks not already pending a fall.
	var floating: Array[Vector3i] = []
	for pos: Vector3i in states.keys():
		if states[pos] == StabilityChecker.State.FALLING and not _pending_fall.has(pos):
			floating.append(pos)

	if floating.is_empty():
		return

	var components := _find_components(floating, grid)
	collapse_started.emit(floating.size())

	for component: Array[Vector3i] in components:
		for pos in component:
			_pending_fall[pos] = true
		# Each component falls independently — no await here so all timers run in parallel.
		_warn_then_fall(component, placement, checker, return_to_inventory)

func _warn_then_fall(component: Array[Vector3i], placement: BlockPlacement, checker: StabilityChecker, return_to_inventory: bool) -> void:
	await get_tree().create_timer(fall_warning_duration).timeout
	_spawn_falling_group(component, placement, checker, return_to_inventory)

func _spawn_falling_group(component: Array[Vector3i], placement: BlockPlacement, checker: StabilityChecker, return_to_inventory: bool) -> void:
	# Compute a shared base velocity so the group feels like it falls together.
	var base_impulse := Vector3(randf_range(-0.5, 0.5), randf_range(-1.5, -0.5), randf_range(-0.5, 0.5))

	for pos in component:
		_pending_fall.erase(pos)
		if not placement.grid.has(pos):
			continue

		if return_to_inventory:
			placement.force_remove_block(pos)
		else:
			placement.destroy_block(pos)

		if falling_block_scene == null:
			continue

		var falling: Node3D = falling_block_scene.instantiate()
		get_parent().add_child(falling)
		falling.global_position = Vector3(pos) + Vector3(0.5, 0.5, 0.5)

		if falling is RigidBody3D:
			var rb := falling as RigidBody3D
			# Shared direction + small per-block variation keeps the group coherent.
			rb.apply_central_impulse(base_impulse + Vector3(randf_range(-0.2, 0.2), 0.0, randf_range(-0.2, 0.2)))
			rb.apply_torque_impulse(Vector3(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0), randf_range(-2.0, 2.0)))

	# Re-run stability on whatever remains — could reveal a new cascade.
	var new_states := checker.check(placement.grid, placement.get_layout_types())
	placement.apply_stability_tints(new_states)
	propagate(placement.grid, new_states, placement, checker, return_to_inventory)

# Groups floating positions into connected components via BFS.
func _find_components(floating: Array[Vector3i], _grid: Dictionary) -> Array:
	var floating_set: Dictionary = {}
	for pos in floating:
		floating_set[pos] = true

	var visited: Dictionary = {}
	var components: Array = []

	for start: Vector3i in floating:
		if visited.has(start):
			continue
		var component: Array[Vector3i] = []
		var queue: Array[Vector3i] = [start]
		visited[start] = true
		while not queue.is_empty():
			var current: Vector3i = queue.pop_front()
			component.append(current)
			for offset in StabilityChecker.FACE_OFFSETS:
				var n: Vector3i = current + offset
				if floating_set.has(n) and not visited.has(n):
					visited[n] = true
					queue.append(n)
		components.append(component)

	return components
