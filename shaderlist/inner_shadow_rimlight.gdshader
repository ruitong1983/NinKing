shader_type canvas_item;
// Inner Shadow & Rimlight Shader
// Creates inner shadow depth and rim lighting effects
// BY MABLE

group_uniforms General;
uniform float blur_strength : hint_range(0.0,5.0,0.01) = 0.25;

group_uniforms Shadow_Settings;
uniform float inline_scale :hint_range(1.0,2.0) = 1.0;
uniform float strength : hint_range(0.0,5.0) = 1.0;
uniform bool affect_black = false;
uniform bool pixel_perfect = false;

group_uniforms Rimlight_Settings;
uniform float rim_mix : hint_range(-10.0, 10.0, 0.1) = 2.0;
uniform vec3 effect_color : source_color = vec3(0.5);
uniform float effect_angle : hint_range(-360, 360,0.1) = 0.0;
uniform float effect_distance : hint_range(0.0,50.0,0.1) = 0.0;

// UV clamping with edge softness
float clamp_uv(vec2 uv, float alpha)
{
	float edge_softness = 0.05 * blur_strength;
	float fade_x = smoothstep(0.0, edge_softness, uv.x) * (1.0 - smoothstep(1.0 - edge_softness, 1.0, uv.x));
	float fade_y = smoothstep(0.0, edge_softness, uv.y) * (1.0 - smoothstep(1.0 - edge_softness, 1.0, uv.y));
	float fade = fade_x * fade_y;
	return alpha * fade;
}

// Directional blur algorithm
// Based on: https://www.shadertoy.com/view/Xltfzj and https://xorshaders.weebly.com/tutorials/blur-shaders-5-part-2
vec4 apply_blur(sampler2D tex, vec2 uv, float blur_value){
	float pi = PI * 2.0;
	vec2 texel_size = 1.0 / vec2(textureSize(tex, 0));
	float directions = 12.0;
	float quality = 6.0;
	float size = 8.0 * blur_value;

	vec2 radius = size / texel_size.xy;
	vec4 color = texture(tex, uv);
	for(float d = 0.0; d < pi; d += pi / directions)
	{
		for(float i = 1.0 / quality; i <= 1.0; i += 1.0 / quality)
		{
			vec2 sample_uv = uv + vec2(cos(d), sin(d)) * radius * i;
			color += texture(tex, sample_uv);
		}
	}
	color /= quality * directions + 1.0;
	return color;
}

// Generate inner shadow and rimlight effect
vec3 generate_effect(sampler2D tex, vec2 original_uv, float angle, float distance){
	vec2 texel_size = 1.0 / vec2(textureSize(tex, 0));
	vec2 uv = original_uv;
	
	if (pixel_perfect) {
		uv = floor(uv / texel_size + 0.5) * texel_size;
	}
	
	mat2 scale_matrix = mat2(vec2(inline_scale + (blur_strength / 100.0), 0.0), 
	                        vec2(0.0, inline_scale + (blur_strength / 100.0)));
	uv -= 0.5;
	vec2 rotation = vec2(cos(-angle / 100.0), sin(-angle / 100.0));
	uv = uv * scale_matrix;
	uv += 0.5;
	uv += (rotation * texel_size) * distance;

	// Generate blurred effect
	vec4 inner_effect = apply_blur(tex, uv, abs(sin(blur_strength * 0.00001)));
	inner_effect.rgb = vec3(0.0);
	inner_effect.a = clamp_uv(uv, inner_effect.a);
	
	// Create effect blend
	vec4 base_effect = texture(tex, original_uv);
	base_effect.rgb = vec3(1.0);

	float blend_factor = smoothstep(1.65, rim_mix - 1.15, inner_effect.a / 0.5);
	vec3 effect_blend = mix(inner_effect, base_effect, blend_factor).rgb;

	return effect_blend * strength;
}

// Mix effect with base color
vec3 mix_effect_with_base(vec3 base_color, vec3 effect_value){
	float factor = affect_black ? 1.0 : smoothstep(0.05, 0.5, length(base_color));
	return mix(base_color, base_color + effect_value, factor);
}

void fragment() {
	// Store original clear color
	vec4 original_color = COLOR;
	
	// Apply inner shadow and rimlight effect
	if (abs(inline_scale) > 1.0 || abs(effect_distance) > 0.0001) {
		vec3 effect = generate_effect(TEXTURE, UV, effect_angle, effect_distance);
		effect *= effect_color;
		
		// Mix effect with original clear image
		COLOR.rgb = mix_effect_with_base(original_color.rgb, effect);
	}
	
	// Global blur removed to keep original image clear
	// Effect already has blur applied in generate_effect function
}