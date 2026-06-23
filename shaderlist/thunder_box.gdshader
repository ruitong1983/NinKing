shader_type canvas_item;
render_mode blend_premul_alpha;

// 可视化调节参数（在Inspector中调整）
uniform float lightning_width : hint_range(0.01, 0.2) = 0.05; // 雷电线条宽度
uniform float rotate_speed : hint_range(0.0, 0.5) = 0.1;      // 整体旋转速度
uniform float flicker_speed : hint_range(5.0, 50.0) = 20.0;   // 闪烁速度
uniform float flicker_strength : hint_range(0.0, 1.0) = 0.8;  // 闪烁强度
uniform float noise_intensity : hint_range(0.0, 0.5) = 0.2;   // 噪声扭曲强度
uniform vec3 lightning_color = vec3(1.0, 0.8, 0.2); // 雷电颜色
uniform float edge_softness : hint_range(0.0, 0.1) = 0.02;    // 边缘柔化
uniform float tile_count : hint_range(1.0, 20.0) = 8.0;       // 【新增】平铺数量，控制密度

// 宏定义
#define S smoothstep
#define PI 3.1415926535

// 2D旋转矩阵（Godot兼容写法）
mat2 rotate(float a) {
	float s = sin(a);
	float c = cos(a);
	return mat2(vec2(c, s), vec2(-s, c));
}

// 基础噪声函数
float noise(vec2 p) {
	p = fract(p * vec2(123.45, 67.89));
	p += dot(p, p + 45.67);
	return fract(p.x * p.y);
}

// FBM分形噪声（用于生成自然扭曲）
float fbm(vec2 p) {
	float f = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		f += amplitude * noise(p);
		p *= 2.01;
		amplitude *= 0.5;
	}
	return f;
}

void fragment() {
	// 1. 基础坐标处理（中心化并修正宽高比）
	vec2 uv = UV * 2.0 - 1.0;
	uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	
	// 2. 【核心修改】平铺逻辑 - 实现均匀分布
	vec2 tiled_uv = uv * tile_count;
	vec2 fractional_uv = fract(tiled_uv);
	vec2 centered_uv = fractional_uv * 2.0 - 1.0;
	float edge_dist = 1.0 - length(centered_uv);
	
	// 3. 创建边框遮罩（现在作用于每个平铺单元）
	float edge_mask = S(lightning_width, lightning_width + edge_softness, edge_dist);
	edge_mask *= S(-edge_softness, 0.0, edge_dist);
	
	// 4. 动态旋转与垂直向量
	float rotate_angle = TIME * rotate_speed;
	vec2 dir = normalize(vec2(cos(rotate_angle), sin(rotate_angle)));
	vec2 dir_perp1 = dir.yx * vec2(-1.0, 1.0) * sin(TIME);
	vec2 dir_perp2 = dir.yx * vec2(1.0, -1.0) * sin(TIME + PI/2.0);
	
	// 5. 噪声扭曲（使用世界坐标确保连续性）
	vec2 noise_uv = tiled_uv * rotate(rotate_angle);
	float n1 = fbm(noise_uv + dir_perp1 * noise_intensity);
	float n2 = fbm(noise_uv + dir_perp2 * noise_intensity);
	float noise_distort = (n1 + n2) * 0.5 - 0.5;
	
	// 6. 闪烁效果
	float flicker = sin(flicker_speed * TIME + sin(flicker_speed * 0.5 * TIME)) * flicker_strength;
	flicker = max(flicker, 0.1);
	
	// 7. 计算雷电亮度
	float lightning_dist = abs(edge_dist + noise_distort * edge_mask);
	float lightning_brightness = pow(0.01 / max(lightning_dist, 0.001), 1.5);
	lightning_brightness *= edge_mask * flicker;
	
	// 8. 混合最终颜色
	vec4 base_color = texture(TEXTURE, UV);
	vec3 lightning_color_final = lightning_color * lightning_brightness;
	base_color.rgb += lightning_color_final;
	
	// 9. 输出颜色
	COLOR = base_color;
}