shader_type canvas_item;

#include "res://shaders/fake3d/fake3d_core.gdshaderinc"

// ⚠️ Godot 4.6.2 gl_compatibility 渲染器下 MODULATE uniform 有 bug
// (RGB 通道始终返回 1.0)，取消此行避免编译错误。
// 且因 MODULATE RGB 不生效，此调制本也无视觉效果。
// 未来切换 Vulkan 渲染器后可恢复: COLOR *= MODULATE;

void fragment() {
    if (cull_back && p.z <= 0.0) discard;
    vec2 uv = (p.xy / p.z).xy - o;
    COLOR = texture(TEXTURE, uv + 0.5);
    COLOR.a *= step(max(abs(uv.x), abs(uv.y)), 0.5);

    // 绿幕去背
    float dis = distance(COLOR.rgb, delete_color);
    if (dis <= delete_tolerance) COLOR.a = 0.0;
}
