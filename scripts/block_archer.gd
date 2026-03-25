# ArcherBlock — scans for the nearest enemy inside its attack cone and fires a projectile.
# Accuracy degrades when stability budget is low; fire rate increases when isolated.
# Rotation (set during Build Phase via Q/E) determines which direction the cone faces.
class_name BlockArcher
extends StaticBody3D

@export var attack_range: float = 8.0
@export var attack_cone_angle: float = 90.0   # full cone width in degrees; 90° = ±45° arc
@export var fire_rate: float = 2.0            # base shots per second (when fully isolated)
@export var projectile_scene: PackedScene

## Max spread angle (degrees) when stability budget is 0 (wobbling).
@export var max_spread_degrees: float = 25.0
## Fire rate multiplier bonus per missing face-neighbor (max 6 neighbors).
## 0 neighbors = fire_rate * (1 + 6 * bonus); fully surrounded = fire_rate * 1.0.
@export var isolation_fire_bonus: float = 0.1

# Shared across all instances — newly placed blocks inherit the current toggle state.
static var cones_visible: bool = true

@onready var _timer: Timer = $AttackTimer
@onready var _cone: ConeVisual = $ConeVisual

# Updated by BuildPhase after each stability run.
var _stability_budget: int = 6
var _neighbor_count: int = 0

func _ready() -> void:
	_timer.wait_time = 1.0 / fire_rate
	_timer.timeout.connect(_try_fire)
	_timer.start()

	_setup_cone()
	GameEvents.attack_cones_visible_changed.connect(_on_cones_visible_changed)

func _setup_cone() -> void:
	_cone.setup(attack_range, attack_cone_angle)
	_cone.visible = cones_visible

func _on_cones_visible_changed(show: bool) -> void:
	BlockArcher.cones_visible = show
	_cone.visible = show

## Called by BuildPhase whenever stability or neighbor count changes.
func update_combat_stats(budget: int, neighbor_count: int) -> void:
	_stability_budget = budget
	_neighbor_count = neighbor_count
	# Isolated blocks reload faster; each missing face-neighbor adds a bonus.
	var isolation: int = 6 - neighbor_count
	var effective_rate: float = fire_rate * (1.0 + isolation * isolation_fire_bonus)
	_timer.wait_time = 1.0 / effective_rate

func _try_fire() -> void:
	if projectile_scene == null:
		return
	var target := _find_nearest_enemy_in_cone()
	if target == null:
		return

	var proj: Node3D = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	var dir := (target.global_position - global_position).normalized()
	dir = _apply_spread(dir)
	if proj.has_method("init"):
		proj.call("init", dir)

func _find_nearest_enemy_in_cone() -> Node3D:
	# Godot's forward direction for a node is -Z in local space.
	var forward := -global_transform.basis.z
	var cone_cos := cos(deg_to_rad(attack_cone_angle * 0.5))
	var best: Node3D = null
	var best_dist_sq := attack_range * attack_range

	for e: Node in get_tree().get_nodes_in_group("enemies"):
		if not e is Node3D:
			continue
		var to_e: Vector3 = (e as Node3D).global_position - global_position
		var d2 := to_e.length_squared()
		if d2 >= best_dist_sq:
			continue
		# Reject enemies outside the cone using a dot-product angle check.
		if to_e.normalized().dot(forward) < cone_cos:
			continue
		best_dist_sq = d2
		best = e as Node3D

	return best

## Returns live combat stats for the inspect panel.
func get_inspect_stats() -> Dictionary:
	var isolation: int     = 6 - _neighbor_count
	var eff_rate: float    = fire_rate * (1.0 + isolation * isolation_fire_bonus)
	var stab_factor: float = clamp(float(_stability_budget) / 6.0, 0.0, 1.0)
	var spread_deg: float  = max_spread_degrees * (1.0 - stab_factor)
	return {
		"Fire Rate":  "%.1f / sec" % eff_rate,
		"Spread":     "%.0f°" % spread_deg,
		"Neighbors":  "%d / 6" % _neighbor_count,
		"Range":      "%.0f units" % attack_range,
	}

## Adds random directional scatter based on current stability budget.
## High budget = stable = no spread. Budget ≤ 0 = full spread.
func _apply_spread(dir: Vector3) -> Vector3:
	var stability_factor: float = clamp(float(_stability_budget) / 6.0, 0.0, 1.0)
	var spread: float = deg_to_rad(max_spread_degrees) * (1.0 - stability_factor)
	if spread <= 0.0:
		return dir
	# Build two axes perpendicular to the shot direction and scatter within them.
	var up_hint := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.9 else Vector3.FORWARD
	var right_axis := dir.cross(up_hint).normalized()
	var up_axis := dir.cross(right_axis).normalized()
	return (dir
		+ right_axis * tan(randf_range(-spread, spread))
		+ up_axis   * tan(randf_range(-spread, spread))
	).normalized()
