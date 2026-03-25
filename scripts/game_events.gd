# Signal bus — no state, no logic. Emit and connect only.
extends Node

signal block_placed(grid_pos: Vector3i, block_type: String)
signal block_removed(grid_pos: Vector3i)
signal block_destroyed(grid_pos: Vector3i, block_type: String)
signal enemy_killed
signal inventory_changed(inventory: Dictionary)
signal layout_saved()
signal layout_loaded()
signal run_failed()
signal run_won()
signal wave_started(wave_num: int, total_waves: int)
signal wave_completed(wave_num: int)
signal attack_cones_visible_changed(show: bool)
signal scrap_changed(new_amount: int)
