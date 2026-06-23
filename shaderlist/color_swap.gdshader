// 声明着色器类型：CanvasItem（适用于Godot 2D节点，如Sprite2D、TextureRect等）
shader_type canvas_item;

// ===================== 可配置参数（Uniform） =====================
// 色相筛选最小值（HSV的H通道，范围0~1，对应0~360°）
uniform float _min;
// 色相筛选最大值（HSV的H通道，范围0~1）
uniform float _max;
// 目标着色颜色（rgba）：rgb为目标色，a为着色透明度（0=不着色，1=完全着色）
uniform vec4 color;
// 色相范围边缘的平滑过渡宽度（限制0~0.1，避免过渡过宽），默认0.02
uniform float smoothness : hint_range(0.0, 0.1) = 0.02;

// ===================== 辅助函数 =====================
/**
 * RGB转HSV颜色空间
 * @param c 输入的RGB颜色（范围0~1）
 * @return vec3(H, S, V)：色相、饱和度、明度，均为0~1
 */
vec3 rgb2hsv(vec3 c) {
    // HSV转换的常量系数
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    // 第一步混合：根据蓝/绿通道大小调整
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    // 第二步混合：根据红通道与第一步结果调整
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    // 计算差值（避免饱和度为0时除以0）
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10; // 极小值，防止除以0

    // 返回HSV：H(色相)、S(饱和度)、V(明度)
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

/**
 * 计算RGB颜色的感知亮度（Luma）
 * 模拟人眼对红、绿、蓝的敏感度（绿>红>蓝），比简单灰度更符合视觉体验
 * @param rgb 输入的RGB颜色
 * @return 感知亮度值（范围0~1）
 */
float get_luma(vec3 rgb) {
    // 加权计算：0.299(红) + 0.587(绿) + 0.114(蓝) 是行业标准权重
    return dot(rgb, vec3(0.299, 0.587, 0.114));
}

// ===================== 核心片元处理（逐像素渲染） =====================
void fragment() {
    // 1. 采样当前UV坐标对应的原始纹理颜色（rgba）
    vec4 tex = texture(TEXTURE, UV);
    // 2. 将RGB转换为HSV，提取色相通道（hsv.r=H, hsv.g=S, hsv.b=V）
    vec3 hsv = rgb2hsv(tex.rgb);

    // 3. 计算色相范围的平滑混合因子（factor）
    // smoothstep(a,b,x)：x<a→0，x>b→1，a<x<b→0~1平滑插值
    // 前半部分：色相从_min-smoothness到_min，factor从0→1
    // 后半部分：色相从_max到_max+smoothness，factor从1→0
    // 两者相乘：仅色相在[_min, _max]范围内时factor≈1，边缘平滑过渡
    float factor = smoothstep(_min - smoothness, _min, hsv.r) *
                   (1.0 - smoothstep(_max, _max + smoothness, hsv.r));

    // 4. 仅对色相在目标范围的像素进行颜色处理（factor>0）
    if (factor > 0.0) {
        // 4.1 计算原像素的感知亮度（保留明暗细节）
        float luma = get_luma(tex.rgb);
        // 4.2 基于原亮度生成目标颜色：保留明暗，替换为目标色相
        // vec3(luma)是灰度值，乘以目标色rgb，保证亮度匹配原像素
        vec3 colored = vec3(luma) * color.rgb;

        // 4.3 混合原始颜色和目标颜色
        // mix(a,b,t)：t=0→a，t=1→b；t=factor*color.a 同时控制范围和透明度
        tex.rgb = mix(tex.rgb, colored, factor * color.a);
    }

    // 5. 输出最终处理后的像素颜色
    COLOR = tex;
}