shader_type canvas_item;

// DawnBringer 16 色板
const vec3[16] PALETTE = vec3[](
    vec3(0.0784, 0.0471, 0.1098),
    vec3(0.2667, 0.1412, 0.2039),
    vec3(0.1882, 0.2039, 0.4275),
    vec3(0.3059, 0.2902, 0.3059),
    vec3(0.5216, 0.2980, 0.1882),
    vec3(0.2039, 0.3961, 0.1412),
    vec3(0.8157, 0.2745, 0.2824),
    vec3(0.4588, 0.4431, 0.3804),
    vec3(0.3490, 0.4902, 0.8078),
    vec3(0.8235, 0.4902, 0.1725),
    vec3(0.5216, 0.5843, 0.6314),
    vec3(0.4275, 0.6667, 0.1725),
    vec3(0.8235, 0.6667, 0.6000),
    vec3(0.4275, 0.7608, 0.7922),
    vec3(0.8549, 0.8314, 0.3686),
    vec3(0.8706, 0.9333, 0.8392)
);

// Uniform 参数
uniform float intensity : hint_range(0.0, 5.0) = 1.0;
uniform float gamma_value : hint_range(0.5, 3.0) = 1.5;
uniform float color_boost : hint_range(0.5, 2.0) = 1.0;
uniform float dither_strength : hint_range(0.0, 5.0) = 0.0; // 抖动强度
uniform bool enable_dither = false; // 启用抖动

// 生成随机噪声
float random_noise(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// 快速颜色匹配函数
vec3 fast_color_match(vec3 color, vec2 uv) {
    // 应用伽马校正
    vec3 gamma_color = vec3(
        pow(color.r, gamma_value),
        pow(color.g, gamma_value),
        pow(color.b, gamma_value)
    );
    
    // 增强颜色饱和度
    gamma_color = mix(vec3(dot(gamma_color, vec3(0.333))), gamma_color, color_boost);
    
    // 应用抖动（如果需要）
    if (enable_dither && dither_strength > 0.0) {
        float noise = random_noise(uv) * dither_strength - (dither_strength * 0.5);
        gamma_color += vec3(noise);
        gamma_color = clamp(gamma_color, 0.0, 1.0);
    }
    
    // 使用曼哈顿距离加速最近邻搜索
    float min_dist = 1000.0;
    vec3 best_color = gamma_color;
    
    // 遍历调色板找到最接近的颜色
    for (int i = 0; i < 16; i++) {
        vec3 diff = abs(gamma_color - PALETTE[i]);
        float dist = diff.r + diff.g + diff.b; // 曼哈顿距离
        
        if (dist < min_dist) {
            min_dist = dist;
            best_color = PALETTE[i];
        }
    }
    
    return best_color;
}

void fragment() {
    // 获取原始纹理颜色
    vec4 tex_color = texture(TEXTURE, UV);
    vec3 original_color = tex_color.rgb;
    
    // 应用颜色量化（传入UV用于抖动）
    vec3 quantized_color = fast_color_match(original_color, UV);
    
    // 根据强度参数混合原始和量化颜色
    vec3 final_color = mix(original_color, quantized_color, intensity);
    
    // 输出最终颜色
    COLOR = vec4(final_color, tex_color.a);
} 