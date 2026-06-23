shader_type canvas_item;

uniform float wobble_strength : hint_range(0.0, 0.05) = 0.02;
uniform float wobble_speed : hint_range(0.0, 20.0) = 12.0;

void fragment() {
    vec2 offset = vec2(
        sin(TIME * wobble_speed + UV.y * 15.0),
        sin(TIME * wobble_speed * 1.3 + UV.x * 15.0)
    ) * wobble_strength;
    
    COLOR = texture(TEXTURE, UV + offset);
}