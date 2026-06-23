shader_type canvas_item;

// 参数
uniform float gamma : hint_range(0.0,3.0) = 1.0;
uniform float pixel_size : hint_range(0.0,5.0) = 0.0;
uniform bool retro_crt = false;
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.1;

// 新增：调色板选择
uniform int palette_mode : hint_range(0, 1) = 0; // 0=PICO-8, 1=32色, 2=64色

// PICO-8 16色调色板
const vec3[16] palette_16 = vec3[16](
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

// 32色调色板（扩展）
const vec3[32] palette_32 = vec3[32](
    // 原有16色
    vec3(0.0, 0.0, 0.0),                // 0
    vec3(0.1137, 0.1686, 0.3255),      // 1
    vec3(0.4941, 0.1451, 0.3255),      // 2
    vec3(0.0, 0.5294, 0.3176),         // 3
    vec3(0.6706, 0.3216, 0.2118),      // 4
    vec3(0.3725, 0.3412, 0.3098),      // 5
    vec3(0.7608, 0.7647, 0.7804),      // 6
    vec3(1.0, 0.9451, 0.9098),         // 7
    vec3(1.0, 0.0, 0.3020),            // 8
    vec3(1.0, 0.6392, 0.0),            // 9
    vec3(1.0, 0.9255, 0.1529),         // 10
    vec3(0.0, 0.8941, 0.2118),         // 11
    vec3(0.1608, 0.6784, 1.0),         // 12
    vec3(0.5137, 0.4627, 0.6118),      // 13
    vec3(1.0, 0.4667, 0.6588),         // 14
    vec3(1.0, 0.8, 0.6667),            // 15
    
    // 新增16色
    vec3(0.2, 0.2, 0.2),               // 16: 深灰
    vec3(0.3, 0.15, 0.4),              // 17: 深紫色
    vec3(0.8, 0.2, 0.1),               // 18: 亮红色
    vec3(0.95, 0.5, 0.2),              // 19: 亮橙色
    vec3(0.3, 0.7, 0.4),               // 20: 草绿色
    vec3(0.1, 0.6, 0.8),               // 21: 天蓝色
    vec3(0.6, 0.3, 0.7),               // 22: 紫色
    vec3(0.9, 0.8, 0.3),               // 23: 金丝雀黄
    vec3(0.4, 0.3, 0.2),               // 24: 深棕色
    vec3(0.7, 0.9, 0.5),               // 25: 浅绿色
    vec3(0.5, 0.7, 0.9),               // 26: 淡蓝色
    vec3(0.9, 0.6, 0.8),               // 27: 浅粉色
    vec3(0.2, 0.4, 0.3),               // 28: 深青色
    vec3(0.8, 0.4, 0.1),               // 29: 土橙色
    vec3(0.6, 0.6, 0.6),               // 30: 中灰色
    vec3(0.95, 0.95, 0.8)              // 31: 淡黄色
);

// 量化函数（自动选择调色板）
vec3 quantize_color(vec3 color, int mode) {
    float min_dist = 10.0;
    vec3 best_color = vec3(0.0);
    
    if (mode == 0) {
        // PICO-8 16色模式
        for (int i = 0; i < 16; i++) {
            float dist = distance(color, palette_16[i]);
            if (dist < min_dist) {
                min_dist = dist;
                best_color = palette_16[i];
            }
        }
    } else if (mode == 1) {
        // 32色模式
        for (int i = 0; i < 32; i++) {
            float dist = distance(color, palette_32[i]);
            if (dist < min_dist) {
                min_dist = dist;
                best_color = palette_32[i];
            }
        }
    }
    // 如果需要64色模式，可以在这里添加
    
    return best_color;
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
    
    // 量化到选择的调色板
    color = quantize_color(color, palette_mode);
    
    // CRT 扫描线效果
    if (retro_crt) {
        float scanline = sin(FRAGCOORD.y * 3.14159) * 0.5 + 0.5;
        color *= mix(1.0, scanline, scanline_opacity);
    }
    
    COLOR = vec4(color, tex.a);
}