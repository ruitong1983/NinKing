shader_type canvas_item;

// 模糊半径
uniform float blur_radius : hint_range(0.0, 10.0) = 3.0;
// 采样点数（性能与质量平衡）
uniform int samples = 9;

void fragment() {
    vec2 uv = UV;
    vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
    
    vec4 result = vec4(0.0);
    float total_weight = 0.0;
    
    // 计算高斯模糊
    for (int x = -samples/2; x <= samples/2; x++) {
        for (int y = -samples/2; y <= samples/2; y++) {
            // 计算高斯权重
            float distance = length(vec2(x, y));
            float weight = exp(-distance * distance / (2.0 * blur_radius * blur_radius));
            
            // 采样纹理
            vec2 offset = vec2(x, y) / tex_size * blur_radius;
            vec2 sample_uv = uv + offset;
            
            result += texture(TEXTURE, sample_uv) * weight;
            total_weight += weight;
        }
    }
    
    // 归一化
    result /= total_weight;
    
    COLOR = result;
}