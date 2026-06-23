shader_type canvas_item;

// ========== 可调节参数 (Uniforms) ==========
// 模糊与抽象化
uniform float blur_intensity : hint_range(0.0, 10.0) = 1.5;
uniform int posterize_levels : hint_range(2, 20) = 8;

// 色彩调整
uniform float color_intensity : hint_range(0.5, 2.0) = 1.0; // 整体颜色强度
uniform float color_temperature : hint_range(-0.5, 0.5) = 0.1; // 正值偏暖
uniform float saturation : hint_range(0.0, 2.0) = 1.1; // 饱和度

// 胶片与绘画质感
uniform float grain_amount : hint_range(0.0, 0.4) = 0.02; // 颗粒强度
uniform float grain_size : hint_range(0.0, 10.0) = 2.0; // 颗粒大小
uniform float fade : hint_range(0.0, 1.0) = 0.05; // 整体褪色感

// ========== 常量定义 (保留性能优化) ==========
const vec3 LUMINANCE_WEIGHT = vec3(0.299, 0.587, 0.114);
const float GAUSS_WEIGHTS[25] = float[](
    0.015625, 0.03125, 0.046875, 0.03125, 0.015625,
    0.03125, 0.0625,  0.09375,  0.0625,  0.03125,
    0.046875, 0.09375, 0.140625, 0.09375, 0.046875,
    0.03125, 0.0625,  0.09375,  0.0625,  0.03125,
    0.015625, 0.03125, 0.046875, 0.03125, 0.015625
);
 
// ========== 辅助函数 ==========
// 高斯模糊 (保留预计算权重优化)
vec4 apply_blur(sampler2D tex, vec2 uv, float intensity, vec2 pixel_size) {
    vec4 color = vec4(0.0);
    float total_weight = 0.0;
    float offset_x = intensity * pixel_size.x;
    float offset_y = intensity * pixel_size.y;
    
    int weight_idx = 0;
    for (float x = -2.0; x <= 2.0; x++) {
        for (float y = -2.0; y <= 2.0; y++) {
            float weight = GAUSS_WEIGHTS[weight_idx++];
            color += texture(tex, uv + vec2(x * offset_x, y * offset_y)) * weight;
            total_weight += weight;
        }
    }
    return color / total_weight;
}

// 色块化 (保留优化)
vec3 apply_posterize(vec3 color, int levels) {
    float levels_float = float(levels);
    float step = 1.0 / (levels_float - 1.0);
    return floor(color / step + 0.5) * step;
}

// 胶片颗粒 (关键恢复：改回经典的伪随机噪声算法，产生更自然、非均匀的颗粒)
vec3 apply_grain(vec3 color, vec2 uv, float amount, float size) {
    // 恢复经典算法：使用 sin 和 dot 产生伪随机数，fract 确保在 [0,1) 范围
    float noise = fract(sin(dot(uv * size, vec2(12.9898, 78.233))) * 43758.5453);
    // 将噪声从 [0,1) 映射到 [-0.5, 0.5)，然后与原始颜色混合
    return color + (noise - 0.5) * amount;
}

// ========== 主函数 ==========
void fragment() {
    vec2 base_uv = UV;
    
    // 1. 基础高斯模糊
    vec4 blurred_color = apply_blur(TEXTURE, base_uv, blur_intensity, TEXTURE_PIXEL_SIZE);
    
    // 2. 色块化处理
    vec3 processed_color = apply_posterize(blurred_color.rgb, posterize_levels);
    
    // 3. 色彩调整（整体颜色强度+色温+饱和度）
    processed_color *= color_intensity;
    processed_color.rgb += vec3(color_temperature, color_temperature * -0.5, color_temperature * -1.0);
    float luminance = dot(processed_color, LUMINANCE_WEIGHT);
    processed_color = mix(vec3(luminance), processed_color, saturation);
    
    // 4. 应用胶片颗粒与整体褪色
    processed_color = apply_grain(processed_color, SCREEN_UV * grain_size, grain_amount, 1.0);
    processed_color = mix(processed_color, vec3(0.5), fade);
    
    // 输出最终颜色
    COLOR = vec4(processed_color, blurred_color.a);
}