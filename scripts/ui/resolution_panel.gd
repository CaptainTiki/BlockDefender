# Displays end-of-run statistics and the Continue button.
class_name ResolutionPanel
extends CanvasLayer

signal continue_pressed

const SCRAP_PER_KILL: int = 3
const SCRAP_PER_WAVE: int = 10

@onready var _title_label:   Label  = $Overlay/Center/Panel/VBox/TitleLabel
@onready var _waves_label:   Label  = $Overlay/Center/Panel/VBox/StatsHBox/LeftVBox/WavesLabel
@onready var _enemies_label: Label  = $Overlay/Center/Panel/VBox/StatsHBox/LeftVBox/EnemiesLabel
@onready var _blocks_label:  Label  = $Overlay/Center/Panel/VBox/StatsHBox/RightVBox/BlocksLabel
@onready var _scrap_label:   Label  = $Overlay/Center/Panel/VBox/ScrapLabel
@onready var _continue_btn:  Button = $Overlay/Center/Panel/VBox/ContinueBtn

func _ready() -> void:
	hide()
	_continue_btn.pressed.connect(func(): continue_pressed.emit())

func show_stats(stats: Dictionary) -> void:
	var won: bool              = stats.get("won", false)
	var waves: int             = stats.get("waves_survived", 0)
	var total_waves: int       = stats.get("total_waves", 0)
	var kills: int             = stats.get("enemies_killed", 0)
	var total_enemies: int     = stats.get("total_enemies", 0)
	var blocks_lost: Dictionary = stats.get("blocks_lost", {})

	_title_label.text = "VICTORY!" if won else "DEFEATED"
	_title_label.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.4) if won else Color(1.0, 0.3, 0.3))

	_waves_label.text   = "Waves Survived:   %d / %d" % [waves, total_waves]
	_enemies_label.text = "Enemies Defeated: %d / %d" % [kills, total_enemies]

	var lost_lines: Array[String] = []
	for type: String in blocks_lost:
		lost_lines.append("  %s: %d" % [type.capitalize(), blocks_lost[type]])
	_blocks_label.text = "Blocks Lost:\n" + ("\n".join(lost_lines) if lost_lines.size() > 0 else "  None")

	var scrap_earned: int  = stats.get("scrap_earned", kills * SCRAP_PER_KILL + waves * SCRAP_PER_WAVE)
	var wallet_before: int = stats.get("wallet_before", 0)
	_scrap_label.text = (
		"Scrap Earned: +%d   (wallet: %d → %d)\n  (%d kills × %d) + (%d waves × %d)" % [
		scrap_earned, wallet_before, wallet_before + scrap_earned,
		kills, SCRAP_PER_KILL, waves, SCRAP_PER_WAVE])

	show()
