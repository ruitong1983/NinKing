shader_type canvas_item;

// 晶格的精细度。数值越大，晶格越小，细节越多。
uniform float resolution : hint_range(10.0, 100.0, 1.0) = 40.0;

// 时间输入，用于动画效果，模拟冰晶“生长”或“闪烁 ”。
uniform float time_speed = 0.5;

// =======================================================
// 辅助函数定义
vec2 hash(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}
// =======================================================

void fragment() {
    // 【已移除冗余变量 vec2 size = 1.0 / SCREEN_PIXEL_SIZE;】
    
    // 将UV坐标放大到我们需要的“晶格”空间
    // cell现在是放大了 resolution 倍的UV坐标
    vec2 cell = UV * resolution;
    
    // --- 1. 找到当前晶格的中心点 (Closest Grid Point) ---
    // floor(cell)找到晶格的左上角整数坐标，+0.5 得到晶格的中心整数坐标
    vec2 nearest_center = floor(cell) + 0.5;
    
    // --- 2. 引入抖动/随机扰动 (Jitter) ---
    // 使用外部定义的 hash 函数进行随机偏移
    vec2 offset = (hash(nearest_center) - 0.5) * 0.8; 
    // 增加时间动画
    offset += sin(nearest_center * 10.0 + TIME * time_speed) * 0.05; 
    
    // 修正中心点，使其随机化
    nearest_center += offset;
    
    // --- 3. 确定最终的纹理采样坐标 ---
    // 将修正后的晶格中心点重新缩回到 UV 空间（除以 resolution）
    vec2 sample_uv = nearest_center / resolution;
    
    // --- 4. 采样颜色 ---
    vec4 final_color = texture(TEXTURE, sample_uv);
    
    COLOR = final_color;
}