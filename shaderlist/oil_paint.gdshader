shader_type canvas_item;

// 统一变量：笔触的大小/油画效果的半径。值越大，笔触越粗糙。
uniform float brush_radius_pixels : hint_range(1.0, 10.0) = 5.0;

// 统一变量：颜色量化的强度。值越高，颜色越简化。
uniform float color_quantization_strength : hint_range(0.0, 10.0) = 5.0;

// 统一变量：细节保持的阈值。值越高，越能保持原始图像的细节。
uniform float detail_threshold : hint_range(0.0, 1.0) = 0.05;

void fragment() {
    // 1. 获取当前像素的原始颜色
    vec4 base_color = texture(TEXTURE, UV);

    // 2. 将像素半径转换为 UV 空间偏移量
    vec2 pixel_offset_uv = TEXTURE_PIXEL_SIZE * brush_radius_pixels;

    // 3. 颜色聚合/局部平均（模拟笔触）
    // 这个算法叫做“Kuwahara Filter”或类似的边缘保持模糊。
    // 它在一个小窗口内，计算多个子区域的平均值和方差，并选择方差最小的那个区域的平均颜色。
    // 这能有效模糊平坦区域，同时保持边缘锐利。

    // 我们将使用一个简化的邻域颜色聚合方法：
    // 遍历周围的像素，找到颜色最接近的邻居，并将其颜色作为主色。

    vec3 dominant_color_rgb = base_color.rgb;
    float min_color_diff = 100000.0; // 足够大的初始值

    // 采样周围 9 个像素 (3x3 窗口)
    for (float x = -1.0; x <= 1.0; x += 1.0) {
        for (float y = -1.0; y <= 1.0; y += 1.0) {
            vec2 sample_uv = UV + vec2(x, y) * pixel_offset_uv;
            vec4 sample_color = texture(TEXTURE, sample_uv);

            // 计算当前采样颜色与基础颜色的欧氏距离平方（颜色差异）
            float color_diff = dot(sample_color.rgb - base_color.rgb, sample_color.rgb - base_color.rgb);

            // 如果这个颜色差异是最小的，那么这个采样颜色就是当前最接近的“主色”
            if (color_diff < min_color_diff) {
                min_color_diff = color_diff;
                dominant_color_rgb = sample_color.rgb;
            }
        }
    }

    // 4. 将颜色进行进一步量化（结合颜色量化强度）
    // 这可以使笔触颜色更离散，更像真实油画的调色板。
    // 可以参考我们之前的 Posterization 效果。
    // 我们使用 `color_quantization_strength` 来控制量化级别。

    if (color_quantization_strength > 0.0) {
        float levels_minus_one = floor(color_quantization_strength);
        if (levels_minus_one < 1.0) levels_minus_one = 1.0; // 至少2个级别

        dominant_color_rgb.r = floor(dominant_color_rgb.r * levels_minus_one) / levels_minus_one;
        dominant_color_rgb.g = floor(dominant_color_rgb.g * levels_minus_one) / levels_minus_one;
        dominant_color_rgb.b = floor(dominant_color_rgb.b * levels_minus_one) / levels_minus_one;
    }

    // 5. 最终颜色混合
    // 我们可以根据 `detail_threshold` 将原始细节与油画效果混合。
    // 例如，如果原始颜色与主色的差异很小（细节不明显），则更多地使用主色；
    // 如果差异很大（边缘），则保留更多原始颜色或使用主色。

    // 这是一个非常简单的边缘保持：如果颜色差异很大，则使用原始颜色，否则使用油画颜色。
    float current_color_to_dominant_diff = dot(base_color.rgb - dominant_color_rgb, base_color.rgb - dominant_color_rgb);

    vec3 final_rgb = mix(dominant_color_rgb, base_color.rgb, step(detail_threshold, current_color_to_dominant_diff));

    // 6. 输出最终颜色
    COLOR = vec4(final_rgb, base_color.a);
}