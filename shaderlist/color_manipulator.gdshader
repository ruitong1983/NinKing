// 着色器类型：canvas_item（用于2D画布项目）
shader_type canvas_item;
// 渲染模式：混合模式为mix（混合），unshaded（无光照）
render_mode blend_mix,unshaded;

// 亮度 uniform 变量，范围 -1 到 1，默认值 0
uniform float brightness : hint_range(-1, 1) = 0;
// 对比度 uniform 变量，范围 0 到 3，默认值 1.0
uniform float contrast : hint_range(0, 3) = 1.0;
// 饱和度 uniform 变量，范围 0 到 3，默认值 1.0
uniform float saturation : hint_range(0, 3) = 1.0;

// 红色通道系数，范围 0 到 1，默认值 1.0
uniform float redVal : hint_range(0, 1) = 1.0;
// 绿色通道系数，范围 0 到 1，默认值 1.0
uniform float greenVal : hint_range(0, 1) = 1.0;
// 蓝色通道系数，范围 0 到 1，默认值 1.0
uniform float blueVal : hint_range(0, 1) = 1.0;

// 色调颜色，RGBA格式，默认白色
uniform vec4 tint_color = vec4(1.0, 1.0, 1.0, 1.0);
// 色调效果混合因子，范围 0 到 1，默认值 0.0
uniform float tint_effect_factor : hint_range(0, 1) = 0.0;

//---------------------------------------------
// 对比度矩阵函数
// 参数 _contrast: 对比度值
// 返回: 4x4对比度变换矩阵
//---------------------------------------------
mat4 contrastMatrix( float _contrast ){
	float t = ( 1.0 - _contrast ) / 2.0; // 计算偏移量
    return mat4( 
		vec4(_contrast, 0, 0, 0),    // 第一列
		vec4(0, _contrast, 0, 0),    // 第二列
		vec4(0, 0, _contrast, 0),    // 第三列
		vec4(t, t, t, 1));           // 第四列（包含偏移）
}

//---------------------------------------------
// 亮度矩阵函数
// 参数 _brightness: 亮度值
// 返回: 4x4亮度变换矩阵
//---------------------------------------------
mat4 brightnessMatrix( float _brightness ){
    return mat4( vec4(1, 0, 0, 0),        // 第一列
                 vec4(0, 1, 0, 0),        // 第二列
                 vec4(0, 0, 1, 0),        // 第三列
                 vec4(_brightness, _brightness, _brightness, 1)); // 第四列（亮度偏移）
}

//---------------------------------------------
// 饱和度矩阵函数
// 参数 _saturation: 饱和度值
// 返回: 4x4饱和度变换矩阵
//---------------------------------------------
mat4 saturationMatrix( float _saturation ){
    // NTSC亮度权重（人眼对不同颜色的敏感度）
    vec3 luminance = vec3( 0.3086, 0.6094, 0.0820 );
    float oneMinusSat = 1.0 - _saturation; // 计算补饱和度
	
    // 构建红色通道变换向量
    vec3 red = vec3( luminance.x * oneMinusSat ); // 基础灰度部分
    red+= vec3(_saturation, 0, 0)*redVal;         // 添加饱和度的红色分量，乘以红色系数
    
    // 构建绿色通道变换向量
    vec3 green = vec3( luminance.y * oneMinusSat ); // 基础灰度部分
    green += vec3( 0,_saturation, 0 )*greenVal;     // 添加饱和度的绿色分量，乘以绿色系数
    
    // 构建蓝色通道变换向量
    vec3 blue = vec3( luminance.z * oneMinusSat ); // 基础灰度部分
    blue += vec3( 0, 0,_saturation )*blueVal;      // 添加饱和度的蓝色分量，乘以蓝色系数
	
    // 组合成4x4矩阵（只影响RGB，不改变Alpha）
    return mat4(
        vec4(red, 0),    // 第一列：红色通道变换
        vec4(green,0),   // 第二列：绿色通道变换
        vec4(blue,0),    // 第三列：蓝色通道变换
        vec4(0, 0, 0, 1) // 第四列：单位向量
    );
}

//---------------------------------------------
// 片段着色器主函数
// 对每个像素执行颜色变换
//---------------------------------------------
void fragment() {
	// 从纹理中获取原始颜色
	vec4 c = texture(TEXTURE, UV);
	// 计算色调调整后的颜色（乘以色调颜色）
	vec4 c2 = c * tint_color;
	
	// 应用颜色变换：
	// 1. 先混合原始颜色和色调颜色（根据tint_effect_factor）
	// 2. 应用饱和度矩阵
	// 3. 应用对比度矩阵
	// 4. 应用亮度矩阵
	// 注意：矩阵乘法顺序是从右到左应用变换
	COLOR = brightnessMatrix( brightness ) * 
	        contrastMatrix( contrast ) *
	        saturationMatrix( saturation ) * 
	        mix(c, c2, tint_effect_factor);
}