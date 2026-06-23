shader_type canvas_item;

uniform float ripple_strength : hint_range(0.0, 0.2) = 0.02;
uniform float ripple_speed : hint_range(0.0, 5.0) = 1.5;
uniform float ripple_density : hint_range(5.0, 50.0) = 10.0;
uniform float decay_factor : hint_range(0.0, 10.0) = 3.0; // 新增：衰减系数
uniform float center_wobble : hint_range(0.0, 1.0) = 0.02; // 新增：中心摆动幅度

void fragment() {
    vec2 uv = UV;
    
    // 中心扰动：随时间摆动的中心点
    vec2 center = vec2(0.5) + vec2(sin(TIME), cos(TIME * 0.7)) * center_wobble;
    
    // 计算到动态中心的距离
    float dist = length(uv - center);
    
    // 距离衰减：离中心越远效果越弱
    float decay = 1.0 / (1.0 + decay_factor * dist);
    
    // 计算波纹偏移（带衰减）
    float ripple = sin(dist * ripple_density - TIME * ripple_speed) 
                   * ripple_strength * decay;
    
    // 应用波纹变形
    vec2 distorted_uv = uv + ripple * normalize(uv - center);
    
    vec4 color = texture(TEXTURE, distorted_uv);
    COLOR = color;
}