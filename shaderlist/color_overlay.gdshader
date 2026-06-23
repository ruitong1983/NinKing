shader_type canvas_item;

// 拆分RGBA为4个独立滑动条（范围0.0~1.0，步长0.01，默认全1=白色）
uniform float red : hint_range(0.0, 1.0, 0.01) = 1.0;   // 红色通道
uniform float green : hint_range(0.0, 1.0, 0.01) = 1.0; // 绿色通道
uniform float blue : hint_range(0.0, 1.0, 0.01) = 1.0;  // 蓝色通道
uniform float alpha : hint_range(0.0, 1.0, 0.01) = 1.0; // 透明度通道

void fragment() {
    // 1. 采样原始纹理颜色
    vec4 color = texture(TEXTURE, UV);
    // 2. 合并滑动条值为叠加色（vec4(R,G,B,A)）
    vec4 overlay_color = vec4(red, green, blue, alpha);
    // 3. 颜色乘法叠加（如需保留原始Alpha，见下方优化）
    COLOR = color * overlay_color;
}