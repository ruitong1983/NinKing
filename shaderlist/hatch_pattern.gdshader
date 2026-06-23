shader_type canvas_item;

// 影线效果专用参数
uniform float hatch_density : hint_range(1.0, 100.0) = 40.0;
uniform float hatch_angle : hint_range(0.0, 180.0) = 45.0;
uniform float hatch_intensity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 hatch_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float threshold : hint_range(0.0, 1.0) = 0.7;
uniform bool use_cross_hatch = false;  // 新增：是否使用交叉影线

// 获取旋转矩阵
mat2 get_rotation_matrix(float angle) {
    float rad = radians(angle);
    float s = sin(rad);
    float c = cos(rad);
    return mat2(vec2(c, -s), vec2(s, c));
}

// 生成基础影线模式
float get_hatch_pattern(vec2 uv, float density, float angle) {
    mat2 rotation = get_rotation_matrix(angle);
    vec2 rotated_uv = rotation * uv;
    
    // 使用正弦函数创建周期性的线条
    float pattern = sin(rotated_uv.x * density);
    
    // 二值化：当正弦值大于0时为1，小于等于0时为0
    return step(0.0, pattern);
}

// 生成交叉影线效果
float get_cross_hatch_pattern(vec2 uv, float density, float angle) {
    float hatch1 = get_hatch_pattern(uv, density, angle);
    float hatch2 = get_hatch_pattern(uv, density, angle + 90.0);
    return (hatch1 + hatch2) * 0.5;
}

void fragment() {
    // 获取原始颜色
    vec4 original_color = texture(TEXTURE, UV);
    
    // 计算亮度
    float brightness = dot(original_color.rgb, vec3(0.299, 0.587, 0.114));
    
    // 根据亮度控制影线可见度
    // 越暗的区域影线越明显
    float hatch_opacity = (1.0 - brightness) * hatch_intensity;
    
    // 生成影线图案
    float hatch_pattern;
    if (use_cross_hatch) {
        hatch_pattern = get_cross_hatch_pattern(UV, hatch_density, hatch_angle);
    } else {
        hatch_pattern = get_hatch_pattern(UV, hatch_density, hatch_angle);
    }
    
    // 根据阈值调整影线
    // threshold控制从何处开始显示影线（阈值以上显示）
    if (brightness > threshold) {
        hatch_pattern = 0.0;
    }
    
    // 混合影线与原始颜色
    vec3 final_color = mix(
        original_color.rgb, 
        hatch_color.rgb,
        hatch_pattern * hatch_opacity 
    );
    
    // 输出结果
    COLOR = vec4(final_color, original_color.a);
}