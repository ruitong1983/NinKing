shader_type canvas_item;

// 可调参数 - 全部添加 hint_range 以便在 Inspector 中显示滑条
uniform float brightness : hint_range(0.0, 2.0) = 1.0 ;
uniform float progress : hint_range(0.0, 1.0) = 1.0  ;
uniform vec2 overlay_scale = vec2(1.0, 1.0);
uniform vec2 overlay_offset = vec2(0.0, 0.0);
uniform float overlay_power : hint_range(0.0, 1.0) = 0.5 ;
uniform float time_multiplier : hint_range(0.0, 100.0) = 30.0 ;
uniform float noise_intensity : hint_range(0.0, 0.001) = 0.00015 ;
uniform float edge_offset_strength : hint_range(0.0, 0.01) = 0.001 ;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.15 ;
uniform float color_quantize : hint_range(1.0, 10.0) = 3.0 ;
uniform float base_power : hint_range(1.0, 20.0) = 10.5 ;
uniform vec3 cream_tint = vec3(240.0, 225.0, 201.0);

// 随机函数 - 代替纹理噪声
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

// 插值噪声
float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    // 四个角的随机值
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // 平滑插值
    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// 分形噪声 - 更自然的纹理
float fractal_noise(vec2 uv, float frequency, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float max_value = 0.0;

    for (int i = 0; i < octaves; i++) {
        value += noise(uv * frequency) * amplitude;
        max_value += amplitude;
        frequency *= 2.0;
        amplitude *= 0.5;
    }

    return value / max_value;
}

// sRGB 解码函数
vec3 srgb_decode(vec3 e) {
    bvec3 cutoff = lessThan(e, vec3(0.04045));
    vec3 lower = e / 12.92;
    vec3 higher = pow((e + 0.055) / 1.055, vec3(2.4));
    return mix(higher, lower, cutoff);
}

void fragment() {
    vec2 uv = UV;

    // 时间相关的噪声
    float time_noise = noise_intensity * sin(TIME * time_multiplier);

    // 覆盖纹理 UV（使用程序噪声）
    vec2 overlay_uv = (uv - 0.5 + overlay_offset) / overlay_scale + 0.5 + (time_noise * 0.5);

    // 生成程序噪声代替纹理
    float overlay = fractal_noise(overlay_uv * 15.0, 2.0, 4);

    // 采样主纹理
    vec3 base_col = srgb_decode(texture(TEXTURE, uv).rgb);

    // 平均反转颜色
    vec3 inv_col = 1.0 - base_col;
    float inv_avg = (inv_col.r + inv_col.g + inv_col.b) / 3.0;

    // 应用噪声调整幂因子
    float pow_factor = base_power * mix(1.0, overlay * (2.0 / max(inv_avg, 0.001)), overlay_power);
    float overlay_masked = round(pow(inv_avg, pow_factor) * color_quantize) / color_quantize + 0.0025;

    // 边缘高光效果
    vec3 col_green = 1.0 - srgb_decode(texture(TEXTURE, uv + vec2(edge_offset_strength) + vec2(time_noise, 0.0)).rgb);
    vec3 col_purple = 1.0 - srgb_decode(texture(TEXTURE, uv - vec2(edge_offset_strength)).rgb);
    float green = round(pow(dot(col_green, vec3(1.0)) / 3.0, base_power));
    float purple = round(pow(dot(col_purple, vec3(1.0)) / 3.0, base_power));

    // 应用奶油色调
    vec3 col = vec3(overlay_masked, green, purple) * cream_tint;
    col = clamp(col, 0.0, 1.0);

    // 暗部遮罩保留
    float dark_mask = clamp(1.0 - floor(dot(base_col, vec3(1.0)) / 3.0 + 0.998), 0.0, 1.0);
    col = mix(vec3(overlay_masked), col * (1.0 - dark_mask), progress) * brightness + 0.005;

    // 渐晕效果
    vec2 v_uv = uv * (1.0 - uv.xy);
    col = col * pow(v_uv.x * v_uv.y * 15.0, vignette_strength);

    COLOR = vec4(col, 1.0);
}