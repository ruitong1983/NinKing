shader_type canvas_item;

// 参数
uniform int range : hint_range(1, 5) = 1;
uniform float sensitivity : hint_range(0.1, 10.0) = 2.0;
uniform bool use_edge_detection = true;

void fragment() {
    vec3 col = texture(TEXTURE, UV).rgb;
    float noise = 0.0;
    int sample_count = 0;
    
    vec2 pixel_size = TEXTURE_PIXEL_SIZE;
    
    // 计算邻域差异
    for(int i = -range; i <= range; i++) {
        for(int j = -range; j <= range; j++) {
            // 跳过中心点
            if(i == 0 && j == 0) continue;
            
            vec2 offset = vec2(float(i), float(j)) * pixel_size;
            vec2 neighbor_uv = UV + offset;
            
            // 可选：边界钳制
            // neighbor_uv = clamp(neighbor_uv, 0.0, 1.0);
            
            vec3 neighbor = texture(TEXTURE, neighbor_uv).rgb;
            vec3 diff = col - neighbor;
            noise += dot(diff, diff);
            sample_count++;
        }
    }
    
    // 归一化（可选）
    if(sample_count > 0) {
        noise = noise / float(sample_count);
    }
    
    // 应用灵敏度
    float edge_value = 1.0 - (sensitivity * noise);
    
    if(use_edge_detection) {
        // 边缘检测模式
        vec3 final_color = vec3(clamp(edge_value, 0.0, 1.0));
        COLOR = vec4(final_color, texture(TEXTURE, UV).a);
    } else {
        // 原始颜色模式（可用于调试）
        COLOR = vec4(col, texture(TEXTURE, UV).a);
    }
}