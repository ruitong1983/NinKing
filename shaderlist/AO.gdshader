shader_type canvas_item;

// 统一变量：包含场景几何体信息的 SDF 纹理。
uniform sampler2D sdf_map;

// 统一变量：光源的位置 (相对屏幕 UV 坐标 [0, 1])
uniform vec2 light_position = vec2(0.5, 0.5);

// 统一变量：阴影的锐利度。值越高，阴影边缘越锐利。
uniform float shadow_sharpness : hint_range(5.0, 50.0) = 20.0;

// 统一变量：环境光颜色（在阴影区域的底色）
uniform vec4 ambient_color = vec4(0.1, 0.1, 0.1, 1.0); 

// 辅助函数：从 SDF 纹理中获取距离值
// 注意：SDF 纹理必须存储距离信息，通常在 R 通道或 G 通道。
float get_distance(vec2 p) {
    // 假设 SDF 纹理的红通道存储了距离值，范围可能在 [0, 1]。
    // 我们需要将这个 [0, 1] 范围映射回 SDF 空间，例如 [-MaxDist, +MaxDist]。
    // 这里的具体映射取决于您如何生成 SDF 纹理。
    // 假设 0.5 对应距离 0，0.0 对应 -MaxDist，1.0 对应 +MaxDist。
    float map_value = texture(sdf_map, p).r;
    
    // 假设映射：(Value * 2.0 - 1.0) * Max_Distance_Scale
    // 我们使用一个简单且通用的缩放。
    return (map_value * 2.0 - 1.0) * 1.0; 
}


// 主光线步进函数：计算当前像素的阴影因子
float calculate_shadow(vec2 origin, vec2 light_dir, float max_dist) {
    float total_distance_traveled = 0.0;
    float final_shadow_factor = 1.0;
    
    // 光线步进迭代次数，次数越多，阴影越精确但性能越低。
    const int steps = 16; 
    
    for (int i = 0; i < steps; i++) {
        // 当前光线步进的位置
        vec2 p = origin + light_dir * total_distance_traveled;
        
        // 获取当前位置到最近几何体的距离
        float distance_to_geometry = get_distance(p);
        
        // 核心：软阴影的计算
        // k 是软阴影的系数。这个表达式用于平滑地衰减阴影。
        // 它基于距离/光线步进距离的比例。
        float k = distance_to_geometry / total_distance_traveled; 
        final_shadow_factor = min(final_shadow_factor, shadow_sharpness * k);
        
        // 累加距离，为下一次步进做准备
        total_distance_traveled += distance_to_geometry;
        
        // 退出条件 1: 如果光线击中几何体 (距离为负或接近 0)，停止
        if (distance_to_geometry < 0.001) { 
            final_shadow_factor = 0.0; // 完全在阴影中
            break;
        }
        
        // 退出条件 2: 如果光线超出光源范围，停止
        if (total_distance_traveled > max_dist) {
            break;
        }
    }
    
    // 钳制最终因子到 [0, 1]
    return clamp(final_shadow_factor, 0.0, 1.0);
}

void fragment() {
    // 1. 获取基础颜色
    vec4 base_color = texture(TEXTURE, UV);
    
    // 2. 计算光照信息
    vec2 to_light_vector = light_position - UV;
    float max_ray_distance = length(to_light_vector); // 当前像素到光源的最大距离
    vec2 light_dir_norm = normalize(to_light_vector); // 单位光线方向向量
    
    // 3. 计算阴影因子
    float shadow_factor = calculate_shadow(UV, light_dir_norm, max_ray_distance);
    
    // 4. 应用阴影
    // 使用 mix 函数混合环境光和原始颜色
    // mix(环境光颜色, 原始颜色, 阴影因子)
    // shadow_factor=0 (全阴影) -> 得到 ambient_color
    // shadow_factor=1 (全亮) -> 得到 base_color
    vec3 final_rgb = mix(ambient_color.rgb * base_color.rgb, base_color.rgb, shadow_factor);
    
    COLOR = vec4(final_rgb, base_color.a);
}