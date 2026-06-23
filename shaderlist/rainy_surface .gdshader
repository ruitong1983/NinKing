shader_type canvas_item;

// 保留原代码的核心参数（可在编辑器调整）
uniform float xscale : hint_range(0.1, 2.0) = 0.5;    // X轴缩放
uniform float yscale : hint_range(1.0, 20.0) = 12.0;  // Y轴缩放
uniform float speed : hint_range(0.01, 0.5) = 0.08;   // 动画速度
uniform float xdistort : hint_range(0.0, 0.2) = 0.05; // X轴扭曲强度
uniform float ydistort : hint_range(0.0, 0.1) = 0.01; // Y轴扭曲强度

void fragment() {
    // 1. 归一化UV坐标（Godot内置，替代原fragCoord/iResolution）
    vec2 uv = UV;
    
    // 2. 计算原代码的uv_warp（拉伸+时间流动，和原逻辑一致）
    vec2 uv_warp = vec2(
        uv.x / xscale,
        uv.y / yscale + TIME * speed
    );
    
    // 3. 程序化生成扰动值（替代原iChannel1的纹理采样，模拟随机扰动）
    // 用sin/cos组合生成类似纹理采样的0~1范围值，避免外部纹理依赖
    float noise1 = (sin(uv_warp.x * 10.0 + uv_warp.y * 20.0 + TIME * 5.0) + 1.0) / 2.0;
    float noise2 = (sin(uv_warp.x * 10.0 + (uv_warp.y + speed) * 20.0 + TIME * 5.0) + 1.0) / 2.0;
    vec2 uv_samp = vec2(noise1, noise2);
    
    // 4. 原逻辑的扰动计算（和原代码完全一致）
    vec2 distorted_uv = vec2(
        uv.x + (uv_samp.x - uv_samp.y) * xdistort,
        uv.y + uv_samp.y * ydistort
    );
    
    // 5. 采样原纹理并输出颜色
    COLOR = texture(TEXTURE, distorted_uv);
}