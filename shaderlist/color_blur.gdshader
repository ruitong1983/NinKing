shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 8.0) = 0.0;
uniform float mix_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color_over : source_color = vec4(1.0, 0.5, 0.2, 1.0); // 暖色调
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;

void fragment() {
    // 基础LOD模糊
    vec4 original = texture(TEXTURE, UV);
    vec4 blurred = textureLod(TEXTURE, UV, blur_amount * 1.5); // 增强模糊强度
    
    // 可选：添加一些额外的简单模糊来柔化LOD的硬边
    if (blur_amount > 0.0) {
        vec2 pixel_size = TEXTURE_PIXEL_SIZE * 0.5;
        blurred += texture(TEXTURE, UV + vec2(pixel_size.x, 0.0));
        blurred += texture(TEXTURE, UV - vec2(pixel_size.x, 0.0));
        blurred += texture(TEXTURE, UV + vec2(0.0, pixel_size.y));
        blurred += texture(TEXTURE, UV - vec2(0.0, pixel_size.y));
        blurred /= 5.0;
    }
    
    // 调整亮度和饱和度
    vec3 color_blurred = blurred.rgb;
    float luma = dot(color_blurred, vec3(0.299, 0.587, 0.114));
    color_blurred = mix(vec3(luma), color_blurred, saturation) * brightness;
    
    // 混合颜色
    vec3 final_color = mix(color_blurred, color_over.rgb, mix_amount * color_over.a);
    
    // 保持原始Alpha或使用混合Alpha
    float final_alpha = mix(original.a, color_over.a, mix_amount);
    
    COLOR = vec4(final_color, final_alpha);
}