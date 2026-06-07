shader_type canvas_item;

// Card glow — golden edge glow for selected tile
uniform vec4 glow_color : source_color = vec4(1.0, 0.82, 0.0, 0.7);
uniform float pulse_speed : hint_range(0.0, 5.0) = 3.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Radial gradient from edge — UV distance from center
	vec2 center = UV - 0.5;
	float dist = length(center) * 2.0;  // 0 at center, ~1.4 at corners
	// Soft edge glow: stronger at edges
	float edge = smoothstep(0.3, 1.0, dist);
	// Pulse
	float pulse = 0.6 + 0.4 * sin(TIME * pulse_speed);
	// Composite: glow at edges, preserve original at center
	vec4 glow = glow_color * edge * pulse;
	COLOR = tex + glow * (1.0 - tex.a);
}
