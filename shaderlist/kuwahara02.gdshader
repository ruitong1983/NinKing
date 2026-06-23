shader_type canvas_item;

// ========== 可调节参数 (Uniforms) ==========
// Kuwahara滤镜参数
uniform int kuwahara_radius : hint_range(1, 8) = 4;
uniform float kuwahara_hardness : hint_range(0.1, 10.0) = 2.0;

// 模糊与抽象化
uniform float blur_intensity : hint_range(0.0, 10.0) = 1.5;
uniform int posterize_levels : hint_range(2, 20) = 8;

// 色彩调整
uniform float color_intensity : hint_range(0.5, 2.0) = 1.0;
uniform float color_temperature : hint_range(-0.5, 0.5) = 0.1;
uniform float saturation : hint_range(0.0, 2.0) = 1.1;

// 胶片与绘画质感
uniform float grain_amount : hint_range(0.0, 0.4) = 0.02;
uniform float grain_size : hint_range(0.0, 10.0) = 2.0;
uniform float fade : hint_range(0.0, 1.0) = 0.05;

// 边缘强调参数
uniform float edge_emphasis : hint_range(0.0, 2.0) = 0.3;
uniform float edge_threshold : hint_range(0.0, 0.5) = 0.1;

// ========== 常量定义 ==========
const vec3 LUMINANCE_WEIGHT = vec3(0.299, 0.587, 0.114);

// 预计算的高斯权重（用于后处理模糊）
const float GAUSS_WEIGHTS[25] = float[](
    0.015625, 0.03125, 0.046875, 0.03125, 0.015625,
    0.03125, 0.0625,  0.09375,  0.0625,  0.03125,
    0.046875, 0.09375, 0.140625, 0.09375, 0.046875,
    0.03125, 0.0625,  0.09375,  0.0625,  0.03125,
    0.015625, 0.03125, 0.046875, 0.03125, 0.015625
);

// ========== 辅助函数 ==========
// 计算亮度
float luminance(vec3 color) {
    return dot(color, LUMINANCE_WEIGHT);
}

// Sobel边缘检测
float detect_edges(sampler2D tex, vec2 uv, vec2 pixel_size) {
    float top_left = luminance(texture(tex, uv + vec2(-1, -1) * pixel_size).rgb);
    float top = luminance(texture(tex, uv + vec2(0, -1) * pixel_size).rgb);
    float top_right = luminance(texture(tex, uv + vec2(1, -1) * pixel_size).rgb);
    
    float left = luminance(texture(tex, uv + vec2(-1, 0) * pixel_size).rgb);
    //float center = luminance(texture(tex, uv).rgb);
    float right = luminance(texture(tex, uv + vec2(1, 0) * pixel_size).rgb);
    
    float bottom_left = luminance(texture(tex, uv + vec2(-1, 1) * pixel_size).rgb);
    float bottom = luminance(texture(tex, uv + vec2(0, 1) * pixel_size).rgb);
    float bottom_right = luminance(texture(tex, uv + vec2(1, 1) * pixel_size).rgb);
    
    // 计算梯度
    float gx = (top_right + 2.0 * right + bottom_right) - 
               (top_left + 2.0 * left + bottom_left);
    float gy = (bottom_left + 2.0 * bottom + bottom_right) - 
               (top_left + 2.0 * top + top_right);
    
    // 梯度幅度
    return length(vec2(gx, gy));
}

// 高斯模糊（用于后处理）
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

// 色块化
vec3 apply_posterize(vec3 color, int levels) {
    float levels_float = float(levels);
    float step = 1.0 / (levels_float - 1.0);
    return floor(color / step + 0.5) * step;
}

// 胶片颗粒
vec3 apply_grain(vec3 color, vec2 uv, float amount, float size) {
    float noise = fract(sin(dot(uv * size, vec2(12.9898, 78.233))) * 43758.5453);
    return color + (noise - 0.5) * amount;
}

// 色温调整
vec3 apply_temperature(vec3 color, float temperature) {
    // 暖色调增加红色，减少蓝色；冷色调相反
    if (temperature >= 0.0) {
        // 暖色调：增强红色，轻微减少蓝色
        vec3 warm_filter = vec3(1.0 + temperature * 0.3, 
                                1.0 + temperature * 0.1, 
                                1.0 - temperature * 0.2);
        return color * warm_filter;
    } else {
        // 冷色调：增强蓝色，轻微减少红色
        float t = -temperature;
        vec3 cool_filter = vec3(1.0 - t * 0.1, 
                                1.0 + t * 0.05, 
                                1.0 + t * 0.3);
        return color * cool_filter;
    }
}

// ========== 主函数 ==========
void fragment() {
    vec2 base_uv = UV;
    vec2 pixel_size = TEXTURE_PIXEL_SIZE;
    
    // ===== 1. 应用Kuwahara滤镜（产生绘画感）=====
    int radius = kuwahara_radius;
    float hardness = kuwahara_hardness;
    
    // Kuwahara滤镜核心算法（直接在fragment函数中实现）
    // 四个象限的统计：左上(0), 右上(1), 左下(2), 右下(3)
    vec3 m[4];
    vec3 s[4];
    int n[4];
    
    for (int i = 0; i < 4; i++) {
        m[i] = vec3(0.0);
        s[i] = vec3(0.0);
        n[i] = 0;
    }
    
    // 收集统计信息
    for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
            vec2 offset = vec2(float(dx), float(dy)) * pixel_size;
            vec3 color = texture(TEXTURE, base_uv + offset).rgb;
            
            // 确定象限
            int q;
            if (dx < 0 && dy < 0) q = 0;
            else if (dx >= 0 && dy < 0) q = 1;
            else if (dx < 0 && dy >= 0) q = 2;
            else q = 3;
            
            m[q] += color;
            s[q] += color * color;
            n[q]++;
        }
    }
    
    // 软选择：加权混合所有象限
    vec3 kuwahara_color = vec3(0.0);
    float total_weight = 0.0;
    
    for (int i = 0; i < 4; i++) {
        if (n[i] > 0) {
            vec3 mean = m[i] / float(n[i]);
            vec3 variance = s[i] / float(n[i]) - mean * mean;
            float total_variance = variance.r + variance.g + variance.b;
            
            // 使用hardness控制选择的硬度
            float weight = exp(-hardness * total_variance);
            kuwahara_color += mean * weight;
            total_weight += weight;
        }
    }
    
    if (total_weight > 0.0) {
        kuwahara_color = kuwahara_color / total_weight;
    }
    
    float alpha = texture(TEXTURE, base_uv).a;
    
    // ===== 2. 边缘检测（用于边缘强调）=====
    float edge_strength = detect_edges(TEXTURE, base_uv, pixel_size);
    
    // ===== 3. 可选的后处理高斯模糊（用于柔化效果）=====
    vec4 blurred_color;
    if (blur_intensity > 0.01) {
        blurred_color = apply_blur(TEXTURE, base_uv, blur_intensity, pixel_size);
        // 混合Kuwahara颜色和模糊颜色（保留一些细节）
        kuwahara_color = mix(kuwahara_color, blurred_color.rgb, 0.3);
    }
    
    // ===== 4. 色块化处理 =====
    vec3 processed_color = kuwahara_color;
    if (posterize_levels > 2) {
        processed_color = apply_posterize(processed_color, posterize_levels);
    }
    
    // ===== 5. 色彩调整（整体颜色强度+色温+饱和度）=====
    processed_color *= color_intensity;
    processed_color = apply_temperature(processed_color, color_temperature);
    
    float lum = luminance(processed_color);
    processed_color = mix(vec3(lum), processed_color, saturation);
    
    // ===== 6. 边缘强调（增强绘画感）=====
    if (edge_emphasis > 0.01 && edge_strength > edge_threshold) {
        // 在边缘处稍微加深颜色
        float edge_factor = clamp(edge_strength * edge_emphasis * 2.0, 0.0, 0.5);
        processed_color *= (1.0 - edge_factor);
        
        // 可选：在边缘处增加对比度
        // processed_color = clamp(processed_color * (1.0 + edge_factor), 0.0, 1.0);
    }
    
    // ===== 7. 应用胶片颗粒与整体褪色 =====
    if (grain_amount > 0.01) {
        processed_color = apply_grain(processed_color, SCREEN_UV * grain_size, grain_amount, 1.0);
    }
    
    if (fade > 0.01) {
        processed_color = mix(processed_color, vec3(0.5), fade);
    }
    
    // 输出最终颜色
    COLOR = vec4(processed_color, alpha);
}