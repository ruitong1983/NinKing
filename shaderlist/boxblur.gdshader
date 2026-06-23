shader_type canvas_item;
// 格式：hint_range(最小值, 最大值, 步长)
// 示例：0~0.02范围，步长0.001（UV坐标是0~1，blur_size过大会糊成黑块，建议0~0.02）
uniform float blur_size : hint_range(0.0, 1.0, 0.001) = 0.005;

void fragment() {
    vec4 color = vec4(0.0);
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            color += texture(TEXTURE, UV + vec2(float(x), float(y)) * blur_size);
        }
    }
    COLOR = color / 9.0;
}