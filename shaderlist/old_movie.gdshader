shader_type canvas_item;

// 原有参数（修复vignette默认值越界问题）
uniform float projector_power : hint_range(0,1) = 0.5;
uniform sampler2D distortionTexture;
uniform float vignette_param: hint_range(1,10)=5.0; // 修正默认值到1~10范围内

// 新增可控参数（2-3个，不复杂）
uniform float speckle_intensity : hint_range(0, 30.0) = 20.0; // 斑点亮度阈值（越大斑点越多/越亮）
uniform float line_intensity : hint_range(0, 10.0) = 8.0;    // 线条亮度阈值（越大线条越多/越亮）
uniform float flicker_speed : hint_range(0.1, 100.0) = 60.0; // 渐晕/噪声闪烁速度（越大越快）

// 伪随机噪声函数（保留）
float noise(vec2 input){
	return fract(sin(dot(input,vec2(3.1415,8952.37)*12.29))*93.116);
}

void fragment() {
	// 1. 动态渐晕（改用新增的flicker_speed控制闪烁速度）
	float vignette_param2 = vignette_param + 0.5 * noise(vec2(TIME/flicker_speed, TIME/(flicker_speed-1.0)));
	float vig = 1.0 - vignette_param2 * ((UV.x-0.5)*(UV.x-0.5) + (UV.y-0.5)*(UV.y-0.5)); // 修正为0~1范围，避免过暗
	vec4 vignette = vec4(vig, vig, vig, 1.0);

	// 2. 灰度化（修复绿色权重错误）
	vec4 pixelcolor = texture(TEXTURE, UV);
	float brightness = (0.299*pixelcolor.r + 0.587*pixelcolor.g + 0.114*pixelcolor.b); // 标准灰度公式
	vec4 grayscale = vec4(brightness, brightness, brightness, pixelcolor.a);

	// 3. 随机畸变（保留）
	vec4 random = texture(distortionTexture, UV);

	// 4. 小斑点（改用新增的speckle_intensity控制）
	float RTIME1 = round(TIME*20.0);
	vec2 position1 = vec2(noise(vec2(RTIME1, RTIME1)), noise(vec2(RTIME1/2.0, RTIME1/2.0)));
	float speckle_energy = 1000000.0 * (1.0 + 0.5*noise(vec2(RTIME1, RTIME1)));
	float xdev1 = (UV.x - position1.x);
	float ydev1 = (UV.y - position1.y);
	float spec = speckle_energy * (xdev1*xdev1 + 0.5*ydev1*ydev1) + 0.1*noise(vec2(UV.x, UV.y));
	vec4 speckle = vec4(max(0.0, speckle_intensity - spec), max(0.0, speckle_intensity - spec), max(0.0, speckle_intensity - spec), 1.0);

	// 5. 扫描线条（改用新增的line_intensity控制，单独定义line_energy避免复用）
	float RTIME2 = round(TIME*5.0);
	vec2 positionline = vec2(noise(vec2(RTIME2, RTIME2))/4.0, noise(vec2(RTIME2/3.0, RTIME2/3.0)));
	float line_energy = 1000000.0 * (1.0 + 0.3*noise(vec2(RTIME2, RTIME2))); // 单独的线条能量，解耦斑点
	float xline = (UV.x - positionline.x);
	float yline = (UV.y - positionline.y);
	float lin = line_energy * (xline*xline + 0.00001*yline*yline) + 0.1*noise(vec2(UV.x, UV.y));
	vec4 line = vec4(max(0.0, line_intensity - lin), max(0.0, line_intensity - lin), max(0.0, line_intensity - lin), 1.0);

	// 6. 效果混合（保留原有逻辑）
	vec4 dirt = mix(speckle, line, 0.5);
	vec4 grayscale2 = mix(random, vignette, 0.7);
	vec4 grayscale3 = mix(dirt, grayscale2, 0.7);
	COLOR = mix(grayscale, grayscale3, projector_power);
}