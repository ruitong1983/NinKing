shader_type canvas_item;

//  参数，范围0-1，控制黑白分界点
// 值越高，图像中白色区域越多；值越低，黑色区域越多
uniform float threshold : hint_range(0, 1) = 0.9 ;

void fragment() {
    // 采样原始纹理颜色
    vec4 original_color = texture(TEXTURE, UV);
    
    // 1. 将彩色转为灰度（使用人眼感知加权公式）
    float gray = 0.299 * original_color.r + 0.587 * original_color.g + 0.114 * original_color.b;
    
    // 2. 二值化处理：根据阈值判断为纯黑或纯白
    float binary = gray >= threshold ? 1.0 : 0.0;
    
    // 输出结果，保留原始alpha通道（透明度）
    COLOR = vec4(vec3(binary), original_color.a);
}
