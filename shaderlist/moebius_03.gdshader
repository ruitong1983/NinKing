shader_type canvas_item;
render_mode unshaded;

// 基础参数
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float edge_sensitivity : hint_range(0.0, 2.0) = 1.0;
uniform float edge_threshold : hint_range(0.0, 1.0) = 0.1;

// 线条控制
uniform float line_width : hint_range(0, 10.0) = 1.0;
uniform bool edges_only = false;

// 边缘检测质量
uniform bool use_double_threshold = true;
uniform bool enable_edge_connection = true;
uniform bool enable_non_maximum_suppression = true; // 新增：控制非极大值抑制

// 边缘连接强度
uniform float connection_strength : hint_range(0.0, 1.0) = 0.5;

// 抗锯齿
uniform float antialias : hint_range(0.0, 1.0) = 0.5;

// 亮度计算函数
float rgb_to_luminance(vec3 rgb) {
    return dot(rgb, vec3(0.299, 0.587, 0.114));
}

// 计算梯度强度和方向
void compute_gradient(sampler2D tex, vec2 uv, vec2 pixel_size, out float magnitude, out float direction) {
    // 使用5x5 Sobel算子（更好的边缘检测）
    vec2 offsets[25] = vec2[25](
        vec2(-2, -2), vec2(-1, -2), vec2(0, -2), vec2(1, -2), vec2(2, -2),
        vec2(-2, -1), vec2(-1, -1), vec2(0, -1), vec2(1, -1), vec2(2, -1),
        vec2(-2, 0), vec2(-1, 0), vec2(0, 0), vec2(1, 0), vec2(2, 0),
        vec2(-2, 1), vec2(-1, 1), vec2(0, 1), vec2(1, 1), vec2(2, 1),
        vec2(-2, 2), vec2(-1, 2), vec2(0, 2), vec2(1, 2), vec2(2, 2)
    );
    
    // 5x5 Sobel-X 算子
    const float sobel_x[25] = float[25](
        -2.0, -2.0, 0.0, 2.0, 2.0,
        -2.0, -3.0, 0.0, 3.0, 2.0,
        -4.0, -6.0, 0.0, 6.0, 4.0,
        -2.0, -3.0, 0.0, 3.0, 2.0,
        -2.0, -2.0, 0.0, 2.0, 2.0
    );
    
    // 5x5 Sobel-Y 算子
    const float sobel_y[25] = float[25](
        -2.0, -2.0, -4.0, -2.0, -2.0,
        -2.0, -3.0, -6.0, -3.0, -2.0,
        0.0, 0.0, 0.0, 0.0, 0.0,
        2.0, 3.0, 6.0, 3.0, 2.0,
        2.0, 2.0, 4.0, 2.0, 2.0
    );
    
    // 采样并计算亮度
    float samples[25];
    for(int i = 0; i < 25; i++) {
        samples[i] = rgb_to_luminance(textureLod(tex, uv + offsets[i] * pixel_size, 0.0).rgb);
    }
    
    // 计算梯度
    float gx = 0.0;
    float gy = 0.0;
    for(int i = 0; i < 25; i++) {
        gx += sobel_x[i] * samples[i];
        gy += sobel_y[i] * samples[i];
    }
    
    // 计算梯度幅度和方向
    magnitude = sqrt(gx * gx + gy * gy);
    direction = atan(gy, gx);
}

// 简化的梯度幅度计算（用于边缘连接）
float compute_simple_gradient(sampler2D tex, vec2 uv, vec2 pixel_size) {
    // 简化版的3x3 Sobel
    vec2 offsets[9] = vec2[9](
        vec2(-1, -1), vec2(0, -1), vec2(1, -1),
        vec2(-1, 0),  vec2(0, 0),  vec2(1, 0),
        vec2(-1, 1),  vec2(0, 1),  vec2(1, 1)
    );
    
    const float sobel_x[9] = float[9](-1.0, 0.0, 1.0, -2.0, 0.0, 2.0, -1.0, 0.0, 1.0);
    const float sobel_y[9] = float[9](-1.0, -2.0, -1.0, 0.0, 0.0, 0.0, 1.0, 2.0, 1.0);
    
    float samples[9];
    for(int i = 0; i < 9; i++) {
        samples[i] = rgb_to_luminance(textureLod(tex, uv + offsets[i] * pixel_size, 0.0).rgb);
    }
    
    float gx = 0.0;
    float gy = 0.0;
    for(int i = 0; i < 9; i++) {
        gx += sobel_x[i] * samples[i];
        gy += sobel_y[i] * samples[i];
    }
    
    return sqrt(gx * gx + gy * gy);
}

// 改进的边缘连接函数 - 使用容差进行浮点比较
float connect_edges(sampler2D tex, vec2 uv, vec2 pixel_size, float current_edge, float high_threshold, float low_threshold) {
    // 如果当前不是弱边缘，直接返回
    const float EPSILON = 0.001;
    if (abs(current_edge - 1.0) < EPSILON || abs(current_edge - 0.0) < EPSILON) {
        return current_edge;
    }
    
    // 检查8邻域
    int strong_neighbors = 0;
    int weak_neighbors = 0;
    
    for(int x = -1; x <= 1; x++) {
        for(int y = -1; y <= 1; y++) {
            if (x == 0 && y == 0) continue;
            
            vec2 offset = vec2(float(x), float(y)) * pixel_size * 2.0;
            vec2 sample_uv = clamp(uv + offset, vec2(0.0), vec2(1.0));
            
            float neighbor_magnitude = compute_simple_gradient(tex, sample_uv, pixel_size);
            float neighbor_strength = neighbor_magnitude * edge_sensitivity;
            
            // 使用容差进行比较
            if (neighbor_strength > high_threshold - EPSILON) {
                strong_neighbors++;
            } else if (neighbor_strength > low_threshold - EPSILON) {
                weak_neighbors++;
            }
        }
    }
    
    // 连接规则
    if (strong_neighbors > 0) {
        return 1.0;
    } else if (weak_neighbors >= 2) {
        return mix(0.5, 1.0, connection_strength);
    }
    
    return current_edge;
}

// 非极大值抑制 - Canny边缘检测的关键步骤
float non_maximum_suppression(float magnitude, float direction, sampler2D tex, vec2 uv, vec2 pixel_size) {
    const float EPSILON = 0.0001;
    
    // 将角度量化到4个主要方向（0°, 45°, 90°, 135°）
    float angle = mod(direction, 3.14159265);
    float quantized_angle;
    
    if (angle < 0.3927 || angle > 2.7489) { // 0° ±22.5°
        quantized_angle = 0.0;
    } else if (angle < 1.1781) { // 67.5° ±22.5°
        quantized_angle = 0.785398; // 45°
    } else if (angle < 1.9635) { // 112.5° ±22.5°
        quantized_angle = 1.5708; // 90°
    } else { // 157.5° ±22.5°
        quantized_angle = 2.35619; // 135°
    }
    
    // 沿梯度方向采样相邻像素
    vec2 dir1 = vec2(cos(quantized_angle), sin(quantized_angle));
    vec2 dir2 = -dir1;
    
    vec2 uv1 = clamp(uv + dir1 * pixel_size, vec2(0.0), vec2(1.0));
    vec2 uv2 = clamp(uv + dir2 * pixel_size, vec2(0.0), vec2(1.0));
    
    // 计算相邻像素的梯度幅度
    float mag1, dir1_angle;
    float mag2, dir2_angle;
    compute_gradient(tex, uv1, pixel_size, mag1, dir1_angle);
    compute_gradient(tex, uv2, pixel_size, mag2, dir2_angle);
    
    // 非极大值抑制：使用容差进行比较
    if (magnitude + EPSILON >= mag1 && magnitude + EPSILON >= mag2) {
        return magnitude;
    } else {
        return 0.0;
    }
}

void fragment() {
    // 1. 计算像素大小
    highp vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
    
    // 2. 计算梯度
    float magnitude, direction;
    compute_gradient(TEXTURE, UV, pixel_size, magnitude, direction);
    
    // 3. 应用非极大值抑制（如果启用）
    float suppressed_magnitude = magnitude;
    if (enable_non_maximum_suppression) {
        suppressed_magnitude = non_maximum_suppression(magnitude, direction, TEXTURE, UV, pixel_size);
    }
    
    // 4. 应用边缘敏感度
    float edge_strength = suppressed_magnitude * edge_sensitivity;
    
    // 5. 阈值处理
    float edge = 0.0;
    float high_threshold = edge_threshold;
    float low_threshold = edge_threshold * 0.4;
    
    if (use_double_threshold) {
        // 双阈值处理
        const float EPSILON = 0.0001;
        if (edge_strength > high_threshold - EPSILON) {
            edge = 1.0; // 强边缘
        } else if (edge_strength > low_threshold - EPSILON) {
            edge = 0.5; // 弱边缘
        }
        
        // 应用边缘连接（如果启用）
        if (enable_edge_connection && abs(edge - 0.5) < 0.1) { // 使用容差判断是否为弱边缘
            edge = connect_edges(TEXTURE, UV, pixel_size, edge, high_threshold, low_threshold);
        }
    } else {
        // 单阈值处理
        edge = step(edge_threshold, edge_strength);
    }
    
    // 6. 应用抗锯齿
    if (antialias > 0.0) {
        if (use_double_threshold) {
            // 双阈值的抗锯齿处理
            const float EPSILON = 0.0001;
            if (edge_strength > high_threshold - EPSILON) {
                edge = 1.0;
            } else if (edge_strength > low_threshold - EPSILON) {
                edge = smoothstep(low_threshold, high_threshold, edge_strength);
            }
        } else {
            // 单阈值的抗锯齿处理
            edge = smoothstep(edge_threshold * 0.7, edge_threshold * 1.3, edge_strength);
        }
    }
    
    // 7. 线条宽度扩展（优化版）
    const float EPSILON = 0.0001;
    if (line_width > 1.0 && edge > EPSILON) {
        float max_edge = edge;
        float radius = line_width * 0.5;
        int samples = int(clamp(radius, 2.0, 8.0));
        
        for(int x = -samples; x <= samples; x++) {
            for(int y = -samples; y <= samples; y++) {
                if (x == 0 && y == 0) continue;
                
                float dist = length(vec2(float(x), float(y)));
                if (dist <= radius + EPSILON) {
                    vec2 offset = vec2(float(x), float(y)) * pixel_size;
                    vec2 sample_uv = clamp(UV + offset, vec2(0.0), vec2(1.0));
                    
                    float sample_magnitude = compute_simple_gradient(TEXTURE, sample_uv, pixel_size);
                    float sample_strength = sample_magnitude * edge_sensitivity;
                    
                    float sample_edge = 0.0;
                    const float THRESHOLD_EPSILON = 0.0001;
                    if (use_double_threshold) {
                        if (sample_strength > high_threshold - THRESHOLD_EPSILON) {
                            sample_edge = 1.0;
                        } else if (sample_strength > low_threshold - THRESHOLD_EPSILON) {
                            sample_edge = 0.5;
                        }
                    } else {
                        sample_edge = step(edge_threshold, sample_strength);
                    }
                    
                    float weight = 1.0 - smoothstep(0.0, radius, dist);
                    max_edge = max(max_edge, sample_edge * weight);
                }
            }
        }
        
        edge = max_edge;
    }
    
    // 8. 获取原始颜色
    vec4 original_color = texture(TEXTURE, UV);
    
    // 9. 混合结果
    vec3 final_color;
    
    if (edges_only) {
        final_color = line_color.rgb * edge;
    } else {
        final_color = mix(original_color.rgb, line_color.rgb, edge);
    }
    
    // 10. 输出
    float alpha = edges_only ? edge : original_color.a;
    COLOR = vec4(final_color, alpha);
} 