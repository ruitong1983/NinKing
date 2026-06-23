shader_type canvas_item;

uniform float blur_strength : hint_range(0.0, 1.0) = 0.5;
uniform float blur_radius : hint_range(0.0, 20.0) = 5.0;
uniform int blur_direction : hint_range(0, 1) = 0;
uniform int samples : hint_range(3, 25) = 13;

// 平滑曲线函数
float smooth_curve(float x) {
    // 使用平滑曲线：x^2 在低强度时平缓，线性在中段，sqrt在高端平滑
    if (x < 0.3) {
        return x * x * 3.33;  // 在低端更平缓
    } else if (x < 0.7) {
        return x;  // 中段线性
    } else {
        return sqrt(x * 1.43);  // 高端饱和
    }
}

vec4 gaussian_blur_advanced(sampler2D tex, vec2 uv, vec2 dir, float radius, float strength, int count) {
    vec4 color = texture(tex, uv);
    float total_weight = 1.0;
    
    // 根据strength调整sigma
    float sigma = 0.5 + strength * 2.0;
    
    // 基础权重，确保即使radius很小也有轻微模糊
    float base_weight = 0.1 * strength;
    
    for (int i = 1; i < count; i++) {
        // 计算权重：基础权重 + 高斯权重
        float dist = float(i) / float(count - 1);
        float gauss_weight = exp(-dist * dist / (2.0 * sigma * sigma));
        float weight = mix(base_weight, gauss_weight, 0.8);
        
        // 使用非线性步长
        float t = float(i) / float(count);
        float offset_factor = t * t * radius;  // 非线性分布
        
        vec2 offset = dir * offset_factor;
        color += texture(tex, uv + offset) * weight;
        color += texture(tex, uv - offset) * weight;
        total_weight += 2.0 * weight;
    }
    
    return color / total_weight;
}

void fragment() {
    vec2 pixel_size = TEXTURE_PIXEL_SIZE;
    
    // 应用平滑曲线
    float smooth_strength = smooth_curve(blur_strength);
    
    // 计算方向
    vec2 direction;
    if (blur_direction == 0) {
        direction = vec2(blur_radius * smooth_strength * pixel_size.x * 2.0, 0.0);
    } else {
        direction = vec2(0.0, blur_radius * smooth_strength * pixel_size.y * 2.0);
    }
    
    COLOR = gaussian_blur_advanced(TEXTURE, UV, direction, blur_radius, smooth_strength, samples);
}