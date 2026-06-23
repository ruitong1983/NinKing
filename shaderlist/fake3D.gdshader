shader_type canvas_item;

uniform vec2 rect_size;

// Camera FOV
uniform float fov : hint_range(1, 179) = 90;
uniform bool cull_back = false;
// 移除原有的x_rot和y_rot，改为使用随机种子和动画参数
uniform float instance_id; // 每个实例的唯一ID
uniform float animation_speed : hint_range(0.0, 5.0) = 1.0; // 动画速度
uniform float animation_strength : hint_range(0.0, 1.0) = 0.1; // 动画强度
uniform float time_offset : hint_range(0.0, 10.0) = 0.0; // 时间偏移，用于错开动画相位

// At 0, the image retains its size when unrotated.
// At 1, the image is resized so that it can do a full
// rotation without clipping inside its rect.
uniform float inset : hint_range(0, 1) = 0.0;

varying flat vec2 o;
varying vec3 p;

// 伪随机数生成器
float rand(float n) {
    return fract(sin(n) * 43758.5453);
}

// 创建基于时间的随机旋转
vec2 get_random_rotation(float time, float id) {
    // 使用实例ID作为随机种子
    float seed = id;

    // 为每个实例生成不同的动画相位
    float phase_x = rand(seed) * 6.28318; // 0-2π
    float phase_y = rand(seed + 1.0) * 6.28318;

    // 为每个实例生成不同的动画频率
    float freq_x = 0.5 + rand(seed + 2.0) * 1.5;
    float freq_y = 0.5 + rand(seed + 3.0) * 1.5;

    // 计算基于时间的旋转角度
    float x_rot = sin(time * freq_x + phase_x) * animation_strength;
    float y_rot = cos(time * freq_y + phase_y) * animation_strength;

    // 转换为度数
    x_rot = degrees(x_rot);
    y_rot = degrees(y_rot);

    return vec2(x_rot, y_rot);
}

// Creates rotation matrix
void vertex(){
    // 计算基于时间的随机旋转
    float time = TIME * animation_speed + time_offset;
    vec2 rotation = get_random_rotation(time, instance_id);
    float x_rot = rotation.x;
    float y_rot = rotation.y;

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

    // to (rect_size is a uniform):
    VERTEX += (UV - 0.5) * rect_size * t * (1.0 - inset);
}

void fragment(){
    if (cull_back && p.z <= 0.0) discard;
    vec2 uv = (p.xy / p.z).xy - o;
    COLOR = texture(TEXTURE, uv + 0.5);
    COLOR.a *= step(max(abs(uv.x), abs(uv.y)), 0.5);
}