shader_type canvas_item;

uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float shine_progress : hint_range(-1.0, 1.0, 0.001) = 0.0;
uniform float shine_size : hint_range(0.01, 1.0, 0.01) = 0.1;
uniform float shine_angle : hint_range(0.0, 360.0, 0.1) = 45.0; 
uniform float softness : hint_range(0.0, 0.1, 0.01) = 0.02;
uniform float speed : hint_range(0.0, 5.0, 0.1) = 1.0;
uniform bool loop_enabled = false;
uniform bool one_way_loop = false;
uniform float loop_direction : hint_range(-1.0, 1.0, 0.1) = 1.0; // 新增：循环方向控制

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    
    if (tex.a < 0.01) {
        COLOR = vec4(0.0);
        //return;
    }
    
    vec4 original_color = tex * COLOR;
    
    // 计算最终进度
    float final_progress;
    if (loop_enabled) {
        if (one_way_loop) {
            // 单向循环
            float cycle = fract(TIME * speed);
            
            // 根据方向参数调整循环
            if (loop_direction >= 0.0) {
                // 正向循环：-1 -> 1
                final_progress = cycle * 2.0 - 1.0;
            } else {
                // 反向循环：1 -> -1
                final_progress = 1.0 - cycle * 2.0;
            }
        } else {
            // 来回循环：使用正弦波
            final_progress = sin(TIME * speed * 3.14159);
        }
    } else {
        final_progress = shine_progress;
    }
    
    // 使用UV坐标（0到1）
    vec2 box_uv = UV;
    
    // 计算方向向量
    float rad = radians(shine_angle);
    vec2 dir = normalize(vec2(cos(rad), sin(rad)));
    float projection = dot(box_uv, dir);
    
    // 计算四个角的投影，确定投影范围
    float p1 = dot(vec2(0.0, 0.0), dir);
    float p2 = dot(vec2(1.0, 0.0), dir);
    float p3 = dot(vec2(0.0, 1.0), dir);
    float p4 = dot(vec2(1.0, 1.0), dir);
    
    float min_dist = min(min(p1, p2), min(p3, p4));
    float max_dist = max(max(p1, p2), max(p3, p4));
    float center_dist = (min_dist + max_dist) * 0.5;
    
    // 根据progress计算闪光带位置
    float target_pos;
    if (final_progress < 0.0) {
        target_pos = mix(min_dist, center_dist, final_progress + 1.0);
    } else {
        target_pos = mix(center_dist, max_dist, final_progress);
    }
    
    // 创建闪光带（带柔和边缘）
    float shine = smoothstep(target_pos, target_pos + softness, projection) 
                - smoothstep(target_pos + shine_size, target_pos + shine_size + softness, projection);
    
    shine = clamp(shine, 0.0, 1.0);
    
    COLOR = original_color;
    
    if (shine > 0.0) {
        vec3 blended = mix(COLOR.rgb, shine_color.rgb, shine_color.a * shine);
        COLOR.rgb = mix(COLOR.rgb, blended, shine * tex.a);
    }
}