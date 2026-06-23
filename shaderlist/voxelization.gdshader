shader_type canvas_item;

// 统一变量：体素块的大小（以像素为单位）。值越大，体素块越大。
uniform float voxel_size_pixels : hint_range(1.0, 32.0) = 8.0;

// 统一变量：体素化阴影的强度 (0.0 到 1.0)。值越高，阴影越明显。
uniform float voxel_shadow_strength : hint_range(0.0, 1.0) = 0.4;

// 统一变量：模拟光源的方向 (通常是右下角或左下角)。
uniform vec2 light_direction_2d = vec2(0.7, 0.7); // 默认右下角光源

void fragment() {
    // 1. 获取像素化后的 UV 坐标
    // 像素坐标 = SCREEN_UV / SCREEN_PIXEL_SIZE
    vec2 pixel_coord = SCREEN_UV / SCREEN_PIXEL_SIZE;
    
    // 将像素坐标向下取整到最近的体素块网格
    vec2 quantized_pixel_coord = floor(pixel_coord / voxel_size_pixels) * voxel_size_pixels;
    
    // 将量化后的像素坐标转换回 UV 空间，用于采样
    vec2 quantized_uv = quantized_pixel_coord * SCREEN_PIXEL_SIZE;
    
    // 2. 采样像素化后的颜色 (这是体素块的基础颜色)
    vec4 base_color = texture(TEXTURE, quantized_uv);
    
    // 3. 计算体素化阴影 (模拟 3D 效果的关键)
    float shadow_factor = 1.0;
    
    // a. 模拟环境光遮蔽 (Ambient Occlusion) 
    // 检查右下角方向的相邻体素块是否存在（即是否有颜色）
    // 如果相邻体素块有颜色，则当前体素的“右下角”面应该变暗。
    
    vec2 next_block_pixel_coord_x = quantized_pixel_coord + vec2(voxel_size_pixels, 0.0);
    vec2 next_block_pixel_coord_y = quantized_pixel_coord + vec2(0.0, voxel_size_pixels);
    
    vec4 next_block_color_x = texture(TEXTURE, next_block_pixel_coord_x * SCREEN_PIXEL_SIZE);
    vec4 next_block_color_y = texture(TEXTURE, next_block_pixel_coord_y * SCREEN_PIXEL_SIZE);
    
    // 如果右边有相邻的“体素块”（alpha > 0.1），则当前块的右侧面可能在阴影中
    if (next_block_color_x.a > 0.1) {
        // 简单地降低亮度，模拟右侧 AO
        // 这里可以根据当前像素在体素块内的相对位置进一步细化阴影
        shadow_factor -= voxel_shadow_strength; // 降低亮度
    }
    // 如果下方有相邻的“体素块”（alpha > 0.1），则当前块的底侧面可能在阴影中
    if (next_block_color_y.a > 0.1) {
        shadow_factor -= voxel_shadow_strength; // 降低亮度
    }
    
    // b. 模拟方向性光照 (Directional Light) - 更加精确的体素化阴影
    // 为了模拟光源，我们需要知道当前像素在它所属的体素块中的相对位置
    vec2 relative_pixel_in_block = mod(pixel_coord, voxel_size_pixels);
    
    // 归一化相对位置，范围 [0, 1]
    vec2 normalized_relative_pos = relative_pixel_in_block / voxel_size_pixels;
    
    // 模拟法线：简单的体素，我们可以假设上方和左方的面是朝向光源的。
    // 如果光源来自右下角 (light_direction_2d = (0.7, 0.7))
    // 那么体素的左侧和上方会被照亮，右侧和下方会是阴影。
    
    // 我们根据相对位置和光源方向，来判断当前像素在体素的哪个“面”上。
    // 这是一种非常简化的方法，但能产生视觉效果。
    float face_light_factor = 1.0;
    
    // 如果光源来自右下 (light_direction_2d.x > 0, light_direction_2d.y > 0)
    // 那么体素块的左侧和上侧应该更亮。
    // 我们可以用相对位置来判断：越靠近左上角越亮。
    face_light_factor = (1.0 - normalized_relative_pos.x * abs(light_direction_2d.x)) * (1.0 - normalized_relative_pos.y * abs(light_direction_2d.y));
    
    // 结合 AO 阴影和方向光
    shadow_factor = mix(shadow_factor, face_light_factor, 0.5); // 混合两种阴影效果
    
    // 确保阴影因子在有效范围内
    shadow_factor = clamp(shadow_factor, 0.0, 1.0);
    
    // 4. 应用阴影因子到体素颜色
    vec3 final_rgb = base_color.rgb * shadow_factor;
    
    // 5. 输出最终颜色 (保持原始 Alpha)
    COLOR = vec4(final_rgb, base_color.a);
}