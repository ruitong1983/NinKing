shader_type canvas_item;

// Godot 内置变量：
// UV: 纹理坐标 [0, 1]
// TIME: 运行时间 (等同于 iTime)
// SCREEN_PIXEL_SIZE: 1/iResolution.xy

// ----------------------------------------------------
// 1. Uniforms (输入通道和控制参数)
// ----------------------------------------------------

// iChannel0 对应 TEXTURE (主纹理)
// iChannel1 对应 BACKGROUND_TEXTURE (背景纹理)
uniform sampler2D background_texture ;
// iChannel2 对应 ENV_MAP (环境反射贴图, 必须是 Cubemap 或 Sphere Map)
uniform sampler2D env_map ;
// iChannel3 对应 NORMAL_MAP (细节法线贴图)
uniform sampler2D detail_normal_map ;

uniform float time_scale = 1.0;
uniform float distortion_strength = 1.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.15;


// ----------------------------------------------------
// 2. Auxiliary Functions
// ----------------------------------------------------

// 辅助函数: 简单的矩形遮罩 (未使用，但保留转换)
float rectMask(float b, float w, vec2 uv)
{
    vec4 e=smoothstep(vec4(-b-.5*w),vec4(-b+.5*w),vec4(uv,vec2(1)-uv));
    return e.x*e.y*e.z*e.w;
}


// ----------------------------------------------------
// 3. Main Fragment Function
// ----------------------------------------------------

void fragment() {
    // ----------------------------------------------------
    // A. 坐标初始化和时间
    // ----------------------------------------------------
    
    // TIME 是 Godot 内置变量
    float t = TIME * time_scale; 

    // SCREEN_UV: fragCoord / iResolution.xy
    vec2 fragCoord = FRAGCOORD.xy;
    vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
    
    // 屏幕抖动/晃动 (从 fragCoord 改为直接影响 UV)
    vec2 offset_time = iResolution.y * 0.003 * vec2(sin(t * 0.6667 * 3.0), 2.0 * cos(t * 0.5 * 3.0));
    
    // 模拟原始的 UV 计算: 调整 fragCoord 得到 UV
    vec2 adjusted_fragCoord = fragCoord + offset_time;
    vec2 uv = (adjusted_fragCoord / iResolution - 0.5) * 1.05 + 0.5;

    // ----------------------------------------------------
    // B. 纹理采样 (内容)
    // ----------------------------------------------------
    
    // c0: 主纹理 (TEXTURE)
    vec4 c0 = texture(TEXTURE, uv);
    
    // c1: 背景纹理 (略微缩小)
    vec2 uv1 = (uv - 0.5) * 0.97 + 0.5;
    vec4 c1 = texture(background_texture, uv1);

    // ----------------------------------------------------
    // C. 几何扭曲与法线计算
    // ----------------------------------------------------
    
    // coord: 居中坐标
    vec2 coord = adjusted_fragCoord - iResolution * 0.5;
    
    // 径向扭曲
    coord += dot(coord, coord) * coord * vec2(1.5, 0.6) / (iResolution.x * iResolution.x) * 0.9 * distortion_strength;
    coord *= vec2(0.8, 0.9) * 1.1;
    
    // 表面纹理坐标
    vec2 uv2 = coord / iResolution.x;
    vec2 uv3 = coord / iResolution * 1.6;
    
    // 核心扰动坐标 (uvS)
    vec2 uvS = uv2 * 1.5 + uv3 * pow(abs(uv3), vec2(22.0)) * 530.0 * 1.0
             + 0.1 * vec2(sin(t * 0.27), cos(t * 0.31));

    // 法线向量 n (添加细节法线贴图 iChannel3)
    // 假设 detail_normal_map 使用 Tiling (iChannelResolution 不重要)
    vec3 detail_n = texture(detail_normal_map, 1.0 * coord / iResolution.xy).xyz; 
    
    vec3 n = normalize(vec3(uvS, 1.1) + 0.01 * detail_n);
    vec3 n2 = normalize(vec3(uvS, 1.13));

    // ----------------------------------------------------
    // D. 反射与高光 (Specular)
    // ----------------------------------------------------
    
    // 视线向量 v
    vec3 v = normalize(vec3(coord / iResolution.x * 0.25, -1.0));
    
    // 反射采样 (使用 env_map)
    vec3 reflect_v = reflect(v, n);
    // Godot 通常使用内置的 NORMALMAP 宏或专门的 Cubemap/Sphere Map 采样函数。
    // 这里我们直接使用 texture(sampler, uv) 模拟，假设 env_map 是一个简单的 2D 环境纹理。
    // 转换: .zyx*vec3(1,-1,-1) -> 用于匹配原始代码的 Cubemap/环境贴图坐标。
    // 在 Godot 2D 中，我们简化为使用反射向量的 xy 或 zx 分量作为 UV。
    vec4 spec = texture(env_map, reflect_v.xz * 0.5 + 0.5); // 使用 xz 作为 UV 简单近似
    
    vec3 reflect_v2 = reflect(v, n2);
    spec += texture(env_map, reflect_v2.xz * 0.5 + 0.5); 
    
    // 高光强度 (菲涅尔近似)
    spec *= 0.08 + 1.5 * pow(abs(1.0 - n.z), 4.0);

    // ----------------------------------------------------
    // E. 最终混合与晕影
    // ----------------------------------------------------
    
    // 晕影 (Vignette)
    float r = length(fragCoord - iResolution * 0.5) / iResolution.x;
    // 使用统一控制的晕影强度
    float vign = 1.0 - r * r * r * vignette_strength; 

    // 最终颜色混合
    vec3 final_color = ((c0.rgb + c1.rgb * c1.rgb * 2.0 + c1.rgb * 1.5) * 0.3 + spec.rgb) * vign;

    COLOR = vec4(final_color, c0.a);
}