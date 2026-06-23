shader_type canvas_item;

// 基础参数 - 使用滑条控制
uniform vec4 neon_color : source_color = vec4(0.0, 0.8, 1.0, 1.0); // 霓虹颜色
uniform float glow_intensity : hint_range(0.1, 5.0, 0.1) = 1.0;    // 发光强度
uniform float glow_radius : hint_range(1.0, 10.0, 0.1) = 3.0;      // 发光半径
uniform float edge_threshold : hint_range(0.0, 1.0, 0.01) = 0.2;   // 边缘检测阈值
uniform float sensitivity : hint_range(0.1, 3.0, 0.1) = 1.0;       // 边缘敏感度

// 发光层数控制
uniform int glow_layers : hint_range(1, 8) = 3;                    // 发光层数
uniform float layer_falloff : hint_range(0.1, 0.9, 0.05) = 0.7;    // 层间衰减

// 背景选项
uniform vec4 bg_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);   // 背景颜色
uniform bool show_original  = false;                  // 显示原始图像

// 亮度计算函数
float get_luminance(vec4 color) {
    return dot(color.rgb, vec3(0.299, 0.587, 0.114));
}

void fragment() {
    // 采样当前像素
    vec4 original_color = texture(TEXTURE, UV);
    
    // 边缘检测 - Sobel算子
    vec2 pixel_size = TEXTURE_PIXEL_SIZE;
    
    // 采样周围像素
    float lum_center = get_luminance(original_color);
    float lum_tl = get_luminance(texture(TEXTURE, UV + vec2(-pixel_size.x, -pixel_size.y)));
    float lum_t = get_luminance(texture(TEXTURE, UV + vec2(0.0, -pixel_size.y)));
    float lum_tr = get_luminance(texture(TEXTURE, UV + vec2(pixel_size.x, -pixel_size.y)));
    float lum_l = get_luminance(texture(TEXTURE, UV + vec2(-pixel_size.x, 0.0)));
    float lum_r = get_luminance(texture(TEXTURE, UV + vec2(pixel_size.x, 0.0)));
    float lum_bl = get_luminance(texture(TEXTURE, UV + vec2(-pixel_size.x, pixel_size.y)));
    float lum_b = get_luminance(texture(TEXTURE, UV + vec2(0.0, pixel_size.y)));
    float lum_br = get_luminance(texture(TEXTURE, UV + vec2(pixel_size.x, pixel_size.y)));
    
    // 计算梯度
    float sobel_x = (lum_tr + 2.0 * lum_r + lum_br) - (lum_tl + 2.0 * lum_l + lum_bl);
    float sobel_y = (lum_bl + 2.0 * lum_b + lum_br) - (lum_tl + 2.0 * lum_t + lum_tr);
    
    // 边缘强度
    float edge_strength = sqrt(sobel_x * sobel_x + sobel_y * sobel_y) * sensitivity;
    
    // 阈值处理
    edge_strength = smoothstep(edge_threshold - 0.1, edge_threshold + 0.1, edge_strength);
    
    // 发光效果 - 多层模糊叠加
    float total_glow = 0.0;
    
    for (int i = 0; i < glow_layers; i++) {
        float layer_radius = float(i + 1) * glow_radius / float(glow_layers);
        float layer_weight = pow(layer_falloff, float(i));
        
        // 径向采样模糊
        for (int j = 0; j < 8; j++) {
            float angle = float(j) * 3.14159 * 2.0 / 8.0;
            vec2 offset = vec2(cos(angle), sin(angle)) * pixel_size * layer_radius;
            
            // 采样偏移位置并计算边缘强度
            vec2 sample_uv = UV + offset;
            
            // 简单采样（实际应用中可能需要更精确的边缘检测）
            vec4 sample_color = texture(TEXTURE, sample_uv);
            float sample_lum = get_luminance(sample_color);
            
            // 快速边缘检测（使用中心与采样的差异）
            float edge_diff = abs(lum_center - sample_lum) * sensitivity;
            float sample_edge = smoothstep(edge_threshold - 0.05, edge_threshold + 0.05, edge_diff);
            
            total_glow += sample_edge * layer_weight * glow_intensity / 8.0;
        }
    }
    
    // 组合边缘和发光
    float final_glow = max(edge_strength, total_glow / float(glow_layers));
    
    // 应用颜色
    vec4 neon_result = neon_color * final_glow;
    
    // 混合背景
    vec4 final_color;
    if (show_original) {
        // 保留原始图像并叠加发光
        final_color = mix(original_color, neon_result, final_glow);
    } else {
        // 纯霓虹效果
        final_color = mix(bg_color, neon_result, final_glow);
    }
    
    // 增强对比度
    final_color.rgb = pow(final_color.rgb, vec3(0.8));
    
    COLOR = final_color;
}