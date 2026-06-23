shader_type canvas_item;

// 外部参数：噪声贴图
uniform sampler2D noise_texture;
// 外部参数：溶解进度，从 0.0 (未溶解) 到 1.0 (完全溶解)
uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;
// 外部参数：溶解边缘的宽度
uniform float edge_size : hint_range(0.0, 1.0) = 0.05;
// 外部参数：边缘的颜色
uniform vec4 edge_color = vec4(1.0, 0.4, 0.0, 1.0); // 橙色

void fragment() {
    // 1. 获取原始纹理颜色
    vec4 base_color = texture(TEXTURE, UV);
    
    // 2. 从噪声贴图获取一个随机值 (作为遮罩)
    float noise_value = texture(noise_texture, UV).r;
    
    // 3. 核心逻辑：比较噪声值和溶解进度
    
    // 如果噪声值小于溶解进度，则该像素应该被“切除” (Alpha=0)
    if (noise_value < dissolve_progress) {
        // 判断是否位于边缘 (即在 dissolve_progress - edge_size 和 dissolve_progress 之间)
        if (noise_value > dissolve_progress - edge_size) {
            // 边缘像素：设置为边缘颜色，但保持一定的透明度 (edge_color.a)
            COLOR = edge_color;
        } else {
            // 完全切除的部分：透明度为 0
            discard; // 抛弃此像素，不绘制任何东西
        }
    } else {
        // 未被溶解的部分：正常绘制
        COLOR = base_color;
    }
}