shader_type canvas_item;

// 线稿参数 - 使用hint_range提供滑条
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // 线条颜色
uniform vec4 bg_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);   // 背景颜色
uniform float sensitivity : hint_range(0.0, 5.0, 0.1) = 1.0;      // 边缘检测敏感度
uniform float line_width : hint_range(0.1, 10.0, 0.1) = 1.0;      // 线宽
uniform float threshold : hint_range(0.0, 1.0, 0.01) = 0.1;       // 边缘强度阈值
uniform float smoothness : hint_range(0.0, 0.5, 0.01) = 0.05;     // 边缘平滑度
uniform float edge_power : hint_range(0.1, 5.0, 0.1) = 1.0;       // 边缘强度幂次调整

// 功能开关
uniform bool use_antialiasing = true;              // 使用抗锯齿
uniform bool use_center_detection = false;         // 使用中心像素检测（增强内部细节）
uniform float center_weight : hint_range(0.0, 2.0, 0.1) = 0.5;   // 中心像素权重

// 计算像素亮度（灰度值）
float get_luminance(vec4 color) {
    // 标准灰度转换公式：Y = 0.299R + 0.587G + 0.114B
    return dot(color.rgb, vec3(0.299, 0.587, 0.114));
}

// 计算中心像素差异（用于增强内部细节）
float get_center_difference(float center, float tl, float t, float tr, float l, float r, float bl, float b, float br) {
    // 计算中心像素与周围8个像素的平均差异
    float sum_diff = 0.0;
    sum_diff += abs(center - tl);
    sum_diff += abs(center - t);
    sum_diff += abs(center - tr);
    sum_diff += abs(center - l);
    sum_diff += abs(center - r);
    sum_diff += abs(center - bl);
    sum_diff += abs(center - b);
    sum_diff += abs(center - br);
    
    return sum_diff / 8.0; // 返回平均差异
}

void fragment() {
    // 采样偏移（基于纹理像素尺寸和线宽）
    vec2 pixel_step = TEXTURE_PIXEL_SIZE * line_width;
    
    // 采样当前像素及周围8个像素
    vec4 center = texture(TEXTURE, UV);
    vec4 tl = texture(TEXTURE, UV + vec2(-pixel_step.x, -pixel_step.y)); // 左上
    vec4 t  = texture(TEXTURE, UV + vec2(0.0, -pixel_step.y));          // 上
    vec4 tr = texture(TEXTURE, UV + vec2(pixel_step.x, -pixel_step.y)); // 右上
    vec4 l  = texture(TEXTURE, UV + vec2(-pixel_step.x, 0.0));          // 左
    vec4 r  = texture(TEXTURE, UV + vec2(pixel_step.x, 0.0));           // 右
    vec4 bl = texture(TEXTURE, UV + vec2(-pixel_step.x, pixel_step.y)); // 左下
    vec4 b  = texture(TEXTURE, UV + vec2(0.0, pixel_step.y));           // 下
    vec4 br = texture(TEXTURE, UV + vec2(pixel_step.x, pixel_step.y));  // 右下
    
    // 计算亮度值
    float lum_center = get_luminance(center);
    float lum_tl = get_luminance(tl);
    float lum_t  = get_luminance(t);
    float lum_tr = get_luminance(tr);
    float lum_l  = get_luminance(l);
    float lum_r  = get_luminance(r);
    float lum_bl = get_luminance(bl);
    float lum_b  = get_luminance(b);
    float lum_br = get_luminance(br);
    
    // Sobel算子：计算X/Y方向梯度
    float sobel_x = (lum_tr + 2.0 * lum_r + lum_br) - (lum_tl + 2.0 * lum_l + lum_bl);
    float sobel_y = (lum_bl + 2.0 * lum_b + lum_br) - (lum_tl + 2.0 * lum_t + lum_tr);
    
    // 梯度模长（边缘总强度）
    float edge_strength = sqrt(sobel_x * sobel_x + sobel_y * sobel_y) * sensitivity;
    
    // 如果启用中心像素检测，增强内部细节
    if (use_center_detection) {
        float center_diff = get_center_difference(lum_center, lum_tl, lum_t, lum_tr, lum_l, lum_r, lum_bl, lum_b, lum_br);
        edge_strength = max(edge_strength, center_diff * center_weight * sensitivity);
    }
    
    // 应用幂次调整（增强或减弱边缘对比度）
    edge_strength = pow(edge_strength, edge_power);
    
    // 阈值处理（支持抗锯齿）
    float alpha;
    if (use_antialiasing) {
        // 平滑过渡边缘（抗锯齿）
        alpha = smoothstep(threshold - smoothness, threshold + smoothness, edge_strength);
    } else {
        // 硬边缘
        alpha = step(threshold, edge_strength);
    }
    
    // 混合颜色
    vec4 result = mix(bg_color, line_color, alpha);
    
    // 保持原始纹理的透明度
    result.a *= center.a;
    
    // 可选：保留一些原始颜色信息
    // result.rgb = mix(result.rgb, center.rgb, 0.1);
    
    COLOR = result;
}