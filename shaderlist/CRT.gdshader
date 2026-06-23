shader_type canvas_item;

// 统一变量：扫描线强度 (0.0 到 1.0)。值越高，扫描线越明显。
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.3;

// 统一变量：扫描线的密度。值越高，扫描线越细密。
// 通常是屏幕高度的倍数，例如 400.0 或 600.0。
uniform float scanline_density : hint_range(100.0, 1000.0) = 480.0; // 假设屏幕高度为480或更高

// 统一变量：屏幕弯曲强度 (0.0 为无弯曲)。
// 推荐值在 0.05 到 0.2 之间。
uniform float barrel_distortion_strength : hint_range(0.0, 0.5) = 0.15;

// (可选) 统一变量：色差强度。
// uniform float chromatic_aberration_strength : hint_range(0.0, 0.01) = 0.005;


void fragment() {
    // 1. 屏幕弯曲 (Barrel Distortion)
    vec2 distorted_uv = UV;
    
    // 将 UV 坐标从 [0,1] 转换为 [-0.5, 0.5] 区间，使中心为 (0,0)
    vec2 center_uv = UV - vec2(0.5);
    
    // 计算当前像素到中心点的距离
    float dist_sq = dot(center_uv, center_uv); // 距离的平方
    
    // 计算弯曲偏移量。使用一个简单的多项式函数。
    // dist_sq 越大 (离中心越远)，弯曲效果越强。
    float distortion_factor = 1.0 + dist_sq * barrel_distortion_strength;
    
    // 应用弯曲：将 UV 坐标向外推 (或根据需要向内拉)
    distorted_uv = center_uv * distortion_factor + vec2(0.5);
    
    // 2. 边界检查：如果 UV 坐标超出 [0,1] 范围 (由于弯曲)，则丢弃像素
    // 否则会采样到纹理外部，产生重复或黑色条纹。
    if (distorted_uv.x < 0.0 || distorted_uv.x > 1.0 || 
        distorted_uv.y < 0.0 || distorted_uv.y > 1.0) {
        discard;
    }
    
    // 3. 采样原始纹理颜色，使用扭曲后的 UV
    vec4 base_color = texture(TEXTURE, distorted_uv);
    
    // (可选) 4. 色差 (Chromatic Aberration)
    /*
    vec3 chromatic_rgb;
    chromatic_rgb.r = texture(TEXTURE, distorted_uv + vec2(chromatic_aberration_strength, 0.0)).r;
    chromatic_rgb.g = texture(TEXTURE, distorted_uv).g; // 绿色通常保持不变
    chromatic_rgb.b = texture(TEXTURE, distorted_uv - vec2(chromatic_aberration_strength, 0.0)).b;
    base_color.rgb = chromatic_rgb;
    */
    
    // 5. 扫描线 (Scanlines)
    // 根据当前像素的 Y 坐标计算扫描线效果
    // fract(UV.y * scanline_density) 会在 [0,1] 之间周期性变化
    // smoothstep 用于平滑过渡，避免硬边缘
    float scanline_factor = smoothstep(0.0, 0.5, fract(distorted_uv.y * scanline_density));
    
    // 降低亮度的因子
    // scanline_factor 接近 0 时，亮度降低 (scanline_strength 生效)
    // scanline_factor 接近 1 时，亮度几乎不变
    float brightness_modifier = 1.0 - (scanline_factor * scanline_strength);
    
    // 应用扫描线效果到颜色
    base_color.rgb *= brightness_modifier;
    
    // 6. 输出最终颜色
    COLOR = base_color;
}