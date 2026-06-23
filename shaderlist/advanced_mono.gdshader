shader_type canvas_item;

// 统一变量：红、绿、蓝通道的贡献权重 (它们总和不必为 1.0)
uniform vec3 channel_weights = vec3(0.21, 0.72, 0.07); // 默认使用标准的亮度加权 (ITU-R BT.709)

// 统一变量：对比度调整 (1.0 为不变， >1.0 增加对比， <1.0 降低对比)
uniform float contrast : hint_range(0.5, 3.0) = 1.0;

// 统一变量：伽马矫正 (1.0 为不变， <1.0 提亮中间调， >1.0 压暗中间调)
uniform float gamma : hint_range(0.1 , 3.0) = 1.0;

void fragment() {
    // 1. 获取原始颜色
    vec4 base_color = texture(TEXTURE, UV);
    
    // 2. 颜色通道加权转换 (Luminance Calculation)
    // 使用用户定义的权重计算亮度值 L
    float luminance = dot(base_color.rgb, channel_weights);
    
    // 3. 对比度调整 (Contrast)
    // 围绕 0.5 (中灰) 进行调整。
    // V_new = 0.5 + (V_old - 0.5) * Contrast
    float contrasted_luminance = 0.5 + (luminance - 0.5) * contrast;
    
    // 确保值在 [0, 1] 范围内
    contrasted_luminance = clamp(contrasted_luminance, 0.0, 1.0);
    
    // 4. 伽马矫正 (Gamma Correction)
    // 使用幂函数调整亮度曲线
    // V_new = V_old ^ Gamma
    float final_luminance = pow(contrasted_luminance, gamma);
    
    // 5. 输出最终颜色
    // 将最终亮度值赋值给 RGB 三个通道，实现黑白效果
    COLOR = vec4(vec3(final_luminance), base_color.a);
}