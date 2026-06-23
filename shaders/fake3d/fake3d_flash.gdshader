shader_type canvas_item;

#include "res://shaders/fake3d/fake3d_core.gdshaderinc"

// =====================
// 闪光效果参数
// =====================
uniform bool use_flash = false;

// 局部进行闪光效果处理
uniform int flash_filter_type : hint_range(0, 2) = 0;
uniform vec3 filter_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float filter_tolerance : hint_range(0, 1) = 0.2;

uniform int flash_type : hint_range(0, 2) = 0;
uniform vec4 pure_flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D gradient_texture : filter_linear, repeat_enable;

uniform sampler2D mask_texture : filter_linear_mipmap;
uniform float mask_scale : hint_range(0.1, 5.0) = 1.0;
uniform float speed : hint_range(0.1, 5.0) = 0.1;
uniform float stripe_spacing : hint_range(0.1, 50.0) = 6.5;
uniform float stripe_width : hint_range(0.1, 20.0) = 1.5;
uniform float stripe_offset : hint_range(0.0, 1.0) = 0.55;
uniform float gradient_offset : hint_range(0.0, 1.0) = 0.5;
uniform float gradient_scale : hint_range(0.1, 3.0) = 1.414;
uniform float move_speed : hint_range(0.0, 5.0) = 5.0;
uniform float intensity : hint_range(0.0, 2.0) = 0.5;
uniform float angle : hint_range(0.0, 360.0) = 45.0;
uniform bool one_way_loop = false;
uniform float loop_direction : hint_range(-1.0, 1.0) = 1.0;
uniform float softness : hint_range(0.0, 0.5, 0.01) = 0.0;

// =====================
// 旋转工具函数
// =====================
vec2 rotate(vec2 uv, vec2 pivot_r, float rot_angle) {
    float s = sin(rot_angle);
    float c = cos(rot_angle);
    mat2 rot = mat2(vec2(c, -s), vec2(s, c));
    return (rot * (uv - pivot_r)) + pivot_r;
}

void fragment() {
    if (cull_back && p.z <= 0.0) discard;
    vec2 uv = (p.xy / p.z).xy - o;
    COLOR = texture(TEXTURE, uv + 0.5);
    COLOR.a *= step(max(abs(uv.x), abs(uv.y)), 0.5);

    // 绿幕去背
    float dis = distance(COLOR.rgb, delete_color);
    if (dis <= delete_tolerance) COLOR.a = 0.0;

    // 闪光效果范围筛选
    float ddis = distance(COLOR.rgb, filter_color);
    bool fil_cons = true;
    if (flash_filter_type == 0) {
        fil_cons = true;
    } else if (flash_filter_type == 1) {
        if (ddis <= filter_tolerance) fil_cons = false;
    } else if (flash_filter_type == 2) {
        if (ddis > filter_tolerance) fil_cons = false;
    }

    // 闪光效果实现
    if (use_flash && COLOR.a > 0.0 && fil_cons) {
        float rad = radians(angle);
        vec2 dir = vec2(cos(rad), sin(rad));

        float rotation_factor = (x_rot * sin(rad) - y_rot * cos(rad)) * speed;
        float time_factor;
        if (one_way_loop) {
            float half = TIME * speed * 0.5;
            float tri = 1.0 - abs(fract(half) * 2.0 - 1.0);
            time_factor = mix(1.0 - tri, tri, loop_direction * 0.5 + 0.5);
        } else {
            time_factor = TIME * 2.0 * move_speed;
            time_factor *= sign(loop_direction);
        }
        rotation_factor += time_factor * speed;

        vec2 mask_uv = (uv + 0.5);
        mask_uv = (mask_uv - 0.5) * mask_scale + 0.5;

        float mask_alpha = texture(mask_texture, mask_uv).a;

        float stripe = sin(dot(uv + 0.5, dir) * stripe_spacing + (rotation_factor + 2.0 * stripe_offset) * PI) * 0.5 + 0.5;
        float flash = pow(stripe, stripe_width) * intensity * mask_alpha;

        if (softness > 0.005) {
            flash = smoothstep(0.5 - softness, 0.5 + softness, stripe) * intensity * mask_alpha;
        }

        if (flash_type == 0) {
            COLOR.rgb = mix(COLOR.rgb, pure_flash_color.rgb, flash * pure_flash_color.a);
        } else if (flash_type == 1) {
            float hue = fract(dot(uv + 1.0, dir));
            vec3 rainbow = vec3(
                0.5 + 0.5 * sin(6.2831 * hue),
                0.5 + 0.5 * sin(6.2831 * (hue + 0.33)),
                0.5 + 0.5 * sin(6.2831 * (hue + 0.66))
            );
            COLOR.rgb = mix(COLOR.rgb, rainbow, flash);
        } else {
            float gradient_uv_x = fract(dot(uv, dir) / gradient_scale + gradient_offset);
            vec4 gradient_color = texture(gradient_texture, vec2(gradient_uv_x, 0.0));
            COLOR.rgb = mix(COLOR.rgb, gradient_color.rgb, flash * gradient_color.a);
        }
    }

    // ⚠️ Godot 4.6.2 gl_compatibility 渲染器下 MODULATE uniform 有 bug
    // (RGB 通道始终返回 1.0)，取消此行避免编译错误。
    // 未来切换 Vulkan 渲染器后可恢复: COLOR *= MODULATE;
}
