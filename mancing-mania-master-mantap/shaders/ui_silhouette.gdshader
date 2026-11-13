shader_type canvas_item;
// Fish Book silhouette (GDD 174.9): draws a portrait as a flat ink shape, so a
// fish that has not been beaten yet shows its outline and nothing else.

uniform vec4 ink : source_color = vec4(0.208, 0.184, 0.161, 0.85);

void fragment() {
	COLOR = vec4(ink.rgb, texture(TEXTURE, UV).a * ink.a);
}
