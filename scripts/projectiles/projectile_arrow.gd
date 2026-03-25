# Arrow projectile — travels in a straight line, damages the first enemy it touches, then frees itself.
class_name ProjectileArrow
extends Area3D

@export var speed:    float = 14.0
@export var damage:   int   = 1
@export var lifetime: float = 3.0

var _direction: Vector3 = Vector3.FORWARD

func init(direction: Vector3) -> void:
	_direction = direction

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _process(delta: float) -> void:
	global_position += _direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
