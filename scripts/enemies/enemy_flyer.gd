# EnemyFlyer — bypasses ground-level defences by flying at a randomised height.
# Height is chosen in init() from the range [cornerstone Y … top of tallest placed block].
# No gravity; moves by setting global_position directly so it glides freely through the air.
class_name EnemyFlyer
extends CharacterBody3D

@export var move_speed:       float = 4.5
@export var attack_damage:    int   = 1
@export var attack_rate:      float = 1.0
@export var attack_range:     float = 1.2
@export var max_hp:           int   = 3
## A block must have its centre within this many units of the fly-line to be targeted.
@export var height_tolerance: float = 0.8

var hp: int
var _placement: BlockPlacement = null
var _fly_height: float         = 2.0
var _attack_cooldown: float    = 0.0
var _cornerstone_target: Node3D = null
var _target_pos: Vector3i      = Vector3i.ZERO
var _has_target: bool          = false

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")

func init(placement: BlockPlacement) -> void:
	_placement = placement
	_fly_height = _pick_fly_height()
	# Override the Y the spawner placed us at.
	global_position.y = _fly_height

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		queue_free()

func _physics_process(delta: float) -> void:
	_attack_cooldown -= delta
	# Snap to fly-line — no gravity, no drift.
	global_position.y = _fly_height
	velocity = Vector3.ZERO

	_find_nearest_block()

	if not _has_target:
		_approach_cornerstone(delta)
		return

	var target_world := Vector3(_target_pos.x + 0.5, _fly_height, _target_pos.z + 0.5)
	var xz_dist := Vector2(
		global_position.x - target_world.x,
		global_position.z - target_world.z
	).length()

	if xz_dist > attack_range:
		var dir := Vector3(
			target_world.x - global_position.x,
			0.0,
			target_world.z - global_position.z
		).normalized()
		global_position += dir * move_speed * delta
	else:
		_try_attack()

func _find_nearest_block() -> void:
	_has_target = false
	if _placement == null or _placement.grid.is_empty():
		return

	var best_dist_sq := INF
	for pos: Vector3i in _placement.grid.keys():
		# Only consider blocks whose centre is near the fly-line.
		var block_center_y: float = float(pos.y) + 0.5
		if abs(block_center_y - _fly_height) > height_tolerance:
			continue
		var dx := global_position.x - (pos.x + 0.5)
		var dz := global_position.z - (pos.z + 0.5)
		var d2 := dx * dx + dz * dz
		if d2 < best_dist_sq:
			best_dist_sq = d2
			_target_pos = pos
			_has_target = true

func _try_attack() -> void:
	if _attack_cooldown > 0.0:
		return
	if not _placement.grid.has(_target_pos):
		_has_target = false
		return
	var health := _placement.grid[_target_pos].get_node_or_null("BlockHealth") as BlockHealth
	if health:
		health.take_damage(attack_damage)
	_attack_cooldown = 1.0 / attack_rate

func _approach_cornerstone(delta: float) -> void:
	# Lazily resolve the cornerstone; fly toward it if no blocks are at this height.
	if _cornerstone_target == null or not is_instance_valid(_cornerstone_target):
		var nodes := get_tree().get_nodes_in_group("cornerstone")
		_cornerstone_target = nodes[0] if not nodes.is_empty() else null
	if _cornerstone_target == null:
		return

	var target_world := Vector3(
		_cornerstone_target.global_position.x,
		_fly_height,
		_cornerstone_target.global_position.z
	)
	var dist := global_position.distance_to(target_world)
	if dist > attack_range:
		var dir := Vector3(
			target_world.x - global_position.x,
			0.0,
			target_world.z - global_position.z
		).normalized()
		global_position += dir * move_speed * delta
	elif _attack_cooldown <= 0.0 and _cornerstone_target.has_method("take_damage"):
		_cornerstone_target.take_damage(attack_damage)
		_attack_cooldown = 1.0 / attack_rate

func _pick_fly_height() -> float:
	# Lower bound: the cornerstone's world-space Y centre.
	var min_y: float = 1.0
	var cornerstones := get_tree().get_nodes_in_group("cornerstone")
	if not cornerstones.is_empty():
		min_y = (cornerstones[0] as Node3D).global_position.y

	# Upper bound: top surface of the highest placed block.
	var max_y: float = min_y
	if _placement != null:
		for pos: Vector3i in _placement.grid.keys():
			var block_top: float = float(pos.y) + 1.0
			if block_top > max_y:
				max_y = block_top

	# If the structure is flat or empty, fly just above the cornerstone.
	if max_y < min_y + 0.5:
		return min_y + 0.5
	return randf_range(min_y, max_y)
