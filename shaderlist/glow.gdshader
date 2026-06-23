shader_type canvas_item;

// 基础参数
uniform bool allow_out_of_bounds = true;

// 辉光参数（新增衰减强度控制）
uniform float glow_strength: hint_range(0.0, 2.0 ) = 1.0;
uniform float glow_range: hint_range(0.0, 150.0, 1.0) = 4.0;
uniform vec4 glow_color: source_color = vec4(1.0, 1.0, 0.8, 1.0);
// 新增：衰减陡峭度（值越大，衰减越快，建议1.0-5.0）
uniform float glow_falloff_power: hint_range(1.0, 20.0, 0.1) = 2.0;

bool is_inside_usquare(vec2 x) {
	return x == clamp(x, vec2(0.0), vec2(1.0));
}

vec4 blend(vec4 bottom, vec4 top) {
    float alpha = top.a + bottom.a * (1.0 - top.a);
    if (alpha < 0.0001) return vec4(0.0);
    vec3 color = mix(bottom.rgb * bottom.a, top.rgb, top.a) / alpha;
    return vec4(color, alpha);
}

// 修改后：支持幂次衰减的函数
float glow_falloff(float distance, float range, float falloff_power) {
    // 1. 基础线性衰减
    float linear_falloff = 1.0 - smoothstep(0.0, range, distance);
    // 2. 幂次运算强化衰减（核心修改）
    return pow(linear_falloff, falloff_power);
}

void vertex() {
	if (allow_out_of_bounds) {
		VERTEX += (UV * 2.0 - 1.0) * glow_range;
	}
}

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	vec2 uv = UV;

	if (allow_out_of_bounds) {
		float total_range = glow_range;
		vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(total_range * 2.0));
		uv = (uv - texture_pixel_size * total_range) * TEXTURE_PIXEL_SIZE / texture_pixel_size;

		if (is_inside_usquare(uv)) {
			texture_color = texture(TEXTURE, uv);
		} else {
			texture_color = vec4(0.0);
		}
	}

	// 辉光计算（调用修改后的衰减函数）
	float glow_alpha = 0.0;
	if (glow_range > 0.0 && glow_strength > 0.0 && glow_color.a > 0.0) {
		for (float y = 1.0; y <= glow_range; y++) {
			for (float x = 0.0; x <= y; x++) {
				float distance = length(vec2(x, y));
				if (distance > glow_range) break;

				// 关键修改：传入衰减陡峭度参数
				float falloff = glow_falloff(distance, glow_range, glow_falloff_power);
				if (falloff <= 0.001) continue;

				float look_at_alpha;
				vec2 look_at_uv[8] = {
					uv + vec2(x, y) * TEXTURE_PIXEL_SIZE,
					uv + vec2(-x, y) * TEXTURE_PIXEL_SIZE,
					uv + vec2(x, -y) * TEXTURE_PIXEL_SIZE,
					uv + vec2(-x, -y) * TEXTURE_PIXEL_SIZE,
					uv + vec2(y, x) * TEXTURE_PIXEL_SIZE,
					uv + vec2(-y, x) * TEXTURE_PIXEL_SIZE,
					uv + vec2(y, -x) * TEXTURE_PIXEL_SIZE,
					uv + vec2(-y, -x) * TEXTURE_PIXEL_SIZE
				};

				for (int i = 0; i < 8; i++) {
					if (is_inside_usquare(look_at_uv[i])) {
						look_at_alpha = texture(TEXTURE, look_at_uv[i]).a;
						float contribution = look_at_alpha * falloff * glow_strength;
						if (contribution > glow_alpha) glow_alpha = contribution;
						if (glow_alpha >= 1.0) break;
					}
				}
				
				if (glow_alpha >= 1.0) break;
			}
			
			if (glow_alpha >= 1.0) break;
		}
	}

	vec4 glow_layer = vec4(glow_color.rgb, glow_alpha * glow_color.a);
	COLOR = blend(glow_layer, texture_color);
}