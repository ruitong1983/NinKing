shader_type canvas_item;

// Ink-bleed edge fade for the left score panel.
// The right edge smoothly transitions from solid panel color to transparent,
// visually blending the panel into the game background (manga ink-wash style).
uniform float fade_start : hint_range(0.0, 1.0) = 0.82;

void fragment() {
	float fade = smoothstep(fade_start, 1.0, UV.x);
	COLOR.a = 1.0 - fade;
}
