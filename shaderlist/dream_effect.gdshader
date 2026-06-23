shader_type canvas_item;

// 定義一個紋理uniform來接收噪聲紋理
uniform sampler2D noise_texture : source_color, repeat_disable, filter_linear_mipmap;
// 控制參數
uniform float time_scale : hint_range(0.0, 1.0) = 1.0; // 現在會正確使用了
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.05;
uniform float noise_speed : hint_range(0.0, 1.0) = 1.0;
uniform float bloom_amount : hint_range(0.0, 1.0) = 0.0;

// 簡單高斯模糊函數（3x3核心）
vec3 gaussian_blur(sampler2D tex, vec2 uv, vec2 resolution, float intensity) {
    vec3 color = vec3(0.0);
    float total = 0.0;
    
    // 簡化的3x3高斯核
    for(int x = -1; x <= 1; x++) {
        for(int y = -1; y <= 1; y++) {
            vec2 offset = vec2(float(x), float(y)) * intensity / resolution;
            // 高斯權重
            float weight = exp(-(float(x*x) + float(y*y)) / 2.0);
            color += texture(tex, uv + offset).rgb * weight;
            total += weight;
        }
    }
    return color / total;
}

void fragment() {
    vec2 uv = UV;
    
    // 獲取屏幕分辨率
    vec2 resolution = 1.0 / TEXTURE_PIXEL_SIZE;
    
    // 先對主紋理進行輕微模糊（用於光暈效果）
    vec3 base_color;
    if (bloom_amount > 0.0) {
        base_color = gaussian_blur(TEXTURE, uv, resolution, bloom_amount);
    } else {
        base_color = texture(TEXTURE, uv).rgb;
    }
    
    // 動態噪聲採樣 - 現在使用time_scale參數
    float noise_time = TIME * time_scale * noise_speed * 0.5;
    
    // 方法1：旋轉噪聲UV（類似原代碼）
    vec2 noise_uv = uv + 0.5 * vec2(cos(noise_time), sin(noise_time));
    
    // 方法2：滾動噪聲（可選）
    // vec2 noise_uv = uv * 2.0 + vec2(cos(noise_time * 0.3), sin(noise_time * 0.3)) * 0.1;
    // noise_uv = fract(noise_uv);
    
    // 採樣噪聲紋理
    vec3 blue_noise = texture(noise_texture, noise_uv).rgb;
    
    // 創建偏移向量（從[0,1]映射到[-0.5, 1.5]）
    vec3 offset = 2.0 * blue_noise - vec3(0.5, 0.5, 0.5);
    
    // 計算亮度以調整扭曲強度
    float luminance = dot(base_color, vec3(0.299, 0.587, 0.114));
    float dynamic_strength = distortion_strength * (1.0 + luminance * 0.5);
    
    // 應用偏移扭曲
    vec2 distorted_uv = uv + offset.xy * dynamic_strength;
    
    // 採樣扭曲後的顏色
    vec3 distorted_color = texture(TEXTURE, distorted_uv).rgb;
    
    // 可選：添加色差效果
    float chromatic_aberration = dynamic_strength * 0.3;
    vec3 chromatic_color;
    chromatic_color.r = texture(TEXTURE, distorted_uv + vec2(chromatic_aberration, 0.0)).r;
    chromatic_color.g = texture(TEXTURE, distorted_uv).g;
    chromatic_color.b = texture(TEXTURE, distorted_uv - vec2(chromatic_aberration, 0.0)).b;
    
    // 混合原始和扭曲的顏色
    float blend_factor = 0.7;
    vec3 final_color = mix(base_color, distorted_color, blend_factor);
    
    // 可選：混合色差效果
    final_color = mix(final_color, chromatic_color, 0.3);
    
    // 輸出最終顏色
    COLOR = vec4(final_color, 1.0);
}