// ============================================================
// Fake3D Core — 共享 vertex 变换 + 绿幕去除
// 被 fake3d.gdshader / fake3d_flash.gdshader / fake3d_shadow.gdshader
// 通过 #include 继承。
// 修改此文件同时影响三个 shader。
// ============================================================
// License: MIT (Hei)
// ============================================================

// ─── 基础透视参数 ───
uniform float fov : hint_range(1, 179) = 90;
uniform bool cull_back = true;
uniform float y_rot : hint_range(-180, 180) = 0.0;
uniform float x_rot : hint_range(-180, 180) = 0.0;

// At 0, the image retains its size when unrotated.
// At 1, the image is resized so that it can do a full
// rotation without clipping inside its rect.
uniform float inset : hint_range(0, 1) = 0.0;

// ─── 绿幕去背 ───
uniform vec3 delete_color : source_color = vec3(0.0, 0.5, 0.5);
uniform float delete_tolerance : hint_range(0, 1) = 0.2;

// ─── Varyings ───
varying flat vec2 o;
varying vec3 p;

// ─── Vertex 变换矩阵 ───
void vertex() {
    float sin_b = sin(y_rot / 180.0 * PI);
    float cos_b = cos(y_rot / 180.0 * PI);
    float sin_c = sin(x_rot / 180.0 * PI);
    float cos_c = cos(x_rot / 180.0 * PI);

    mat3 inv_rot_mat;
    inv_rot_mat[0][0] = cos_b;
    inv_rot_mat[0][1] = 0.0;
    inv_rot_mat[0][2] = -sin_b;

    inv_rot_mat[1][0] = sin_b * sin_c;
    inv_rot_mat[1][1] = cos_c;
    inv_rot_mat[1][2] = cos_b * sin_c;

    inv_rot_mat[2][0] = sin_b * cos_c;
    inv_rot_mat[2][1] = -sin_c;
    inv_rot_mat[2][2] = cos_b * cos_c;

    float t = tan(fov / 360.0 * PI);
    p = inv_rot_mat * vec3((UV - 0.5), 0.5 / t);
    float v = (0.5 / t) + 0.5;
    p.xy *= v * inv_rot_mat[2].z;
    o = v * inv_rot_mat[2].xy;

    VERTEX += (UV - 0.5) / TEXTURE_PIXEL_SIZE * t * (1.0 - inset);
}

// ─── Fragment 辅助：透视UV + 绿幕 ───
// 在 fragment() 中调用以下代码块：
//   if (cull_back && p.z <= 0.0) discard;
//   vec2 uv = (p.xy / p.z).xy - o;
//   COLOR = texture(TEXTURE, uv + 0.5);
//   COLOR.a *= step(max(abs(uv.x), abs(uv.y)), 0.5);
//   float dis = distance(COLOR.rgb, delete_color);
//   if (dis <= delete_tolerance) COLOR.a = 0.0;
