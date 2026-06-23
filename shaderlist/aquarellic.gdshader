shader_type canvas_item;

// 核心可调参数（保持直观性，新增缩放参数适配不同分辨率）
uniform float watercolor_strength : hint_range(0.0, 5.0) = 0.6;    // 水彩扩散强度
uniform float pencil_effect : hint_range(0.0, 10.0) = 0.2;         // 铅笔线条强度
uniform float paper_strength : hint_range(0.0, 5.0) = 0.15;       // 纸张纹理强度
uniform float edge_scale : hint_range(0.0, 5.0) = 1.0;            // 边缘检测缩放（适配不同素材）
uniform float wet_edge_strength : hint_range(0.0, 1.0) = 0.15;    // 湿边提亮强度
uniform vec3 paper_tint = vec3(1.0, 0.98, 0.95);     // 纸张底色（默认暖白，贴近真实水彩纸）

// 辅助函数: 伪随机数生成（基础噪点）
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// 辅助函数: 值噪点（平滑颗粒感）
float noise_value(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f); // 平滑插值
    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// 优化版分形噪点（增加层数+各向异性，模拟真实纸张纹理）
float fbm(vec2 p) {
    float f = 0.0;
    float amp = 0.5;          // 振幅衰减
    vec2 shift = vec2(100.0); // 偏移避免重复
    for (int i = 0; i < 5; i++) { // 增加到5层，提升纹理层次
        f += amp * noise_value(p + shift);
        p = p * 2.0 * vec2(1.2, 0.8); // 各向异性缩放（模拟纸张纹理方向）
        amp *= 0.5;
        shift += vec2(11.1, 17.3); // 随机偏移
    }
    return f / (0.5 + 0.25 + 0.125 + 0.0625 + 0.03125); // 归一化
}

// 辅助函数: 计算色相差（用于色彩渗色）
float hue(vec3 col) {
    float maxc = max(max(col.r, col.g), col.b);
    float minc = min(min(col.r, col.g), col.b);
    float h = 0.0;
    if (abs(maxc-minc)<0.001) h = 0.0;
    else if (abs(maxc-col.r)<0.001) h = (col.g - col.b) / (maxc - minc);
    else if (abs(maxc-col.g)<0.001) h = 2.0 + (col.b - col.r) / (maxc - minc);
    else h = 4.0 + (col.r - col.g) / (maxc - minc);
    h = fract(h / 6.0);
    return h;
}

void fragment() {
    vec2 uv = UV;
    vec3 original_color = texture(TEXTURE, uv).rgb;
    vec3 color = original_color;
    float alpha = texture(TEXTURE, uv).a; // 保留原始透明度
    float lum = dot(color, vec3(0.2126, 0.7152, 0.0722)); // 亮度
    
    // ===================== 1. 分辨率适配的水彩扩散（核心优化）=====================
    // 用TEXTURE_PIXEL_SIZE替代固定偏移，适配任意分辨率
    vec2 offset_base = TEXTURE_PIXEL_SIZE * edge_scale * 2.0;
    vec3 blur = vec3(0.0);
    float total_weight = 0.0;
    
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            if (x == 0 && y == 0) continue;
            
            vec2 sample_uv = uv + vec2(float(x), float(y)) * offset_base;
            vec3 sample_color = texture(TEXTURE, sample_uv).rgb;
            float sample_lum = dot(sample_color, vec3(0.2126, 0.7152, 0.0722));
            
            // 亮度差权重（基础扩散）
            float lum_diff = abs(lum - sample_lum);
            float weight = exp(-lum_diff * 30.0); 
            
            // 色彩渗色权重（新增：色相/饱和度越接近，渗色越强）
            float hue_diff = abs(hue(color) - hue(sample_color));
            float sat = length(color - vec3(lum));
            float sample_sat = length(sample_color - vec3(sample_lum));
            float sat_diff = abs(sat - sample_sat);
            float color_weight = exp(-(hue_diff * 2.0 + sat_diff * 1.5));
            
            weight *= color_weight; // 融合亮度+色彩权重
            blur += sample_color * weight;
            total_weight += weight;
        }
    }
    
    blur = total_weight > 0.0 ? blur / total_weight : color;
    color = mix(color, blur, pow(watercolor_strength, 1.5)); // 强度非线性调节
    lum = dot(color, vec3(0.2126, 0.7152, 0.0722)); // 更新亮度

    // ===================== 2. 优化边缘检测（减少噪点）=====================
    vec2 edge_offset = TEXTURE_PIXEL_SIZE * edge_scale;
    // 先轻度模糊再差分，减少高频噪点
    float edge_h = dot(textureLod(TEXTURE, uv + edge_offset, 0.5).rgb - textureLod(TEXTURE, uv - edge_offset, 0.5).rgb, vec3(0.333));
    float edge_v = dot(textureLod(TEXTURE, uv + edge_offset.yx, 0.5).rgb - textureLod(TEXTURE, uv - edge_offset.yx, 0.5).rgb, vec3(0.333));
    float edge = sqrt(edge_h * edge_h + edge_v * edge_v);

    // ===================== 3. 铅笔线条（柔和贴合底色）=====================
    float pencil_line = clamp(edge * 4.0 - 0.3, 0.0, 1.0) * pencil_effect;
    // 线条颜色：基于原图暗调，而非纯黑（更融入画面）
    vec3 line_color = original_color * 0.2; 
    // 仅在暗部显示线条，避免亮部线条突兀
    float line_visibility = smoothstep(0.1, 0.6, 1.0 - lum); 
    color = mix(color, line_color, pencil_line * line_visibility * 0.3);

    // ===================== 4. 自然湿边效果（渐变提亮）=====================
    vec2 wet_edge_offset = TEXTURE_PIXEL_SIZE * edge_scale * 5.0;
    float wet_edge_base = 0.0;
    wet_edge_base += sqrt(abs(dot(texture(TEXTURE, uv + wet_edge_offset).rgb - texture(TEXTURE, uv - wet_edge_offset).rgb, vec3(0.333))));
    wet_edge_base += sqrt(abs(dot(texture(TEXTURE, uv + wet_edge_offset.yx).rgb - texture(TEXTURE, uv - wet_edge_offset.yx).rgb, vec3(0.333))));
    wet_edge_base /= 2.0;
    
    float wet_effect = wet_edge_base * 4.0 * watercolor_strength;
    // 渐变蒙版：仅边缘区域提亮，过渡更自然
    float edge_mask = smoothstep(0.1, 0.4, wet_effect) * smoothstep(0.6, 0.4, wet_effect);
    color = mix(color, vec3(1.0), edge_mask * wet_edge_strength);

    // ===================== 5. 层次化纸张纹理（暖调+各向异性）=====================
    float grain_noise = fbm(uv * 1024.0); // 高频纸张颗粒
    // 基于饱和度动态混合：高饱和区域减少纸张纹理，避免冲淡色彩
    float sat = length(color - vec3(lum));
    float paper_mix_weight = (1.0 - smoothstep(0.2, 0.6, sat)) * paper_strength * 0.5;
    color = mix(color, paper_tint, grain_noise * paper_mix_weight);

    // ===================== 6. 动态颜色融合（保留高饱和/亮部细节）=====================
    // 高亮度/高饱和区域保留更多原图色彩
    float mix_weight = smoothstep(0.3, 0.8, lum) * smoothstep(0.2, 0.6, sat) * 0.2;
    color = mix(color, original_color, mix_weight);
    // 低饱和区域适度提亮，增加通透感
    float white_mix_weight = (1.0 - sat) * 0.1 * watercolor_strength;
    color = mix(color, vec3(1.0), white_mix_weight);

    // ===================== 7. 自然晕影（保留）=====================
    vec2 center = uv * 2.0 - 1.0;
    float vignette = 1.0 - dot(center, center) * 0.15;
    color *= vignette;

    // 最终输出（保留原始透明度）
    COLOR = vec4(color, alpha);
}