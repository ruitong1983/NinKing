shader_type canvas_item;

uniform vec2 blur_center = vec2(0.5, 0.5);
uniform float blur_strength : hint_range(0, 2.0) = 0.05;
uniform int sample_count : hint_range(4, 32) = 16;
uniform bool outward_blur = true;  // true=向外，false=向内

void fragment() {
    vec2 uv = UV;
    vec4 final_color = vec4(0.0);
    
    // 计算方向
    vec2 to_center = blur_center - uv;
    vec2 direction = to_center * blur_strength;
    
    // 根据模式选择采样方向
    if(outward_blur) {
        direction = -direction;  // 反转方向：向外
    }
    
    for(int i = 0; i < sample_count; i++) {
        float t = float(i) / float(sample_count - 1);
        vec2 sample_uv = uv + direction * t;
        final_color += texture(TEXTURE, sample_uv);
    }
    
    final_color /= float(sample_count);
    COLOR = final_color;
}