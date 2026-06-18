shader_type canvas_item;

// 统一变量：扭曲的强度。值越大，扭曲越剧烈。
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.03;

// 统一变量：扭曲的速度。值越大，水流动的越快。
uniform float distortion_speed : hint_range(0.1, 5.0) = 1.0;

// 统一变量：波纹的频率/密度。值越大，波纹越密集。
uniform float wave_frequency : hint_range(1.0, 50.0) = 15.0;

void fragment() {
    // 1. 获取当前 UV 坐标
    vec2 uv = UV;

    // 2. 创建第一个波形 (水平方向波)
    // 结合时间、速度和频率
    float time_factor_a = TIME * distortion_speed;
    float wave_a = sin(uv.y * wave_frequency + time_factor_a); // 波形沿Y轴方向传播

    // 3. 创建第二个波形 (垂直方向波)，增加液体的随机感
    float time_factor_b = TIME * distortion_speed * 0.8; // 不同的速度
    float wave_b = cos(uv.x * wave_frequency * 0.7 + time_factor_b); // 不同的频率和cos函数

    // 4. 结合波形：将两个波形叠加
    // 将波形范围 [-1, 1] 归一化到 [-0.5, 0.5]，然后相加
    float total_wave = (wave_a * 0.5 + wave_b * 0.5);

    // 5. 计算 UV 偏移量
    // 使用 total_wave 乘以强度
    vec2 offset = vec2(total_wave, total_wave) * distortion_strength;

    // 6. 应用偏移到新的 UV 坐标
    // 我们可以让偏移只影响一个轴，例如只扭曲 X 轴来模拟水波纹：
    // new_uv.x = uv.x + total_wave * distortion_strength;
    // new_uv.y = uv.y;

    // 或者，为了更像液体或热浪，同时扭曲 X 和 Y 轴
    vec2 new_uv = uv + offset;

    // 7. 使用新的 UV 坐标采样原始纹理
    vec4 final_color = texture(TEXTURE, new_uv);

    // 8. 输出最终颜色
    COLOR = final_color;
}