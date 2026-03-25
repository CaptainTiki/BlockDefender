# BlockInspectPanel — shows live runtime stats for a placed block when clicked in inspect mode.
# Receives a block node + metadata from BuildPhase; queries the block directly for current values.
class_name BlockInspectPanel
extends PanelContainer

@onready var _title:    Label         = %InspectTitleLabel
@onready var _grid:     GridContainer = %InspectStatsGrid
@onready var _desc:     Label         = %InspectDescLabel
@onready var _hint:     Label         = %InspectHintLabel

## Populate the panel with live data from the given block instance.
## budget is the raw stability budget for this block from StabilityChecker.
func show_block(block_node: Node3D, block_type: String, budget: int) -> void:
	var type_data: Dictionary = BuildUI.BLOCK_DATA.get(block_type, {})
	_title.text = type_data.get("display_name", block_type)
	_desc.text  = type_data.get("description", "")

	var stats: Dictionary = {}

	# --- HP and armor from BlockHealth ---
	var health := block_node.get_node_or_null("BlockHealth") as BlockHealth
	if health:
		stats["HP"] = "%d / %d" % [health.hp, health.max_hp]
		if health.armor > 0.0:
			stats["Armor"] = "%d%%" % int(health.armor * 100.0)

	# --- Stability from the budget value ---
	if budget > 2:
		stats["Stability"] = "Grounded"
	elif budget > 0:
		stats["Stability"] = "Grounded (weak)"
	elif budget == 0:
		stats["Stability"] = "Wobbling ⚠"
	else:
		stats["Stability"] = "Falling ✗"

	# --- Block-type-specific live stats ---
	if block_node.has_method("get_inspect_stats"):
		var type_stats: Dictionary = block_node.call("get_inspect_stats")
		for key: String in type_stats.keys():
			stats[key] = type_stats[key]

	# --- Rebuild stat rows ---
	for child in _grid.get_children():
		child.queue_free()
	for key: String in stats.keys():
		var k := Label.new()
		k.text = key
		k.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		_grid.add_child(k)
		var v := Label.new()
		v.text                  = str(stats[key])
		v.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
		v.size_flags_horizontal = SIZE_EXPAND_FILL
		_grid.add_child(v)

	show()

func clear() -> void:
	hide()
