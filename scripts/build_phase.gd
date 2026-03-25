# Orchestrates Build and (provisional) Defense phases.
# Wires placement, stability, collapse, UI, enemies, and save/load together.
class_name BuildPhase
extends Node3D

const DEFAULT_INVENTORY := { "basic": 20, "archer": 20, "melee": 20, "armor": 20 }

# Authoritative purchase costs — must match BLOCK_DATA costs in build_ui.gd.
const BLOCK_COSTS: Dictionary = { "basic": 5, "archer": 15, "melee": 10, "armor": 8 }

@export var cornerstone_scene: PackedScene

@onready var _placement:    BlockPlacement     = $BlockPlacement
@onready var _stability:    StabilityChecker   = $StabilityChecker
@onready var _propagator:   CollapsePropagator = $CollapsePropagator
@onready var _ui:           BuildUI            = $BuildUI
@onready var _save:         SaveSystem         = $SaveSystem
@onready var _wave_spawner: WaveSpawner        = $WaveSpawner
@onready var _resolution:   ResolutionPanel    = $ResolutionPanel

var _blocks_lost: Dictionary = {}
var _wallet: int = 0          # scrap the player currently holds
var _pending_scrap: int = 0   # earned this run, credited on Continue
var _cornerstone_parent: Node3D = null
var _cornerstone_local_transform: Transform3D

func _ready() -> void:
	_stability.rebuild_foundation_cells()

	_ui.block_selected.connect(_placement.select_block_type)
	_ui.keep_layout_pressed.connect(_save_layout)
	_ui.clear_all_pressed.connect(_on_clear_all)
	_ui.start_defense_pressed.connect(_start_defense)
	_ui.show_cones_toggled.connect(func(show: bool): GameEvents.attack_cones_visible_changed.emit(show))
	_ui.purchase_requested.connect(_on_purchase_requested)

	GameEvents.block_placed.connect(func(_p, _t): _run_stability())
	GameEvents.block_removed.connect(func(_p): _run_stability())
	GameEvents.block_destroyed.connect(_on_block_destroyed)

	_placement.block_destroy_requested.connect(_on_destroy_requested)

	GameEvents.run_failed.connect(func(): _on_run_ended(false))
	GameEvents.run_won.connect(func(): _on_run_ended(true))

	_resolution.continue_pressed.connect(_return_to_build)

	_connect_cornerstone()
	_load_or_init()

func _connect_cornerstone() -> void:
	var cornerstones := get_tree().get_nodes_in_group("cornerstone")
	for node: Node3D in cornerstones:
		if node.has_signal("destroyed"):
			_cornerstone_parent = node.get_parent() as Node3D
			_cornerstone_local_transform = node.transform
			node.destroyed.connect(_on_cornerstone_destroyed)

func _respawn_cornerstone() -> void:
	if cornerstone_scene == null or _cornerstone_parent == null:
		push_warning("BuildPhase: cannot respawn cornerstone — scene or parent missing.")
		return
	var cs: Node3D = cornerstone_scene.instantiate()
	cs.transform = _cornerstone_local_transform
	_cornerstone_parent.add_child(cs)
	cs.destroyed.connect(_on_cornerstone_destroyed)

func _on_cornerstone_destroyed() -> void:
	_stability.rebuild_foundation_cells()
	_run_stability_and_propagate()
	GameEvents.run_failed.emit()

# --- Build phase ---

func _load_or_init() -> void:
	var data: Dictionary = _save.load_save()

	# No save file — fresh start.
	if data.is_empty():
		_placement.set_inventory(DEFAULT_INVENTORY.duplicate())
		_wallet = 0
		GameEvents.scrap_changed.emit(_wallet)
		return

	# Stale save (version missing or outdated) — reset inventory to defaults so new
	# block types appear at their correct starting counts. Layout is preserved.
	var inv: Dictionary
	if data.get("version", 1) < SaveSystem.SAVE_VERSION:
		inv = DEFAULT_INVENTORY.duplicate()
	else:
		# Current save: use stored counts exactly (blocks lost in defense stay lost).
		# Any block type not yet in the save gets its default starting count.
		inv = {}
		for type: String in DEFAULT_INVENTORY.keys():
			inv[type] = DEFAULT_INVENTORY[type]
		for type: String in data.get("inventory", {}).keys():
			inv[type] = data["inventory"][type]

	_placement.set_inventory(inv)
	_wallet = data.get("scrap", 0)
	GameEvents.scrap_changed.emit(_wallet)
	var raw: Array = data.get("layout", [])
	if not raw.is_empty():
		var deserialized: Array = _save.deserialize_layout(raw)
		_placement.load_layout(deserialized[0], deserialized[1])
		_run_stability()

func _on_destroy_requested(grid_pos: Vector3i) -> void:
	_placement.destroy_block(grid_pos)

func _on_clear_all() -> void:
	_placement.clear_all()
	_run_stability()

func _on_purchase_requested(block_type: String) -> void:
	var cost: int = BLOCK_COSTS.get(block_type, 0)
	if cost == 0 or _wallet < cost:
		return
	_wallet -= cost
	var inv := _placement.get_inventory()
	inv[block_type] = inv.get(block_type, 0) + 1
	_placement.set_inventory(inv)
	GameEvents.scrap_changed.emit(_wallet)
	_save_full()

func _save_layout() -> void:
	_save_full()
	GameEvents.layout_saved.emit()

func _save_full() -> void:
	_save.save(_placement.get_layout_types(), _placement.get_layout_rotations(),
			_placement.get_inventory(), _wallet)

# --- Defense phase ---

func _start_defense() -> void:
	_blocks_lost.clear()
	_save_full()   # snapshot pre-defense state so _return_to_build has an accurate baseline
	_placement.set_building_enabled(false)
	_ui.set_build_controls_visible(false)
	GameEvents.attack_cones_visible_changed.emit(false)
	_wave_spawner.start(_placement)

func _on_block_destroyed(_pos: Vector3i, block_type: String) -> void:
	_run_stability_and_propagate()
	_blocks_lost[block_type] = _blocks_lost.get(block_type, 0) + 1

func _on_run_ended(won: bool) -> void:
	_wave_spawner.stop()
	var kills: int = _wave_spawner.get_enemies_killed()
	var waves: int = _wave_spawner.get_waves_survived()
	_pending_scrap = kills * ResolutionPanel.SCRAP_PER_KILL + waves * ResolutionPanel.SCRAP_PER_WAVE
	var stats: Dictionary = {
		"won": won,
		"waves_survived": waves,
		"total_waves": _wave_spawner.get_total_waves(),
		"enemies_killed": kills,
		"total_enemies": _wave_spawner.get_total_enemies(),
		"blocks_lost": _blocks_lost.duplicate(),
		"scrap_earned": _pending_scrap,
		"wallet_before": _wallet,
	}
	_resolution.show_stats(stats)

func _return_to_build() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	_placement.clear_all()
	if get_tree().get_nodes_in_group("cornerstone").is_empty():
		_respawn_cornerstone()
	_stability.rebuild_foundation_cells()
	# Reload the pre-defense snapshot, subtract what was actually destroyed, then credit scrap.
	_load_or_init()
	if not _blocks_lost.is_empty():
		var inv := _placement.get_inventory()
		for type: String in _blocks_lost:
			inv[type] = max(0, inv.get(type, 0) - _blocks_lost.get(type, 0))
		_placement.set_inventory(inv)
	_wallet += _pending_scrap
	_pending_scrap = 0
	GameEvents.scrap_changed.emit(_wallet)
	_save_full()   # persist depleted inventory + new wallet balance
	_resolution.hide()
	_placement.set_building_enabled(true)
	_ui.set_build_controls_visible(true)
	GameEvents.attack_cones_visible_changed.emit(true)

# --- Stability helpers ---

func _run_stability() -> void:
	var states := _stability.check(_placement.grid, _placement.get_layout_types())
	_placement.apply_stability_tints(states)
	_update_block_bonuses()

func _run_stability_and_propagate() -> void:
	var states := _stability.check(_placement.grid, _placement.get_layout_types())
	_placement.apply_stability_tints(states)
	_propagator.propagate(_placement.grid, states, _placement, _stability, false)
	# Bonus update happens via block_removed → _run_stability() during propagation,
	# but run once more after so the final post-collapse state is reflected.
	_update_block_bonuses()

# --- Block bonus propagation ---
# Runs after every stability check to keep archer/melee/armor effects current.

# Rotation step → the grid direction directly *behind* the block's facing direction.
# Facing is -Z at step 0; each step rotates +90° around Y.
const _BACKING_DIRS: Array[Vector3i] = [
	Vector3i( 0, 0,  1),  # step 0: faces -Z, backed by +Z
	Vector3i( 1, 0,  0),  # step 1: faces -X, backed by +X
	Vector3i( 0, 0, -1),  # step 2: faces +Z, backed by -Z
	Vector3i(-1, 0,  0),  # step 3: faces +X, backed by -X
]

func _update_block_bonuses() -> void:
	var grid       := _placement.grid
	var grid_types := _placement.get_layout_types()
	var grid_rots  := _placement.get_layout_rotations()
	var budgets    := _stability.get_last_budgets()

	# --- Reset armor on all blocks first ---
	for pos: Vector3i in grid.keys():
		var health := grid[pos].get_node_or_null("BlockHealth") as BlockHealth
		if health:
			health.armor = 0.0

	# --- Propagate armor bonuses from armor blocks ---
	for pos: Vector3i in grid.keys():
		if grid_types.get(pos, "") != "armor":
			continue
		var armor_block := grid[pos] as BlockArmor
		if armor_block == null:
			continue
		for offset: Vector3i in StabilityChecker.FACE_OFFSETS:
			var n: Vector3i = pos + offset
			if not grid.has(n):
				continue
			var health := grid[n].get_node_or_null("BlockHealth") as BlockHealth
			if health:
				# Cap total armor at 90% so blocks can never be made invincible.
				health.armor = minf(0.9, health.armor + armor_block.armor_bonus)

	# --- Update archer fire rate and accuracy ---
	for pos: Vector3i in grid.keys():
		if grid_types.get(pos, "") != "archer":
			continue
		var block = grid[pos]
		if not block.has_method("update_combat_stats"):
			continue
		var budget: int = budgets.get(pos, 0)
		var neighbor_count: int = _count_face_neighbors(pos, grid)
		block.call("update_combat_stats", budget, neighbor_count)

	# --- Update melee backing chain damage ---
	for pos: Vector3i in grid.keys():
		if grid_types.get(pos, "") != "melee":
			continue
		var block = grid[pos]
		if not block.has_method("update_backing_count"):
			continue
		var rot_step: int = grid_rots.get(pos, 0)
		var backing: int = _count_backing_chain(pos, rot_step, grid)
		block.call("update_backing_count", backing)

func _count_face_neighbors(pos: Vector3i, grid: Dictionary) -> int:
	var count := 0
	for offset: Vector3i in StabilityChecker.FACE_OFFSETS:
		if grid.has(pos + offset):
			count += 1
	return count

func _count_backing_chain(pos: Vector3i, rotation_steps: int, grid: Dictionary) -> int:
	var dir: Vector3i = _BACKING_DIRS[rotation_steps % 4]
	var count := 0
	var check := pos + dir
	while grid.has(check):
		count += 1
		check += dir
	return count
