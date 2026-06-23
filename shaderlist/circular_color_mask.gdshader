shader_type canvas_item;

// ---- 区域模式参数 ----
uniform vec2 center = vec2(0.5, 0.5); // 中心点（UV坐标，默认屏幕中心）
uniform float radius : hint_range(0.0, 1.0) = 0.3; // 彩色区域半径
uniform float edge_hardness : hint_range(0.0, 10.0) = 5.0; // 边缘过渡硬度
uniform float effect_strength : hint_range(0.0, 1.0) = 1.0; // 效果强度

void fragment() {
    // 1. 获取原始颜色
    vec4 original_color = texture(TEXTURE, UV);
    vec3 rgb = original_color.rgb;
    
    // 2. 计算灰度值（使用亮度公式）
    float gray = dot(rgb, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(gray);
    
    // 3. 计算当前像素到中心点的距离
    float dist = distance(UV, center);
    
    // 4. 计算混合因子：距离小于半径则为1，大于半径则为0，中间有平滑过渡
    float blend_factor = 1.0 - smoothstep(radius * 0.9, radius * 1.1, dist);
    
    // 5. 调整边缘硬度
    blend_factor = pow(blend_factor, edge_hardness);
    
    // 6. 混合彩色和灰度结果
    vec3 final_color = mix(grayscale, rgb, blend_factor);
    
    // 7. 应用整体效果强度
    final_color = mix(original_color.rgb, final_color, effect_strength);
    
    COLOR = vec4(final_color, original_color.a);
}