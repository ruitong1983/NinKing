shader_type canvas_item;

// 统一变量：效果的中心点 (相对坐标，0.0-1.0)。
// vec2(0.5, 0.5) 是精灵的中心。
uniform vec2 center = vec2(0.5, 0.5);
//: hint_range(vec2(0.0), vec2(1.0)) = vec2(0.5, 0.5);

// 统一变量：效果影响的半径。
uniform float radius : hint_range(0.0, 1.0) = 0.4;

// 统一变量：效果的强度。
// 正值 (如 0.1-0.5) 产生膨胀效果。
// 负值 (如 -0.1 to -0.5) 产生液化/收缩效果。
uniform float strength : hint_range(-0.5, 0.5) = 0.2; // 默认膨胀效果

void fragment() {
    // 1. 计算当前像素的 UV 坐标相对于中心点的向量
    vec2 to_center = UV - center;

    // 2. 计算当前像素到中心点的距离
    float distance = length(to_center);

    // 3. 初始化新的 UV 坐标为当前 UV
    vec2 new_uv = UV;

    // 4. 只有在效果半径范围内才应用变形
    if (distance < radius) {
        // 计算距离在半径内的归一化值 (0.0 到 1.0)
        // 距离越近中心 (distance=0)，weight越接近1。
        // 距离越远中心 (distance=radius)，weight越接近0。
        float weight = 1.0 - (distance / radius);

        // 我们可以让强度根据距离以非线性方式衰减，例如平方
        // 这会使效果在中心更强，向边缘平滑过渡。
        weight = pow(weight, 2.0); // 可以尝试 pow(weight, 3.0) 甚至更高，看看效果

        // 5. 计算纹理坐标偏移量
        // to_center 是从 UV 指向中心点的向量，其方向需要反转才能向外推。
        // 或者，我们直接使用方向向量 to_center 本身 (从中心到 UV 的向量)。

        // 我们需要一个从中心点指向当前 UV 的单位方向向量
        vec2 direction = normalize(to_center);

        // 根据强度和权重计算偏移量
        // strength > 0 : 膨胀 (向外推)
        // strength < 0 : 液化 (向内拉)
        vec2 offset = direction * strength * weight;

        // 6. 应用偏移到新的 UV 坐标
        new_uv = UV + offset;
    }

    // 7. 使用新的 UV 坐标采样原始纹理，并输出颜色
    COLOR = texture(TEXTURE, new_uv);
}