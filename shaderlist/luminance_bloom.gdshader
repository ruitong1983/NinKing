shader_type canvas_item;

uniform float threshold : hint_range(0.0, 1.0) = 0.7;
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.5;
uniform float glow_size : hint_range(0.0, 5.0) = 2.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.8, 0.3, 1.0); // 可自定义发光颜色
uniform float smoothness : hint_range(0.0, 0.3) = 0.1; // 平滑过渡参数

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    // 计算亮度（使用更准确的亮度公式）
    float brightness = dot(tex_color.rgb, vec3(0.2126, 0.7152, 0.0722));

    // 计算发光效果 - 使用亮度而不是单一通道
    vec2 pixel_size = TEXTURE_PIXEL_SIZE * glow_size;
    float glow = 0.0;

    // 3x3 高斯模糊采样
    for(int x = -1; x <= 1; x++) {
        for(int y = -1; y <= 1; y++) {
            vec2 sample_uv = UV + vec2(float(x), float(y)) * pixel_size;
            vec4 sample_color = texture(TEXTURE, sample_uv);
            float sample_brightness = dot(sample_color.rgb, vec3(0.2126, 0.7152, 0.0722));

            // 高斯权重
            float weight = 1.0;
            if (x != 0 && y != 0) weight = 0.7;  // 角落权重较低
            glow += sample_brightness * weight;
        }
    }
    glow /= 8.8; // 总权重归一化

    // 平滑过渡计算
    float glow_factor = smoothstep(threshold - smoothness, threshold + smoothness, brightness);

    // 颜色混合 - 发光叠加到原颜色上，而不是替换
    vec3 final_glow = glow_color.rgb * glow * glow_intensity;
    COLOR.rgb = tex_color.rgb + final_glow * glow_factor;
    COLOR.a = tex_color.a;
}