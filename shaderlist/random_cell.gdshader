shader_type canvas_item;

// --- 用户参数 ---
uniform float intensity : hint_range(0.0, 1.0) = 0.5; // 效果整体强度
uniform float cell_size : hint_range(2.0, 128.0) = 32.0; // 分割网格的大小（像素块尺寸）
uniform float scramble_strength : hint_range(0.0, 1.0) = 0.8; // 像素块位移的随机强度
uniform float color_mix : hint_range(0.0, 1.0) = 0.3; // 颜色随机混合强度
uniform float rotation_chance : hint_range(0.0, 1.0) = 0.2; // 像素块随机旋转的概率
uniform float time_speed : hint_range(0.0, 5.0) = 1.0; // 随机模式变化速度

// --- 伪随机数生成器 ---
float hash(vec2 p) {
    p = fract(p * vec2(233.34, 851.73));
    p += dot(p, p + 23.45);
    return fract(p.x * p.y);
}

// --- 2D旋转函数 ---
vec2 rotateUV(vec2 uv, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(c * uv.x - s * uv.y, s * uv.x + c * uv.y);
}

void fragment() {
    vec2 uv = UV;
    
    // 1. 计算当前像素属于哪个网格块
    vec2 gridPos = floor(uv * vec2(textureSize(TEXTURE, 0)) / cell_size);
    
    // 2. 基于网格位置和时间为每个像素块生成一个“随机种子”
    float seed = hash(gridPos + floor(TIME * time_speed));
    
    // 3. 根据种子计算该像素块的随机位移目标
    // 将seed映射到一个更大的坐标空间，确保位移看起来足够随机和分散
    vec2 scrambleOffset = vec2(
        hash(vec2(seed, 0.1)) * 2.0 - 1.0,
        hash(vec2(seed, 0.2)) * 2.0 - 1.0
    ) * scramble_strength * intensity;
    
    // 4. 应用位移：计算该像素块应该去采样原图的哪个位置
    // 确保位移后的坐标仍在[0,1]范围内，并保留网格内的相对位置
    vec2 cellUV = fract(uv * vec2(textureSize(TEXTURE, 0)) / cell_size); // 像素在块内的相对坐标
    vec2 sourceUV = (gridPos + scrambleOffset) * (cell_size / vec2(textureSize(TEXTURE, 0))) + cellUV * (cell_size / vec2(textureSize(TEXTURE, 0)));
    
    // 5. 随机旋转（按概率）
    if (hash(vec2(seed, 0.3)) < rotation_chance * intensity) {
        float rotAngle = hash(vec2(seed, 0.4)) * 6.28318; // 0 到 2*PI
        // 以网格块中心为旋转中心
        vec2 centerOffset = cellUV - vec2(0.5);
        centerOffset = rotateUV(centerOffset, rotAngle);
        sourceUV = (gridPos + scrambleOffset) * (cell_size / vec2(textureSize(TEXTURE, 0))) + (centerOffset + vec2(0.5)) * (cell_size / vec2(textureSize(TEXTURE, 0)));
    }
    
    // 6. 颜色随机混合
    vec3 color = texture(TEXTURE, sourceUV).rgb;
    if (color_mix > 0.0) {
        vec3 mixColor = vec3(
            hash(vec2(seed, 0.5)),
            hash(vec2(seed, 0.6)),
            hash(vec2(seed, 0.7))
        );
        color = mix(color, mixColor, color_mix * intensity);
    }
    
    // 7. 最终输出（可在此处进行边缘处理或与原始图像混合）
    COLOR = vec4(color, 1.0);
}