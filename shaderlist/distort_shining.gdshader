shader_type canvas_item;

//const float PI = 3.141516;

uniform float speed = 1.0;
uniform vec4 tint  = vec4(1.0, 1.0, 0.0, 1.0);
uniform float span : hint_range(0.1, 1.0) = 0.3;
uniform float seed = 0.0;

float get_random(vec2 coord) {
    return fract(sin(dot(coord, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec4 colour = texture(TEXTURE, UV);
    
    if (colour.a > 0.0) {
        // 使用UV和种子生成随机值，确定动画类型
        float random_val = get_random(UV + vec2(seed));
        float animation_blend = fract(TIME * 0.3 + random_val * 2.0);
        int animation_type = int(random_val * 4.0);
        
        // 基础时间动画
        float time_offset = sin(TIME * PI * speed + random_val * PI * 2.0);
        
        if (animation_type == 0) {
            // 亮度着色动画
            float lum = 0.299 * colour.r + 0.587 * colour.g + 0.114 * colour.b;
            float target = (time_offset * 0.5 + 0.5) * (1.0 + span);
            float mx = clamp(1.0 - abs(lum - target) / span, 0.0, 1.0);
            colour.rgb = mix(colour.rgb, tint.rgb, mx);
        }
        else if (animation_type == 1) {
            // 偏移动画（使用混合值平滑过渡）
            vec2 offset = vec2(time_offset * 0.1, 0.0);
            if (animation_blend > 0.5) {
                offset = vec2(0.0, time_offset * 0.1);
            }
            colour = texture(TEXTURE, UV + offset);
        }
        else if (animation_type == 2) {
            // 颜色旋转动画
            vec3 shifted = colour.rgb;
            float rotation = floor(animation_blend * 3.0);
            if (rotation < 1.0) shifted = colour.gbr;
            else if (rotation < 2.0) shifted = colour.brg;
            colour.rgb = mix(colour.rgb, shifted, 0.7);
        }
        else {
            // 脉冲动画
            float pulse = (sin(TIME * PI * speed * 2.0) * 0.5 + 0.5) * 0.3;
            colour.rgb *= (1.0 + pulse);
        }
    }
    
    COLOR = colour;
}