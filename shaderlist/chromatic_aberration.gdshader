shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.6;
uniform float red_amount : hint_range(0.0, 0.1) = 0.01;
uniform float green_amount : hint_range(0.0, 0.1) = 0.007;
uniform float blue_amount : hint_range(0.0, 0.1) = 0.013;

uniform bool radial = true;
uniform float angle : hint_range(0.0, 10.0) = 0.0;

uniform float jitter_speed : hint_range(0.0, 10.0) = 0.0;
uniform float jitter_strength : hint_range(0.0, 0.02) = 0.0;

uniform int samples : hint_range(1, 8) = 2;

vec2 rotate(vec2 v, float a) {
    float c = cos(a);
    float s = sin(a);
    return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

void fragment() {
    vec2 uv = UV;
    vec4 base = texture(TEXTURE, uv);

    float t = TIME;
    vec2 jitter = vec2(0.0);
    if (jitter_speed > 0.0 && jitter_strength > 0.0) {
        jitter.x = sin(t * jitter_speed * 1.37) * jitter_strength;
        jitter.y = cos(t * jitter_speed * 1.13) * jitter_strength;
    }

    vec2 dir;
    if (radial) {
        vec2 center = vec2(0.5, 0.5);
        dir = normalize(uv - center + vec2(0.00001));
    } else {
        dir = vec2(cos(angle), sin(angle));
    }

    float i = clamp(intensity, 0.0, 1.0);

    vec3 acc = vec3(0.0);
    float total_weight = 0.0;

    for (int s = 0; s < samples; s++) {
        float f = float(s) / float(max(samples - 1, 1));
        float weight = 1.0 - f * 0.7;

        // 每个通道的偏移方向都旋转不同角度
        vec2 dirR = rotate(dir, 0.2);
        vec2 dirG = rotate(dir, -0.15);
        vec2 dirB = rotate(dir, 0.37);

        vec2 offR = dirR * red_amount * i * (0.2 + 0.8 * f) + jitter;
        vec2 offG = dirG * green_amount * i * (0.2 + 0.8 * f) + jitter;
        vec2 offB = dirB * blue_amount * i * (0.2 + 0.8 * f) + jitter;

        vec4 sampR = texture(TEXTURE, uv + offR);
        vec4 sampG = texture(TEXTURE, uv + offG);
        vec4 sampB = texture(TEXTURE, uv + offB);

        acc.r += sampR.r * weight;
        acc.g += sampG.g * weight;
        acc.b += sampB.b * weight;

        total_weight += weight;
    }

    acc /= max(total_weight, 1e-6);
    vec3 final_rgb = mix(base.rgb, acc, i);

    COLOR = vec4(final_rgb, base.a);
}
