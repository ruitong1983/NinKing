// 着色器类型：CanvasItem（用于2D节点）
shader_type canvas_item;

/* ================= 设置参数 ================= */

// 故障效果发生的概率
uniform float glitch_chance : hint_range(0.0, 1.0) = 0.2;

// 故障状态变化的速度
uniform float glitch_speed : hint_range(0.0, 10.0) = 7.0;

// 水平切片的数量（密度）
uniform float slice_density : hint_range(0.0, 20.0) = 14.0;

// 切片水平位移的强度
uniform float slice_strength : hint_range(0.0, 1.0) = 0.38;

// 全局抖动的强度
uniform float shake_strength : hint_range(0.0, 1.0) = 0.02;

// 色差（颜色分离）的偏移量
uniform float chroma_offset : hint_range(0.0, 1.0) = 0.016;

// 数字噪声的强度
uniform float noise_strength : hint_range(0.0, 1.0) = 0.2;

// 颜色闪烁效果的强度
uniform float color_flash_strength : hint_range(0.0, 1.0) = 0.4;

// 扫描线掉落效果的强度
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.18;

// 局部扭曲变形的强度
uniform float local_warp_strength : hint_range(0.0, 1.0) = 0.14;

// 切片水平翻转的概率
uniform float flip_chance : hint_range(0.0,1.0) = 0.15;

/* ================= 随机数函数 ================= */

// 一维随机数生成函数
float rand(float x) {
	return fract(sin(x * 143758.5453) * 43758.5453);
}

// 二维随机数生成函数
float rand2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453);
}

/* ================= 片段着色器主函数 ================= */

void fragment() {
	// 获取当前像素的UV坐标
	vec2 uv = UV;

	// 根据时间决定当前帧是否发生故障效果
	// step函数：当第一个参数 <= 第二个参数时返回1，否则返回0
	float glitch = step(1.0 - glitch_chance, rand(floor(TIME * glitch_speed)));

	/* ----- 切片效果 ----- */
	// 计算当前像素属于哪个水平切片
	float slice_id = floor(uv.y * slice_density + rand(floor(TIME)));
	// 为当前切片生成随机值
	float slice_rand = rand(slice_id + floor(TIME * glitch_speed));
	// 创建切片遮罩：只有部分切片会应用效果
	float slice_mask = step(0.5, slice_rand) * glitch;

	// 随机翻转部分切片（水平镜像）
	if(rand(slice_id * TIME) < flip_chance) {
		uv.x = 1.0 - uv.x;
	}

	// 对当前切片应用水平位移
	uv.x += (slice_rand - 0.5) * slice_strength * slice_mask;

	/* ----- 微抖动效果 ----- */
	// 生成快速的小幅度随机抖动
	float jitter = step(0.85, rand(TIME * 12.0)) * glitch;
	uv.x += (rand(TIME * 3.0) - 0.5) * 0.08 * jitter;

	/* ----- 局部扭曲效果 ----- */
	// 在某些切片区域添加局部扭曲变形
	float warp_zone = step(0.65, rand2(vec2(slice_id, TIME)));
	uv += (vec2(rand2(uv + TIME), rand2(uv - TIME)) - 0.5) * local_warp_strength * warp_zone * glitch;

	/* ----- 全局抖动效果 ----- */
	// 对整个屏幕应用随机位移
	uv += vec2(
		rand(TIME * 1.3) - 0.5,
		rand(TIME * 1.7) - 0.5
	) * shake_strength * glitch;

	/* ----- 颜色分离效果（色差） ----- */
	// 获取原始纹理颜色
	vec4 base = texture(TEXTURE, uv);
	// 对红色通道和蓝色通道应用相反的偏移
	float r = texture(TEXTURE, uv + vec2(chroma_offset * glitch, 0.0)).r;
	float b = texture(TEXTURE, uv - vec2(chroma_offset * glitch, 0.0)).b;
	// 组合颜色：红色偏移、绿色保持原样、蓝色偏移
	vec3 color = vec3(r, base.g, b);

	/* ----- 数字噪声效果 ----- */
	// 添加随机噪声（类似电视雪花）
	color += (rand2(uv * TIME * 1.5) - 0.5) * noise_strength * glitch;

	/* ----- 扫描线掉落效果 ----- */
	// 随机使部分水平扫描线变暗
	float scan = step(0.9, rand(uv.y * 100.0 + TIME * 10.0));
	color *= 1.0 - scan * scanline_strength * glitch;

	/* ----- 颜色闪烁效果 ----- */
	// 生成随机颜色用于闪烁
	vec3 flash_color = vec3(
		step(0.5, rand(TIME + 0.1)),  // 随机红色分量
		step(0.5, rand(TIME + 3.1)),  // 随机绿色分量
		step(0.5, rand(TIME + 6.1))   // 随机蓝色分量
	);
	// 将原始颜色与闪烁颜色混合
	color = mix(color, flash_color, rand(TIME * 4.0) * color_flash_strength * glitch);

	// 输出最终颜色，保持原始透明度
	COLOR = vec4(color, base.a);
}