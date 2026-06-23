shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1);
uniform float line_thickness : hint_range(0, 10) = 1.0;

// S4: LOD — high_quality=false 时仅采 4 对角线方向（4次 texture()），
// 适合牌组预览等多卡场景减半纹理采样 (416→208 texture()/帧)。
uniform bool high_quality = true;

const vec2 OFFSETS_HQ[8] = {
	vec2(-1, -1), vec2(-1, 0), vec2(-1, 1), vec2(0, -1), vec2(0, 1),
	vec2(1, -1), vec2(1, 0), vec2(1, 1)
};

const vec2 OFFSETS_LQ[4] = {
	vec2(-1, -1), vec2(-1, 1), vec2(1, -1), vec2(1, 1)
};

void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * line_thickness / 2.0;
	vec4 color = texture(TEXTURE, UV);

	float inline_res = 1.0;
	float outline = 0.0;

	if (high_quality) {
		for (int i = 0; i < 8; i++) {
			float sample = texture(TEXTURE, UV + size * OFFSETS_HQ[i]).a;
			outline += sample;
			inline_res *= sample;
		}
	} else {
		for (int i = 0; i < 4; i++) {
			float sample = texture(TEXTURE, UV + size * OFFSETS_LQ[i]).a;
			outline += sample;
			inline_res *= sample;
		}
	}

	outline = min(1.0, outline) - color.a;
	inline_res = (1.0 - inline_res) * color.a;

	vec4 outlined_result = mix(color, line_color, outline + inline_res);
	COLOR = mix(color, outlined_result, outlined_result.a);
}
