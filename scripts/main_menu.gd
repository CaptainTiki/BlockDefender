# Main menu — launches directly into Build Phase.
extends Control

@onready var _start_btn: Button = %StartBtn

func _ready() -> void:
	_start_btn.pressed.connect(_on_start)

func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/BuildPhase.tscn")
