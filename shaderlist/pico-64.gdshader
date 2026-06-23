shader_type canvas_item;

// 参数
uniform float gamma : hint_range(0.0,3.0) = 1.0;
uniform float pixel_size : hint_range(0.0,5.0) = 0.0;
uniform bool retro_crt = false;
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.1;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.3; // 新增：抖动强度

// 改进的64色调色板（更好的色彩分布）
const vec3[64] palette_64 = vec3[64](
    // 黑色到白色渐变 (8色)
    vec3(0.0, 0.0, 0.0),          // 纯黑
    vec3(0.15, 0.15, 0.15),       // 深灰
    vec3(0.3, 0.3, 0.3),          // 暗灰
    vec3(0.45, 0.45, 0.45),       // 中灰
    vec3(0.6, 0.6, 0.6),          // 浅灰
    vec3(0.75, 0.75, 0.75),       // 亮灰
    vec3(0.9, 0.9, 0.9),          // 淡灰
    vec3(1.0, 1.0, 1.0),          // 纯白
    
    // 红色系 (7色)
    vec3(0.3, 0.0, 0.0),          // 深红
    vec3(0.5, 0.0, 0.0),          // 红
    vec3(0.7, 0.0, 0.0),          // 亮红
    vec3(0.9, 0.0, 0.0),          // 鲜红
    vec3(1.0, 0.3, 0.3),          // 淡红
    vec3(1.0, 0.5, 0.5),          // 浅红
    vec3(1.0, 0.7, 0.7),          // 粉红
    
    // 绿色系 (7色)
    vec3(0.0, 0.3, 0.0),          // 深绿
    vec3(0.0, 0.5, 0.0),          // 绿
    vec3(0.0, 0.7, 0.0),          // 亮绿
    vec3(0.0, 0.9, 0.0),          // 鲜绿
    vec3(0.3, 1.0, 0.3),          // 淡绿
    vec3(0.5, 1.0, 0.5),          // 浅绿
    vec3(0.7, 1.0, 0.7),          // 薄荷绿
    
    // 蓝色系 (7色)
    vec3(0.0, 0.0, 0.3),          // 深蓝
    vec3(0.0, 0.0, 0.5),          // 蓝
    vec3(0.0, 0.0, 0.7),          // 亮蓝
    vec3(0.0, 0.0, 0.9),          // 鲜蓝
    vec3(0.3, 0.3, 1.0),          // 淡蓝
    vec3(0.5, 0.5, 1.0),          // 浅蓝
    vec3(0.7, 0.7, 1.0),          // 天蓝
    
    // 黄色系 (6色)
    vec3(0.3, 0.3, 0.0),          // 深黄
    vec3(0.5, 0.5, 0.0),          // 黄
    vec3(0.7, 0.7, 0.0),          // 亮黄
    vec3(1.0, 1.0, 0.0),          // 鲜黄
    vec3(1.0, 1.0, 0.5),          // 浅黄
    vec3(1.0, 1.0, 0.8),          // 淡黄
    
    // 紫色系 (6色)
    vec3(0.3, 0.0, 0.3),          // 深紫
    vec3(0.5, 0.0, 0.5),          // 紫
    vec3(0.7, 0.0, 0.7),          // 亮紫
    vec3(0.9, 0.0, 0.9),          // 鲜紫
    vec3(1.0, 0.5, 1.0),          // 淡紫
    vec3(1.0, 0.7, 1.0),          // 粉紫
    
    // 青色系 (6色)
    vec3(0.0, 0.3, 0.3),          // 深青
    vec3(0.0, 0.5, 0.5),          // 青
    vec3(0.0, 0.7, 0.7),          // 亮青
    vec3(0.0, 0.9, 0.9),          // 鲜青
    vec3(0.5, 1.0, 1.0),          // 淡青
    vec3(0.8, 1.0, 1.0),          // 浅青
    
    // 橙色系 (6色)
    vec3(0.3, 0.15, 0.0),         // 深橙
    vec3(0.5, 0.25, 0.0),         // 橙
    vec3(0.7, 0.35, 0.0),         // 亮橙
    vec3(1.0, 0.5, 0.0),          // 鲜橙
    vec3(1.0, 0.7, 0.3),          // 浅橙
    vec3(1.0, 0.8, 0.5),          // 淡橙
    
    // 棕色系 (5色)
    vec3(0.2, 0.1, 0.0),          // 深棕
    vec3(0.4, 0.2, 0.0),          // 棕
    vec3(0.6, 0.3, 0.0),          // 亮棕
    vec3(0.8, 0.4, 0.1),          // 浅棕
    vec3(1.0, 0.8, 0.6),          // 米色
    
    // 混合色 (6色)
    vec3(1.0, 0.3, 0.0),          // 橙红
    vec3(0.0, 1.0, 0.3),          // 青绿
    vec3(0.3, 0.0, 1.0),          // 蓝紫
    vec3(1.0, 0.0, 0.5),          // 玫红
    vec3(0.5, 0.0, 1.0),          // 紫蓝
    vec3(0.0, 0.5, 1.0)           // 天青
);

// 改进的颜色量化函数 - 使用感知均匀的颜色距离
vec3 quantize_color_perceptual(vec3 color) {
    float min_dist = 10.0;
    int best_idx = 0;
    
    // 转换为YUV色彩空间（更符合人眼感知）
    float y = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
    float u = -0.14713 * color.r - 0.28886 * color.g + 0.436 * color.b;
    float v = 0.615 * color.r - 0.51499 * color.g - 0.10001 * color.b;
    
    for (int i = 0; i < 64; i++) {
        // 将调色板颜色也转换为YUV
        float py = 0.299 * palette_64[i].r + 0.587 * palette_64[i].g + 0.114 * palette_64[i].b;
        float pu = -0.14713 * palette_64[i].r - 0.28886 * palette_64[i].g + 0.436 * palette_64[i].b;
        float pv = 0.615 * palette_64[i].r - 0.51499 * palette_64[i].g - 0.10001 * palette_64[i].b;
        
        // 计算YUV空间的距离（更符合人眼感知）
        float ydiff = y - py;
        float udiff = u - pu;
        float vdiff = v - pv;
        
        // 加权距离：亮度权重更高
        float dist = ydiff * ydiff * 0.7 + (udiff * udiff + vdiff * vdiff) * 0.3;
        
        if (dist < min_dist) {
            min_dist = dist;
            best_idx = i;
        }
    }
    
    return palette_64[best_idx];
}

// 抖动函数 - 增加颜色过渡的平滑度
vec3 apply_dither(vec3 color, vec2 coord, float strength) {
    // Bayer矩阵用于有序抖动
    float bayer_matrix[16] = float[16](
        0.0,  8.0,  2.0,  10.0,
        12.0, 4.0,  14.0, 6.0,
        3.0,  11.0, 1.0,  9.0,
        15.0, 7.0,  13.0, 5.0
    );
    
    // 获取像素位置
    int x = int(mod(coord.x, 4.0));
    int y = int(mod(coord.y, 4.0));
    int index = x + y * 4;
    
    // 计算抖动值 (-0.5 到 0.5)
    float dither_value = (bayer_matrix[index] / 16.0 - 0.5) * strength;
    
    // 应用抖动
    return color + vec3(dither_value, dither_value, dither_value);
}

void fragment() {
    // 1. 应用像素化效果
    vec2 pixelated_uv = UV;
    if (pixel_size > 1.0) {
        vec2 pixel_count = TEXTURE_PIXEL_SIZE * pixel_size;
        pixelated_uv = floor(UV / pixel_count) * pixel_count + pixel_count * 0.5;
    }
    
    // 2. 采样纹理
    vec4 tex = texture(TEXTURE, pixelated_uv);
    vec3 color = tex.rgb;
    
    // 3. 伽马校正
    color = pow(color, vec3(gamma));
    
    // 4. 应用抖动（在量化前）
    if (dither_strength > 0.0) {
        color = apply_dither(color, FRAGCOORD.xy, dither_strength * 0.1);
        color = clamp(color, 0.0, 1.0);
    }
    
    // 5. 使用改进的感知量化
    color = quantize_color_perceptual(color);
    
    // 6. 应用CRT扫描线效果
    if (retro_crt) {
        float scanline = sin(FRAGCOORD.y * 3.14159) * 0.5 + 0.5;
        color *= mix(1.0, scanline, scanline_opacity);
    }
    
    // 7. 输出最终颜色
    COLOR = vec4(color, tex.a);
}