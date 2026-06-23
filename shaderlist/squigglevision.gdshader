shader_type canvas_item;
render_mode world_vertex_coords;

group_uniforms Squiggle;
/**
 * Noise texture X scale - larger values make the squiggles smaller and more frequent
 */
uniform float scale_x : hint_range(0.1, 10.0) = 1.0 ;
/**
 * Noise texture Y scale - larger values make the squiggles smaller and more frequent
 */
uniform float scale_y  : hint_range(0.1, 10.0) = 1.0;
/**
 * Distortion strength - higher values create more pronounced squiggles
 */
uniform float strength : hint_range(0.0, 5.0) = 1.0 ;
/**
 * Animation speed in frames per second
 */
uniform float fps  : hint_range(0.0, 60.0) = 6.0;
/**
 * Base squiggle intensity multiplier
 */
uniform float intensity : hint_range(0.0, 0.05) = 0.005 ;
/**
 * Noise texture (grayscale recommended)
 */
uniform sampler2D noise : filter_linear, repeat_enable;
group_uniforms;

// Use irrational constants for unique squiggles every frame
#define OFFSET_MULTIPLIER vec2(PI, E)
#define NOISE_RANGE 4.0 * PI

varying vec4 vertex_color;
varying vec2 world_uv;

void vertex() {
	vertex_color = COLOR;
	
	// Calculate world-space UVs for consistent scaling
	// Subtract object position to keep pattern attached to object
	vec2 object_origin = MODEL_MATRIX[3].xy;
	vec2 local_vertex = VERTEX - object_origin;
	
	// Normalize by noise texture size and user scale
	vec2 noise_tex_size = vec2(textureSize(noise, 0));
	vec2 scale = vec2(scale_x, scale_y);
	world_uv = local_vertex / (noise_tex_size * scale);
}

void fragment() {
	// Calculate time-based offset with frame discretization
	float frame_time = floor(TIME * fps);
	vec2 noise_offset = frame_time * OFFSET_MULTIPLIER;
	
	// Sample noise and convert to direction vector
	float noise_value = texture(noise, world_uv + noise_offset).r;
	float angle = noise_value * NOISE_RANGE;
	vec2 direction = vec2(cos(angle), sin(angle));
	
	// Apply distortion to UV coordinates
	vec2 distorted_uv = UV + direction * strength * intensity;
	
	// Sample texture with distortion and apply vertex coloring
	vec4 tex_color = texture(TEXTURE, distorted_uv);
	COLOR = tex_color * vertex_color;
}