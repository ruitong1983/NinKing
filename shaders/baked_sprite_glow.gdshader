/*
Baked Sprite Glow
Code inspiration: [jzayed](https://github.com/jzayed)
Adapted by: [Razoric](https://razori.ca)

The shader is intended to work with a sprite that has a glowing effect built
into the pixel data itself. It will draw the sprite twice, reducing or
intensifying the glow's alpha by the alpha_falloff for each layer.

The result is tinted and blended together. This makes it a high performance
shader, though the drawback is that it necessitates the sprite to be altered
with a glow effect.

S5: 新增 emissive_mode — 加法发光模式，覆盖 sources/blink.gdshader 功能。
当 emissive_mode=true 时，跳过混合发光管线，改为 sin(TIME) 驱动的 RGB 加法辉光。
*/
shader_type canvas_item;

// Amount of falloff to apply to the front of the sprite's glow.
uniform float alpha_falloff_front : hint_range(0.0, 3.0) = 1.0;

// Color to tin the front of the sprite's glow by.
uniform vec4 tint_front : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Amount of falloff to apply to the back of the sprite's glow.
uniform float alpha_falloff_back : hint_range(0.0, 3.0) = 1.0;

// Color to tint the back of the sprite's glow by.
uniform vec4 tint_back : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Linear proportion to blend between back and front layers of the sprite's glow.
uniform float blend_amount : hint_range(0.0, 1.0) = 1.0;

// Maximum alpha value before no longer being considered for falloff. Sprites
// that have fuzzy edges on top of the glow may need this adjusted to prevent
// cutting pixelization.
uniform float falloff_max_alpha : hint_range(0.0, 1.0) = 1.0;

// S5: emissive mode — 加法发光替代混合发光管线
uniform bool emissive_mode = false;
// 辉光颜色 (blink 等效)
uniform vec4 emissive_color : source_color = vec4(1.0, 0.8, 0.2, 1.0);
// 闪烁频率 Hz (blink 等效)
uniform float emissive_frequency : hint_range(0.5, 5.0) = 2.0;
// 最大辉光强度 (blink 等效)
uniform float emissive_intensity : hint_range(0.0, 1.0) = 0.5;

const vec3 TINT_RGB_COMPARISON = vec3(0.222, 0.707, 0.071);

vec4 tint_rgba(vec4 tex, vec4 color) {
	float tint_amount = dot(tex.rgb, TINT_RGB_COMPARISON);
	vec3 tint = color.rgb * tint_amount;
	tex.rgb = mix(tex.rgb, tint.rgb, color.a);
	return tex;
}

vec4 alpha_intensity(vec4 tex, float fade) {
	if (tex.a < falloff_max_alpha) {
		tex.a = mix(0.0, tex.a, fade);
	}
	return tex;
}

vec4 blend(vec4 origin, vec4 overlay, float blend) {
	vec4 blended_output = origin;
	blended_output.a = overlay.a + origin.a * (1.0 - overlay.a);

	blended_output.rgb = (overlay.rgb * overlay.a + origin.rgb * origin.a * (1.0 - overlay.a))
			/ (blended_output.a + 0.0000001);

	blended_output.a = clamp(blended_output.a, 0.0, 1.0);
	blended_output = mix(origin, blended_output, blend);

	return blended_output;
}

void fragment() {
	vec4 main_texture = texture(TEXTURE, UV);

	// S5: emissive 模式 — 加法发光，跳过混合发光管线
	if (emissive_mode) {
		float blink = 0.5 * (sin(TIME * emissive_frequency) + 1.0);
		vec3 emission = emissive_color.rgb * blink * emissive_intensity;
		COLOR = vec4(main_texture.rgb + emission, main_texture.a);
		return;
	}

	vec4 intensity_front_tex = alpha_intensity(main_texture, alpha_falloff_front);
	vec4 tint_front_tex = tint_rgba(intensity_front_tex, tint_front);

	vec4 intensity_back_tex = alpha_intensity(main_texture, alpha_falloff_back);
	vec4 tint_back_tex = tint_rgba(intensity_back_tex, tint_back);

	vec4 blended_texture = blend(tint_back_tex, tint_front_tex, blend_amount);
	blended_texture *= main_texture;

	COLOR = blended_texture;
}