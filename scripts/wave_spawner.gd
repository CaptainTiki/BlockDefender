# Spawns enemies wave-by-wave during the Defense Phase.
# Emits wave_started / wave_completed / run_won through GameEvents.
# enemy_scenes is a pool — each individual spawn picks uniformly at random from the array.
class_name WaveSpawner
extends Node

## Pool of enemy scenes to draw from. Add all desired enemy types here in the inspector.
@export var enemy_scenes: Array[PackedScene] = []
## Enemies per wave; add or remove entries in the inspector to change wave count.
@export var wave_enemy_counts: Array[int] = [3, 5, 7]
@export var spawn_radius: float = 8.0
@export var spawn_interval: float = 0.5      # seconds between individual spawns within a wave
@export var time_between_waves: float = 5.0  # seconds between wave-clear and next wave

var _current_wave: int = 0
var _enemies_remaining: int = 0  # yet to be spawned this wave
var _enemies_alive: int = 0      # currently alive on the field
var _enemies_killed: int = 0
var _wave_total: int = 0
var _spawn_index: int = 0
var _finished: bool = false      # guards against run_won after run_failed
var _placement: BlockPlacement = null

@onready var _spawn_timer: Timer   = $SpawnTimer
@onready var _between_timer: Timer = $BetweenWavesTimer

func _ready() -> void:
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_between_timer.timeout.connect(_on_between_timer_timeout)

func start(placement: BlockPlacement) -> void:
	_placement = placement
	_current_wave = 0
	_enemies_killed = 0
	_finished = false
	_begin_wave()

## Call when the run ends prematurely (run_failed) to silence further events.
func stop() -> void:
	_finished = true
	_spawn_timer.stop()
	_between_timer.stop()

func _begin_wave() -> void:
	_wave_total = wave_enemy_counts[_current_wave]
	_enemies_remaining = _wave_total
	_enemies_alive = 0
	_spawn_index = 0
	GameEvents.wave_started.emit(_current_wave + 1, wave_enemy_counts.size())
	_spawn_next()

func _spawn_next() -> void:
	if enemy_scenes.is_empty():
		push_warning("WaveSpawner: enemy_scenes pool is empty — assign scenes in the inspector.")
		return
	var angle := (TAU / _wave_total) * _spawn_index
	var pos   := Vector3(cos(angle) * spawn_radius, 0.0, sin(angle) * spawn_radius)
	# Pick a random enemy type from the pool for each individual spawn.
	var chosen: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy: Node3D = chosen.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = pos
	if enemy.has_method("init"):
		enemy.call("init", _placement)
	enemy.tree_exited.connect(_on_enemy_died)
	_spawn_index += 1
	_enemies_alive += 1
	_enemies_remaining -= 1
	if _enemies_remaining > 0:
		_spawn_timer.start(spawn_interval)

func _on_spawn_timer_timeout() -> void:
	_spawn_next()

func _on_enemy_died() -> void:
	_enemies_alive -= 1
	if not _finished:
		_enemies_killed += 1
		GameEvents.enemy_killed.emit()
	_check_wave_cleared()

func get_enemies_killed() -> int:
	return _enemies_killed

func get_waves_survived() -> int:
	return _current_wave

func get_total_waves() -> int:
	return wave_enemy_counts.size()

func get_total_enemies() -> int:
	var total: int = 0
	for count in wave_enemy_counts:
		total += count
	return total

func _check_wave_cleared() -> void:
	if _finished or _enemies_remaining > 0 or _enemies_alive > 0:
		return
	GameEvents.wave_completed.emit(_current_wave + 1)
	_current_wave += 1
	if _current_wave >= wave_enemy_counts.size():
		_finished = true
		GameEvents.run_won.emit()
		return
	_between_timer.start(time_between_waves)

func _on_between_timer_timeout() -> void:
	_begin_wave()
