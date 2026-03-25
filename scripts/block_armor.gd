# ArmorBlock — passive block that boosts the damage reduction of every face-adjacent block.
# Stacks additively: a block touching two armor blocks gets 2× the reduction.
# BuildPhase scans for these after each placement and propagates the bonus to BlockHealth.armor.
class_name BlockArmor
extends StaticBody3D

## Damage reduction fraction granted to each touching block. 0.35 = 35% less damage.
@export var armor_bonus: float = 0.35

## Returns live stats for the inspect panel.
func get_inspect_stats() -> Dictionary:
	return {
		"Aura":  "%d%% reduction" % int(armor_bonus * 100.0),
		"Reach": "All 6 faces",
		"Stack": "Additive",
	}
