shader_type canvas_item;

// 热成像颜色渐变参数
uniform float temperature_min = 0.0;
uniform float temperature_max = 1.0;
uniform bool use_custom_colors = false;
uniform vec4 cold_color = vec4(0.0, 0.0, 0.3, 1.0);      // 低温 - 深蓝
uniform vec4 cool_color = vec4(0.0, 0.5, 1.0, 1.0);      // 凉 - 蓝色
uniform vec4 warm_color = vec4(1.0, 1.0, 0.0, 1.0);      // 温暖 - 黄色
uniform vec4 hot_color = vec4(1.0, 0.5, 0.0, 1.0);       // 热 - 橙色
uniform vec4 very_hot_color = vec4(1.0, 0.0, 0.0, 1.0);  // 极热 - 红色

// 噪声参数（用于模拟热成像的颗粒感）
uniform float noise_intensity = 0.05;
uniform float noise_scale = 5.0;

// 边缘增强参数
uniform float edge_threshold = 0.1;
uniform float edge_intensity = 1.5;

// 随机数生成函数
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// 噪声函数
float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    // 获取原始纹理颜色
    vec4 original_color = texture(TEXTURE, UV);
    
    // 转换为灰度（温度值）
    float temperature = (original_color.r + original_color.g + original_color.b) / 3.0;
    
    // 归一化温度到 [0,1] 范围
    temperature = (temperature - temperature_min) / (temperature_max - temperature_min);
    temperature = clamp(temperature, 0.0, 1.0);
    
    // 添加噪声模拟热成像颗粒感
    float n = noise(UV * noise_scale) * noise_intensity;
    temperature += n;
    temperature = clamp(temperature, 0.0, 1.0);
    
    vec4 thermal_color;
    
    if (use_custom_colors) {
        // 使用自定义颜色渐变
        if (temperature < 0.25) {
            thermal_color = mix(cold_color, cool_color, temperature * 4.0);
        } else if (temperature < 0.5) {
            thermal_color = mix(cool_color, warm_color, (temperature - 0.25) * 4.0);
        } else if (temperature < 0.75) {
            thermal_color = mix(warm_color, hot_color, (temperature - 0.5) * 4.0);
        } else {
            thermal_color = mix(hot_color, very_hot_color, (temperature - 0.75) * 4.0);
        }
    } else {
        // 使用标准热成像颜色映射（黑->蓝->青->绿->黄->红->白）
        if (temperature < 0.2) {
            thermal_color = mix(vec4(0.0, 0.0, 0.0, 1.0), vec4(0.0, 0.0, 0.5, 1.0), temperature * 5.0);
        } else if (temperature < 0.4) {
            thermal_color = mix(vec4(0.0, 0.0, 0.5, 1.0), vec4(0.0, 1.0, 1.0, 1.0), (temperature - 0.2) * 5.0);
        } else if (temperature < 0.6) {
            thermal_color = mix(vec4(0.0, 1.0, 1.0, 1.0), vec4(0.0, 1.0, 0.0, 1.0), (temperature - 0.4) * 5.0);
        } else if (temperature < 0.8) {
            thermal_color = mix(vec4(0.0, 1.0, 0.0, 1.0), vec4(1.0, 1.0, 0.0, 1.0), (temperature - 0.6) * 5.0);
        } else {
            thermal_color = mix(vec4(1.0, 1.0, 0.0, 1.0), vec4(1.0, 0.0, 0.0, 1.0), (temperature - 0.8) * 5.0);
        }
    }
    
    // 简单的边缘检测增强
    vec2 pixel_size = 1.0 / TEXTURE_PIXEL_SIZE;
    float left = texture(TEXTURE, UV + vec2(-pixel_size.x, 0.0)).r;
    float right = texture(TEXTURE, UV + vec2(pixel_size.x, 0.0)).r;
    float top = texture(TEXTURE, UV + vec2(0.0, -pixel_size.y)).r;
    float bottom = texture(TEXTURE, UV + vec2(0.0, pixel_size.y)).r;
    
    float edge = abs(left - right) + abs(top - bottom);
    if (edge > edge_threshold) {
        thermal_color.rgb *= edge_intensity;
    }
    
    COLOR = thermal_color;
}