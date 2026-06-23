shader_type canvas_item;

// 残像纹理
uniform sampler2D residual_image_tex ;
// 残像强度
uniform float residual_image_rate : hint_range( 0.0, 1.0 ) = 0.95;
// 抖动效果强度
uniform float dithering : hint_range( 0.0, 1.0 ) = 0.1;
// 是否为彩色液晶
uniform bool color_lcd = false;
// 单色液晶亮色
uniform vec4 monochrome_light = vec4( 0.5372549019607843, 0.6274509803921569, 0.34765625, 1.0 );
// 单色液晶暗色
uniform vec4 monochrome_dark = vec4( 0.19607843137254902, 0.22745098039215686, 0.1450980392156863, 1.0 );
// 液晶发色阶数
uniform int steps : hint_range( 2, 255 ) = 4;

// 随机数生成函数
float random( vec2 seed )
{
	return fract( 543.2543 * sin( dot( seed, vec2( 3525.46, -54.3415 ) ) ) );
}

void fragment( )
{
	// 获取节点自身的纹理颜色
	vec4 pixel_color = texture( TEXTURE, UV );
	float rand = random( UV );
	float steps_floated = float( steps );

	// 抖动处理
	float dither_rand = rand * dithering - ( dithering * 0.5 );
	pixel_color = clamp( pixel_color + vec4( dither_rand, dither_rand, dither_rand, 0.0 ), vec4( 0.0, 0.0, 0.0, 0.0 ), vec4( 1.0, 1.0, 1.0, 1.0 ) );

	// 彩色或单色处理
	float monochrome = pixel_color.r * 0.2126 + pixel_color.g * 0.7152 + pixel_color.b * 0.0722;
	pixel_color = mix(
		mix( monochrome_dark, monochrome_light, floor( monochrome * steps_floated ) / steps_floated )
	,	floor( pixel_color * steps_floated) / steps_floated
	,	float( color_lcd )
	);

	// 与残像纹理混合
	COLOR = mix( pixel_color, texture( residual_image_tex, UV ), residual_image_rate );
}