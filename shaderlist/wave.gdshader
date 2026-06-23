// 可调节版本
shader_type canvas_item;
uniform float time;
uniform float frequency : hint_range(1.0, 50.0, 1.0) = 10.0;
uniform float amplitude : hint_range(0.0, 0.2, 0.005) = 0.05;
uniform float speed : hint_range(0.0, 5.0, 0.1) = 1.0;

void fragment() {
    // 使用可调节参数
    vec2 uv = UV + vec2(
        sin(UV.y * frequency + time * speed) * amplitude, 
        0.0
    );
    COLOR = texture(TEXTURE, uv);
}