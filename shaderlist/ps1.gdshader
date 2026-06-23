shader_type canvas_item;

// 改为Sprite自身的低分辨率（而非屏幕）
uniform int resolution_x : hint_range(80, 640, 10) = 320;
uniform int resolution_y : hint_range(60, 480, 10) = 240;
uniform int color_bit_depth : hint_range(1, 8, 1) = 4;
uniform float dither_strength : hint_range(0.0, 0.1, 0.001) = 0.03;

// 抖动参数（适配Sprite局部空间，幅度缩小）
uniform float jitter_amount : hint_range(0.0, 0.05, 0.001) = 0.004;
uniform float jitter_speed : hint_range(0.1, 5.0, 0.1) = 1.2;
uniform float jitter_frequency : hint_range(50.0, 500.0, 10.0) = 180.0;

// 色差&渐晕（适配Sprite局部）
uniform float chromatic_aberration_strength : hint_range(0.0, 0.1) = 0.015;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.8;
uniform float vignette_radius : hint_range(0.0, 2.0) = 0.9;

// 保留随机数函数
float hash(vec2 p){
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// 调整抖动函数：基于Sprite局部UV
vec2 psx_jitter(vec2 uv){
    float t = floor(TIME * jitter_speed * 8.0) / 8.0;
    
    float h_shake = hash(vec2(floor(uv.y * jitter_frequency), t)) - 0.5;
    h_shake *= jitter_amount * 0.75;
    
    float v_shake = hash(vec2(floor(uv.x * jitter_frequency * 0.4), t)) - 0.5;
    v_shake *= jitter_amount * 0.35;
    
    float micro = hash(uv * 600.0 + t) - 0.5;
    micro *= jitter_amount * 0.1;
    
    return uv + vec2(h_shake + micro, v_shake + micro);
}

void fragment(){
    // 1. 基于Sprite自身尺寸做像素化（替换原屏幕分辨率逻辑）
    vec2 px = vec2(1.0 / float(resolution_x), 1.0 / float(resolution_y));
    // 用Sprite的UV（而非SCREEN_UV）做像素化
    vec2 uv = floor(UV / px) * px + px * 0.5;
    
    // 2. 应用抖动（基于Sprite局部UV）
    uv = psx_jitter(uv);
    // 限制UV范围，避免采样越界变黑
    uv = clamp(uv, vec2(0.0), vec2(1.0));
    
    // 3. 色差：采样Sprite自身的TEXTURE（而非SCREEN_TEXTURE）
    vec3 col;
    if(chromatic_aberration_strength > 0.001){
        vec2 offset = (uv - 0.5) * chromatic_aberration_strength;
        col.r = texture(TEXTURE, clamp(uv + offset, 0.0, 1.0)).r;
        col.g = texture(TEXTURE, uv).g;
        col.b = texture(TEXTURE, clamp(uv - offset, 0.0, 1.0)).b;
    }else{
        col = texture(TEXTURE, uv).rgb;
    }
    
    // 4. 色彩位深压缩（不变）
    float levels = pow(2.0, float(color_bit_depth));
    col = floor(col * levels) / levels;
    
    // 5. 渐晕：基于Sprite局部UV（而非SCREEN_UV）
    if(vignette_strength > 0.0){
        float dist = distance(UV, vec2(0.5)); // 改用UV而非SCREEN_UV
        float vignette = 1.0 - vignette_strength * smoothstep(vignette_radius * 0.5, vignette_radius, dist);
        col *= vignette;
    }
    
    // 6. Dither抖动（不变，改用UV）
    if(dither_strength > 0.0){
        float noise = hash(UV * 80.0 + floor(TIME * 50.0)); // 改用UV
        col += (noise - 0.5) * dither_strength;
    }
    
    // 7. 输出颜色（保留Alpha通道，适配Sprite透明）
    COLOR = vec4(col, texture(TEXTURE, UV).a);
} 