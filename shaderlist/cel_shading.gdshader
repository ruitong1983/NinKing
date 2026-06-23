shader_type canvas_item;

// 统一变量：光照强度阈值。低于此值视为阴影。
uniform float shadow_threshold : hint_range(0.0, 1.1) = 0.6; 

// 统一变量：阴影部分的颜色乘数 (0.0 到 1.0)。
uniform float shadow_multiplier : hint_range(0.1, 1.0) = 0.5;

// 统一变量：模拟简单单向光的方向 (影响整个场景，需要全局设置)
uniform vec2 light_direction_2d = vec2(1.0, 1.0); 

void fragment() {
    // 1. 获取原始颜色
    vec4 base_color = texture(TEXTURE, UV);
    
    // 2. 简化光照模型：计算当前像素的平均亮度作为光照输入
    // 假设场景中有恒定的环境光，并有一个来自 light_direction_2d 的光
    
    // 简单地使用像素在屏幕上的位置模拟一个简单的光照变化 (替代法线贴图)
    // 这种方法只能模拟屏幕上的渐变，不依赖物体的形状
    float light_dot = dot(UV, normalize(light_direction_2d));
    
    // 将光照值映射到 [0, 1] 范围
    float diffuse_intensity = clamp(light_dot, 0.0, 1.0);
    
    // **********************************************
    // 如果你结合法线贴图，请替换 diffuse_intensity 的计算：
    // float diffuse_intensity = [来自法线贴图的点积计算结果];
    // **********************************************
    
    // 3. 核心：颜色量化 / Cel Shading
    
    // 使用 step 函数进行量化：
    // 如果 diffuse_intensity < shadow_threshold，则处于阴影中 (结果为 0.0)
    // 如果 diffuse_intensity >= shadow_threshold，则处于亮部 (结果为 1.0)
    float light_level = step(shadow_threshold, diffuse_intensity);
    
    // 4. 映射颜色
    
    // 阴影颜色乘数：如果在阴影中 (light_level = 0.0)，使用 shadow_multiplier
    // 亮部颜色乘数：如果在亮部中 (light_level = 1.0)，使用 1.0
    
    // 使用 mix 函数混合：mix(阴影值, 亮部值, light_level)
    float final_light_factor = mix(shadow_multiplier, 1.0, light_level);
    
    // 5. 应用光照因子
    vec3 final_rgb = base_color.rgb * final_light_factor;
    
    // 6. 输出最终颜色
    COLOR = vec4(final_rgb, base_color.a);
}