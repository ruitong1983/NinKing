shader_type canvas_item;

// 简化参数
uniform float line_thickness : hint_range(0.5, 3.0) = 1.2;
uniform float shading_power : hint_range(0.5, 2.0) = 1.2;

// 程序化噪点
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void fragment() {
    // 原始颜色
    vec4 col = texture(TEXTURE, UV);
    
    // 亮度
    float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    
    // 简单边缘检测
    vec2 texel = vec2(1.0) / TEXTURE_PIXEL_SIZE.xy * line_thickness * 0.002;
    
    float left = dot(texture(TEXTURE, UV + vec2(-texel.x, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
    float right = dot(texture(TEXTURE, UV + vec2(texel.x, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
    float top = dot(texture(TEXTURE, UV + vec2(0.0, -texel.y)).rgb, vec3(0.299, 0.587, 0.114));
    float bottom = dot(texture(TEXTURE, UV + vec2(0.0, texel.y)).rgb, vec3(0.299, 0.587, 0.114));
    
    float edge = abs(left - right) + abs(top - bottom);
    edge = smoothstep(0.1, 0.3, edge);
    
    // 素描阴影
    float shade = 1.0 - lum;
    shade = pow(shade, shading_power);
    
    // 铅笔纹理
    float grain = hash(UV * 100.0) * 0.15;
    
    // 组合效果
    float result = 0.9 - shade * 0.7 + grain * 0.1;
    
    // 强化边缘
    result = mix(result * 0.4, result, 1.0 - edge * 0.7);
    
    // 添加纸张感
    float paper = hash(UV * 50.0) * 0.05;
    result -= paper;
    
    COLOR = vec4(vec3(clamp(result, 0.0, 1.0)), col.a);
}