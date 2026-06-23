shader_type canvas_item;

// 边框参数
uniform float border_size : hint_range(0.0, 0.15) = 0.08;
uniform float bottom_extra : hint_range(0.0, 0.2) = 0.12;
uniform vec4 border_color : source_color = vec4(0.97, 0.97, 0.97, 1.0);

// 圆角控制（两个独立的参数）
uniform float paper_corner_radius : hint_range(0.0, 0.5) = 0.04;  // 白色相纸的圆角
uniform float photo_corner_radius : hint_range(0.0, 0.5) = 0.02;   // 照片区域的圆角

// 宝丽来效果
uniform float warm_tone : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_strength : hint_range(0.0, 0.5) = 0.2;

// 圆角矩形距离场函数
float rounded_rectangle(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + r;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - r;
}

void fragment() {
    vec2 uv = UV;
    
    // 计算底部调整（让照片区域在中心偏上的位置）
    float bottom_adjust = bottom_extra * 0.5;
    vec2 paper_center = vec2(0.5, 0.5 - bottom_adjust * 0.5);
    vec2 paper_size = vec2(1.0, 1.0 - bottom_adjust);
    
    // 计算照片区域
    vec2 photo_center = vec2(0.5, 0.5 - bottom_adjust * 0.25);
    vec2 photo_size = vec2(
        1.0 - border_size * 2.0,
        1.0 - border_size * 2.0 - bottom_adjust
    );
    
    // 计算到相纸和照片的距离（基于相纸中心）
    vec2 paper_uv = (uv - paper_center) * 2.0;
    float paper_dist = rounded_rectangle(paper_uv, paper_size, paper_corner_radius);
    
    // 基于照片中心计算
    vec2 photo_uv = (uv - photo_center) * 2.0;
    float photo_dist = rounded_rectangle(photo_uv, photo_size, photo_corner_radius);
    
    // 判断是否在相纸范围内
    if (paper_dist > 0.0) {
        // 在相纸之外
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
        //return;
    }
    
    // 判断是否在照片范围内
    if (photo_dist <= 0.0) {
        // 照片区域 - 计算UV映射
        vec2 mapped_uv = vec2(
            (uv.x - border_size) / (1.0 - border_size * 2.0),
            (uv.y - border_size) / (1.0 - border_size * 2.0 - bottom_extra)
        );
        
        vec4 photo_color = texture(TEXTURE, mapped_uv);
        vec3 color = photo_color.rgb;
        
        // 宝丽来暖色调
        color.r *= (1.0 + warm_tone * 0.1);
        color.b *= (1.0 - warm_tone * 0.05);
        
        // 暗角效果
        vec2 center_uv = mapped_uv - 0.5;
        float vignette = 1.0 - vignette_strength * dot(center_uv, center_uv);
        color *= vignette;
        
        COLOR = vec4(color, photo_color.a);
    } else {
        // 边框区域
        vec3 color = border_color.rgb;
        
        // 底部留白区域稍微暗一点
        if (uv.y > 1.0 - bottom_extra * 0.7) {
            color *= 0.92;
        }
        
        COLOR = vec4(color, border_color.a);
    }
}