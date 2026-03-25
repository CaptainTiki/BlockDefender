# Foundation block — pre-placed in level scenes by the level designer. Indestructible.
# Registers itself so StabilityChecker can seed the flood-fill from adjacent player blocks.
extends StaticBody3D

func _ready() -> void:
	add_to_group("foundation_blocks")
