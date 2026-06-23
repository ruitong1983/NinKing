shader_type canvas_item;

// 可调节的光环参数
uniform float ring_width : hint_range(0.01, 0.5) = 0.1;       // 光环宽度（0.01-0.3范围）
uniform float ring_softness : hint_range(0.01, 0.2) = 0.07;  // 边缘柔和度
uniform float glow_spread : hint_range(0.00, 0.2) = 0.06;    // 泛光范围
uniform float color_speed : hint_range(0.01, 2.0) = 0.2;     // 颜色变化速度
uniform float brightness : hint_range(0.5, 2.0) = 1.3;       // 整体亮度
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.5;      // 呼吸速度
uniform float edge_offset : hint_range(-0.5, 0.1) = 0.0;    // 边缘偏移调整（负值让边框更靠外）

// HSV转RGB函数
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    // 获取原图颜色
    vec4 original_color = texture(TEXTURE, UV);
    
    vec2 uv = UV;
    vec2 center_uv = uv - vec2(0.5);

    // 计算到图片边缘的距离（优化后：完全贴合边缘）
    // 加入edge_offset参数用于微调位置，负值向外扩展，正值向内收缩
    float left = uv.x + edge_offset;
    float right = (1.0 - uv.x) + edge_offset;
    float bottom = uv.y + edge_offset;
    float top = (1.0 - uv.y) + edge_offset;
    float dist_to_edge = min(min(left, right), min(bottom, top));

    // 1. 基础光环 - 调整计算方式让边框更贴近边缘
    float ring = smoothstep(0.0, ring_softness, dist_to_edge)
               * smoothstep(ring_width, ring_width - ring_softness, dist_to_edge);

    // 2. 泛光层
    float bloom = smoothstep(-glow_spread, ring_softness, dist_to_edge)
                * smoothstep(ring_width + glow_spread, ring_width, dist_to_edge)
                * 0.5;

    float total_glow = ring + bloom;

    // 3. 彩虹色效果
    float time = TIME;
    float angle = atan(center_uv.y, center_uv.x);
    
    float hue = (angle + 3.14159) / (2.0 * 3.14159);
    hue = fract(hue + time * color_speed);
    
    vec3 ring_color = hsv2rgb(vec3(hue, 0.7, 0.9)) * brightness;

    // 4. 呼吸效果
    float pulse = sin(time * pulse_speed) * 0.05 + 1.0;

    // 计算边框最终颜色（移除了高光）
    vec3 border_color = ring_color * total_glow * pulse;
    border_color = clamp(border_color, 0.0, 2.0);

    // 混合原图与边框
    vec3 final_color = mix(original_color.rgb, border_color, total_glow);
    
    // 输出最终颜色
    COLOR = vec4(final_color, original_color.a);
}