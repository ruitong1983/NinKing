shader_type canvas_item;

// 混合强度（0=完全显示扭曲后的图像，1=完全显示原始图像）
uniform float max_blend : hint_range(0,1) = 0.5;
// 旋转偏移量（弧度）
uniform float rotation_offset = 0.0;
// 扭曲强度
uniform float intensity : hint_range(0, 10.0) = 1.0;
// 反转扭曲方向
uniform bool invert = false;
// 纹理尺寸参考（适配不同分辨率纹理的扭曲比例）
uniform vec2 rel_rect_size = vec2(1024.0, 600.0);

// 计算UV到纹理中心的距离（UV范围0~1，中心是0.5,0.5）
float distFromCen(vec2 p) {
	return distance(p, vec2(0.5));
}

// 2D坐标旋转（弧度制）
vec2 rotate(vec2 p, float angle){
	return vec2(cos(angle)*p.x - sin(angle)*p.y, sin(angle)*p.x + cos(angle)*p.y);
}

void fragment() {
	// 采样原始纹理颜色（自身图像的原始像素）
	vec4 original_color = texture(TEXTURE, UV);

	// 计算距离修正值（invert控制扭曲方向：true=越远越扭曲，false=越近越扭曲）
	float distMod = invert ? distFromCen(UV) : 0.5 - distFromCen(UV);
	// 计算旋转角度（6.28318≈2π，对应360度，intensity控制扭曲幅度）
	float angle = intensity * distMod * 6.28318 + rotation_offset;

	// 以纹理中心为原点旋转UV，再还原到0~1范围
	vec2 rotated_uv = rotate(UV - vec2(0.5), angle) + vec2(0.5);

	// 计算纹理偏移（基于自身纹理的像素尺寸，补偿Y轴反转）
	vec2 disp = (rotated_uv - UV) * rel_rect_size * TEXTURE_PIXEL_SIZE;
	disp.y = -disp.y; // 保持UV与纹理像素坐标的Y轴对齐

	// 采样扭曲后的纹理颜色（基于自身纹理的UV偏移）
	vec4 distorted_color = texture(TEXTURE, UV + disp);

	// 混合原始颜色与扭曲颜色（越靠近中心，混合度越高，扭曲效果越明显）
	COLOR = mix(distorted_color, original_color, max_blend * 2.0 * (0.5 - distFromCen(UV)));

	// 超出中心圆形区域时，直接显示原始纹理（无扭曲效果）
	if (distFromCen(UV) > 0.5) {
		COLOR = original_color;
	}
}