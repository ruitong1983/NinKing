shader_type canvas_item;

// ----------------------------------------------------------------------
// 1. 颜色与整体风格参数
// ----------------------------------------------------------------------
uniform float color_variation : hint_range(0.0, 0.5) = 0.1;   // 颜色随机变化量
uniform float color_saturation : hint_range(0.0, 2.0) = 1.25; // 饱和度增强
uniform float color_brightness : hint_range(0.0, 2.0) = 1.1;  // 亮度增强

// ----------------------------------------------------------------------
// 2. 纸张与颗粒 (Paper Grain) 参数
// ----------------------------------------------------------------------
uniform float paper_grain : hint_range(0.0, 0.2) = 0.08;      // 纸张大颗粒强度
uniform float paper_roughness : hint_range(0.0, 0.5) = 0.2;   // 纸张微小粗糙度强度
uniform float paper_frequency_scale = 10.0;                    // 纹理整体缩放

// ----------------------------------------------------------------------
// 3. 边缘增强 (Outline) 参数
// ----------------------------------------------------------------------
uniform float edge_darken : hint_range(0.0, 0.5) = 0.2;
uniform float edge_threshold : hint_range(0.0, 0.3) = 0.04;
uniform float edge_noise_amount : hint_range(0.0, 5.0) = 1.0; 

// ----------------------------------------------------------------------
// 噪声函数 (保持不变)
// ----------------------------------------------------------------------

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p, int octaves, float persistence) {
    float value = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    float max_value = 0.0;
    
    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise(p * frequency);
        max_value += amplitude;
        amplitude *= persistence;
        frequency *= 2.0;
    }
    return value / max_value;
}

// ----------------------------------------------------------------------
// 核心函数: 生成纸张纹理
// ----------------------------------------------------------------------

float generate_paper_texture(vec2 uv) {
    // 低频大颗粒
    float grain = fbm(uv * 20.0 * paper_frequency_scale, 3, 0.5) * paper_grain;
    // 高频粗糙度
    float roughness = fbm(uv * 80.0 * paper_frequency_scale, 2, 0.7) * paper_roughness;
    
    // 1.0 - (...) 使噪声产生暗部
    float paper = 1.0 - (grain + roughness * 0.3);
    
    return clamp(paper, 0.8, 1.0); 
}

// ----------------------------------------------------------------------
// Fragment 主函数
// ----------------------------------------------------------------------

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    
    if (original_color.a < 0.01) {
        COLOR = original_color;
        // return;
    }
    
    float luminance = dot(original_color.rgb, vec3(0.299, 0.587, 0.114));
    
    // --- 1. 颜色处理 (彩铅颜色和不均匀性) ---
    vec3 processed_color = original_color.rgb * color_brightness;
    
    // 增强饱和度
    float gray = dot(processed_color, vec3(0.299, 0.587, 0.114));
    processed_color = mix(vec3(gray), processed_color, color_saturation);
    
    // 添加随机颜色变化 (模拟颜料不均匀)
    vec2 color_hash_uv = UV * 0.2; 
    processed_color.r *= 1.0 + (hash(color_hash_uv + 0.1) - 0.5) * color_variation;
    processed_color.g *= 1.0 + (hash(color_hash_uv + 0.2) - 0.5) * color_variation;
    processed_color.b *= 1.0 + (hash(color_hash_uv + 0.3) - 0.5) * color_variation;
    
    // --- 2. 边缘加深层 ---
    vec2 texel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
    
    // 边缘检测
    float left_lum = dot(texture(TEXTURE, UV - vec2(texel_size.x, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
    float right_lum = dot(texture(TEXTURE, UV + vec2(texel_size.x, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
    float top_lum = dot(texture(TEXTURE, UV - vec2(0.0, texel_size.y)).rgb, vec3(0.299, 0.587, 0.114));
    float bottom_lum = dot(texture(TEXTURE, UV + vec2(0.0, texel_size.y)).rgb, vec3(0.299, 0.587, 0.114));
    
    float edge = max(abs(left_lum - right_lum), abs(top_lum - bottom_lum));
    
    // 阈值处理并添加噪点抖动
    float edge_detected = step(edge_threshold, edge);
    edge_detected *= 1.0 - (hash(UV * 200.0) - 0.5) * edge_noise_amount * texel_size.x * 200.0;
    
    // 边缘效果：1.0 - (...) 使边缘处颜色变暗
    float edge_effect = 1.0 - clamp(edge_detected, 0.0, 1.0) * edge_darken; 
    
    // --- 3. 叠加效果 (乘法) ---
    
    // 步骤 A: 应用边缘 (使边缘变暗)
    vec3 final_color = processed_color * edge_effect;

    // 步骤 B: 应用纸张纹理 (使纸张纹理处变暗)
    float paper_value = generate_paper_texture(UV * paper_frequency_scale);
    final_color *= paper_value;
    
    // 步骤 C: 最终微小颗粒噪点
    float grain_noise = (noise(UV * 500.0) - 0.5) * 0.05; 
    // 将噪点叠加到颜色上，暗部噪点更明显
    final_color += vec3(grain_noise) * (1.0 - luminance); 

    // 最终输出
    final_color = clamp(final_color, 0.0, 1.0);
    
    COLOR = vec4(final_color, original_color.a);
}