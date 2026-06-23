shader_type canvas_item;

uniform float paper_strength : hint_range(0.0, 1.0) = 0.4;
uniform float noise_scale : hint_range(1.0, 20.0) = 8.0;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    vec2 paper_uv = UV * noise_scale;
    float paper = hash(floor(paper_uv));
    paper = smoothstep(0.4, 0.6, paper);
    col.rgb *= 1.0 - paper * paper_strength;
    COLOR = col;
}