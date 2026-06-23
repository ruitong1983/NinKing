shader_type canvas_item;

// ========== 主要参数 ==========
uniform float color_levels : hint_range(1.0, 64.0) = 15.0;
uniform float mix_factor : hint_range(0.0, 5.0) = 2.2;
uniform float brightness_val : hint_range(0.0, 2.0) = 1.0;
uniform float contrast_val : hint_range(0.0, 2.0) = 1.0;
uniform float saturation_val : hint_range(0.0, 2.0) = 1.0;

// ========== 渐变背景参数 ==========
uniform bool use_gradient_background = true;
uniform vec3 grad_color1 : source_color = vec3(0.4, 0.2, 0.4);
uniform vec3 grad_color2 : source_color = vec3(0.5, 0.7, 0.8);
uniform float gradient_angle : hint_range(0.0, 6.28) = 0.785; // 45度
uniform float gradient_scale : hint_range(0.0, 10.0) = 1.0;

// 灰度转换函数
float to_grayscale(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

// 颜色量化函数
vec3 quantize_color(vec3 color, float levels) {
    return floor(color * levels + 0.5) / levels;
}

// 调整亮度和对比度
vec3 adjust_brightness_contrast(vec3 color) {
    color = color * brightness_val;
    color = (color - 0.5) * contrast_val + 0.5;
    return clamp(color, 0.0, 1.0);
}

// 调整饱和度
vec3 adjust_saturation(vec3 color) {
    float gray = to_grayscale(color);
    return mix(vec3(gray), color, saturation_val);
}

void fragment() {
    vec2 uv = UV;

    // ========== 获取并处理原始颜色 ==========
    vec4 tex_color = texture(TEXTURE, uv);
    vec3 color = tex_color.rgb;

    // Gamma校正
    color = pow(color, vec3(1.0 / 2.2));

    // ========== 应用亮度和对比度调整 ==========
    color = adjust_brightness_contrast(color);

    // ========== 颜色量化 ==========
    vec3 quantized = quantize_color(color, color_levels);

    // ========== 渐变背景 ==========
    vec3 background = vec3(0.0);
    if (use_gradient_background) {
        // 计算渐变UV（考虑角度和缩放）
        vec2 grad_uv = uv * gradient_scale;
        float angle = gradient_angle;

        // 创建旋转矩阵 - 使用不同的构造方式
        float s = sin(angle);
        float c = cos(angle);

        // 方法1：使用4个float参数，按列主序
        // mat2构造函数：mat2(m00, m10, m01, m11)
        // 其中：
        // m00 = c, m10 = s   (第一列)
        // m01 = -s, m11 = c  (第二列)
        //mat2 rot = mat2(c, s, -s, c);

        // 方法2：使用vec2构造列
        mat2 rot = mat2(vec2(c, s), vec2(-s, c));

        grad_uv = rot * (grad_uv - 0.5) + 0.5;

        // 创建渐变（对角线方向）
        float gradient_value = grad_uv.x + grad_uv.y;
        gradient_value = mod(gradient_value, 1.0);

        background = mix(grad_color1, grad_color2, gradient_value);
    } else {
        // 不使用渐变背景时，使用纯色背景
        background = grad_color1;
    }

    // ========== 混合图像和背景 ==========
    float gray_value = to_grayscale(quantized);
    vec3 mixed = mix(background, quantized, gray_value * mix_factor);

    // ========== 应用饱和度调整 ==========
    vec3 final_color = adjust_saturation(mixed);

    // 最终输出
    COLOR = vec4(final_color, tex_color.a);
}