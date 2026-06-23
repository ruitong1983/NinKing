shader_type canvas_item;

uniform sampler2D gradient;

void fragment() {
	//1st step: Set the sprite to Gray tones
	float GrayValue = (COLOR.r + COLOR.g + COLOR.b)/3.0;
	COLOR = vec4(GrayValue,GrayValue,GrayValue,1.0);

	//2nd step: Swap palette
	vec2 new_uv = vec2(GrayValue);
	vec4 gradient_color = texture(gradient, new_uv);
	COLOR = vec4(gradient_color.rgb,1.0)*COLOR;

	//Erase the contour for png images
	vec4 textura = texture(TEXTURE,UV);
	COLOR.a = COLOR.a * textura.a;
}