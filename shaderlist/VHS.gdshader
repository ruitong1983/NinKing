shader_type canvas_item;

// --- 用户可调节参数 ---
uniform float intensity : hint_range(0.0, 1.0) = 1.0; // 效果总体强度
uniform float scanline_spacing : hint_range(50.0, 300.0) = 150.0; // 扫描线间距
uniform float scanline_thickness : hint_range(0.5, 3.0) = 1.5; // 扫描线粗细
uniform float color_offset_strength : hint_range(0.0, 5.0) = 1.0; // 色差强度
uniform float noise_amount : hint_range(0.0, 0.1) = 0.02; // 噪点强度
uniform float jitter_amount : hint_range(0.0, 2.0) = 0.5; // 画面抖动强度
uniform float y_static_strength : hint_range(0.0, 0.05) = 0.01; // 纵向静态条强度
uniform float vhs_tape_wear : hint_range(0.0, 0.3) = 0.1; // 模拟磁带走旧的亮度损失

// --- 随机数生成函数（用于噪声和抖动）---
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;

    // 1. 添加画面垂直抖动 (Jitter)
    float jitter = rand(vec2(TIME, uv.y * 0.1)) * jitter_amount;
    uv.x += jitter * 0.002;

    // 2. 创建颜色通道偏移 (Chromatic Aberration)
    float offset = color_offset_strength * 0.001 * intensity;
    float r = texture(TEXTURE, vec2(uv.x + offset, uv.y)).r;
    float g = texture(TEXTURE, uv).g;
    float b = texture(TEXTURE, vec2(uv.x - offset, uv.y)).b;

    vec3 color = vec3(r, g, b);

    // 3. 添加扫描线 (Scanlines)
    float scanline = sin(uv.y * scanline_spacing + TIME * 2.0);
    scanline = (scanline > 0.95) ? 1.0 - scanline_thickness * 0.1 : 1.0;
    color *= scanline;

    // 4. 添加随机噪声 (Noise)
    float noise = rand(uv + TIME * 0.1);
    color += (noise - 0.5) * noise_amount * intensity;

    // 5. 模拟磁带走旧的纵向静态条 (Y Static)
    float y_static = sin(uv.y * 800.0 + TIME * 10.0) * 0.5 + 0.5;
    y_static = pow(y_static, 10.0); // 使静态条更锐利
    color += y_static * y_static_strength * rand(vec2(uv.y, TIME));

    // 6. 应用整体亮度损失和对比度变化（模拟老化磁带）
    color *= (1.0 - vhs_tape_wear * 0.5);
    color = mix(vec3(0.5), color, 1.1 - vhs_tape_wear); // 简单对比度调整

    // 7. 根据总强度混合最终颜色与原图
    vec3 original_color = texture(TEXTURE, UV).rgb;
    color = mix(original_color, color, intensity);

    COLOR = vec4(color, 1.0);
}