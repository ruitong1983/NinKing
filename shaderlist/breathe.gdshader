shader_type canvas_item;

// 呼吸速度
uniform float speed : hint_range(0.0, 5.0) = 1.0;
// 膨胀幅度（0-1之间）
uniform float intensity : hint_range(0.0, 1.0) = 0.15;
// 是否使用像素化效果
uniform bool pixelated = false;

void fragment() {
    // 计算呼吸效果的时间因子
    float breath = sin(TIME * speed) * intensity;
    
    // 计算UV偏移的中心点（通常是中心）
    vec2 center = vec2(0.5, 0.5);
    
    if (pixelated) {
        // 像素化呼吸效果 - 保持像素风格
        vec2 pixel_uv = floor(UV * 20.0) / 20.0;
        vec2 dir = pixel_uv - center;
        float dist = length(dir);
        
        // 根据距离和呼吸因子创建膨胀效果
        vec2 new_uv = center + dir * (1.0 + breath * (1.0 - dist));
        
        // 采样纹理
        COLOR = texture(TEXTURE, clamp(new_uv, 0.0, 1.0));
    } else {
        // 平滑呼吸效果
        vec2 dir = UV - center;
        float dist = length(dir);
        
        // 距离中心越远，膨胀效果越小，形成球面膨胀
        vec2 new_uv = center + dir * (1.0 + breath * (1.0 - dist));
        
        // 采样纹理
        COLOR = texture(TEXTURE, clamp(new_uv, 0.0, 1.0));
    }
}