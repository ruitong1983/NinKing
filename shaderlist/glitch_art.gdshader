shader_type canvas_item;

// -----------------------------------------------------------
// 统一变量：控制故障效果的强度和频率
// -----------------------------------------------------------

// 全局故障激活阈值：0.0 到 1.0。值越高，故障出现的频率越高。
uniform float global_glitch_chance : hint_range(0.0, 1.0) = 0.05;

// 水平像素偏移的最大距离（以像素为单位）
uniform float max_horizontal_shift : hint_range(0.0, 10.0) = 5.0;

// 颜色通道分离的最大距离（以像素为单位）
uniform float max_color_fringe : hint_range(0.0, 5.0) = 2.0;

// 垂直块抖动的最大幅度（以像素为单位）
uniform float max_vertical_block_jitter : hint_range(0.0, 20.0) = 10.0;

// 随机噪音线的强度
uniform float noise_line_intensity : hint_range(0.0, 0.5) = 0.2;

// -----------------------------------------------------------
// 辅助函数：伪随机数生成器 (基于 UV 和 TIME)
// -----------------------------------------------------------
// 一个简单但有效的哈希函数，用于从 vec2 生成一个 [0, 1] 的浮点数
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 base_uv = UV;
    vec2 final_uv = UV;
    vec4 final_color;

    // 获取当前像素的屏幕坐标 (用于生成像素级别的随机性)
    // Godot 3.x 兼容：SCREEN_UV / SCREEN_PIXEL_SIZE
    vec2 pixel_coord = SCREEN_UV / SCREEN_PIXEL_SIZE;
    
    // 生成一个基础的随机种子，随时间和像素位置变化
    vec2 random_seed = pixel_coord + TIME * 1.5; // 1.5 是速度乘数

    // -----------------------------------------------------------
    // 1. 全局故障条件检测：不是所有像素都故障，只有当随机值低于阈值时才激活
    // -----------------------------------------------------------
    // 获取一个随时间变化的随机值，用于决定是否激活故障
    float global_glitch_rand = hash(vec2(TIME * 0.5, 0.0)); // 使用较低的频率
    
    // 如果 global_glitch_rand 小于 global_glitch_chance，则进入故障模式
    bool is_glitching = global_glitch_rand < global_glitch_chance;

    // -----------------------------------------------------------
    // 2. 颜色通道分离 (类似色差) - 无论是否全局故障都可能发生，但强度受全局影响
    // -----------------------------------------------------------
    vec3 fringe_rgb;
    // 获取随时间变化的随机偏移量，用于红蓝通道
    float fringe_offset_rand_x = (hash(random_seed * 0.7 + vec2(1.0, 0.0)) * 2.0 - 1.0) * max_color_fringe;
    float fringe_offset_rand_y = (hash(random_seed * 0.7 + vec2(0.0, 1.0)) * 2.0 - 1.0) * max_color_fringe;

    // 将偏移量转换为 UV 空间
    vec2 fringe_offset_uv = vec2(fringe_offset_rand_x, fringe_offset_rand_y) * TEXTURE_PIXEL_SIZE;
    
    // 红色通道采样
    fringe_rgb.r = texture(TEXTURE, base_uv + fringe_offset_uv * 0.5 * (is_glitching ? 1.0 : 0.0)).r;
    // 绿色通道（通常不偏移或偏移较小）
    fringe_rgb.g = texture(TEXTURE, base_uv).g;
    // 蓝色通道采样
    fringe_rgb.b = texture(TEXTURE, base_uv - fringe_offset_uv * 0.5 * (is_glitching ? 1.0 : 0.0)).b;
    
    final_color.rgb = fringe_rgb; // 初始颜色是分离后的颜色
    final_color.a = texture(TEXTURE, base_uv).a; // 保持原始透明度

    // -----------------------------------------------------------
    // 3. 水平像素偏移 (Horizontal Shift)
    // -----------------------------------------------------------
    if (is_glitching) {
        // 生成一个随当前行变化的随机偏移值
        float line_shift_rand = (hash(vec2(0.0, pixel_coord.y * 0.1 + TIME * 2.0)) * 2.0 - 1.0);
        float horizontal_shift_pixels = line_shift_rand * max_horizontal_shift;

        // 将偏移量转换为 UV 空间并应用
        final_uv.x += horizontal_shift_pixels * TEXTURE_PIXEL_SIZE.x;
    }
    
    // 重新采样纹理以应用水平偏移（在颜色通道分离之后）
    final_color.rgb = texture(TEXTURE, final_uv).rgb;

    // -----------------------------------------------------------
    // 4. 垂直块抖动 (Vertical Block Jitter)
    // -----------------------------------------------------------
    if (is_glitching) {
        // 将屏幕分成几块，每块以不同的随机值垂直抖动
        float block_height_pixels = 32.0; // 每块的像素高度
        float block_index = floor(pixel_coord.y / block_height_pixels);
        
        float block_jitter_rand = (hash(vec2(block_index, TIME * 5.0)) * 2.0 - 1.0);
        float vertical_jitter_pixels = block_jitter_rand * max_vertical_block_jitter;

        // 将抖动应用于 UV
        final_uv.y += vertical_jitter_pixels * TEXTURE_PIXEL_SIZE.y;
    }
    
    // 重新采样纹理以应用垂直抖动（在之前的偏移之后）
    final_color.rgb = texture(TEXTURE, final_uv).rgb;

    // -----------------------------------------------------------
    // 5. 随机噪音线 (Random Noise Lines) - 独立的强度叠加
    // -----------------------------------------------------------
    if (is_glitching) {
        // 随机决定某些行是否有噪音
        float line_noise_chance = hash(vec2(pixel_coord.y * 0.05 + TIME * 10.0, 0.0));
        if (line_noise_chance < 0.1) { // 10% 的行有噪音
            float noise_value = hash(random_seed * 2.0) * 0.5 + 0.5; // 产生随机亮度
            final_color.rgb = mix(final_color.rgb, vec3(noise_value), noise_line_intensity);
        }
    }

    // 6. 输出最终颜色 (保持原始透明度)
    COLOR = final_color;
}