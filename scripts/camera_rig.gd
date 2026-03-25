# Free-orbit 3D camera for Build Phase and Defense Phase.
# Middle-mouse drag = orbit, scroll = zoom.
# WASD = pan (relative to yaw, always horizontal), Space/Ctrl = up/down, Shift = double speed.
class_name CameraRig
extends Node3D

@export var orbit_speed: float = 0.005
@export var move_speed: float = 8.0
@export var shift_multiplier: float = 2.0
@export var zoom_speed: float = 1.0
@export var zoom_min: float = 2.0
@export var zoom_max: float = 40.0

@onready var _pitch: Node3D = $CameraPitch
@onready var _camera: Camera3D = $CameraPitch/Camera3D

var _orbiting := false
var _zoom_distance := 10.0

func _ready() -> void:
	_camera.position.z = _zoom_distance

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _orbiting:
		# Yaw on the rig (Y only), pitch on the child node (X only).
		rotate_y(-event.relative.x * orbit_speed)
		_pitch.rotate_object_local(Vector3.RIGHT, -event.relative.y * orbit_speed)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_MIDDLE:
			_orbiting = event.pressed
		MOUSE_BUTTON_WHEEL_UP:
			_zoom(-zoom_speed)
		MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(zoom_speed)

func _process(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): dir.z -= 1.0
	if Input.is_key_pressed(KEY_S): dir.z += 1.0
	if Input.is_key_pressed(KEY_A): dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): dir.x += 1.0
	if Input.is_key_pressed(KEY_SPACE): dir.y += 1.0
	if Input.is_key_pressed(KEY_CTRL):  dir.y -= 1.0

	if dir == Vector3.ZERO:
		return

	var speed := move_speed * (shift_multiplier if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	# translate() already applies the rig's local basis — no manual multiplication needed.
	# CameraRig only ever rotates on Y, so local X/Z are always horizontal and local Y = world up.
	translate(dir.normalized() * speed * delta)

func _zoom(delta: float) -> void:
	_zoom_distance = clamp(_zoom_distance + delta, zoom_min, zoom_max)
	_camera.position.z = _zoom_distance
