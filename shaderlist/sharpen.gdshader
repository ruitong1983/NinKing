shader_type canvas_item;

// 锐化控制参数
uniform float intensity : hint_range(0.0, 2.0) = 0.5;
uniform float radius : hint_range(0.0, 2.0) = 1.0;
uniform bool high_quality = false;
uniform bool preserve_brightness = true;

void fragment() {
    vec4 center = texture(TEXTURE, UV);
    
    // 确保纹理像素大小计算正确
    vec2 texel_size = TEXTURE_PIXEL_SIZE;
    
    if (high_quality) {
        // 高质量模式 - 使用更精细的采样
        vec2 offset = radius * texel_size;
        
        // 对角采样 - 这会显著增强锐化效果
        vec4 top_left = texture(TEXTURE, UV + vec2(-offset.x, -offset.y));
        vec4 top = texture(TEXTURE, UV + vec2(0.0, -offset.y));
        vec4 top_right = texture(TEXTURE, UV + vec2(offset.x, -offset.y));
        vec4 left = texture(TEXTURE, UV + vec2(-offset.x, 0.0));
        vec4 right = texture(TEXTURE, UV + vec2(offset.x, 0.0));
        vec4 bottom_left = texture(TEXTURE, UV + vec2(-offset.x, offset.y));
        vec4 bottom = texture(TEXTURE, UV + vec2(0.0, offset.y));
        vec4 bottom_right = texture(TEXTURE, UV + vec2(offset.x, offset.y));
        
        // 应用拉普拉斯算子 - 这是标准锐化卷积核
        vec4 blurred = (top_left + top + top_right + 
                       left + center + right + 
                       bottom_left + bottom + bottom_right) / 9.0;
        
        // 计算细节层（原图 - 模糊图）
        vec4 detail = center - blurred;
        
        // 将细节层加回原图
        vec4 sharpened = center + detail * intensity;
        
        if (preserve_brightness) {
            // 混合以保持亮度平衡
            sharpened = mix(center, sharpened, intensity * 0.7);
        }
        
        COLOR = sharpened;
    } else {
        // 性能优化模式 - 使用简单的3x3卷积核
        // 这里使用更小的偏移量确保radius参数有效
        vec2 offset = texel_size * (0.5 + radius * 0.5);
        
        vec4 top = texture(TEXTURE, UV + vec2(0.0, -offset.y));
        vec4 bottom = texture(TEXTURE, UV + vec2(0.0, offset.y));
        vec4 left = texture(TEXTURE, UV + vec2(-offset.x, 0.0));
        vec4 right = texture(TEXTURE, UV + vec2(offset.x, 0.0));
        
        // 应用锐化卷积核
        vec4 sharpened = 5.0 * center - (top + bottom + left + right);
        
        // 混合结果
        COLOR = mix(center, sharpened, intensity);
    }
    
    // 保持原始透明度
    COLOR.a = center.a;
}