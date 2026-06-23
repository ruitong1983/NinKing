shader_type canvas_item;

// ===================== 核心动态效果参数 =====================
// 抖动参数
uniform float jitter_strength : hint_range(0.0, 20.0) = 2.0;    // 抖动幅度
uniform float jitter_speed : hint_range(0.1, 20.0) = 8.0;      // 抖动速度
uniform float jitter_frequency : hint_range(0.1, 50.0) = 12.0; // 抖动频率
uniform bool separate_xy = true;                               // XY轴分离抖动
uniform float time_offset : hint_range(0.0, 100.0) = 0.0;      // 时间偏移（避免多Sprite同步）

// 旋转参数
uniform bool enable_rotation = true;
uniform float rotation_strength : hint_range(0.0, 45.0) = 5.0; // 旋转角度（度）
uniform float rotation_speed : hint_range(0.1, 10.0) = 3.0;
uniform float rotation_frequency : hint_range(0.1, 20.0) = 4.0;

// 缩放参数
uniform bool enable_scaling = true;
uniform float scale_strength : hint_range(0.0, 0.5) = 0.1;     // 缩放波动幅度
uniform float scale_speed : hint_range(0.1, 10.0) = 2.5;
uniform float scale_frequency : hint_range(0.1, 20.0) = 6.0;
uniform float base_scale : hint_range(0.5, 2.0) = 1.0;         // 基础缩放

// 全局抖动强度（统一控制所有动态效果）
uniform float shake_intensity : hint_range(0.0, 1.0) = 0.5;

// ===================== 像素风格效果参数 =====================
uniform bool enable_pixelation = true;
uniform float pixel_size : hint_range(1.0, 32.0) = 4.0;        // 像素块大小
uniform bool adaptive_pixels = true;                           // 随缩放/旋转自适应像素大小

// 描边参数（像素画风格）
uniform bool enable_outline = true;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_thickness : hint_range(0.5, 3.0) = 1.0;

// 色差参数（复古显示效果）
uniform bool chromatic_aberration = false;
uniform float aberration_strength : hint_range(0.0, 5.0) = 1.0;

// ===================== 工具常量/函数 =====================
const float DEG2RAD = 0.0174533; // 角度转弧度常量

// 伪随机函数（生成0~1随机值）
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 平滑噪声函数（自然渐变，避免纯随机锯齿）
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    vec2 u = f * f * (3.0 - 2.0 * f); // 平滑插值
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// 2D旋转矩阵
mat2 rotate2D(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(vec2(c, -s), vec2(s, c)) ;
}

// ===================== 顶点着色器（控制位置/变换） =====================
void vertex() {
    float time_base = TIME + time_offset;
    vec2 center = vec2(0.5, 0.5); // Sprite中心锚点（UV/顶点中心）
    vec2 vertex_pos = VERTEX;

    // 1. 动态缩放（先缩放，再旋转/抖动）
    if (enable_scaling) {
        float scale_noise = noise(vec2(time_base * scale_speed * scale_frequency, vertex_pos.x * 0.1));
        float scale_offset = (scale_noise - 0.5) * scale_strength * shake_intensity;
        float scale_factor = base_scale + scale_offset;
        vertex_pos = (vertex_pos - center) * scale_factor + center;
    }

    // 2. 动态旋转
    if (enable_rotation) {
        float rotation_noise = noise(vec2(time_base * rotation_speed * rotation_frequency, vertex_pos.y * 0.1));
        float rotation_deg = (rotation_noise - 0.5) * rotation_strength * shake_intensity;
        float rotation_rad = rotation_deg * DEG2RAD;
        
        vec2 rotated_pos = (vertex_pos - center) * rotate2D(rotation_rad);
        vertex_pos = rotated_pos + center;
    }

    // 3. 位置抖动（最后叠加，避免旋转/缩放影响抖动范围）
    vec2 jitter_offset = vec2(0.0);
    float jitter_time = time_base * jitter_speed;
    if (separate_xy) {
        float jitter_x = noise(vec2(jitter_time * jitter_frequency, vertex_pos.x * 0.05)) - 0.5;
        float jitter_y = noise(vec2(vertex_pos.y * 0.05, jitter_time * jitter_frequency + 17.3)) - 0.5;
        jitter_offset = vec2(jitter_x, jitter_y) * jitter_strength;
    } else {
        float jitter_val = noise(vec2(jitter_time * jitter_frequency, length(vertex_pos) * 0.1)) - 0.5;
        jitter_offset = vec2(jitter_val) * jitter_strength;
    }

    // 最终顶点位置（叠加抖动）
    VERTEX = vertex_pos + jitter_offset * shake_intensity;
}

// ===================== 片段着色器（控制像素/颜色） =====================
void fragment() {
    vec2 uv = UV;
    vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE; // 纹理实际尺寸（像素）
    float adaptive_pixel_size = pixel_size;

    // 1. 自适应像素化（随缩放/旋转调整像素块大小）
    if (enable_pixelation) {
        if (adaptive_pixels) {
            // 计算当前帧的缩放/旋转对像素的影响
            float scale_influence = 1.0;
            float rotation_influence = 1.0;
            
            if (enable_scaling) {
                float scale_noise = noise(vec2((TIME + time_offset) * scale_speed * scale_frequency, uv.x * 10.0));
                float scale_factor = base_scale + (scale_noise - 0.5) * scale_strength * shake_intensity;
                scale_influence = scale_factor;
            }
            
            if (enable_rotation) {
                float rotation_noise = noise(vec2((TIME + time_offset) * rotation_speed * rotation_frequency, uv.y * 10.0));
                float rotation_deg = abs((rotation_noise - 0.5) * rotation_strength * shake_intensity);
                rotation_influence = 1.0 + rotation_deg * 0.02;
            }
            
            adaptive_pixel_size = pixel_size * scale_influence * rotation_influence;
        }
        
        // 限制最小像素大小，避免伪影
        adaptive_pixel_size = max(adaptive_pixel_size, 1.0);
        
        // UV对齐到像素网格（核心像素化逻辑）
        uv = floor(uv * texture_size / adaptive_pixel_size) * adaptive_pixel_size / texture_size;
        uv += (adaptive_pixel_size / texture_size) * 0.5; // 像素块中心对齐
    }

    // 基础纹理采样（钳制UV避免边界越界）
    vec4 base_color = texture(TEXTURE, clamp(uv, 0.0, 1.0));

    // 2. 像素画描边（仅在透明区域绘制描边）
    if (enable_outline && base_color.a > 0.1) {
        float outline_step = outline_thickness / max(texture_size.x, texture_size.y);
        float outline_alpha = 0.0;
        
        // 简化为4方向采样（上下左右），提升性能
        vec2 offsets[4] = vec2[](
            vec2(-outline_step, 0.0),
            vec2(outline_step, 0.0),
            vec2(0.0, -outline_step),
            vec2(0.0, outline_step)
        );
        
        for (int i = 0; i < 4; i++) {
            vec2 sample_uv = clamp(uv + offsets[i], 0.0, 1.0);
            if (enable_pixelation) {
                // 描边UV也对齐像素网格
                sample_uv = floor(sample_uv * texture_size / adaptive_pixel_size) * adaptive_pixel_size / texture_size;
                sample_uv += (adaptive_pixel_size / texture_size) * 0.5;
            }
            outline_alpha = max(outline_alpha, texture(TEXTURE, sample_uv).a);
        }
        
        // 透明区域绘制描边
        if (base_color.a < 0.1 && outline_alpha > 0.1) {
            base_color = outline_color;
        }
    }

    // 3. 动态色差（红/蓝通道偏移）
    if (chromatic_aberration && base_color.a > 0.1) {
        float aberration_time = (TIME + time_offset) * jitter_speed;
        float aberration_intensity = noise(vec2(aberration_time * 0.5)) * aberration_strength * 0.01;
        
        // 红/蓝通道UV偏移
        vec2 r_uv = clamp(uv + vec2(aberration_intensity, 0.0), 0.0, 1.0);
        vec2 b_uv = clamp(uv - vec2(aberration_intensity, 0.0), 0.0, 1.0);
        
        // 色差UV对齐像素网格
        if (enable_pixelation) {
            r_uv = floor(r_uv * texture_size / adaptive_pixel_size) * adaptive_pixel_size / texture_size;
            b_uv = floor(b_uv * texture_size / adaptive_pixel_size) * adaptive_pixel_size / texture_size;
            r_uv += (adaptive_pixel_size / texture_size) * 0.5;
            b_uv += (adaptive_pixel_size / texture_size) * 0.5;
        }
        
        // 分离通道采样
        base_color.r = texture(TEXTURE, r_uv).r;
        base_color.b = texture(TEXTURE, b_uv).b;
    }

    // 最终颜色输出（保留Sprite原Alpha）
    COLOR = base_color;
}