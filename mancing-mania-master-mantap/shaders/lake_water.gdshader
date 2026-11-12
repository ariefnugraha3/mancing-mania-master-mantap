shader_type spatial;
// Stylized low-poly lake surface (GDD 126). Works on the Compatibility renderer:
// slow vertex swell, flat facets, and a warm fade toward the far shore.
render_mode cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 near_color : source_color = vec4(0.24, 0.42, 0.42, 1.0);
uniform vec4 far_color : source_color = vec4(0.47, 0.6, 0.57, 1.0);
uniform vec4 glint_color : source_color = vec4(1.0, 0.93, 0.78, 1.0);
uniform float fade_start = 6.0;
uniform float fade_end = 60.0;
uniform float swell_height = 0.035;
uniform float swell_speed = 0.55;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float swell = sin(world_position.x * 0.55 + TIME * swell_speed)
		+ sin(world_position.z * 0.42 - TIME * swell_speed * 0.8);
	VERTEX.y += swell * swell_height;
}

void fragment() {
	// Flat facets: derive the normal from the displaced surface itself.
	vec3 facet = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
	NORMAL = facet;

	float distance_to_camera = length(world_position - CAMERA_POSITION_WORLD);
	float fade = smoothstep(fade_start, fade_end, distance_to_camera);
	vec3 base = mix(near_color.rgb, far_color.rgb, fade);

	// A few slow light streaks so the surface never reads as a flat sheet.
	float streak = sin(world_position.z * 1.7 + sin(world_position.x * 0.45 + TIME * 0.25) * 1.6);
	float glint = smoothstep(0.985, 1.0, streak) * (1.0 - fade) * 0.22;

	ALBEDO = mix(base, glint_color.rgb, glint);
	ROUGHNESS = 0.35;
	SPECULAR = 0.4;
	METALLIC = 0.0;
}
