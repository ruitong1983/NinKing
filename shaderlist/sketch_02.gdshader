shader_type canvas_item;

// 效果控制
uniform float pencil_strength : hint_range(0.0, 2.0) = 1.0;    // 铅笔线条强度
uniform float hatch_density : hint_range(0.0, 5.0) = 2.0;      // 交叉排线密度
uniform bool enable_hatching = true;                           // 是否启用交叉排线
uniform float detail_level : hint_range(0.5, 5.0) = 2.0;       // 细节级别

// 简单的噪点函数（替代纸张纹理）
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// 程序化纸张纹理（替代采样的paper_texture）
float procedural_paper(vec2 uv) {
    // 多层噪点模拟纸张纹理
    float paper = 0.0;
    paper += hash(uv * 3.0) * 0.3;
    paper += hash(uv * 10.0) * 0.2;
    paper += hash(uv * 30.0) * 0.1;
    // 归一化并增加基础亮度
    return (paper * 0.5 + 0.7);
}

// 交叉排线函数
float hatching(vec2 uv, float brightness) {
    if (!enable_hatching) return 1.0;

    float hatch = 0.0;

    // 创建不同角度的排线
    float angle1 = 45.0 * 3.14159 / 180.0;
    float angle2 = 135.0 * 3.14159 / 180.0;

    vec2 dir1 = vec2(cos(angle1), sin(angle1));
    vec2 dir2 = vec2(cos(angle2), sin(angle2));

    // 根据亮度控制排线密度
    float freq = hatch_density * 20.0;

    float line1 = sin((uv.x * dir1.x + uv.y * dir1.y) * freq);
    float line2 = sin((uv.x * dir2.x + uv.y * dir2.y) * freq);

    // 将正弦波转换为线条
    line1 = smoothstep(0.0, 0.1, abs(line1));
    line2 = smoothstep(0.0, 0.1, abs(line2));

    // 根据阴影区域添加排线
    float dark_areas = 1.0 - brightness;
    hatch = max(line1, line2) * dark_areas * 0.7;

    return 1.0 - hatch;
}

void fragment() {
    // 获取原始颜色
    vec4 color = texture(TEXTURE, UV); // 保留主纹理采样（画布基础颜色）

    // 计算亮度
    float brightness = dot(color.rgb, vec3(0.299, 0.587, 0.114));

    // 边缘检测（简化版）
    vec2 texel = vec2(1.0) / TEXTURE_PIXEL_SIZE.xy * 0.5 * detail_level;

    float left = dot(texture(TEXTURE, UV + vec2(-texel.x, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
    float right = dot(texture(TEXTURE, UV + vec2(texel.x, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
    float top = dot(texture(TEXTURE, UV + vec2(0.0, -texel.y)).rgb, vec3(0.299, 0.587, 0.114));
    float bottom = dot(texture(TEXTURE, UV + vec2(0.0, texel.y)).rgb, vec3(0.299, 0.587, 0.114));

    float edge = abs(left - right) + abs(top - bottom);
    edge = smoothstep(0.1, 0.3, edge);

    // 铅笔笔触效果
    vec2 pencil_uv = UV * 10.0;
    float pencil_noise = hash(pencil_uv) * 0.3;

    // 模拟铅笔纹理
    float pencil_grain = sin(pencil_uv.x * 50.0) * sin(pencil_uv.y * 50.0) * 0.1;

    // 亮度转换为素描阴影
    float shading = 1.0 - brightness;
    shading = pow(shading, 1.5); // 增加对比度

    // 应用铅笔强度
    shading *= pencil_strength;

    // 添加铅笔纹理
    shading += pencil_noise + pencil_grain;

    // 应用交叉排线
    float hatch_factor = hatching(UV * 5.0, brightness);

    // 组合所有效果
    float final_shading = shading * hatch_factor;

    // 强化边缘
    final_shading = mix(final_shading, 1.0, edge * 0.5);

    // 程序化纸张纹理（替代采样的paper_texture）
    float paper = procedural_paper(UV);

    // 最终颜色（素描是单色的）
    float final_value = 1.0 - clamp(final_shading, 0.0, 1.0);
    final_value = mix(final_value, 0.9, 0.1); // 保持一定的亮度

    // 应用程序化纸张纹理
    final_value *= paper;

    COLOR = vec4(vec3(final_value), color.a);
}