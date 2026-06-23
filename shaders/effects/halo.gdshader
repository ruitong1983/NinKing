shader_type canvas_item;

// =====================
// 边框光晕环 — Halo Effect
// 移植自 shaderlist halo_01.gdshader
// 适配: 稀有度双色旋转光晕 + 呼吸脉冲 + 方向高光
// =====================

// ── 形态参数 ──
group_uniforms Shape;
uniform float ring_width : hint_range(0.01, 0.5) = 0.1;       // 光环宽度
uniform float ring_softness : hint_range(0.01, 0.2) = 0.07;  // 边缘柔和度
uniform float glow_spread : hint_range(0.01, 0.2) = 0.06;    // 泛光范围
uniform float edge_offset : hint_range(-0.5, 0.1) = 0.05;   // 边缘偏移

// ── 颜色 ──
group_uniforms Color;
uniform vec3 color1 : source_color = vec3(1.0, 0.4, 1.0);  // 基础色1 (紫)
uniform vec3 color2 : source_color = vec3(0.4, 1.0, 1.0);  // 基础色2 (青)
uniform float color_mix_range : hint_range(0.0, 1.0) = 0.6; // 颜色混合范围 (0=纯color1)
uniform vec3 highlight_color : source_color = vec3(1.0, 1.0, 0.9); // 高光色

// ── 动画控制 ──
group_uniforms Animation;
uniform bool animate = true;                                // 是否启用内部动画
uniform float rotate_speed : hint_range(0.0, 5.0) = 0.0;    // 旋转速度 (0=静态，animate=false时由外部驱动)
uniform float color_speed : hint_range(0.0, 2.0) = 0.0;     // 颜色变化速度 (0=固定)
uniform float pulse_speed : hint_range(0.0, 5.0) = 0.0;     // 呼吸速度 (0=无呼吸)

// ── 亮度 ──
group_uniforms Intensity;
uniform float brightness : hint_range(0.0, 2.0) = 1.2;      // 整体亮度
uniform float bloom_intensity : hint_range(0.1, 1.0) = 0.35; // 泛光强度
uniform float highlight_strength : hint_range(0.0, 2.0) = 1.2; // 高光强度

void fragment() {
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

    // 3. 颜色混合
    float ct = TIME;
    if (!animate) ct = 0.0;
    float angle = atan(center_uv.y, center_uv.x);
    float color_angle = angle + ct * color_speed;
    float color_mix = (sin(color_angle) * 0.5 + 0.5) * color_mix_range;
    vec3 ring_color = mix(color1, color2, color_mix) * brightness;

    // 4. 高光旋转
    float highlight_angle = ct * rotate_speed;
    vec2 highlight_dir = vec2(cos(highlight_angle), sin(highlight_angle));
    float dot_prod = dot(normalize(center_uv), highlight_dir);
    float highlight = pow(max(0.0, dot_prod), 8.0) * highlight_strength;

    // 5. 呼吸脉冲
    float pulse = 1.0;
    if (pulse_speed > 0.01) {
        pulse = sin(ct * pulse_speed) * 0.05 + 0.95;
    }

    // 合成最终光晕颜色
    vec3 final_color = (ring_color * total_glow * pulse) + (highlight * highlight_color);
    final_color = clamp(final_color, 0.0, 1.0);

    // 混合原图与光晕边框
    vec3 result_color = mix(original_color.rgb, final_color, total_glow);
    COLOR = vec4(result_color, original_color.a);
}
