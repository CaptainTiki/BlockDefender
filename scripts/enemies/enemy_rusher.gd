# Basic rusher enemy. Finds the nearest block, walks straight toward it, and attacks on contact.
# Receives a BlockPlacement reference on spawn via init().
class_name EnemyRusher
extends CharacterBody3D

@export var move_speed:    float = 3.0
@export var attack_damage: int   = 1
@export var attack_rate:   float = 1.0   # hits per second
@export var attack_range:  float = 1.2   # distance from block centre to start attacking

@export var max_hp: int = 5

var hp: int
var _placement: BlockPlacement = null
var _target_pos: Vector3i      = Vector3i.ZERO
var _has_target: bool          = false
var _attack_cooldown: float    = 0.0
var _cornerstone_target: Node3D = null  # fallback when grid is empty

const GRAVITY: float = 9.8

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")

func init(placement: BlockPlacement) -> void:
	_placement = placement

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		queue_free()

func _physics_process(delta: float) -> void:
	# Gravity — keep enemy on the ground.
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	_attack_cooldown -= delta
	_find_nearest_block()

	if not _has_target:
		# Fall back to charging the cornerstone directly.
		_try_attack_cornerstone()
		move_and_slide()
		return

	# Target the block's horizontal centre at the enemy's own height.
	var target_world := Vector3(_target_pos.x + 0.5, global_position.y, _target_pos.z + 0.5)
	var dist := global_position.distance_to(target_world)

	if dist > attack_range:
		var dir := (target_world - global_position).normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_try_attack()

	move_and_slide()

func _find_nearest_block() -> void:
	if _placement == null or _placement.grid.is_empty():
		_has_target = false
		return

	var best_dist_sq := INF
	var best_pos    := Vector3i.ZERO
	var my_x        := global_position.x
	var my_z        := global_position.z

	for pos: Vector3i in _placement.grid.keys():
		var dx := my_x - (pos.x + 0.5)
		var dz := my_z - (pos.z + 0.5)
		var d2 := dx * dx + dz * dz
		if d2 < best_dist_sq:
			best_dist_sq = d2
			best_pos     = pos

	_target_pos = best_pos
	_has_target = true

func _try_attack() -> void:
	if _attack_cooldown > 0.0:
		return
	if not _placement.grid.has(_target_pos):
		return

	var block: Node3D = _placement.grid[_target_pos]
	var health := block.get_node_or_null("BlockHealth") as BlockHealth
	if health:
		health.take_damage(attack_damage)

	_attack_cooldown = 1.0 / attack_rate

func _try_attack_cornerstone() -> void:
	# Lazily find the cornerstone once; chase and attack it.
	if _cornerstone_target == null or not is_instance_valid(_cornerstone_target):
		var nodes := get_tree().get_nodes_in_group("cornerstone")
		_cornerstone_target = nodes[0] if not nodes.is_empty() else null

	if _cornerstone_target == null:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var target_world := Vector3(_cornerstone_target.global_position.x, global_position.y, _cornerstone_target.global_position.z)
	var dist := global_position.distance_to(target_world)

	if dist > attack_range:
		var dir := (target_world - global_position).normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_cooldown <= 0.0 and _cornerstone_target.has_method("take_damage"):
			_cornerstone_target.take_damage(attack_damage)
			_attack_cooldown = 1.0 / attack_rate
