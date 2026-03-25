# Ghosted 3D cone that visualises an archer block's attack range and facing direction.
# Call setup() once from the owning block's _ready() to size and orient the cone.
class_name ConeVisual
extends Node3D

@onready var mesh: MeshInstance3D = $Mesh

func setup(p_range: float, cone_angle_deg: float) -> void:
	# Duplicate resources so each placed block has independent geometry and material.
	var cyl := mesh.mesh.duplicate() as CylinderMesh
	cyl.top_radius    = 0.0
	cyl.bottom_radius = p_range * tan(deg_to_rad(cone_angle_deg * 0.5))
	cyl.height        = p_range
	mesh.mesh = cyl
	mesh.material_override = mesh.material_override.duplicate()

	# Rotate +90° around X: CylinderMesh's +Y (tip, top_radius=0) maps to +Z.
	# Translate by -range/2 on Z: tip arrives at the block's local origin (0,0,0)
	# and the base (bottom_radius end) sits at Z = -range (Godot's forward/-Z).
	# Keeping the cone geometry 3D makes it future-proof for vertical targeting (flyers).
	mesh.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	mesh.position = Vector3(0.0, 0.0, -p_range / 2.0)
