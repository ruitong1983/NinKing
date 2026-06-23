shader_type canvas_item;

// 增强版本，添加更多控制参数
uniform float levels : hint_range(0.0, 20.0, 0.1) = 4.0;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    vec3 color = base_color.rgb;
    
    // 可选：调整对比度和亮度
    //color = (color - 0.5) + 0.5;
    color = clamp(color, 0.0, 1.0);
    
    // 色调分离核心算法
    vec3 scaled_color = color * levels;
    vec3 floored_color = floor(scaled_color);
    vec3 posterized_rgb = (floored_color + 0.5) / levels;
    
    COLOR = vec4(posterized_rgb, base_color.a);
}