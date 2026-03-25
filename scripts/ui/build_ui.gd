# Build Phase HUD — scrollable inventory grid, block selection, detail panel, layout controls.
class_name BuildUI
extends CanvasLayer

signal block_selected(type: String)
signal keep_layout_pressed()
signal clear_all_pressed()
signal start_defense_pressed()
signal show_cones_toggled(show: bool)
signal purchase_requested(type: String)

# Static block data: display name, stats, description, shop cost.
const BLOCK_DATA: Dictionary = {
	"basic": {
		"display_name": "Basic Block",
		"stats": {"HP": 30, "Bonds": 6, "Weight": 1},
		"description": "A humble cardboard cube. Cheap, stackable, and surprisingly sturdy when taped correctly. The backbone of any fortification worth its salt.",
		"cost": 5,
	},
	"archer": {
		"display_name": "Archer Tower",
		"stats": {"HP": 20, "Range": 8, "Fire Rate": "2/s", "Spread": "stability"},
		"description": "Fires faster when isolated — every connected neighbor slows its reload. Accuracy depends on stability: a wobbling tower sprays wide, a grounded one shoots true.",
		"cost": 15,
	},
	"melee": {
		"display_name": "Melee Spiker",
		"stats": {"HP": 40, "Base DMG": 15, "Per Backer": "+8", "Range": "1 cell"},
		"description": "A spiked cardboard cube. Stack blocks directly behind it to boost damage — each backer in the chain adds a flat damage bonus. Rotation matters.",
		"cost": 10,
	},
	"armor": {
		"display_name": "Armor Plate",
		"stats": {"HP": 35, "Armor Aura": "35%", "Stacks": "additive"},
		"description": "A reinforced cardboard panel wrapped in duct tape. Passively reduces damage taken by every adjacent block. Multiple armor plates touching the same block stack their bonuses.",
		"cost": 8,
	},
}

@onready var _inventory_grid:   GridContainer   = %InventoryGrid
@onready var _inventory_scroll: ScrollContainer = %InventoryScroll
@onready var _detail_panel:     ItemDetailPanel = %DetailPanel
@onready var _keep_btn:         Button          = %KeepLayoutBtn
@onready var _clear_btn:        Button          = %ClearAllBtn
@onready var _defense_btn:      Button          = %StartDefenseBtn
@onready var _cones_btn:        CheckButton     = %ShowConesBtn
@onready var _scrap_label:      Label           = %ScrapLabel

var _inventory: Dictionary = {}


func _ready() -> void:
	_keep_btn.pressed.connect(func(): keep_layout_pressed.emit())
	_clear_btn.pressed.connect(func(): clear_all_pressed.emit())
	_defense_btn.pressed.connect(func(): start_defense_pressed.emit())
	_cones_btn.toggled.connect(func(p: bool): show_cones_toggled.emit(p))
	_detail_panel.purchase_requested.connect(func(t: String): purchase_requested.emit(t))

	# Wire up the statically-placed inventory items.
	var group := ButtonGroup.new()
	group.allow_unpress = false
	for item: InventoryItem in _inventory_grid.get_children():
		item.button_group = group
		item.item_selected.connect(_on_item_selected)

	GameEvents.inventory_changed.connect(_refresh_inventory)
	GameEvents.scrap_changed.connect(_on_scrap_changed)


func set_build_controls_visible(controls_visible: bool) -> void:
	_inventory_scroll.visible = controls_visible
	_keep_btn.visible         = controls_visible
	_clear_btn.visible        = controls_visible
	_defense_btn.visible      = controls_visible
	_cones_btn.visible        = controls_visible
	if not controls_visible:
		_detail_panel.hide()


func _on_scrap_changed(new_amount: int) -> void:
	_scrap_label.text = "Scrap: %d" % new_amount


func _refresh_inventory(inventory: Dictionary) -> void:
	_inventory = inventory
	for item: InventoryItem in _inventory_grid.get_children():
		item.set_count(inventory.get(item.block_type, 0))


func _on_item_selected(block_type: String) -> void:
	# Only commit to this block type for placement when we have stock.
	if _inventory.get(block_type, 0) > 0:
		block_selected.emit(block_type)
	var data: Dictionary = BLOCK_DATA.get(block_type, {
		"display_name": block_type,
		"stats": {},
		"description": "No description available.",
		"cost": 0,
	})
	_detail_panel.show_block(block_type, null, data)
