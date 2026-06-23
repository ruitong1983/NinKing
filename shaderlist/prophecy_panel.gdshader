shader_type canvas_item;

/* Shift this value to create the dissolving effect. Represents the percentage
   of the image that's been dissolved. */
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 texture_size;

// How far the pixels will float away before dissolving
uniform float float_distance : hint_range(0.0, 50.0) = 6.0;

// Increase how far pixels can vertically differ from the "wave"
uniform float random_range : hint_range(0.0, 1.0) = 0.2;

// Controls the smoothness of the dissolve edge
uniform float edge_smoothness : hint_range(0.0, 0.5) = 0.1;

// Controls the direction of float (1 = up, -1 = down, 0 = no float)
uniform float float_direction : hint_range(-1.0, 1.0) = 1.0;

// Control the dissolve color (if you want colored dissolve)
uniform vec4 dissolve_color = vec4(1.0, 1.0, 1.0, 1.0);

// Enable/disable floating effect
uniform bool enable_float = true;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 438.5453);
}

void fragment() {
	// Calculate UV-based float distance
	float v = enable_float ? float_distance / texture_size.y : 0.0;
	
	// Adjust progress with randomization and float distance
	float base_progress = progress * (1.0 + (v + random_range) * 2.0);
	float rand_offset = random(UV) * random_range * 2.0 - random_range;
	float p = base_progress - v - rand_offset;
	
	// Calculate interpolation factor for smooth dissolve
	float dissolve_factor = smoothstep(p - edge_smoothness, p + edge_smoothness, UV.y);
	
	// Apply float direction
	float direction = sign(float_direction);
	v *= abs(float_direction);
	
	// Calculate mapped UV with floating effect
	float mapped_uv_y;
	if (enable_float) {
		float q = smoothstep(p - v * 2.0, p, UV.y);
		mapped_uv_y = UV.y + v * direction - v * q * direction * step(q, 1.0);
	} else {
		mapped_uv_y = UV.y;
	}
	
	// Sample texture
	vec4 tex_color = texture(TEXTURE, vec2(UV.x, mapped_uv_y));
	
	// Apply dissolve
	if (dissolve_factor > 0.5) {
		// Pixel is dissolved
		if (dissolve_color.a > 0.0) {
			// Use dissolve color
			COLOR = mix(tex_color, dissolve_color, dissolve_factor * 2.0 - 1.0);
			COLOR.a *= (1.0 - dissolve_factor) * 2.0;
		} else {
			// Completely dissolve
			COLOR = vec4(tex_color.rgb, tex_color.a * (1.0 - dissolve_factor) * 2.0);
		}
	} else {
		// Pixel is still visible, apply fade-out as it floats
		float q = enable_float ? smoothstep(p - v * 2.0, p, UV.y) : 1.0;
		COLOR = tex_color;
		COLOR.a *= q;
	}
}