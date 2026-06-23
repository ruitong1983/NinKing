shader_type canvas_item;

// ========== 可调节参数 ==========
uniform float paint_blur : hint_range(0.0, 10.0) = 1.0; // 绘画模糊度
uniform int color_levels : hint_range(2, 20) = 10; // 颜色分级数
uniform float color_vividness : hint_range(0.5, 2.0) = 1.3; // 颜色鲜艳度
uniform float color_saturation : hint_range(0.5, 2.0) = 1.2; // 饱和度

// 绘画风格选择
uniform int paint_style : hint_range(1, 3) = 1; // 1:卡通 2:水彩 3:油画
uniform float style_intensity : hint_range(0.0, 1.0) = 0.7; // 风格强度

// ========== 基础函数 ==========
const vec3 LUMINANCE_WEIGHT = vec3(0.299, 0.587, 0.114);
const float GAUSS_WEIGHTS[25] = float[](
    0.015625, 0.03125, 0.046875, 0.03125, 0.015625,
    0.03125, 0.0625,  0.09375,  0.0625,  0.03125,
    0.046875, 0.09375, 0.140625, 0.09375, 0.046875,
    0.03125, 0.0625,  0.09375,  0.0625,  0.03125,
    0.015625, 0.03125, 0.046875, 0.03125, 0.015625
);

// RGB转HSV
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV转RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// 高斯模糊
vec4 apply_blur(sampler2D tex, vec2 uv, float intensity, vec2 pixel_size) {
    vec4 color = vec4(0.0);
    float total_weight = 0.0;
    float offset_x = intensity * pixel_size.x;
    float offset_y = intensity * pixel_size.y;
    
    int weight_idx = 0;
    for (float x = -2.0; x <= 2.0; x++) {
        for (float y = -2.0; y <= 2.0; y++) {
            float weight = GAUSS_WEIGHTS[weight_idx++];
            color += texture(tex, uv + vec2(x * offset_x, y * offset_y)) * weight;
            total_weight += weight;
        }
    }
    return color / total_weight;
}

// 色块化
vec3 apply_posterize(vec3 color, int levels) {
    float levels_float = float(levels);
    float step = 1.0 / (levels_float - 1.0);
    return floor(color / step + 0.5) * step;
}

// 增强颜色对比度
vec3 enhance_contrast(vec3 color, float amount) {
    vec3 hsv = rgb2hsv(color);
    hsv.z = (hsv.z - 0.5) * amount + 0.5;
    return hsv2rgb(hsv);
}

// 卡通风格（简单的色阶渲染）
vec3 apply_cartoon_style(vec3 color, float intensity) {
    float luminance = dot(color, LUMINANCE_WEIGHT);
    float steps = 4.0;
    luminance = floor(luminance * steps) / steps;
    return mix(color, color * luminance * 1.5, intensity);
}

// 水彩风格（颜色扩散）
vec3 apply_watercolor_style(vec3 color, sampler2D tex, vec2 uv, vec2 pixel_size, float intensity) {
    vec3 color1 = texture(tex, uv + vec2(pixel_size.x, 0.0)).rgb;
    vec3 color2 = texture(tex, uv + vec2(0.0, pixel_size.y)).rgb;
    vec3 color3 = texture(tex, uv + vec2(-pixel_size.x, 0.0)).rgb;
    vec3 color4 = texture(tex, uv + vec2(0.0, -pixel_size.y)).rgb;
    
    vec3 blended = (color + color1 + color2 + color3 + color4) / 5.0;
    return mix(color, blended, intensity * 0.5);
}

// 油画风格（颜色平滑）
vec3 apply_oilpaint_style(vec3 color, sampler2D tex, vec2 uv, vec2 pixel_size, float intensity) {
    vec3 avg_color = vec3(0.0);
    float samples = 0.0;
    
    for(float x = -1.0; x <= 1.0; x++) {
        for(float y = -1.0; y <= 1.0; y++) {
            avg_color += texture(tex, uv + vec2(x, y) * pixel_size).rgb;
            samples += 1.0;
        }
    }
    
    avg_color /= samples;
    return mix(color, avg_color, intensity);
}

// ========== 主函数 ==========
void fragment() {
    vec2 base_uv = UV;
    vec2 pixel_size = TEXTURE_PIXEL_SIZE;
    
    // 1. 应用绘画模糊
    vec4 blurred_color = apply_blur(TEXTURE, base_uv, paint_blur, pixel_size);
    
    // 2. 基础色块化
    vec3 painted_color = apply_posterize(blurred_color.rgb, color_levels);
    
    // 3. 应用选择的绘画风格
    if (paint_style == 1) {
        // 卡通风格
        painted_color = apply_cartoon_style(painted_color, style_intensity);
    } else if (paint_style == 2) {
        // 水彩风格
        painted_color = apply_watercolor_style(painted_color, TEXTURE, base_uv, pixel_size, style_intensity);
    } else if (paint_style == 3) {
        // 油画风格
        painted_color = apply_oilpaint_style(painted_color, TEXTURE, base_uv, pixel_size, style_intensity);
    }
    
    // 4. 颜色增强
    painted_color *= color_vividness;
    
    // 5. 饱和度调整
    float luminance = dot(painted_color, LUMINANCE_WEIGHT);
    painted_color = mix(vec3(luminance), painted_color, color_saturation);
    
    // 6. 对比度增强（可选）
    painted_color = enhance_contrast(painted_color, 1.2);
    
    // 输出最终颜色
    COLOR = vec4(painted_color, blurred_color.a);
}