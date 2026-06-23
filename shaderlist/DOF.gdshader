// 带平滑过渡的圆形景深
shader_type canvas_item;

uniform float max_blur : hint_range(0.0, 0.03) = 0.015;
uniform float focus_radius : hint_range(0.0, 0.5) = 0.25;
uniform float transition_width : hint_range(0.0, 0.5) = 0.1;
uniform vec2 focus_center = vec2(0.5, 0.5);

void fragment() {
    vec2 uv = UV;
    float dist = distance(uv, focus_center);
    
    // 计算模糊强度（0.0-1.0）
    float blur_amount = 0.0;
    
    if (dist < focus_radius) {
        // 中心区域，完全不模糊
        blur_amount = 0.0;
    } else if (dist < focus_radius + transition_width) {
        // 过渡区域，逐渐模糊
        blur_amount = (dist - focus_radius) / transition_width;
    } else {
        // 外部区域，完全模糊
        blur_amount = 1.0;
    }
    
    // 根据模糊强度计算实际模糊大小
    float actual_blur = blur_amount * max_blur;
    
    // 简单的平均模糊（4个方向）
    if (actual_blur < 0.001) {
        COLOR = texture(TEXTURE, uv);
    } else {
        vec4 color = texture(TEXTURE, uv);
        color += texture(TEXTURE, uv + vec2(actual_blur, 0.0));
        color += texture(TEXTURE, uv + vec2(-actual_blur, 0.0));
        color += texture(TEXTURE, uv + vec2(0.0, actual_blur));
        color += texture(TEXTURE, uv + vec2(0.0, -actual_blur));
        
        COLOR = color / 5.0;
    }
}