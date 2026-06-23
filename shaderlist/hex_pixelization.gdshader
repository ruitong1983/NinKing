/*
	六角形モザイク by あるる（きのもと 結衣）
	Hex Noise by Yui Kinomoto @arlez80

	MIT License
	優化版 - 保留核心算法，添加實用控制參數
*/
shader_type canvas_item;

// 六邊形大小（原始參數）
uniform vec2 size = vec2(64.0, 48.0);

// 新增控制參數（從優化版吸收）
uniform float hex_scale : hint_range(0.1, 5.0) = 1.0;     // 六邊形縮放
uniform vec3 tint_color : source_color = vec3(1.0);       // 色調顏色
uniform float brightness : hint_range(0.0, 2.0) = 1.0;   // 亮度調節
uniform float contrast : hint_range(0.0, 2.0) = 1.0;     // 對比度調節
uniform bool invert_colors = false;                      // 反色效果

void fragment()
{
	// 應用全局縮放
	vec2 scaled_size = size * hex_scale * TEXTURE_PIXEL_SIZE;

	// 原始版本的核心算法（保持不變）
	bool half = mod(UV.y / 2.0, scaled_size.y) / scaled_size.y < 0.5;
	vec2 uv = UV + vec2(scaled_size.x * 0.5 * float(half), 0.0);
	vec2 center_uv = floor(uv / scaled_size) * scaled_size;
	vec2 norm_uv = mod(uv, scaled_size) / scaled_size;

	center_uv += mix(
		vec2(0.0, 0.0),
		mix(
			mix(
				vec2(scaled_size.x, -scaled_size.y),
				vec2(0.0, -scaled_size.y),
				float(norm_uv.x < 0.5)
			),
			mix(
				vec2(0.0, -scaled_size.y),
				vec2(-scaled_size.x, -scaled_size.y),
				float(norm_uv.x < 0.5)
			),
			float(half)
		),
		float(norm_uv.y < 0.3333333) * float(norm_uv.y / 0.3333333 < (abs(norm_uv.x - 0.5) * 2.0))
	);

	// 採樣原始紋理（保持原始算法的純淨性）
	vec4 color = textureLod(TEXTURE, center_uv, 0.0);

	// 應用色調
	color.rgb *= tint_color;

	// 應用對比度和亮度
	color.rgb = ((color.rgb - 0.5) * contrast) + 0.5;
	color.rgb *= brightness;

	// 反色效果
	if (invert_colors) {
		color.rgb = 1.0 - color.rgb;
	}

	COLOR = color;
}