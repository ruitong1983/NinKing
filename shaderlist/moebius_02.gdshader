shader_type canvas_item;
render_mode unshaded;

// ==============================================
// 效果名称：Texture Variance Mapper
// 中文名称：纹理变化映射器
// 
// 功能描述：
// 通过计算像素邻域的颜色方差，检测图像中的
// 纹理变化和边缘。输出为灰度图，其中：
// - 平坦区域：亮色（接近白色）
// - 纹理/边缘：暗色（接近黑色）
// 
// 技术特点：
// - 基于局部颜色方差计算
// - 可调节检测范围和灵敏度
// - 全向性检测（无方向偏好）
// ==============================================

// 核心参数
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float edge_sensitivity : hint_range(0.0, 0.5) = 0.1;
uniform float edge_width : hint_range(0.5, 3.0) = 1.0;
uniform float softness : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec2 pixel_size = 1.0 / tex_size * edge_width;
    
    vec4 original_color = texture(TEXTURE, UV);
    
    // 透明区域直接返回透明
    if (original_color.a < 0.01) {
        COLOR = vec4(0.0);
        // return;
    }
    
    // Sobel算子（灰度版） - 使用浮点数
    const float sobel_x[9] = float[9](-1.0, 0.0, 1.0, -2.0, 0.0, 2.0, -1.0, 0.0, 1.0);
    const float sobel_y[9] = float[9](-1.0, -2.0, -1.0, 0.0, 0.0, 0.0, 1.0, 2.0, 1.0);
    
    float gx = 0.0, gy = 0.0;
    int idx = 0;
    
    for(int i = -1; i <= 1; i++) {
        for(int j = -1; j <= 1; j++) {
            vec2 offset = clamp(UV + vec2(float(i), float(j)) * pixel_size, 0.0, 1.0);
            vec4 sample = texture(TEXTURE, offset);
            float gray = dot(sample.rgb, vec3(0.299, 0.587, 0.114));
            gx += gray * sobel_x[idx];
            gy += gray * sobel_y[idx];
            idx++;
        }
    }
    
    float edge_strength = gx*gx + gy*gy;
    float threshold = edge_sensitivity * edge_sensitivity;
    
    // 计算边缘强度
    float edge = 1.0 - smoothstep(threshold*(1.0-softness), threshold*(1.0+softness), edge_strength);
    
    // 关键修复：只在边缘处使用 line_color
    vec3 final_color = original_color.rgb;
    if (edge > 0.01) {  // 添加一个小的阈值，避免浮点误差
        // 使用 mix 进行混合，保持边缘的柔化效果
        final_color = mix(original_color.rgb, line_color.rgb, edge);
    }
    
    COLOR = vec4(final_color, original_color.a);
}