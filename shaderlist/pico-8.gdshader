shader_type canvas_item;

// 参数
uniform float gamma : hint_range(0.0,3.0) = 1.0;
uniform float pixel_size : hint_range(0.0,5.0) = 0.0; // 像素化效果
uniform bool retro_crt = false; // CRT 扫描线效果
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.1;

// PICO-8 调色板数组
const vec3[16] palette = vec3[16](
    vec3(0.0, 0.0, 0.0),                // 0: 黑色
    vec3(0.1137, 0.1686, 0.3255),      // 1: 深蓝
    vec3(0.4941, 0.1451, 0.3255),      // 2: 紫红
    vec3(0.0, 0.5294, 0.3176),         // 3: 深绿
    vec3(0.6706, 0.3216, 0.2118),      // 4: 棕色
    vec3(0.3725, 0.3412, 0.3098),      // 5: 灰色
    vec3(0.7608, 0.7647, 0.7804),      // 6: 浅灰
    vec3(1.0, 0.9451, 0.9098),         // 7: 米白
    vec3(1.0, 0.0, 0.3020),            // 8: 红色
    vec3(1.0, 0.6392, 0.0),            // 9: 橙色
    vec3(1.0, 0.9255, 0.1529),         // A: 黄色
    vec3(0.0, 0.8941, 0.2118),         // B: 绿色
    vec3(0.1608, 0.6784, 1.0),         // C: 蓝色
    vec3(0.5137, 0.4627, 0.6118),      // D: 薰衣草色
    vec3(1.0, 0.4667, 0.6588),         // E: 粉色
    vec3(1.0, 0.8, 0.6667)             // F: 桃色
);

vec3 quantize_color(vec3 color) {
    float min_dist = 10.0;
    int best_idx = 0;
    
    for (int i = 0; i < 16; i++) {
        float dist = distance(color, palette[i]);
        if (dist < min_dist) {
            min_dist = dist;
            best_idx = i;
        }
    }
    
    return palette[best_idx];
}

void fragment() {
    // 像素化效果
    vec2 pixelated_uv = UV;
    if (pixel_size > 1.0) {
        vec2 pixel_count = TEXTURE_PIXEL_SIZE * pixel_size;
        pixelated_uv = floor(UV / pixel_count) * pixel_count + pixel_count * 0.5;
    }
    
    vec4 tex = texture(TEXTURE, pixelated_uv);
    vec3 color = tex.rgb;
    
    // 伽马校正
    color = pow(color, vec3(gamma));
    
    // 量化到 PICO-8 调色板
    color = quantize_color(color);
    
    // CRT 扫描线效果
    if (retro_crt) {
        float scanline = sin(FRAGCOORD.y * 3.14159) * 0.5 + 0.5;
        color *= mix(1.0, scanline, scanline_opacity);
    }
    
    COLOR = vec4(color, tex.a);
}