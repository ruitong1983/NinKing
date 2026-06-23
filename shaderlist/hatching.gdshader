shader_type canvas_item;

// ----------------------------------------------------------------------
// 1. 素描排线 (Hatching) 参数
// ----------------------------------------------------------------------
uniform float hatch_density : hint_range(10.0, 80.0) = 40.0;  // 线条密度（值越大线条越密）
uniform float hatch_intensity : hint_range(0.0, 1.0) = 0.6;   // 线条深度（0=无效果，1=最大深度）
uniform vec2 hatch_angle = vec2(1.0, 0.4);                   // 线条方向（向量控制角度）
uniform float hatch_randomness : hint_range(0.0, 1.0) = 0.05; // 线条随机性（模拟手绘不完美感）
uniform float hatch_threshold : hint_range(0.0, 1.0) = 0.5;   // 亮度阈值（高于此值不显示线条）

// ----------------------------------------------------------------------
// 噪声函数（用于添加手绘不规则性）
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

// ----------------------------------------------------------------------
// 核心函数：生成素描排线
// ----------------------------------------------------------------------
float generate_hatching(vec2 uv, float luminance) {
    // 计算旋转角度
    float angle = atan(hatch_angle.y, hatch_angle.x);
    vec2 rotated_uv = vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
    
    // 在旋转前添加轻微随机偏移（模拟手绘抖动）
    vec2 random_offset = vec2(
        noise(uv * 15.0) * hatch_randomness * 0.5,
        noise(uv * 15.0 + 50.0) * hatch_randomness * 0.5
    );
    rotated_uv += random_offset;
    
    // 生成主线条（基础排线）
    float main_lines = sin(rotated_uv.x * hatch_density);
    
    // 生成细节线条（模拟铅笔纹理）
    float detail_lines1 = sin(rotated_uv.x * hatch_density * 1.8 + 0.7);
    float detail_lines2 = sin(rotated_uv.x * hatch_density * 2.5 + 1.2);
    
    // 合并线条（主线条占主导，细节线条加强纹理）
    float lines_raw = (main_lines + detail_lines1 * 0.3 + detail_lines2 * 0.15);
    
    // 将线条值映射到0-1范围（值越小表示线条越深）
    float lines_value = 0.5 - lines_raw * 0.5;
    
    // 根据亮度控制线条可见度：暗部线条更明显
    float visibility = clamp(1.0 - luminance * 1.2, 0.0, 1.0);
    
    // 应用可见度控制
    float final_lines = mix(1.0, lines_value, visibility);
    
    return clamp(final_lines, 0.0, 1.0);
}

// ----------------------------------------------------------------------
// Fragment 主函数
// ----------------------------------------------------------------------
void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    
    // 透明像素直接返回
    if (original_color.a < 0.01) {
        COLOR = original_color;
        //return;
    }
    
    // 计算亮度
    float luminance = dot(original_color.rgb, vec3(0.299, 0.587, 0.114));
    
    // 生成排线遮罩
    float hatch_mask = generate_hatching(UV * 3.5, luminance);
    
    // 应用亮度阈值：亮部区域不显示线条
    if (luminance > hatch_threshold) {
        hatch_mask = 1.0;
    }
    
    // 应用排线效果：线条区域变暗
    // hatch_mask 越小 = 线条越深 = 颜色越暗
    float darkness_factor = 1.0 - (1.0 - hatch_mask) * hatch_intensity;
    
    // 最终颜色
    vec3 final_color = original_color.rgb * darkness_factor;
    
    // 输出结果
    COLOR = vec4(final_color, original_color.a);
}