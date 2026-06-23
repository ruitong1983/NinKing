// kuwahara_soft.gdshader
shader_type canvas_item;

uniform int radius : hint_range(1, 8) = 4;
uniform float hardness : hint_range(0.1, 10.0) = 2.0;

void fragment() {
    vec2 uv = UV;
    vec2 texel_size = TEXTURE_PIXEL_SIZE;

    // 四个象限的统计
    vec3 m[4];
    vec3 s[4];
    int n[4];

    for (int i = 0; i < 4; i++) {
        m[i] = vec3(0.0);
        s[i] = vec3(0.0);
        n[i] = 0;
    }

    // 收集统计信息
    for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
            vec2 offset = vec2(float(dx), float(dy)) * texel_size;
            vec3 color = texture(TEXTURE, uv + offset).rgb;

            int q;
            if (dx < 0 && dy < 0) q = 0;
            else if (dx >= 0 && dy < 0) q = 1;
            else if (dx < 0 && dy >= 0) q = 2;
            else q = 3;

            m[q] += color;
            s[q] += color * color;
            n[q]++;
        }
    }

    // 软选择：加权混合所有象限
    vec3 final_color = vec3(0.0);
    float total_weight = 0.0;

    for (int i = 0; i < 4; i++) {
        if (n[i] > 0) {
            vec3 mean = m[i] / float(n[i]);
            vec3 variance = s[i] / float(n[i]) - mean * mean;
            float total_variance = variance.r + variance.g + variance.b;

            // 使用hardness控制选择的硬度
            float weight = exp(-hardness * total_variance);
            final_color += mean * weight;
            total_weight += weight;
        }
    }

    COLOR = vec4(final_color / total_weight, texture(TEXTURE, uv).a);
}