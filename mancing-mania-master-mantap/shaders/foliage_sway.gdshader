shader_type spatial;
// Vertex-coloured foliage with a low, staggered wind sway (GDD 172.9).
// Sway grows with height above the instance origin, so roots stay planted
// and tips move; each instance gets its own phase from its position.
render_mode cull_disabled, diffuse_lambert, specular_disabled;

uniform float sway_amount = 0.05;
uniform float sway_speed = 1.1;
uniform float sway_height = 1.0;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float phase = origin.x * 0.7 + origin.z * 0.9;
	float lift = clamp(VERTEX.y / sway_height, 0.0, 1.0);
	float wave = sin(TIME * sway_speed + phase) + 0.5 * sin(TIME * sway_speed * 1.7 + phase * 1.3);
	VERTEX.x += wave * sway_amount * lift * lift;
	VERTEX.z += wave * sway_amount * 0.4 * lift * lift;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.95;
}
