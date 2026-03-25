# Shows wave progress and run outcome during the Defense Phase.
# Connects entirely through GameEvents — no reference to BuildPhase needed.
extends CanvasLayer

@onready var _wave_label: Label   = $VBox/WaveLabel
@onready var _status_label: Label = $VBox/StatusLabel

func _ready() -> void:
	GameEvents.wave_started.connect(_on_wave_started)
	GameEvents.wave_completed.connect(_on_wave_completed)
	GameEvents.run_won.connect(_on_run_won)
	GameEvents.run_failed.connect(_on_run_failed)
	_wave_label.text = ""
	_status_label.text = ""

func _on_wave_started(wave_num: int, total_waves: int) -> void:
	_wave_label.text = "Wave %d / %d" % [wave_num, total_waves]
	_status_label.text = ""

func _on_wave_completed(wave_num: int) -> void:
	_status_label.text = "Wave %d complete!" % wave_num

func _on_run_won() -> void:
	_wave_label.text = ""
	_status_label.text = "Victory!"

func _on_run_failed() -> void:
	_status_label.text = "Defeat!"
