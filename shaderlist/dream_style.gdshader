shader_type canvas_item;
render_mode blend_premul_alpha;

// 梦境效果参数 - 所有参数只定义一次
uniform float intensity : hint_range(0.0, 2.0) = 1.0;               // 整体效果强度
uniform float dreaminess : hint_range(0.0, 1.0) = 0.8;              // 梦境感强度
uniform float wave_speed : hint_range(0.0, 3.0) = 1.0;              // 波浪动画速度
uniform float wave_strength : hint_range(0.0, 0.05) = 0.015;        // 波浪扭曲强度
uniform float color_shift : hint_range(0.0, 0.05) = 0.02;           // 颜色偏移/色差（现在会使用）
uniform float blur_amount : hint_range(0.0, 0.03) = 0.008;          // 模糊强度
uniform float bloom_strength : hint_range(0.0, 1.0) = 0.4;          // 辉光强度
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;       // 暗角强度
uniform float saturation : hint_range(0.0, 2.0) = 1.3;              // 饱和度
uniform float brightness : hint_range(0.5, 2.0) = 1.2;              // 亮度
uniform float contrast : hint_range(0.5, 2.0) = 1.1;                // 对比度
uniform float chromatic_aberration : hint_range(0.0, 0.1) = 0.03;   // 色度偏移强度
uniform float film_grain : hint_range(0.0, 0.1) = 0.02;             // 胶片颗粒感
uniform float distortion_speed : hint_range(0.0, 3.0) = 1.0;        // 程序化扭曲速度
uniform float color_pulse_speed : hint_range(0.0, 2.0) = 0.5;       // 颜色脉动速度
uniform float color_pulse_amount : hint_range(0.0, 0.3) = 0.1;      // 颜色脉动强度
uniform float color_bleed : hint_range(0.0, 0.5) = 0.1;             // 颜色溢出效果

// 颜色控制
uniform vec3 primary_tint : source_color = vec3(0.6, 0.7, 1.0);     // 主色调（默认淡蓝）
uniform vec3 secondary_tint : source_color = vec3(1.0, 0.8, 0.9);   // 次色调（默认淡粉）
uniform vec3 highlight_color : source_color = vec3(1.0, 1.0, 0.9);  // 高光色调（默认淡黄）

// 改进的伪随机函数
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 返回二维向量的随机函数
vec2 random2(vec2 p) {
    return fract(sin(vec2(
        dot(p, vec2(127.1, 311.7)),
        dot(p, vec2(269.5, 183.3))
    )) * 43758.5453);
}

// 改进的噪声函数
float noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u * u * (3.0 - 2.0 * u);
    
    float a = random(ip);
    float b = random(ip + vec2(1.0, 0.0));
    float c = random(ip + vec2(0.0, 1.0));
    float d = random(ip + vec2(1.0, 1.0));
    
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// 分形布朗运动（用于生成复杂噪声）
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    // 减少迭代次数以提升性能
    for (int i = 0; i < 3; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

// 细胞噪声（用于生成有机图案）
float cellular_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float min_dist = 1.0;
    
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = random2(i + neighbor);  // 使用 random2 函数
            point = 0.5 + 0.5 * sin(TIME * 0.5 + 6.2831 * point);
            vec2 diff = neighbor + point - f;
            float dist = length(diff);
            min_dist = min(min_dist, dist);
        }
    }
    
    return min_dist;
}

// 生成程序化覆盖图案
vec3 generate_overlay(vec2 uv, float time) {
    vec3 overlay = vec3(0.0);
    
    // 生成多种程序化图案
    float pattern1 = sin(uv.x * 30.0 + time * 0.5) * 
                     cos(uv.y * 25.0 + time * 0.3) * 0.1;
    
    float pattern2 = cellular_noise(uv * 5.0 + vec2(time * 0.2, 0.0)) * 0.15;
    
    float pattern3 = fbm(uv * 3.0 + vec2(0.0, time * 0.1)) * 0.2;
    
    // 组合图案
    overlay.r = pattern1 * 0.3 + pattern2 * 0.4;
    overlay.g = pattern2 * 0.5 + pattern3 * 0.3;
    overlay.b = pattern1 * 0.4 + pattern3 * 0.6;
    
    // 使图案更柔和
    overlay = smoothstep(0.0, 0.5, overlay);
    
    return overlay;
}

// 程序化扭曲噪声 - 修复参数名冲突
vec2 generate_distortion(vec2 uv, float time, float distort_intensity) {
    vec2 distortion = vec2(0.0);
    
    // 多层次扭曲
    distortion.x += sin(uv.y * 8.0 + time * 1.2) * 0.01 * distort_intensity;
    distortion.y += cos(uv.x * 6.0 + time * 0.9) * 0.01 * distort_intensity;
    
    distortion.x += fbm(uv * 4.0 + vec2(time * 0.3, 0.0)) * 0.02 * distort_intensity;
    distortion.y += fbm(uv * 4.0 + vec2(0.0, time * 0.4)) * 0.02 * distort_intensity;
    
    // 添加一些随机性
    distortion += (vec2(random(uv + time * 0.1), random(uv + time * 0.1 + 0.5)) - 0.5) * 0.005 * distort_intensity;
    
    return distortion;
}

// 径向模糊（性能优化版）
vec4 radial_blur(sampler2D tex, vec2 uv, vec2 center, float strength, int samples) {
    vec4 color = vec4(0.0);
    vec2 dir = uv - center;
    float dist = length(dir);
    
    // 根据距离调整模糊强度
    float blur_factor = strength * (0.8 + 0.2 * sin(TIME * 0.5)) * pow(dist, 1.2);
    
    for (int i = 0; i < samples; i++) {
        float t = float(i) / float(samples);
        vec2 sample_uv = uv - dir * t * blur_factor;
        sample_uv = clamp(sample_uv, 0.001, 0.999);
        color += texture(tex, sample_uv);
    }
    
    return color / float(samples);
}

// 高斯模糊采样
vec4 gaussian_blur(sampler2D tex, vec2 uv, vec2 direction, float amount) {
    vec4 color = vec4(0.0);
    float weights[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
    
    color = texture(tex, uv) * weights[0];
    
    for (int i = 1; i < 5; i++) {
        vec2 offset = direction * amount * float(i);
        color += texture(tex, uv + offset) * weights[i];
        color += texture(tex, uv - offset) * weights[i];
    }
    
    return color;
}

// 色度偏移 - 增强版，使用 color_shift 参数
vec4 chromatic_aberration_effect(sampler2D tex, vec2 uv, float amount, float shift_strength) {
    // 结合 chromatic_aberration 和 color_shift 参数
    float total_shift = amount + shift_strength * 0.5;
    
    // RGB通道的不同偏移量，创造更丰富的色差效果
    float r_shift = texture(tex, uv + vec2(total_shift * 0.7, total_shift * 0.2)).r;
    float g_shift = texture(tex, uv + vec2(-total_shift * 0.3, total_shift * 0.4)).g;
    float b_shift = texture(tex, uv - vec2(total_shift * 0.5, total_shift * 0.3)).b;
    float a = texture(tex, uv).a;
    
    return vec4(r_shift, g_shift, b_shift, a);
}

// 添加额外的颜色偏移效果
vec4 additional_color_shift(sampler2D tex, vec2 uv, float shift_amount, float time) {
    // 动态颜色偏移，随时间变化
    float dynamic_shift = shift_amount * (0.8 + 0.2 * sin(time * 2.0));
    
    // 不同方向的颜色偏移
    vec4 color_r = texture(tex, uv + vec2(dynamic_shift * 0.8, -dynamic_shift * 0.3));
    vec4 color_g = texture(tex, uv + vec2(-dynamic_shift * 0.4, dynamic_shift * 0.6));
    vec4 color_b = texture(tex, uv + vec2(dynamic_shift * 0.2, -dynamic_shift * 0.7));
    
    return vec4(color_r.r, color_g.g, color_b.b, color_g.a);
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * wave_speed;
    vec2 center = vec2(0.5, 0.5);
    
    // === 生成程序化扭曲 ===
    vec2 distortion = generate_distortion(uv, time * distortion_speed, dreaminess);
    vec2 distorted_uv = uv + distortion;
    
    // 添加波浪扭曲
    distorted_uv.x += sin(uv.y * 12.0 + time * 1.8) * wave_strength * dreaminess;
    distorted_uv.y += cos(uv.x * 10.0 + time * 1.5) * wave_strength * 0.8 * dreaminess;
    
    // 确保UV在有效范围内
    distorted_uv = clamp(distorted_uv, 0.001, 0.999);
    
    // === 获取基础颜色 ===
    vec4 base_color = texture(TEXTURE, distorted_uv);
    
    // === 应用颜色偏移效果（使用 color_shift 参数） ===
    vec4 color_shifted = additional_color_shift(TEXTURE, distorted_uv, color_shift, time);
    
    // === 色度偏移 ===
    vec4 color_rgb = chromatic_aberration_effect(
        TEXTURE, 
        distorted_uv, 
        chromatic_aberration * dreaminess,
        color_shift
    );
    
    // 混合颜色偏移和色差效果
    color_rgb = mix(color_rgb, color_shifted, 0.5 * dreaminess);
    
    // === 应用径向模糊 ===
    vec4 blurred_color = radial_blur(
        TEXTURE, 
        distorted_uv, 
        center, 
        blur_amount * dreaminess, 
        6
    );
    
    // === 应用高斯模糊 ===
    vec4 gaussian_color = gaussian_blur(
        TEXTURE,
        distorted_uv,
        vec2(1.0, 0.0),
        blur_amount * 0.7
    );
    
    // === 混合模糊效果 ===
    vec4 final_blur = mix(base_color, blurred_color, dreaminess * 0.6);
    final_blur = mix(final_blur, gaussian_color, dreaminess * 0.4);
    
    // === 颜色处理 ===
    vec4 color = mix(color_rgb, final_blur, 0.7);
    
    // 增加亮度
    color.rgb *= brightness;
    
    // 增加对比度
    color.rgb = (color.rgb - 0.5) * contrast + 0.5;
    
    // 调整饱和度
    float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(vec3(luminance), color.rgb, saturation);
    
    // === 应用颜色色调 ===
    // 主色调
    vec3 tinted_color = mix(color.rgb, color.rgb * primary_tint, 0.5 * intensity);
    
    // 添加颜色脉动效果
    float pulse = 1.0 + sin(time * color_pulse_speed) * color_pulse_amount;
    tinted_color *= pulse;
    
    // 添加二级色调（在边缘）
    float edge_factor = distance(uv, center);
    tinted_color = mix(
        tinted_color,
        tinted_color * secondary_tint,
        edge_factor * 0.6 * intensity
    );
    
    // 高光色调
    float highlight_mask = smoothstep(0.6, 1.0, luminance);
    tinted_color = mix(
        tinted_color,
        tinted_color * highlight_color,
        highlight_mask * 0.4 * intensity
    );
    
    // === 添加辉光效果 ===
    float glow = smoothstep(0.5, 1.0, luminance);
    vec3 bloom_color = tinted_color * glow * bloom_strength * (1.0 + sin(time * 0.7) * 0.3);
    tinted_color = mix(tinted_color, bloom_color, bloom_strength * 0.8);
    
    // 颜色溢出效果
    if (color_bleed > 0.0) {
        vec2 bleed_uv = uv + vec2(
            sin(uv.y * 20.0 + time * 1.2) * color_bleed * 0.01,
            cos(uv.x * 18.0 + time * 1.5) * color_bleed * 0.01
        );
        vec4 bleed_color = texture(TEXTURE, clamp(bleed_uv, 0.001, 0.999));
        tinted_color = mix(tinted_color, bleed_color.rgb, color_bleed * 0.2);
    }
    
    // === 添加程序化覆盖图案 ===
    vec3 overlay_color = generate_overlay(uv * 2.0 + vec2(time * 0.1, 0.0), time);
    tinted_color = mix(tinted_color, tinted_color * (1.0 + overlay_color * 0.2), 0.15 * dreaminess);
    
    // === 添加胶片颗粒 ===
    if (film_grain > 0.0) {
        float grain = random(uv * 50.0 + time * 5.0) * 2.0 - 1.0;
        grain *= film_grain * (1.0 - luminance * 0.3);
        tinted_color += grain;
    }
    
    // === 暗角效果 ===
    float vignette = 1.0 - distance(uv, center) * vignette_strength;
    vignette = smoothstep(0.2, 1.0, vignette);
    vignette = mix(1.0, vignette, vignette_strength);
    tinted_color *= vignette;
    
    // === 最终输出 ===
    // 保持原始透明度
    float alpha = base_color.a;
    
    // 根据强度混合最终颜色和原始颜色
    vec3 final_color = mix(base_color.rgb, tinted_color, intensity);
    
    // 确保颜色在有效范围内
    final_color = clamp(final_color, 0.0, 1.0);
    
    COLOR = vec4(final_color, alpha);
}