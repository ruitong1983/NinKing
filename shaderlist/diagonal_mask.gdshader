// 2D Diagonal Borders Masking Shader
// Modified from https://godotshaders.com/shader/hex-mask-border-outline-shader/
shader_type canvas_item;
const float M  = -1.0; // Angle of diagonal line
uniform float effect : hint_range( 0.0, 0.5 ) = 0.5; // how much

void fragment() {
	// Pull in the texture
	COLOR = texture( TEXTURE, UV );
	// Need a copy for original alpha values
	vec4 color = texture( TEXTURE, UV );
	// Set everything to transparent
	COLOR.a = color.a * 0.0;
	// Map current point to first quadrant
	float x0 = min(UV.x, 1.0 - UV.x);
	float y0 = min(UV.y, 1.0 - UV.y);
	// Compute diagonal line through UV.x,UV.y depending on the effect
	float m = M;
	float m0 = -1.0 / m;
	float b0 = effect + (y0 - m0 * x0);
	// Find x,y = intersection of edge through UV.x,UV.y
	float x = ( 0.5 - b0 ) / ( m0 - m );
	float y = m0 * x + b0;
	// Are we inside the diagonal box?
	if ( x0 >= x && y0 >= 0.0 ) {
		float d = distance( vec2( x, y ), vec2( x0, y0 ) );
		COLOR.a = color.a * 1.0;
	}
}