shader_type canvas_item;

#include "res://shaders/fake3d/fake3d_core.gdshaderinc"

// ─── 阴影专属参数 ───
uniform bool selected = false;
uniform vec4 selected_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    if (cull_back && p.z <= 0.0) discard;
    vec2 uv = (p.xy / p.z).xy - o;
    COLOR = texture(TEXTURE, uv + 0.5);
    COLOR.a *= step(max(abs(uv.x), abs(uv.y)), 0.5);

    // 绿幕去背
    float dis = distance(COLOR.rgb, delete_color);
    if (dis <= delete_tolerance) COLOR.a = 0.0;

    // 阴影选中逻辑
    if (selected) COLOR = vec4(selected_color.x, selected_color.y, selected_color.z, sign(COLOR.a) * alpha);
    if (!selected) COLOR = vec4(0.0, 0.0, 0.0, sign(COLOR.a) * alpha);

    // Respect parent's modulate (enables grayed-out cards in deck viewer, etc.)
    COLOR *= MODULATE;
}
