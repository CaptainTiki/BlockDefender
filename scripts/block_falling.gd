# Short-lived physics block spawned during collapse. Auto-destructs after lifetime.
extends RigidBody3D

@export var lifetime: float = 4.0

func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
