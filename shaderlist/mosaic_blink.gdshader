shader_type canvas_item;

// 统一变量：噪点的可见强度。
uniform float grain_strength : hint_range(0.0, 0.2) = 0.05;

// 统一变量：噪点的粒度/粗细。值越大，噪点越细密。
uniform float grain_size : hint_range(1.0, 50.0) = 40.0; 

// 统一变量：噪点的移动速度。
uniform float grain_speed : hint_range(0.0, 5.0) = 1.0; 

// -----------------------------------------------------------
// 辅助函数：伪随机数生成器 (基于 UV 和 TIME)
// -----------------------------------------------------------
// 确保每次调用都返回不同的值
float hash(vec2 p) {
    // 使用一个快速的哈希函数来生成伪随机数
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    // 1. 获取原始颜色
    vec4 base_color = texture(TEXTURE, UV);
    
    // 2. 计算像素坐标，用于控制噪点粒度
    // 像素坐标 = SCREEN_UV / SCREEN_PIXEL_SIZE
    vec2 pixel_coord = SCREEN_UV / SCREEN_PIXEL_SIZE;
    
    // 3. 计算噪点种子
    // 通过除以 grain_size 来控制噪点的粒度：值越大，粒度越细密
    vec2 grain_seed = floor(pixel_coord / grain_size);
    
    // 4. 引入时间：让噪点随时间快速变化 (关键步骤)
    // 使用 floor() 确保噪点块在变化前保持稳定，直到 time_offset 变化足够大
    float time_offset = floor(TIME * grain_speed);
    grain_seed += time_offset;
    
    // 5. 生成 [-1, 1] 范围的噪点值
    // hash() 产生 [0, 1]
    // hash() * 2.0 - 1.0 产生 [-1, 1]
    float noise_value = hash(grain_seed) * 2.0 - 1.0;
    
    // 6. 应用噪点
    // 将噪点值乘以强度，然后加到 RGB 颜色上
    vec3 final_rgb = base_color.rgb + noise_value * grain_strength;
    
    // 7. 确保颜色值保持在 [0, 1] 范围内
    final_rgb = clamp(final_rgb, 0.0, 1.0);
    
    // 8. 输出最终颜色 (保持原始 Alpha)
    COLOR = vec4(final_rgb, base_color.a);
}