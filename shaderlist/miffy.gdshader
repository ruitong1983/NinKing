shader_type canvas_item;
render_mode blend_mix;

// 控制参数
uniform float color_seed : hint_range(0.0, 5.0) = 0.5;
uniform float color_variety : hint_range(0.0, 5.0) = 1.0;
uniform float style_strength : hint_range(0.0, 1.0) = 0.8;

// 浮点数比较容差
const float EPSILON = 0.000001;

// 获取色相函数
float get_hue(vec3 rgb) {
    float max_c = max(max(rgb.r, rgb.g), rgb.b);
    float min_c = min(min(rgb.r, rgb.g), rgb.b);
    float delta = max_c - min_c;

    if (abs(delta) < EPSILON) return 0.0;

    float hue;
    if (abs(max_c - rgb.r) < EPSILON) {
        hue = (rgb.g - rgb.b) / delta;
    } else if (abs(max_c - rgb.g) < EPSILON) {
        hue = 2.0 + (rgb.b - rgb.r) / delta;
    } else {
        hue = 4.0 + (rgb.r - rgb.g) / delta;
    }

    hue /= 6.0;
    if (hue < 0.0) hue += 1.0;
    return hue;
}

void fragment() {
    vec4 original = texture(TEXTURE, UV);

    // 计算亮度和色相
    float brightness = dot(original.rgb, vec3(0.299, 0.587, 0.114));
    float hue = get_hue(original.rgb);

    // 计算饱和度
    float max_rgb = max(max(original.r, original.g), original.b);
    float min_rgb = min(min(original.r, original.g), original.b);
    float saturation = max_rgb - min_rgb;

    // 根据种子调整色相偏移
    float hue_shift = color_seed * 0.2;
    hue = mod(hue + hue_shift, 1.0);

    // 米菲兔七色定义
    vec3 miffy_red = vec3(0.92, 0.21 + color_seed * 0.2, 0.18);
    vec3 miffy_yellow = vec3(1.0, 0.85 - color_seed * 0.15, 0.0);
    vec3 miffy_blue = vec3(0.0, 0.47 + color_seed * 0.1, 0.85);
    vec3 miffy_green = vec3(0.0, 0.65 - color_seed * 0.1, 0.31);
    vec3 miffy_white = vec3(1.0);
    vec3 miffy_gray = vec3(0.5);
    vec3 miffy_black = vec3(0.0);

    // 核心：基于色相和亮度的多彩选择算法
    vec3 result;

    // 第一步：处理极端亮度
    if (brightness > 0.92) {
        result = miffy_white;
    }
    else if (brightness < 0.08) {
        result = miffy_black;
    }
    // 第二步：基于色相选择主色
    else {
        // 色相分区选择主色系
        vec3 base_color;

        // 红色系 (包括橙色、紫色)
        if (hue < 0.05 || hue > 0.9) {
            base_color = miffy_red;
        }
        // 黄色系
        else if (hue < 0.15) {
            base_color = miffy_yellow;
        }
        // 绿色系
        else if (hue < 0.4) {
            base_color = miffy_green;
        }
        // 蓝色系 (包括青色)
        else {
            base_color = miffy_blue;
        }

        // 第三步：根据亮度调整颜色明暗
        if (brightness > 0.75) {
            // 亮部：向白色/黄色混合
            float mix_val = (brightness - 0.75) / 0.17;

            // 比较颜色是否接近红色或黄色
            float red_dist = distance(base_color, miffy_red);
            float yellow_dist = distance(base_color, miffy_yellow);

            if (red_dist < 0.2 || yellow_dist < 0.2) {
                result = mix(base_color, miffy_yellow, mix_val * 0.7);
            } else {
                result = mix(base_color, miffy_white, mix_val * 0.5);
            }
        }
        else if (brightness > 0.4) {
            // 中间亮度：保持原色
            result = base_color;

            // 增加色彩变化
            if (color_variety > 1.0 && saturation > 0.3) {
                // 在主要色系内添加细微变化
                if (hue < 0.05 || hue > 0.9) { // 红色系
                    if (hue > 0.95) {
                        result = mix(miffy_red, vec3(0.8, 0.3, 0.5), 0.3);
                    }
                }
                else if (hue < 0.15) { // 黄色系
                    // 黄色保持纯净
                }
                else if (hue < 0.4) { // 绿色系
                    if (hue < 0.3) {
                        result = mix(miffy_green, vec3(0.3, 0.8, 0.4), 0.2);
                    }
                }
                else { // 蓝色系
                    if (hue < 0.6) {
                        result = mix(miffy_blue, vec3(0.2, 0.7, 0.9), 0.3);
                    }
                }
            }
        }
        else {
            // 暗部：向灰色/黑色混合
            float mix_val = 1.0 - (brightness / 0.4);

            if (brightness > 0.2) {
                result = mix(base_color, miffy_gray, mix_val * 0.7);
            } else {
                result = mix(base_color, miffy_black, mix_val);
            }
        }

        // 低饱和度强制变灰
        if (saturation < 0.15 && brightness > 0.1 && brightness < 0.9) {
            float gray_mix = 1.0 - (saturation / 0.15);
            result = mix(result, miffy_gray, gray_mix);
        }
    }

    // 应用强度
    COLOR = vec4(mix(original.rgb, result, style_strength), original.a);
}