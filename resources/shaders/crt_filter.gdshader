// resources/shaders/crt_filter.gdshader
// ============================================================
// CRT Filter — 扫描线 + 色差 + 暗角 + 微曲面
// 可独立移植: CanvasLayer > ColorRect(full rect) > 此 ShaderMaterial
// ============================================================
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

uniform float scanline_intensity : hint_range(0.0, 0.5) = 0.15;
uniform float aberration_amount : hint_range(0.0, 3.0) = 0.5;
uniform float vignette_amount : hint_range(0.0, 1.0) = 0.3;
uniform float warp_amount : hint_range(0.0, 0.1) = 0.02;
uniform float brightness : hint_range(0.5, 2.0) = 1.1;
uniform float time_offset : hint_range(0.0, 100.0) = 0.0;
uniform float breath : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;

	// ── 曲面 ──
	vec2 delta = uv - 0.5;
	uv += delta * dot(delta, delta) * warp_amount;

	// ── 扫描线 ──
	vec2 pixel_size = 1.0 / vec2(textureSize(SCREEN_TEXTURE, 0));
	float scanline = sin((uv.y / pixel_size.y + time_offset) * 3.14159) * 0.5 + 0.5;
	scanline = mix(1.0, scanline, scanline_intensity);

	// ── 色差（RGB 偏移）──
	float pixel_offset = aberration_amount * pixel_size.x;
	float r = texture(SCREEN_TEXTURE, uv + vec2(pixel_offset, 0.0)).r;
	float g = texture(SCREEN_TEXTURE, uv).g;
	float b = texture(SCREEN_TEXTURE, uv + vec2(-pixel_offset, 0.0)).b;

	vec3 color = vec3(r, g, b) * scanline;

	// ── 暗角 ──
	vec2 vig_uv = uv * (1.0 - uv.yx);
	float vig = vig_uv.x * vig_uv.y * 15.0;
	vig = mix(1.0, vig, vignette_amount);

	color *= vig * brightness * (1.0 + breath * 0.08);

	COLOR = vec4(color, 1.0);
}
