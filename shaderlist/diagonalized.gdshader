/*
 * 挤压精灵着色器 (Squish Sprite Shader)
 * 作者: Garmelon (https://github.com/Garmelon)
 * 文档: Mateus-Carmo31
 * 
 * 功能: 实现精灵的水平挤压/膨胀效果
 * 原理: 通过顶点着色器拉伸精灵边界，片段着色器调整UV采样实现变形
 */

shader_type canvas_item;
render_mode blend_mix;

// 调试模式：显示UV坐标而非纹理
uniform bool uv_mode = false;

// X轴拉伸因子：控制精灵在X方向的初始拉伸
uniform float x_factor = 2.0;

// 膨胀系数：负值表示挤压，正值表示膨胀
uniform float bulge : hint_range(-1.0, 1.0) = 0.0;

/**
 * 膨胀函数：定义变形曲线
 * @param y 归一化的垂直坐标（-1到1）
 * @return 水平方向的位移因子
 * 
 * 当前使用半圆形函数，可修改以实现不同的变形效果
 * 函数必须满足：当y在[-1, 1]范围内时，x在[0, 1]范围内
 */
float bulge_function(float y) {
    return sqrt(1.0 - y * y);
}

/**
 * 顶点着色器
 * 在X轴方向拉伸顶点，为变形效果创建空间
 */
void vertex() {
    // 拉伸顶点X坐标，扩大精灵边界框
    // 这使得后续的UV变形不会超出原始纹理范围
    VERTEX.x *= x_factor;
}

/**
 * 片段着色器
 * 主要变形逻辑，通过调整UV坐标实现挤压/膨胀效果
 */
void fragment() {
    // [步骤1] UV坐标重映射：从[0,1]到[-1,1]
    vec2 uv = UV * 2.0 - 1.0;
    
    // [步骤2] 补偿顶点拉伸：使UV坐标与拉伸后的顶点对齐
    // 由于纹理映射范围固定，这会使纹理在X方向看起来被压缩
    uv.x *= x_factor;
    
    // [步骤3] 计算变形位移
    // 基于Y坐标和膨胀系数计算X方向的变形量
    // 膨胀函数决定变形曲线的形状
    float displacement = 1.0 + bulge * bulge_function(uv.y);
    
    // [步骤4] 应用变形：调整X轴UV坐标
    // 位移 > 1: uv.x减小 → 采样更靠近中心的像素 → 膨胀效果
    // 位移 < 1: uv.x增大 → 采样更远离中心的像素 → 挤压效果
    // 位移 = 1: 无变形
    uv.x /= displacement;
    
    // [步骤5] UV坐标反映射：从[-1,1]回到[0,1]
    uv = (uv + 1.0) / 2.0;
    
    // [步骤6] 渲染处理
    if (uv_mode) {
        // 调试模式：显示UV坐标
        // 红色通道 = uv.x, 绿色通道 = uv.y
        // 超出[0,1]范围的部分显示为黑色
        COLOR = (uv.x >= 0.0 && uv.x <= 1.0) ? vec4(uv, 0.0, 1.0) : vec4(vec3(0.0), 1.0);
    } else {
        // 正常渲染模式
        // 检查UV是否在有效范围内，超出部分渲染为透明
        if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
            COLOR = texture(TEXTURE, uv);
        } else {
            COLOR = vec4(0.0);
        }
    }
}