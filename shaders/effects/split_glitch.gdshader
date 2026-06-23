shader_type canvas_item;

// ===================== 可调节参数（编辑器滑动条） =====================
// 初始网格基础尺寸（控制UV量化的初始粒度）
uniform int grid_size_base : hint_range(1, 50, 1) = 10;
// 网格尺寸最大增量（控制gridSize的波动范围：base ~ base+max_add）
uniform int grid_size_max_add : hint_range(0, 100, 1) = 50;
// 整体扰动强度（越大纹理偏移越明显）
uniform float distort_strength : hint_range(0.0, 1.0, 0.01) = 0.1;
// 时间波动周期（秒，越小变化越快）
uniform float time_cycle : hint_range(1.0, 30.0, 0.1) = 5.0;
// Y轴波纹频率（越大波纹越密集）
uniform float wave_frequency : hint_range(5.0, 100.0, 1.0) = 25.0;
// 随机函数迭代次数（越多随机越混沌，性能略降）
uniform int random_iterations : hint_range(2, 20, 1) = 8;
// 随机系数1（控制随机值的混沌程度）
uniform float rand_coeff1 : hint_range(-100.0, 0.0, 0.1) = -38.0;
// 随机系数2（控制随机值的非线性程度）
uniform float rand_coeff2 : hint_range(0.0, 1.0, 0.01) = 0.2;
// UV范围限制（是否 clamp UV 避免纹理外采样）
uniform bool clamp_uv = true;

// 伪随机数生成函数（使用可调节参数）
float f(vec2 uv) {
    float c = 0.0;
    // 动态迭代次数（兼容GLSL ES 3.0的动态循环）
    for (int i = 0; i < 20; i++) {
        if (i >= random_iterations) break;
        c = fract(uv.x + c * rand_coeff1 + uv.y + c * uv.x * rand_coeff2);
    }
    return c;
}

void fragment() {
    // 1. 归一化UV（Godot内置UV，0~1）
    vec2 uv = UV;
    // 可选：宽高比校正（避免非正方形纹理畸变拉伸）
    // uv.x *= SCREEN_SIZE.x / SCREEN_SIZE.y;
    
    // 2. 动态扰动强度（随时间波动）
    float time_wave = abs(sin(TIME / time_cycle));
    float amount = time_wave * distort_strength;
    
    // 3. 网格量化 + 动态调整网格尺寸
    int gridSize = grid_size_base;
    // 第一次网格量化生成随机值
    float c = f(round(uv * float(gridSize)) / float(gridSize));
    // 动态调整网格尺寸（限制最大值避免溢出）
    int newGridSize = gridSize + int(round(c * float(grid_size_max_add)));
    // 第二次网格量化生成最终随机值
    c = f(round(uv * float(newGridSize)) / float(newGridSize));
    
    // 4. 计算畸变UV（带参数控制）
    vec2 distorted_uv = uv + vec2(
        c * amount,                // X轴偏移
        sin(c * wave_frequency) * amount  // Y轴波纹偏移
    );
    
    // 限制UV范围，避免采样到纹理外
    if (clamp_uv) {
        distorted_uv = clamp(distorted_uv, vec2(0.0), vec2(1.0));
    }
    
    // 5. 采样纹理并输出颜色
    vec3 col = texture(TEXTURE, distorted_uv).rgb;
    COLOR = vec4(col, 1.0);
}