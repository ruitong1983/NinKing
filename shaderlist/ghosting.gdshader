shader_type canvas_item;

uniform float ghost_intensity : hint_range(0.0, 1.0) = 0.1; // 鬼影强度
uniform float ghost_offset_x : hint_range(-1.0, 1.0) = 0.01; // 鬼影水平偏移
uniform float ghost_offset_y : hint_range(-1.0, 1.0) = 0.01; // 鬼影垂直偏移
uniform float ghost_fade : hint_range(0.0, 1.0) = 0.5; // 鬼影衰减程度（越大鬼影越淡）

void fragment() {
    vec2 uv = UV;
    vec4 base_color = texture(TEXTURE, uv); // 获取原始颜色

    // 计算鬼影的偏移位置
    vec2 ghost_uv = uv + vec2(ghost_offset_x, ghost_offset_y);

    // 获取偏移后的像素颜色
    vec4 ghost_color = texture(TEXTURE, ghost_uv);

    // 根据鬼影强度和衰减程度混合鬼影
    vec4 final_color = mix(base_color, ghost_color, ghost_intensity * ghost_fade);

    // 输出最终的颜色
    COLOR = final_color;
}
