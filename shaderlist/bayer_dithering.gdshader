shader_type canvas_item;

// 4x4 拜耳矩阵
const mat4 bayerIndex = mat4(
    vec4(00.0/16.0, 12.0/16.0, 03.0/16.0, 15.0/16.0),
    vec4(08.0/16.0, 04.0/16.0, 11.0/16.0, 07.0/16.0),
    vec4(02.0/16.0, 14.0/16.0, 01.0/16.0, 13.0/16.0),
    vec4(10.0/16.0, 06.0/16.0, 09.0/16.0, 05.0/16.0));

// 可调节参数
uniform float dither_strength : hint_range(0.0, 1.0) = 1.0; // 抖动强度
uniform bool use_gamma_correction = true; // 是否使用gamma校正
uniform float brightness : hint_range(-0.5, 0.5) = 0.0; // 亮度调整
uniform bool monochrome = true; // 是否输出单色
uniform float pattern_scale : hint_range(0.5, 4.0) = 1.0; // 抖动图案缩放

void fragment() {
    // 采样纹理
    vec4 col = texture(TEXTURE, UV);

    // Gamma校正（可选）
    if (use_gamma_correction) {
        col.rgb = pow(max(col.rgb, vec3(0.0)), vec3(2.2));
    }

    // 亮度调整
    col.rgb = clamp(col.rgb + brightness, 0.0, 1.0);

    // 转换为灰度（如果启用单色模式）
    vec3 finalColor = col.rgb;
    if (monochrome) {
        float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
        finalColor = vec3(gray);
    }

    // 应用图案缩放
    vec2 coord = FRAGCOORD.xy / pattern_scale;

    // 获取拜耳矩阵值
    int x = int(coord.x) & 3; // 相当于 % 4
    int y = int(coord.y) & 3; // 相当于 % 4
    float bayerValue = bayerIndex[x][y];

    // 应用抖动强度
    bayerValue = mix(0.5, bayerValue, dither_strength);

    // 应用抖动
    if (monochrome) {
        // 单色模式：只抖动亮度
        float dithered = step(bayerValue, finalColor.r);
        COLOR = vec4(vec3(dithered), col.a);
    } else {
        // 彩色模式：分别抖动RGB通道
        COLOR = vec4(
            step(bayerValue, finalColor.r),
            step(bayerValue, finalColor.g),
            step(bayerValue, finalColor.b),
            col.a
        );
    }
}