# Handles grid-based block placement and removal in the Build Phase.
# Owns the grid dictionary and the ghost preview block.
class_name BlockPlacement
extends Node3D

@export var ground_layer: int = 1   # collision layer for the arena ground
@export var block_layer: int = 2    # collision layer for placed blocks

# Block type → scene registry. Add new block types here.
const BLOCK_SCENES: Dictionary = {
	"basic":  "res://scenes/blocks/block_basic.tscn",
	"archer": "res://scenes/blocks/block_archer.tscn",
	"melee":  "res://scenes/blocks/block_melee.tscn",
	"armor":  "res://scenes/blocks/block_armor.tscn",
}

var _block_scenes: Dictionary = {}  # String → PackedScene, loaded in _ready()

var grid: Dictionary = {}              # Vector3i -> Node3D (placed block scenes)
var _grid_types: Dictionary = {}       # Vector3i -> String (block type per cell)
var _grid_rotations: Dictionary = {}   # Vector3i -> int (0-3, Y rotation steps of 90°)
var _inventory: Dictionary = {}        # block_type -> count
var _selected_type: String = "basic"
var _selected_rotation: int = 0        # 0-3 (×90° Y steps)
var _ghost: Node3D = null

signal block_destroy_requested(grid_pos: Vector3i)
signal block_inspect_requested(grid_pos: Vector3i)   # Vector3i(-1,-1,-1) = clear selection
signal inspect_mode_changed(is_inspect: bool)

# Pre-created materials — reused every tint pass, never allocated per-frame.
var _mat_ghost_ok    := StandardMaterial3D.new()
var _mat_ghost_block := StandardMaterial3D.new()
var _mat_floating    := StandardMaterial3D.new()
var _mat_wobble      := StandardMaterial3D.new()

@onready var _space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

func _ready() -> void:
	for type: String in BLOCK_SCENES:
		_block_scenes[type] = load(BLOCK_SCENES[type])

	_mat_ghost_ok.albedo_color    = Color(0.3, 1.0, 0.4, 0.4)
	_mat_ghost_ok.transparency    = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_ghost_block.albedo_color = Color(1.0, 0.2, 0.2, 0.4)
	_mat_ghost_block.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_floating.albedo_color    = Color(1.0, 0.3, 0.1, 0.7)
	_mat_floating.transparency    = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_wobble.albedo_color      = Color(1.0, 0.85, 0.0, 0.7)
	_mat_wobble.transparency      = BaseMaterial3D.TRANSPARENCY_ALPHA
	_spawn_ghost()

var _building_enabled: bool = true
var _inspect_mode: bool     = false

func set_building_enabled(enabled: bool) -> void:
	_building_enabled = enabled
	if not enabled:
		_set_ghost_visible(false)
		if _inspect_mode:
			_exit_inspect_mode()

func _unhandled_input(event: InputEvent) -> void:
	if not _building_enabled:
		return

	# Escape toggles between build and inspect mode.
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _inspect_mode:
			_exit_inspect_mode()
		else:
			_enter_inspect_mode()
		return

	if _inspect_mode:
		if event is InputEventMouseButton and event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:  _try_inspect()
				MOUSE_BUTTON_RIGHT: block_inspect_requested.emit(Vector3i(-1, -1, -1))
		return

	# --- Build mode input ---
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_try_place()
			MOUSE_BUTTON_RIGHT:
				# Hit a block → remove it. Miss → drop out of build mode.
				if not _try_remove():
					_enter_inspect_mode()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_DELETE: _try_destroy()
			KEY_Q:      _selected_rotation = (_selected_rotation - 1 + 4) % 4
			KEY_E:      _selected_rotation = (_selected_rotation + 1) % 4

func _enter_inspect_mode() -> void:
	_inspect_mode = true
	# Destroy the ghost so nothing follows the cursor in inspect mode.
	if _ghost:
		_ghost.queue_free()
		_ghost = null
	inspect_mode_changed.emit(true)

func _exit_inspect_mode() -> void:
	_inspect_mode = false
	block_inspect_requested.emit(Vector3i(-1, -1, -1))  # clear panel
	_spawn_ghost()
	inspect_mode_changed.emit(false)

func _try_inspect() -> void:
	var result := _raycast(block_layer)
	if result.is_empty():
		block_inspect_requested.emit(Vector3i(-1, -1, -1))
		return
	var grid_pos := _world_to_grid(result["position"] - result["normal"] * 0.1)
	if grid.has(grid_pos):
		block_inspect_requested.emit(grid_pos)
	else:
		block_inspect_requested.emit(Vector3i(-1, -1, -1))

func _process(_delta: float) -> void:
	_update_ghost()

# --- Placement ---

func _try_place() -> void:
	var result := _raycast(ground_layer | block_layer)
	if result.is_empty():
		return
	var grid_pos := _hit_to_place_pos(result)
	if grid.has(grid_pos):
		return
	if not _has_inventory(_selected_type):
		return
	_place_block(grid_pos, _selected_type, _selected_rotation)

func _place_block(grid_pos: Vector3i, block_type: String, rotation_steps: int = 0, consume: bool = true) -> void:
	var scene: PackedScene = _block_scenes.get(block_type)
	if scene == null:
		push_error("BlockPlacement: no scene registered for block type '%s'" % block_type)
		return
	var block: Node3D = scene.instantiate()
	add_child(block)
	block.global_position = Vector3(grid_pos) + Vector3(0.5, 0.5, 0.5)
	block.rotation.y = rotation_steps * (PI / 2.0)
	grid[grid_pos] = block
	_grid_types[grid_pos] = block_type
	_grid_rotations[grid_pos] = rotation_steps
	# Bind health component so damage triggers collapse through the normal destroy flow.
	var health : BlockHealth = block.get_node_or_null("BlockHealth") as BlockHealth
	if health:
		health.init(grid_pos)
		health.died.connect(_on_block_health_died)
	if consume:
		_consume_inventory(block_type)
	GameEvents.block_placed.emit(grid_pos, block_type)

func _on_block_health_died(grid_pos: Vector3i) -> void:
	destroy_block(grid_pos)

# --- Removal & Destruction ---

func _try_remove() -> bool:
	var result := _raycast(block_layer)
	if result.is_empty():
		return false
	var grid_pos := _world_to_grid(result["position"] - result["normal"] * 0.1)
	if not grid.has(grid_pos):
		return false
	_remove_block(grid_pos)
	return true

func _remove_block(grid_pos: Vector3i) -> void:
	grid[grid_pos].queue_free()
	grid.erase(grid_pos)
	_return_inventory(_grid_types[grid_pos])
	_grid_types.erase(grid_pos)
	_grid_rotations.erase(grid_pos)
	GameEvents.block_removed.emit(grid_pos)

# Delete key — simulates an enemy destroying a block (no inventory return).
func _try_destroy() -> void:
	var result := _raycast(block_layer)
	if result.is_empty():
		return
	var grid_pos := _world_to_grid(result["position"] - result["normal"] * 0.1)
	if grid.has(grid_pos):
		block_destroy_requested.emit(grid_pos)

# Called by BuildPhase when a block is destroyed (enemy hit / test). No inventory return.
func destroy_block(grid_pos: Vector3i) -> void:
	if not grid.has(grid_pos):
		return
	var block_type: String = _grid_types.get(grid_pos, "")
	grid[grid_pos].queue_free()
	grid.erase(grid_pos)
	_grid_types.erase(grid_pos)
	_grid_rotations.erase(grid_pos)
	GameEvents.block_destroyed.emit(grid_pos, block_type)

# Called by CollapsePropagator during build-phase cascade. Returns block to inventory.
func force_remove_block(grid_pos: Vector3i) -> void:
	if not grid.has(grid_pos):
		return
	_remove_block(grid_pos)

func get_block_type_at(grid_pos: Vector3i) -> String:
	return _grid_types.get(grid_pos, "")

# --- Ghost preview ---

func _spawn_ghost() -> void:
	var scene: PackedScene = _block_scenes.get(_selected_type)
	if scene == null:
		return
	_ghost = scene.instantiate()
	add_child(_ghost)
	_set_ghost_visible(false)
	# Make ghost non-collidable so raycasts ignore it.
	if _ghost is StaticBody3D:
		(_ghost as StaticBody3D).collision_layer = 0
		(_ghost as StaticBody3D).collision_mask = 0

func _update_ghost() -> void:
	if _inspect_mode or _ghost == null:
		return
	var result := _raycast(ground_layer | block_layer)
	if result.is_empty():
		_set_ghost_visible(false)
		return
	var grid_pos := _hit_to_place_pos(result)
	var blocked := grid.has(grid_pos)
	_set_ghost_visible(true)
	_ghost.global_position = Vector3(grid_pos) + Vector3(0.5, 0.5, 0.5)
	_ghost.rotation.y = _selected_rotation * (PI / 2.0)
	_set_ghost_color(not blocked)

func _set_ghost_visible(block_is_visible: bool) -> void:
	if _ghost:
		_ghost.visible = block_is_visible

func _set_ghost_color(ok: bool) -> void:
	_apply_material_override(_ghost, _mat_ghost_ok if ok else _mat_ghost_block)

# Tints every placed block based on the stability state map from StabilityChecker.
func apply_stability_tints(states: Dictionary) -> void:
	for pos: Vector3i in grid.keys():
		var state : StabilityChecker.State = states.get(pos, StabilityChecker.State.FLOATING)
		var mat: StandardMaterial3D
		match state:
			StabilityChecker.State.GROUNDED: mat = null
			StabilityChecker.State.WOBBLE:   mat = _mat_wobble
			StabilityChecker.State.FALLING:  mat = _mat_floating
		_apply_material_override(grid[pos], mat)

# Recursively sets material override on every MeshInstance3D in the subtree.
func _apply_material_override(node: Node, mat: StandardMaterial3D) -> void:
	if node is ConeVisual:
		return  # Cone keeps its own ghost material permanently — never tint it.
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
	for child in node.get_children():
		_apply_material_override(child, mat)

# --- Grid helpers ---

func _hit_to_place_pos(result: Dictionary) -> Vector3i:
	# Offset by the face normal so we place on top of / beside the hit surface.
	var offset_pos : Vector3 = result["position"] + result["normal"] * 0.5
	return _world_to_grid(offset_pos)

func _world_to_grid(world_pos: Vector3) -> Vector3i:
	return Vector3i(floori(world_pos.x), floori(world_pos.y), floori(world_pos.z))

# --- Raycast ---

func _raycast(layers: int) -> Dictionary:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return {}
	var mouse := get_viewport().get_mouse_position()
	var origin := cam.project_ray_origin(mouse)
	var target := origin + cam.project_ray_normal(mouse) * 100.0
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.collision_mask = layers
	return _space.intersect_ray(query)

# --- Inventory ---

func set_inventory(inv: Dictionary) -> void:
	_inventory = inv
	GameEvents.inventory_changed.emit(_inventory)

func get_inventory() -> Dictionary:
	return _inventory

func select_block_type(type: String) -> void:
	# Clicking an inventory item always returns to build mode.
	if _inspect_mode:
		_exit_inspect_mode()
	if type == _selected_type:
		return
	_selected_type = type
	# Respawn ghost so it uses the correct scene for the new type.
	if _ghost:
		_ghost.queue_free()
		_ghost = null
	_spawn_ghost()

func _has_inventory(type: String) -> bool:
	return _inventory.get(type, 0) > 0

func _consume_inventory(type: String) -> void:
	_inventory[type] = _inventory.get(type, 0) - 1
	GameEvents.inventory_changed.emit(_inventory)

func _return_inventory(type: String) -> void:
	_inventory[type] = _inventory.get(type, 0) + 1
	GameEvents.inventory_changed.emit(_inventory)

# --- Layout persistence ---

func get_layout_types() -> Dictionary:
	return _grid_types.duplicate()

func get_layout_rotations() -> Dictionary:
	return _grid_rotations.duplicate()

func load_layout(types: Dictionary, rotations: Dictionary = {}) -> void:
	clear_all()
	for pos: Vector3i in types.keys():
		_place_block(pos, types[pos], rotations.get(pos, 0), false)

func clear_all() -> void:
	for pos in grid.keys():
		grid[pos].queue_free()
	grid.clear()
	_grid_types.clear()
	_grid_rotations.clear()
