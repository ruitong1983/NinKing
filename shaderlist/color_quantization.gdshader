shader_type canvas_item;

// 颜色数量 (2-256)
uniform int color_levels : hint_range(2, 256) = 8;

void fragment() {
    vec3 color = texture(TEXTURE, UV).rgb;
    
    // 简单色彩量化
    float step_size = 1.0 / float(color_levels - 1);
    vec3 quantized;
    
    // 对每个颜色通道独立量化
    quantized.r = floor(color.r / step_size + 0.5) * step_size;
    quantized.g = floor(color.g / step_size + 0.5) * step_size;
    quantized.b = floor(color.b / step_size + 0.5) * step_size;
    
    COLOR.rgb = quantized;
}