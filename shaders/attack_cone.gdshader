// Draws a dim sector/fan shape for the archer block attack cone visualization.
// Applied to a flat QuadMesh (rotated -90° X) centered on the block.
// The quad is scaled to (attack_range * 2) in X and Z by block_archer.gd.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

// Half-angle of the cone in radians. Set per-instance by block_archer.gd.
uniform float cone_half_angle: hint_range(0.01, 3.14159) = 0.785;
uniform vec4 cone_color: source_color = vec4(0.35, 0.85, 1.0, 1.0);

void fragment() {
	// UV (0,0)=back-left, (1,1)=forward-right after the -90° X rotation.
	// Positive uv_c.y points toward world -Z (block's forward direction).
	vec2 uv_c = UV - vec2(0.5);

	// Angle from the forward axis (+Y in UV space).
	float angle = atan(uv_c.x, uv_c.y);

	// Distance from block centre in UV units; 0.5 = edge of the quad = attack_range.
	float dist = length(uv_c);

	// Discard everything outside the cone or behind the block (uv_c.y < 0 = backward).
	if (abs(angle) >= cone_half_angle || dist >= 0.5 || uv_c.y < 0.0) {
		discard;
	}

	// Dim fill that fades in from the block and out near the range boundary.
	float body = smoothstep(0.02, 0.12, dist) * (1.0 - smoothstep(0.38, 0.50, dist));

	// Slightly brighter arc drawn at the range boundary.
	float rim = smoothstep(0.44, 0.48, dist) * smoothstep(0.50, 0.47, dist) * 0.6;

	ALBEDO = cone_color.rgb;
	ALPHA = cone_color.a * (body * 0.12 + rim * 0.25);
}
