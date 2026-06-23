shader_type canvas_item;

uniform bool hide = false;
uniform bool invert = false;
uniform vec4 color = vec4(1.0);
uniform float strength = 0.2;

void fragment() {
    vec4 pixel = texture(TEXTURE, UV);
    
    if (hide) {
        COLOR = pixel;
        //return;
    }
    
    // 计算颜色距离和灰度值
    float color_distance = distance(pixel.rgb, color.rgb);
    vec3 grayscale = vec3(dot(pixel.rgb, vec3(0.299, 0.587, 0.114)));
    
    // 原始效果：接近目标颜色的区域变灰
    // 反转效果：接近目标颜色的区域保持彩色，其他区域变灰
    float range = 1.0 - step(color_distance, strength);
    
    if (invert) {
        range = 1.0 - range; // 反转效果
    }
    
    // 混合原始颜色和灰度
    vec3 result = mix(grayscale, pixel.rgb, range);
    
    COLOR = vec4(result, pixel.a);
}