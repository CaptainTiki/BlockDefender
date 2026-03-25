# Detail view — shows the selected block's icon, stats, description, and purchase option.
class_name ItemDetailPanel
extends PanelContainer

signal purchase_requested(block_type: String)

@onready var _name_label:   Label         = %BlockNameLabel
@onready var _icon_rect:    TextureRect   = %IconRect
@onready var _stats_grid:   GridContainer = %StatsGrid
@onready var _desc_label:   Label         = %DescriptionLabel
@onready var _purchase_btn: Button        = %PurchaseBtn

var _current_block_type: String = ""
var _current_cost: int = 0
var _wallet: int = 0


func _ready() -> void:
	_purchase_btn.pressed.connect(func(): purchase_requested.emit(_current_block_type))
	GameEvents.scrap_changed.connect(_on_scrap_changed)
	hide()


func _on_scrap_changed(new_amount: int) -> void:
	_wallet = new_amount
	_refresh_purchase_btn()


func show_block(block_type: String, icon: Texture2D, data: Dictionary) -> void:
	_current_block_type = block_type
	_current_cost       = data.get("cost", 0)
	_name_label.text    = data.get("display_name", block_type)
	_icon_rect.texture  = icon

	# Rebuild stat rows.
	for child in _stats_grid.get_children():
		child.queue_free()
	for stat_key: String in data.get("stats", {}).keys():
		var key_lbl := Label.new()
		key_lbl.text = stat_key
		var val_lbl := Label.new()
		val_lbl.text                    = str(data["stats"][stat_key])
		val_lbl.horizontal_alignment    = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.size_flags_horizontal   = SIZE_EXPAND_FILL
		_stats_grid.add_child(key_lbl)
		_stats_grid.add_child(val_lbl)

	_desc_label.text = data.get("description", "")
	_refresh_purchase_btn()
	show()


func _refresh_purchase_btn() -> void:
	if _current_cost <= 0:
		_purchase_btn.text     = "Not For Sale"
		_purchase_btn.disabled = true
		return
	var can_afford: bool       = _wallet >= _current_cost
	_purchase_btn.text         = "Purchase  (%d scrap)" % _current_cost
	_purchase_btn.disabled     = not can_afford
	# Tooltip so the player knows exactly why they're broke.
	_purchase_btn.tooltip_text = "" if can_afford else "Need %d more scrap" % (_current_cost - _wallet)
