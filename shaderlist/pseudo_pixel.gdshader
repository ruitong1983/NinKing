shader_type canvas_item;

uniform float mask_softness : hint_range(-2.0, 2.0) = 1.4; // 负值会使遮罩反转
uniform float mask_threshold : hint_range(0, 1.0) = 0.6;
uniform float sort : hint_range(0.0, 5.0) = 0.0;

void fragment() {
	vec2 uv = UV;
	vec4 tex = texture(TEXTURE, uv);
	
	// 遮罩计算
	float f = mask_softness / 2.0;
	float a = mask_threshold - f;
	float b = mask_threshold + f;
	float average = (tex.r + tex.g + tex.b) / 3.0;
	float mask = smoothstep(a, b, average);
	
	// 像素排序效果
	float sort_strength = clamp(sort / 2.6, 0.0, 1.0);
	
	// 融化的湍流效果
	float turbulence = fract(sin(dot(vec2(uv.x), vec2(12.9, 78.2))) * 437.5);
	
	// 计算偏移量 - 根据排序强度调整
	float melt_offset = pow(sort, 2.0 + (sort * 2.0)) * mask * turbulence;
	vec2 melted_uv = uv;
	melted_uv.y += melt_offset;
	
	// 混合原始和融化后的UV
	vec4 final_color;
	
	if (melted_uv.y > 1.0) {
		// 当偏移超出纹理范围时，使用像素排序效果
		vec2 sorted_uv = vec2(uv.x, 1.0 - sort_strength);
		final_color = texture(TEXTURE, sorted_uv);
	} else if (melted_uv.y < 0.0) {
		// 处理向上偏移的情况
		vec2 sorted_uv = vec2(uv.x, sort_strength);
		final_color = texture(TEXTURE, sorted_uv);
	} else {
		// 正常偏移在纹理范围内
		final_color = texture(TEXTURE, melted_uv);
	}
	
	COLOR = final_color;
	
	// 调试用 - 取消注释以查看遮罩效果
	// COLOR = vec4(mask, mask, mask, 1.0);
} 