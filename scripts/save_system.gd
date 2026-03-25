# Handles saving and loading layout + inventory to disk.
extends Node
class_name SaveSystem

const SAVE_PATH := "user://save.json"
## Bump this whenever DEFAULT_INVENTORY changes so stale saves don't override new block counts.
const SAVE_VERSION := 2

func save(layout: Dictionary, rotations: Dictionary, inventory: Dictionary, scrap: int = 0) -> void:
	var data := {
		"version": SAVE_VERSION,
		"layout": _serialize_layout(layout, rotations),
		"inventory": inventory,
		"scrap": scrap,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func load_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		return {}
	return parsed

func _serialize_layout(layout: Dictionary, rotations: Dictionary) -> Array:
	# Vector3i keys can't serialize directly — convert to array of entry dicts.
	var out := []
	for pos: Vector3i in layout.keys():
		out.append({
			"x": pos.x, "y": pos.y, "z": pos.z,
			"type": layout[pos],
			"rot": rotations.get(pos, 0),
		})
	return out

func deserialize_layout(raw: Array) -> Array:
	# Returns [types: Dictionary, rotations: Dictionary]
	var types := {}
	var rotations := {}
	for entry: Dictionary in raw:
		var pos := Vector3i(entry["x"], entry["y"], entry["z"])
		types[pos] = entry["type"]
		rotations[pos] = entry.get("rot", 0)
	return [types, rotations]
