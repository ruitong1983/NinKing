shader_type canvas_item;
render_mode unshaded;

// ==================== 线条系统 ====================
uniform vec4 line_color : source_color = vec4(0.05, 0.05, 0.1, 1.0);
uniform float edge_sensitivity : hint_range(0.0, 0.5) = 0.08;
uniform float line_thickness : hint_range(0.5, 3.0) = 1.2;
uniform float line_smoothness : hint_range(0.0, 1.0) = 0.3;
uniform float line_variation : hint_range(0.0, 0.5) = 0.15;

// ==================== 色彩系统 ====================
uniform int color_levels : hint_range(2, 16) = 4;
uniform float color_saturation : hint_range(0.0, 2.0) = 1.3;
uniform vec3 dominant_color : source_color = vec3(0.4, 0.6, 0.9);
uniform float color_blend : hint_range(0.0, 1.0) = 0.25;
uniform float warm_cool_balance : hint_range(-1.0, 1.0) = 0.1;

// ==================== 噪点控制系统 ====================
uniform float pattern_noise : hint_range(0.0, 1.0) = 0.3;  // 控制量化图案的噪点强度

// ==================== 艺术效果 ====================
uniform float stylization_intensity : hint_range(0.0, 1.0) = 0.7;

// ==================== 辅助函数 ====================
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 改进的量化函数：添加抖动，打破偶数levels的图案
vec3 quantize_with_dither(vec3 color, float levels, vec2 uv, float dither_strength) {
    float step = 1.0 / levels;
    
    // 计算抖动值（基于像素位置的伪随机）
    float dither = (hash(uv * 100.0) - 0.5) * dither_strength * step;
    
    // 应用抖动后量化
    vec3 quantized;
    quantized.r = floor((color.r + dither) * levels) / levels;
    quantized.g = floor((color.g + dither * 1.3) * levels) / levels;  // 不同通道使用不同抖动
    quantized.b = floor((color.b + dither * 0.7) * levels) / levels;
    
    return clamp(quantized, 0.0, 1.0);
}

// 莫比斯风格色彩转换
vec3 moebius_color_transform(vec3 original, vec2 uv) {
    vec3 color = original;
    
    // 1. 色彩量化（添加抖动）
    float levels = float(color_levels);
    color = quantize_with_dither(color, levels, uv, pattern_noise);
    
    // 2. 饱和度增强（保护亮度）
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(luminance), color, color_saturation);
    
    // 3. 冷暖色调平衡
    vec3 warm_tone = vec3(0.95, 0.8, 0.6);
    vec3 cool_tone = vec3(0.5, 0.7, 0.95);
    
    float balance = warm_cool_balance * 0.5 + 0.5;
    vec3 temperature = mix(cool_tone, warm_tone, balance);
    
    // 混合原始色和温度调色板
    color = mix(saturated, saturated * temperature, 0.3);
    
    // 4. 与主色调混合
    color = mix(color, dominant_color, color_blend);
    
    return clamp(color, 0.0, 1.0);
}

// ==================== 主函数 ====================
void fragment() {
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec2 base_pixel_size = 1.0 / tex_size;
    
    vec4 original_color = texture(TEXTURE, UV);
    
    // 透明区域处理
    if (original_color.a < 0.01) {
        COLOR = vec4(0.0);
        //return;
    }
    
    vec2 uv = UV;
    
    // --- 1. 改进的边缘检测系统 ---
    float edge_strength = 0.0;
    
    // 直接使用原始颜色（未量化）进行边缘检测
    // 这样边缘检测不会被量化图案干扰
    float center_lum = dot(original_color.rgb, vec3(0.299, 0.587, 0.114));
    
    // 多方向边缘检测
    const int DIRECTIONS = 8;
    for (int i = 0; i < DIRECTIONS; i++) {
        float angle = float(i) * (3.14159 / float(DIRECTIONS));
        vec2 direction = vec2(cos(angle), sin(angle));
        
        // 使用变化的线条厚度
        float thickness_variation = 1.0 + hash(uv * 5.0 + float(i)) * line_variation;
        vec2 pixel_size = base_pixel_size * line_thickness * thickness_variation;
        
        // 采样两个点
        vec2 offset1 = clamp(uv + direction * pixel_size, 0.0, 1.0);
        vec2 offset2 = clamp(uv - direction * pixel_size, 0.0, 1.0);
        
        vec3 sample1 = texture(TEXTURE, offset1).rgb;
        vec3 sample2 = texture(TEXTURE, offset2).rgb;
        
        float lum1 = dot(sample1, vec3(0.299, 0.587, 0.114));
        float lum2 = dot(sample2, vec3(0.299, 0.587, 0.114));
        
        // 计算梯度
        float gradient = max(abs(lum1 - center_lum), abs(lum2 - center_lum));
        
        // 应用line_smoothness参数
        float edge = smoothstep(
            edge_sensitivity * (1.0 - line_smoothness),
            edge_sensitivity * (1.0 + line_smoothness),
            gradient
        );
        
        edge_strength = max(edge_strength, edge);
    }
    
    // 添加随机性使线条更自然
    float line_noise = hash(uv * 20.0) * 0.1;
    edge_strength = clamp(edge_strength + line_noise, 0.0, 1.0);
    
    // --- 2. 莫比斯风格色彩处理 ---
    vec3 color = original_color.rgb;
    
    // 基础色彩转换（包含抖动量化）
    color = moebius_color_transform(color, uv);
    
    // 简化的阴影处理
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    if (luminance < 0.5) {
        float shadow = (0.5 - luminance) * 2.0;
        color *= (1.0 - shadow * 0.15);
        color = mix(color, color * dominant_color, shadow * 0.2);
    }
    
    // --- 3. 线条与颜色合成 ---
    vec3 final_color = color;
    
    // 根据边缘强度分层处理
    float strong_edge = step(0.7, edge_strength);
    float medium_edge = step(0.4, edge_strength);
    float weak_edge = step(0.1, edge_strength);
    
    if (strong_edge > 0.5) {
        final_color = line_color.rgb;
    } else if (medium_edge > 0.5) {
        float t = (edge_strength - 0.4) / 0.3;
        vec3 dark_color = color * 0.6;
        vec3 line_mix = mix(dark_color, line_color.rgb, t * 0.8);
        final_color = mix(color, line_mix, t * stylization_intensity);
    } else if (weak_edge > 0.5) {
        float t = (edge_strength - 0.1) / 0.3;
        final_color = color * (1.0 - t * 0.3 * stylization_intensity);
    }   
    
    // 最终输出
    COLOR = vec4(clamp(final_color, 0.0, 1.0), original_color.a);
}