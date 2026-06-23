shader_type canvas_item;

// 统一变量：辉光颜色
uniform vec4 glow_color = vec4(1.0, 0.8, 0.2, 1.0); // 默认金色光芒

// 统一变量：闪烁频率 (Hz)。值越高，闪烁越快。
uniform float blink_frequency : hint_range(0.5, 5.0) = 2.0;

// 统一变量：最大辉光强度。
uniform float max_intensity : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    // 1. 获取当前像素的原始颜色
    vec4 base_color = texture(TEXTURE, UV);
    
    // 2. 如果像素是透明的，则不应用辉光，直接丢弃或保持透明。
    if (base_color.a == 0.0) {
        // 如果您希望透明区域保持不变，可以使用 base_color;
        // 如果您希望透明区域被丢弃 (不绘制)，可以使用 discard;
        COLOR = base_color;
        //return; 
    }
    
    // 3. 计算时间函数，获得周期性变化的值 (Ping-Pong 效果)
    
    // a. 结合频率和时间
    float time_factor = TIME * blink_frequency; 
    
    // b. 使用 sin 函数，结果在 [-1, 1] 之间
    float sin_value = sin(time_factor);
    
    // c. 将 sin_value 映射到 [0, 1] 之间 (像呼吸灯效果，从暗到亮再到暗)
    // 0.5 * (sin_value + 1.0)
    float blink_factor = 0.5 * (sin_value + 1.0); 

    // 4. 计算最终的辉光颜色
    // 辉光强度 = blink_factor (0到1) * max_intensity (最大强度)
    vec3 emission_color = glow_color.rgb * blink_factor * max_intensity;
    
    // 5. 将辉光叠加到原始颜色上
    // 使用加法实现自发光效果：物体颜色 + 辉光颜色
    vec3 final_rgb = base_color.rgb + emission_color;
    
    // 6. 输出最终颜色 (保持原始 Alpha)
    COLOR = vec4(final_rgb, base_color.a);
}