shader_type canvas_item;

uniform float outline_thickness : hint_range(0.001, 0.02) = 0.004;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float shake_strength : hint_range(0.0, 0.005) = 0.002;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 shake = vec2(rand(UV + TIME), rand(UV + TIME + 100.0)) * shake_strength;
    float alpha = texture(TEXTURE, UV + shake).a;
    
    float outline = 0.0;
    for (float i = -1.0; i <= 1.0; i += 1.0) {
        for (float j = -1.0; j <= 1.0; j += 1.0) {
            outline += texture(TEXTURE, UV + vec2(i, j) * outline_thickness + shake).a;
        }
    }
    
    if (outline > 0.1 && alpha < 0.5) {
        COLOR = outline_color;
    } else {
        COLOR = texture(TEXTURE, UV);
    }
}