shader_type canvas_item;

uniform sampler2D u_normal_map : hint_normal; // 法线贴图

// 光源方向（分开控制，增强Z轴对深度的影响）
uniform float light_dir_x : hint_range(-2, 2) = 1.0;
uniform float light_dir_y : hint_range(-2, 2) = 1.0;
uniform float light_dir_z : hint_range(0.1, 3.0) = 1.5; // Z轴范围放大，强化深度感

// 增强效果的参数
uniform float bump_strength : hint_range(0.5, 3.0) = 1.2; // 凹凸强度（越大反差越明显）
uniform float contrast : hint_range(0.5, 2.0) = 1.3; // 对比度（拉大明暗差距）
uniform vec3 light_color : source_color = vec3(1.0, 1.0, 0.9);
uniform float specular_power : hint_range(0, 100) = 32.0;
uniform float ambient_strength : hint_range(0.0, 2.0) = 0.4; // 降低环境光，让暗部更暗

void fragment() {
    vec2 uv = UV;

    // 获取法线并强化Z轴分量（增强深度暗示）
    vec3 normal = texture(u_normal_map, uv).xyz;
    normal.z = normal.z * 0.8 + 0.2; // 确保Z轴有基础值，避免过度扁平
    normal = normalize(normal) * bump_strength; // 放大法线影响

    // 光源方向（Z值越大，光线越"垂直"于平面，深度感越强）
    vec3 light_dir = vec3(light_dir_x, light_dir_y, light_dir_z);
    vec3 light_dir_norm = normalize(light_dir);

    // 环境光（降低强度，让暗部更明显）
    vec3 ambient = ambient_strength * vec3(1.0);

    // 漫反射（强化明暗对比）
    float diff = max(dot(normal, light_dir_norm), 0.0);
    vec3 diffuse = (diff * 0.8 + 0.2) * light_color; // 基础亮度+反差强化

    // 镜面高光（缩小高光范围，让凸起处更亮）
    vec3 view_dir = vec3(0.0, 0.0, 1.0);
    vec3 reflect_dir = reflect(-light_dir_norm, normal);
    float spec = pow(max(dot(view_dir, reflect_dir), 0.0), specular_power) * 1.5;
    vec3 specular = spec * vec3(1.2, 1.2, 1.0); // 高光略偏暖，更突出

    // 合并光照并增强对比度
    vec3 light_total = (ambient + diffuse + specular) * contrast;

    // 应用到原图
    vec4 tex_color = texture(TEXTURE, uv);
    COLOR = tex_color * vec4(light_total, 1.0);
}
