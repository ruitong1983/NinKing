shader_type canvas_item;

// 亮度增强参数
uniform float intensity : hint_range(0.0, 5.0, 0.1) = 2.0;
uniform float brightness_power : hint_range(0.0, 3.0, 0.1) = 1.0;
uniform float threshold : hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
    // 采样当前像素的原始纹理颜色
    vec4 color = texture(TEXTURE, UV);
    
    // 计算亮度（RGB通道中的最大值）
    float brightness = max(color.r, max(color.g, color.b));
    
    // 应用亮度阈值：低于阈值的亮度设为0
    brightness = max(brightness - threshold, 0.0) / (1.0 - threshold);
    
    // 应用亮度幂次调整（非线性亮度响应）
    brightness = pow(brightness, brightness_power);
    
    // 应用亮度增强
    vec3 result = color.rgb * brightness * intensity;
    
    // 限制颜色值在有效范围内
    result = clamp(result, 0.0, 1.0);
    
    // 输出最终颜色
    COLOR = vec4(result, color.a);
}