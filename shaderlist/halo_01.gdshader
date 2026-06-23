shader_type canvas_item;

// 边框形态参数
uniform float ring_width : hint_range(0.01, 0.5) = 0.1;       // 光环宽度
uniform float ring_softness : hint_range(0.01, 0.2) = 0.07;  // 边缘柔和度
uniform float glow_spread : hint_range(0.01, 0.2) = 0.06;    // 泛光范围
uniform float edge_offset : hint_range(-0.5, 0.1) = 0.05;   // 边缘偏移

// 动画参数
uniform float rotate_speed : hint_range(0.0, 5.0) = 1.0;      // 旋转速度（0=静止）
uniform float color_speed : hint_range(0.0, 2.0) = 0.5;       // 颜色变化速度（0=无变化）
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.5;       // 呼吸速度（0=无呼吸）

// 颜色控制参数（核心）
// 基础色1（RGB通道）
uniform float color1_r : hint_range(0.0, 1.0) = 1.0;
uniform float color1_g : hint_range(0.0, 1.0) = 0.4;
uniform float color1_b : hint_range(0.0, 1.0) = 1.0;

// 基础色2（RGB通道）
uniform float color2_r : hint_range(0.0, 1.0) = 0.4;
uniform float color2_g : hint_range(0.0, 1.0) = 1.0;
uniform float color2_b : hint_range(0.0, 1.0) = 1.0;

// 颜色混合范围（0=纯color1，1=两种颜色完全混合）
uniform float color_mix_range : hint_range(0.0, 1.0) = 1.0;

// 高光参数
uniform float highlight_strength : hint_range(0.0, 2.0) = 1.2; // 高光强度
// 高光颜色（RGB通道）
uniform float highlight_r : hint_range(0.0, 1.0) = 1.0;
uniform float highlight_g : hint_range(0.0, 1.0) = 1.0;
uniform float highlight_b : hint_range(0.0, 1.0) = 0.9;

// 亮度调节
uniform float brightness : hint_range(0.0, 2.0) = 1.2;         // 整体亮度
uniform float bloom_intensity : hint_range(0.1, 1.0) = 0.35;   // 泛光强度

void fragment() {
    // 组合颜色（在函数内部组合避免全局变量错误）
    vec3 base_color1 = vec3(color1_r, color1_g, color1_b);
    vec3 base_color2 = vec3(color2_r, color2_g, color2_b);
    vec3 highlight_color = vec3(highlight_r, highlight_g, highlight_b);
    
    // 获取原图颜色
    vec4 original_color = texture(TEXTURE, UV);
    
    vec2 uv = UV;
    vec2 center_uv = uv - vec2(0.5);

    // 计算到边缘的距离
    float left = uv.x + edge_offset;
    float right = (1.0 - uv.x) + edge_offset;
    float bottom = uv.y + edge_offset;
    float top = (1.0 - uv.y) + edge_offset;
    float dist_to_edge = min(min(left, right), min(bottom, top));

    // 1. 基础光环
    float ring = smoothstep(-0.01, ring_softness, dist_to_edge)
               * smoothstep(ring_width + ring_softness, ring_width, dist_to_edge);

    // 2. 泛光层
    float bloom = smoothstep(-glow_spread, ring_softness, dist_to_edge)
                * smoothstep(ring_width + glow_spread, ring_width, dist_to_edge)
                * bloom_intensity;

    float total_glow = ring + bloom;

    // 3. 颜色混合（核心：可控的颜色变化）
    float time = TIME;
    float angle = atan(center_uv.y, center_uv.x);
    float color_angle = angle + time * color_speed;
    // 限制颜色混合范围，实现纯色效果
    float color_mix = (sin(color_angle) * 0.5 + 0.5) * color_mix_range;
    vec3 ring_color = mix(base_color1, base_color2, color_mix) * brightness;

    // 4. 高光
    float highlight_angle = time * rotate_speed;
    vec2 highlight_dir = vec2(cos(highlight_angle), sin(highlight_angle));
    float dot_prod = dot(normalize(center_uv), highlight_dir);
    float highlight = pow(max(0.0, dot_prod), 8.0) * highlight_strength;

    // 5. 呼吸效果
    float pulse = sin(time * pulse_speed) * 0.05 + 0.95;

    // 最终颜色混合
    vec3 final_color = (ring_color * total_glow * pulse) + (highlight * highlight_color);
    final_color = clamp(final_color, 0.0, 1.0);

    // 混合原图与边框，输出最终颜色
    vec3 result_color = mix(original_color.rgb, final_color, total_glow);
    COLOR = vec4(result_color, original_color.a);
}
    