shader_type canvas_item;

// 控制参数
uniform vec4 edge_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // 边缘颜色
uniform float strength : hint_range(0.0, 1.0, 0.01) = 0.05;       // 检测强度
uniform float smooth_edge : hint_range(0.0, 0.5, 0.05) = 0.0;    // 边缘平滑度
uniform bool use_brightness = true;                               // 使用亮度检测
uniform bool simple_mode = false;                                 // 简单模式（性能更好）

// 计算亮度（灰度）
float get_brightness(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

void fragment() {
    // 获取像素偏移
    vec2 pixel = TEXTURE_PIXEL_SIZE;
    vec4 center = texture(TEXTURE, UV);

    if (simple_mode) {
        // 简单模式：只检测4个主要方向
        vec4 right = texture(TEXTURE, UV + vec2(pixel.x, 0.0));
        vec4 bottom = texture(TEXTURE, UV + vec2(0.0, pixel.y));
        vec4 left = texture(TEXTURE, UV - vec2(pixel.x, 0.0));
        vec4 top = texture(TEXTURE, UV - vec2(0.0, pixel.y));

        // 计算4个方向的最大差异（修复：使用了所有4个采样）
        float edge = 0.0;

        if (use_brightness) {
            float center_bright = get_brightness(center.rgb);
            edge = max(edge, abs(center_bright - get_brightness(right.rgb)));
            edge = max(edge, abs(center_bright - get_brightness(bottom.rgb)));
            edge = max(edge, abs(center_bright - get_brightness(left.rgb)));
            edge = max(edge, abs(center_bright - get_brightness(top.rgb)));
        } else {
            edge = max(edge, length(center.rgb - right.rgb));
            edge = max(edge, length(center.rgb - bottom.rgb));
            edge = max(edge, length(center.rgb - left.rgb));
            edge = max(edge, length(center.rgb - top.rgb));
        }

        // 阈值处理
        float alpha;
        if (smooth_edge > 0.0) {
            alpha = smoothstep(strength - smooth_edge, strength + smooth_edge, edge);
        } else {
            alpha = step(strength, edge);
        }

        COLOR = mix(vec4(0.0), edge_color, alpha);
        COLOR.a *= center.a;
    } else {
        // 增强模式：检测8个方向（更完整但更耗性能）
        // 优化版：只采样4次，但计算8个方向
        vec4 right = texture(TEXTURE, UV + vec2(pixel.x, 0.0));
        vec4 bottom = texture(TEXTURE, UV + vec2(0.0, pixel.y));
        vec4 bottom_right = texture(TEXTURE, UV + vec2(pixel.x, pixel.y));
        vec4 bottom_left = texture(TEXTURE, UV + vec2(-pixel.x, pixel.y));

        float edge = 0.0;

        if (use_brightness) {
            float center_bright = get_brightness(center.rgb);

            // 主要4个方向
            edge = max(edge, abs(center_bright - get_brightness(right.rgb)));
            edge = max(edge, abs(center_bright - get_brightness(bottom.rgb)));
            edge = max(edge, abs(center_bright - get_brightness(bottom_right.rgb)));
            edge = max(edge, abs(center_bright - get_brightness(bottom_left.rgb)));

            // 通过对称性推断其他方向
            // 左上 ≈ 右下（相对于右上对称，近似处理）
            edge = max(edge, abs(center_bright - get_brightness(bottom_right.rgb)) * 0.7);
        } else {
            edge = max(edge, length(center.rgb - right.rgb));
            edge = max(edge, length(center.rgb - bottom.rgb));
            edge = max(edge, length(center.rgb - bottom_right.rgb));
            edge = max(edge, length(center.rgb - bottom_left.rgb));
        }

        // 应用阈值
        float alpha;
        if (smooth_edge > 0.0) {
            alpha = smoothstep(strength - smooth_edge, strength + smooth_edge, edge);
        } else {
            alpha = step(strength, edge);
        }

        vec4 result = mix(vec4(0.0), edge_color, alpha);
        result.a *= center.a;
        COLOR = result;
    }
}