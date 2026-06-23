shader_type canvas_item;

// 像素化参数
uniform float pixel_size_x : hint_range(10.0, 1000.0) = 320.0 ;
uniform float pixel_size_y  : hint_range(10.0, 1000.0) = 240.0;

// 颜色量化参数
uniform float color_levels  : hint_range(1.0, 20.0) = 3.0;
uniform float brightness_boost  : hint_range(0.5, 3.0) = 1.2;

// 边缘检测参数
uniform float edge_threshold  : hint_range(0.0, 2.0) = 0.73;

void fragment() {
	// 像素化处理
	vec2 uv = UV;
	uv = vec2(floor(uv.x * pixel_size_x) / pixel_size_x, 
	          floor(uv.y * pixel_size_y) / pixel_size_y);
	
	// 采样当前像素和相邻像素
	vec4 sample_center = texture(TEXTURE, uv);
	vec4 sample_right = texture(TEXTURE, uv + vec2(1.0 / pixel_size_x, 0.0));
	vec4 sample_down = texture(TEXTURE, uv + vec2(0.0, 1.0 / pixel_size_y));
	vec4 sample_left = texture(TEXTURE, uv + vec2(-1.0 / pixel_size_x, 0.0));
	vec4 sample_up = texture(TEXTURE, uv + vec2(0.0, -1.0 / pixel_size_y));
	
	// 颜色量化
	float brightness = floor(length(sample_center.rgb) + 0.5) * 0.5 + brightness_boost;
	vec3 quantized_color = vec3(
		floor(sample_center.r * color_levels) / color_levels * brightness,
		floor(sample_center.g * color_levels) / color_levels * brightness,
		floor(sample_center.b * color_levels) / color_levels * brightness
	);
	
	// 边缘检测
	float border = floor(
		distance(sample_right.rgb, sample_center.rgb) +
		distance(sample_down.rgb, sample_center.rgb) +
		distance(sample_left.rgb, sample_center.rgb) +
		distance(sample_up.rgb, sample_center.rgb) +
		edge_threshold
	);
	
	// 静态效果生成
	vec3 effect = vec3(0.0);
	effect.r = sin(sin(uv.x * 2.0) + uv.y * 10.0) * 0.5 + 0.5;
	effect.g = sin(sin(uv.x * 5.0) + uv.y * 70.0) * 0.5 + 0.5;
	effect.b = sin(sin(uv.x * 8.0) + uv.y * 100.0) * 0.5 + 0.5;
	
	// 效果颜色量化
	float effect_brightness = floor(length(effect.rgb) + 0.5) * 0.5 + brightness_boost;
	vec3 quantized_effect = vec3(
		floor(effect.r * color_levels) / color_levels * effect_brightness,
		floor(effect.g * color_levels) / color_levels * effect_brightness,
		floor(effect.b * color_levels) / color_levels * effect_brightness
	);
	
	// 条件颜色替换
	vec3 final_color = vec3(0.0);
	
	// 如果是绿色区域，使用效果颜色；否则使用量化后的原色
	if(quantized_color.g > 0.5 && quantized_color.r < 0.5 && quantized_color.b < 0.5) {
		final_color = quantized_effect * (1.0 - vec3(border));
	} else {
		final_color = quantized_color * (1.0 - vec3(border));
	}
	
	COLOR = vec4(final_color, 1.0);
}