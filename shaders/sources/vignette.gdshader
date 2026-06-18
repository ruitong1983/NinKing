shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 15.0) = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 vignette_rgb = vec4(0.0, 0.0, 0.0, 1.0);

float vignette(vec2 uv){
	uv *= 1.0 - uv.xy;
	float vignette = uv.x * uv.y * 15.0;
	return pow(vignette, vignette_intensity * vignette_opacity);
}

void fragment(){
	vec4 text = texture(TEXTURE, UV);
	
	// 应用晕影效果
	float vig = vignette(UV);
	text.rgb = mix(text.rgb * vignette_rgb.rgb, text.rgb, vig);
	
	COLOR = text;
}