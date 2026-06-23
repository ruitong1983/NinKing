shader_type canvas_item;

// 可调节的参数
uniform float cell_size : hint_range(1, 200) = 100.0;
uniform bool show_original = false;
uniform float mouse_x_norm : hint_range(0.0, 1.0) = 0.5; // 归一化的鼠标X位置

// 自定义函数
float luminance(vec3 rgb) {
    return rgb.r * 0.33 + rgb.g * 0.33 + rgb.b * 0.33;
}

void fragment() {
    // 获取当前像素的UV坐标
    vec2 uv = UV;
    
    // 计算宽高比
    vec2 texture_size = vec2(textureSize(TEXTURE, 0));
    vec2 ar = vec2(1.0, texture_size.y / texture_size.x);
    
    vec3 col = vec3(0.0);
    
    // 创建错位的网格
    vec2 uvR = vec2(fract(uv.x * cell_size), fract(uv.y * cell_size * ar.y));
    vec2 uvG = vec2(fract(uv.x * cell_size + 0.33), fract((uv.y * cell_size + 0.33) * ar.y));
    vec2 uvB = vec2(fract(uv.x * cell_size + 0.66), fract((uv.y * cell_size + 0.66) * ar.y));
    
    // 计算网格位置
    vec2 pos = floor(uv * cell_size * ar) / cell_size;
    vec2 posG = floor((uv * cell_size + 0.33) * ar) / cell_size;
    vec2 posB = floor((uv * cell_size + 0.66) * ar) / cell_size;
    
    // 从纹理中采样亮度值
    float intensityR = texture(TEXTURE, (pos / ar) + 0.5 / cell_size).r;
    float intensityG = texture(TEXTURE, ((posG) / ar) + (0.5 - 0.33) / cell_size).g;
    float intensityB = texture(TEXTURE, ((posB) / ar) + (0.5 - 0.66) / cell_size).b;
    
    // 绘制圆点（根据亮度决定大小）
    float circleR = float(length(uvR - 0.5) < intensityR * 0.5);
    float circleG = float(length(uvG - 0.5) < intensityG * 0.5);
    float circleB = float(length(uvB - 0.5) < intensityB * 0.5);
    
    // 组合颜色
    col = vec3(circleR, circleG, circleB);
    
    // 根据条件切换显示效果
    if (show_original || uv.x > mouse_x_norm) {
        col = texture(TEXTURE, uv).rgb;
    }
    
    COLOR = vec4(col, 1.0);
}