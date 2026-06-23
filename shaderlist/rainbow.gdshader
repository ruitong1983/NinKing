shader_type canvas_item;

// 多巴胺配色效果参数
uniform float speed : hint_range(0, 4) = 1.2; // 活泼的动画速度
uniform float saturation : hint_range(0.7, 1.5) = 1.2; // 高饱和度
uniform float brightness : hint_range(0.0, 2.0) = 1.1; // 明亮的亮度
uniform float frequency : hint_range(4.0, 12.0) = 7.0; // 色彩分布密度
uniform float scale : hint_range(0.0, 2.0) = 1.2; // 彩虹大小
uniform bool animate = true; // 是否动画
uniform float contrast : hint_range(0.0, 2.0) = 1.2; // 增强对比度
// 透明度
uniform float alpha : hint_range(0.1, 1.0) = 1.0;

void fragment() {
    // 计算到中心的距离
    vec2 center = vec2(0.5, 0.5);
    vec2 uv = UV;
    float dist = length(uv - center) * scale;

    // 边缘处理
    float edge_factor = smoothstep(0.0, 0.2, 1.0 - dist * 0.8);

    // 动画效果
    if (animate) {
        dist += TIME * speed * 0.07;
    }

    // 计算HUE值，使用正弦和余弦组合创造更丰富的色彩变化
    float hue = fract((sin(dist * frequency * 0.3) + cos(dist * frequency * 0.2)) * 0.5 + 0.5);

    // 多巴胺风格配色（明亮、高饱和的粉、黄、蓝、绿等）
    vec3 color;
    if (hue < 0.15) {
        color = mix(vec3(1.0, 0.4, 0.7), vec3(1.0, 0.7, 0.4), hue / 0.15); // 亮粉到亮橙
    } else if (hue < 0.3) {
        color = mix(vec3(1.0, 0.7, 0.4), vec3(1.0, 1.0, 0.4), (hue - 0.15) / 0.15); // 亮橙到亮黄
    } else if (hue < 0.45) {
        color = mix(vec3(1.0, 1.0, 0.4), vec3(0.4, 1.0, 0.6), (hue - 0.3) / 0.15); // 亮黄到亮绿
    } else if (hue < 0.6) {
        color = mix(vec3(0.4, 1.0, 0.6), vec3(0.4, 0.8, 1.0), (hue - 0.45) / 0.15); // 亮绿到亮青
    } else if (hue < 0.75) {
        color = mix(vec3(0.4, 0.8, 1.0), vec3(0.6, 0.4, 1.0), (hue - 0.6) / 0.15); // 亮青到亮蓝
    } else {
        color = mix(vec3(0.6, 0.4, 1.0), vec3(1.0, 0.4, 0.7), (hue - 0.75) / 0.25); // 亮蓝到亮粉
    }

    // 应用饱和度、亮度和对比度
    color = pow(color, vec3(1.0 / contrast));
    color *= saturation * brightness;

    // 限制颜色最大值，避免过曝
    color = clamp(color, 0.0, 1.0);

    // 应用边缘效果
    color *= edge_factor;

    // 混合原始纹理
    vec4 tex_color = texture(TEXTURE, UV);
    COLOR = vec4(color * tex_color.rgb, alpha);
}
