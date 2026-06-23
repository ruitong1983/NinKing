// godot_sharp_shader.shader
shader_type canvas_item;

// 可调节的锐化强度
uniform float strength : hint_range(0, 20) = 2.0;

void fragment() {
    vec2 texel_size = 1.0 / TEXTURE_PIXEL_SIZE;
    
    // 动态计算锐化核权重（基于strength参数）
    float center_weight = strength * 4.0 + 1.0;
    float side_weight = -strength;
    
    vec3 result = vec3(0.0);
    
    // 3x3卷积
    for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
            // 计算采样偏移（以像素为单位）
            vec2 offset = vec2(float(x) - 1.0, float(y) - 1.0);
            
            // 计算当前权重
            float weight;
            if (x == 1 && y == 1) {
                weight = center_weight;  // 中心权重
            } else if ((x == 1) != (y == 1)) {  // XOR：行或列居中（但不同时）
                weight = side_weight;    // 十字方向权重
            } else {
                weight = 0.0;            // 对角线权重
            }
            
            // 采样并累加
            result += texture(TEXTURE, UV + offset / texel_size).rgb * weight;
        }
    }
    
    COLOR = vec4(result, 1.0);
}