shader_type canvas_item;

uniform float dot_size : hint_range(1.0, 50.0) = 20.0;
uniform float angle : hint_range(0.0, 3.14159) = 0.78;

// 网点颜色控制
uniform vec3 dot_color_r = vec3(1.0, 0.0, 0.0);  // 红色网点颜色
uniform vec3 dot_color_g = vec3(0.0, 1.0, 0.0);  // 绿色网点颜色
uniform vec3 dot_color_b = vec3(0.0, 0.0, 1.0);  // 蓝色网点颜色
uniform vec3 background_color = vec3(0.0);       // 背景颜色

// 混合模式控制
uniform bool use_custom_colors = false;          // 是否使用自定义颜色
uniform bool preserve_original_brightness = true; // 是否保持原始亮度

float halftone(vec2 uv, float theta, float brightness) {
    vec2 s = vec2(sin(theta), cos(theta));
    vec2 coord = uv * dot_size;

    // 手动旋转计算
    float c = s.y;  // cos(theta)
    float si = s.x; // sin(theta)
    vec2 rotated;
    rotated.x = coord.x * c - coord.y * si;
    rotated.y = coord.x * si + coord.y * c;
    coord = rotated;

    float pattern = length(fract(coord) - 0.5);
    return step(pattern, brightness);
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    // 计算原始亮度（用于保持亮度关系）
    float original_brightness = (tex_color.r + tex_color.g + tex_color.b) / 3.0;

    // 对每个颜色通道单独应用半调
    float r_dot = halftone(UV, angle + 0.00, tex_color.r);
    float g_dot = halftone(UV, angle + 0.52, tex_color.g);
    float b_dot = halftone(UV, angle + 1.04, tex_color.b);

    vec3 color;

    if (use_custom_colors) {
        // 使用自定义颜色模式
        if (preserve_original_brightness) {
            // 保持原始亮度：用原始图像亮度来调制自定义颜色
            color = background_color;
            color += dot_color_r * r_dot * tex_color.r;
            color += dot_color_g * g_dot * tex_color.g;
            color += dot_color_b * b_dot * tex_color.b;
        } else {
            // 纯自定义颜色：忽略原始亮度
            color = background_color;
            color += dot_color_r * r_dot;
            color += dot_color_g * g_dot;
            color += dot_color_b * b_dot;
        }
    } else {
        // 原始模式：使用图像原始颜色
        color = vec3(r_dot, g_dot, b_dot);
    }

    COLOR = vec4(color, tex_color.a);
}