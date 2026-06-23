shader_type canvas_item;

// 定義著色器的 uniform 參數
uniform vec4 key_color = vec4(0,1,0,1);  // 要摳除的顏色，預設為綠色
uniform float similarity : hint_range(0.0,1.0) = 0.4;  // 相似度閾值，越高摳除的顏色範圍越大
uniform float smoothness : hint_range(0.00,1.0) = 0.08;  // 邊緣平滑度，防止鋸齒邊緣
uniform float spill : hint_range(0.0,1.0) = 0.1;  // 顏色溢出控制，處理邊緣顏色殘留

// 將 RGB 顏色轉換為 YUV 顏色空間的 UV 分量
// 使用 YUV 顏色空間是因為色度資訊與亮度分離，適合做顏色鍵控
// 公式來源：https://github.com/libretro/glsl-shaders/blob/master/nnedi3/shaders/rgb-to-yuv.glsl
vec2 RGBtoUV(vec3 rgb) {
  return vec2(
    rgb.r * -0.169 + rgb.g * -0.331 + rgb.b *  0.5    + 0.5,  // U 分量計算
    rgb.r *  0.5   + rgb.g * -0.419 + rgb.b * -0.081  + 0.5   // V 分量計算
  );
}

// 主要的色度鍵處理函數
vec4 ProcessChromaKey(sampler2D tex, vec2 texCoord) {
  // 1. 取得當前像素的顏色
  vec4 rgba = texture(tex, texCoord);
  
  // 2. 計算當前像素顏色與目標鍵控顏色的色度距離
  // 在 YUV 顏色空間中計算歐幾里得距離，距離越小表示顏色越相似
  float chromaDist = distance(RGBtoUV(rgba.rgb), RGBtoUV(key_color.rgb));
  
  // 3. 計算透明度遮罩
  // baseMask: 基礎遮罩值，負值表示顏色相似，正值表示不相似
  float baseMask = chromaDist - similarity;
  // fullMask: 將基礎遮罩平滑化，產生漸變的透明度
  // 使用 pow(..., 1.5) 進行伽馬校正，控制遮罩曲線
  float fullMask = pow(clamp(baseMask / smoothness, 0., 1.), 1.5);
  rgba.a = fullMask;  // 將計算出的遮罩設為透明度
  
  // 4. 處理顏色溢出（Color Spill）
  // 顏色溢出是指目標鍵控顏色反射或溢出到前景物體上
  // spillVal: 計算溢出遮罩
  float spillVal = pow(clamp(baseMask / spill, 0., 1.), 1.5);
  
  // 計算去飽和顏色（灰階）
  // 使用標準的亮度權重：R:0.2126, G:0.7152, B:0.0722
  float desat = clamp(rgba.r * 0.2126 + rgba.g * 0.7152 + rgba.b * 0.0722, 0., 1.);
  
  // 混合原色和去飽和顏色，以減少鍵控顏色的溢出
  // 當 spillVal 接近 0（顏色相似時）使用更多去飽和顏色
  // 當 spillVal 接近 1（顏色不相似時）使用更多原色
  rgba.rgb = mix(vec3(desat, desat, desat), rgba.rgb, spillVal);
  
  return rgba;
}

// 片段著色器主函數
void fragment() {
  // 對當前像素進行色度鍵處理
  // TEXTURE: 輸入紋理
  // UV: 當前像素的紋理座標
  COLOR = ProcessChromaKey(TEXTURE, UV);
}