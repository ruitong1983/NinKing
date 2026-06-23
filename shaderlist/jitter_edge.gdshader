shader_type canvas_item;

// 统一变量：抖动的最大幅度（以像素为单位）。
uniform float max_jitter_amplitude : hint_range(0.0, 5.0) = 2.0;

// 统一变量：抖动的速度/频率。值越大，抖动越快。
uniform float jitter_speed : hint_range(1.0, 50.0) = 30.0;

// 统一变量：边缘检测的宽度（用于识别边缘像素）。
uniform float edge_detect_width : hint_range(1.0, 3.0) = 1.0;

// -----------------------------------------------------------
// 辅助函数：伪随机数生成器 (基于 UV 和 TIME)
// -----------------------------------------------------------
float hash(vec2 p) {
    // 使用一个快速的哈希函数来生成伪随机数，基于输入 vec2 p
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    // 1. 获取基础颜色和边缘检测的偏移量
    vec4 base_color = texture(TEXTURE, UV);
    vec2 offset = TEXTURE_PIXEL_SIZE * edge_detect_width;

    // 2. 边缘检测：检查当前像素是否靠近物体的Alpha边缘
    // 检查右侧和下侧的邻居是否透明度有显著差异（简化检查）
    vec4 neighbor_right = texture(TEXTURE, UV + vec2(offset.x, 0.0));
    vec4 neighbor_down = texture(TEXTURE, UV + vec2(0.0, offset.y));

    // 计算透明度变化梯度 (绝对值)
    float alpha_diff_x = abs(base_color.a - neighbor_right.a);
    float alpha_diff_y = abs(base_color.a - neighbor_down.a);

    // 如果透明度变化显著，则认为我们在边缘附近
    // 使用一个较低的阈值 (如 0.2) 来捕获边缘
    float is_edge = step(0.2, alpha_diff_x) + step(0.2, alpha_diff_y);

    // 3. 计算抖动偏移量

    // a. 获取随机值：结合 TIME 和 UV 来确保每帧和每个像素的抖动都不同
    vec2 random_seed = UV + TIME * jitter_speed;
    float jitter_random_x = hash(random_seed); // 范围 [0, 1]
    float jitter_random_y = hash(random_seed * 1.5); // 另一个独立的随机值

    // b. 将随机值映射到 [-1, 1] 范围，并乘以最大幅度
    // jitter_vector 范围在 [-max_jitter_amplitude, max_jitter_amplitude]
    vec2 jitter_vector = vec2(jitter_random_x * 2.0 - 1.0,
                              jitter_random_y * 2.0 - 1.0) * max_jitter_amplitude;

    // 4. 应用抖动：只对边缘像素应用偏移
    // is_edge > 0.0 时，jitter_vector 全部生效；否则为 vec2(0.0)
    vec2 final_uv_offset = jitter_vector * step(0.01, is_edge) * TEXTURE_PIXEL_SIZE;

    // 5. 使用偏移后的 UV 采样纹理
    vec4 final_color = texture(TEXTURE, UV + final_uv_offset);

    // 6. 输出最终颜色
    COLOR = final_color;
}