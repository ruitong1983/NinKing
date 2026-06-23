// 实际效果像加彩色雪花……
shader_type canvas_item;

// 控制颜色随机变化的程度
uniform float hue_strength : hint_range(0.0, 0.5) = 0.2;     // 色相变化强度
uniform float saturation_strength : hint_range(0.0, 10.0) = 0.2; // 饱和度变化强度
uniform float value_strength : hint_range(0.0, 0.5) = 0.2;     // 明度变化强度

// 伪随机函数，基于UV坐标生成固定的随机值
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

// RGB转HSV颜色空间
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV转RGB颜色空间
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    // 读取精灵的原始颜色
    vec4 original_color = texture(TEXTURE, UV);

    // 使用条件判断代替return，处理透明像素
    if (original_color.a >= 0.01) {
        // 将原始颜色转换为HSV
        vec3 hsv = rgb2hsv(original_color.rgb);

        // 基于UV坐标生成随机偏移值（每个像素的随机值固定）
        float random_hue = rand(UV * 100.0) * 2.0 - 1.0; // -1到1之间
        float random_sat = rand(UV * 100.0 + 123.45) * 2.0 - 1.0;
        float random_val = rand(UV * 100.0 + 678.90) * 2.0 - 1.0;

        // 应用随机变化
        hsv.x = fract(hsv.x + random_hue * hue_strength);
        hsv.y = clamp(hsv.y + random_sat * saturation_strength, 0.0, 1.0);
        hsv.z = clamp(hsv.z + random_val * value_strength, 0.0, 1.0);

        // 转换回RGB并输出
        vec3 modified_rgb = hsv2rgb(hsv);
        COLOR = vec4(modified_rgb, original_color.a);
    } else {
        // 透明像素直接使用原始颜色
        COLOR = original_color;
    }
}
