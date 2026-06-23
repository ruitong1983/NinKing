shader_type canvas_item;
// =============================================================
// multi_filter.gdshader — 复合滤镜（灰度 / 暗角 / 颜色叠加）
// =============================================================
// 合并 3 种常见后处理效果到单次 pass，通过 mode 切换：
//   0 = 灰度 (grayscale)
//   1 = 暗角 (vignette)
//   2 = 颜色叠加 (color overlay)
//   3 = 混合（灰度+暗角可调权重）
// =============================================================

// ─── 模式选择 ───
uniform int mode : hint_range(0, 3) = 0;

// ─── 灰度 (mode=0/3) ───
// 混合权重：0=全彩, 1=全灰（仅 mode=3 生效）
uniform float grayscale_weight : hint_range(0.0, 1.0) = 1.0;

// ─── 暗角 (mode=1/3) ───
uniform float vignette_intensity : hint_range(0.0, 15.0) = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 vignette_color = vec4(0.0, 0.0, 0.0, 1.0);

// ─── 颜色叠加 (mode=2) ───
uniform vec4 overlay_color = vec4(1.0, 1.0, 1.0, 1.0);


float calc_vignette(vec2 uv) {
	uv *= 1.0 - uv.xy;
	float v = uv.x * uv.y * 15.0;
	return pow(v, vignette_intensity * vignette_opacity);
}


void fragment() {
	vec4 col = texture(TEXTURE, UV);

	if (mode == 0) {
		// ── 灰度 ──
		float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
		COLOR = vec4(vec3(gray), col.a);

	} else if (mode == 1) {
		// ── 暗角 ──
		float vig = calc_vignette(UV);
		col.rgb = mix(col.rgb * vignette_color.rgb, col.rgb, vig);
		COLOR = col;

	} else if (mode == 2) {
		// ── 颜色叠加 ──
		COLOR = col * overlay_color;

	} else if (mode == 3) {
		// ── 混合：灰度 + 暗角 ──
		float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
		vec3 result = mix(col.rgb, vec3(gray), grayscale_weight);
		float vig = calc_vignette(UV);
		result = mix(result * vignette_color.rgb, result, vig);
		COLOR = vec4(result, col.a);
	}
}
