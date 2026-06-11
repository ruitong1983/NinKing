# V36 — 人牌 J/Q/K 漫画插图实现记录

> **用途：** 豆包 AI 出图 → 矢量追踪 → 内嵌到 `4color_deck_by_heratexx/` 中 J/Q/K 的 SVG
> **状态：** ✅ 已完成
> **关键决策：** Godot 的 SVG 导入器（nanosvg）不支持 `<image>` 标签，改用 PNG→SVG 矢量路径追踪后内嵌

---

## 一、最终方案

```
res://assets/images/cards/face_portraits/
  ├── jack_portrait.png          ← 豆包出图 (332×524)
  ├── queen_portrait.png         ← 豆包出图 (332×524)
  ├── king_portrait.png          ← 豆包出图 (332×524)
  ├── jack_traced.svg            ← 矢量追踪 (imagetracer)
  ├── queen_traced.svg           ← 矢量追踪 (imagetracer)
  └── king_traced.svg            ← 矢量追踪 (imagetracer)
```

**流程：**

```
豆包 AI 出 3 张 PNG (332×524, 透明背景, 少年漫画风)
  ↓
imagetracer 矢量追踪 (16色量化, 优化平涂轮廓)
  ↓
路径内嵌到 12 个卡牌 SVGs
  ↓
清理: 移除蓝色内框 <rect> + 中心叠层小花色 <use>
```

---

## 二、3 张 Prompt 记录

### ① J — 忍者学徒（jack_portrait.png）

**正向：**

> 日本少年漫画风，粗黑硬边描边（3-5px），黑白为主+银灰色强调，半身胸像，正面向，画面居中对称。约 16 岁忍者学徒少年，轻便黑色短装忍者服，银灰色短发，眼神锐利专注，表情认真。腰间挂暗器袋和苦无套，肩后露出手里剑边缘。阴影用平涂灰阶+漫画网点表现，无写实渐变。半身腰以上构图。背景透明PNG，不要任何背景元素。输出 332×524px。

**负向：**

> 不要背景，不要白色背景，不要边框，不要西洋/中世纪服装，不要王冠，不要铠甲（忍者装可以），不要写实渲染，不要3D，不要水印，不要文字，不要额外人物，不要全身，不要半透明描边（必须粗黑实线），不要渐变，不要厚涂上色，不要过于复杂的装饰细节

---

### ② Q — 女忍大师（queen_portrait.png）

**正向：**

> 日本少年漫画风，粗黑硬边描边（3-5px），黑白为主+紫红色强调，半身胸像，正面向，画面居中对称。20 岁左右女忍大师，紧身黑色忍者服+紫色腰帯，黑长直发束高马尾，发梢飘动，面容冷艳，眼尾上挑，双瞳暗紫色。衣带有飘动感，胸前微露紫色內襟。阴影用平涂灰阶+漫画网点。半身腰以上构图。背景透明PNG。输出 332×524px。

**负向：**

> 不要背景，不要白色背景，不要边框，不要西洋/中世纪服装，不要王冠，不要后冠，不要公主裙，不要写实渲染，不要3D，不要水印，不要文字，不要额外人物，不要全身，不要半透明描边，不要渐变，不要厚涂，不要过于复杂的饰物，不要露骨/色情，角色年龄不超过 25 岁

---

### ③ K — 忍皇（king_portrait.png）

**正向：**

> 日本少年漫画风，粗黑硬边描边（3-5px），黑白为主+暗金色强调，半身胸像，正面向，画面居中对称。40 岁左右忍者霸主，厚重黑色甲胄（日本甲冑风格）+漆黑披风（破边飘动），面部露出，双瞳暗紫色光芒，表情威严冷酷，眼神向下俯视。头顶黑色兜帽+金纹头箍，甲胄边缘有银灰色勾边。阴影用平涂灰阶+漫画网点。半身腰以上构图。背景透明PNG。输出 332×524px。

**负向：**

> 不要背景，不要白色背景，不要边框，不要西洋/中世纪服装，不要欧洲王冠，不要铠甲（日本甲冑OK），不要写实渲染，不要3D，不要水印，不要文字，不要额外人物，不要全身，不要半透明描边，不要渐变，不要厚涂，不要胡须过长

---

## 三、SVG 实现细节

### 3.1 为什么不能用 `<image>`

Godot 4.6.2 的 SVG 导入器基于 **nanosvg**，该库**不支持任何 `<image>` 标签**：
- 无论 `href="file.png"`（外部文件）还是 `data:image/png;base64,xxx`（内嵌 base64）
- 导入时静默忽略，中央插图区保持空白

### 3.2 替代方案：矢量路径追踪

使用 [imagetracer](https://github.com/murongg/imagetracer) 将 PNG 追踪为 SVG path：

| 参数 | 值 | 理由 |
|------|-----|------|
| `numberofcolors` | 16 | 足够区分皮肤/头发/眼睛/服饰，不溢出噪声 |
| `minpathsize` | 2 | 抑制 JPEG 压缩产生的单像素噪点 |
| `linefilter` | true | 平滑对角线的锯齿边缘 |
| `ltres` | 0.5 | 折中精度与文件大小 |
| `qtres` | 1 | 量化分辨率 |

追踪后文件大小：jack=387KB, queen=825KB, king=697KB（比 `<image>` 方式大，但纯矢量，Godot 原生支持）。

### 3.3 嵌入位置

追踪的 SVG 路径放入 illustration group 内，使用统一变换：

```svg
<g transform="translate(-82,-130) scale(0.497)">
  <!-- 追踪的 path 数据 -->
</g>
```

- 插图区尺寸：165×261（SVG 坐标系，以 card 中心为原点）
- 缩放比：`min(165/332, 261/524) ≈ 0.497`（等比例适配）

### 3.4 额外清理

嵌入后从所有 12 张人物 SVGs 中移除冗余元素：

| 元素 | 原因 | 文件 |
|------|------|------|
| 5 个废弃 `<symbol>`（go/re/bu/ba/de） | 旧矢量人物，已无人引用 | J/Q/K × 4 |
| `<image href="...">` | nanosvg 不支持，留空 | J/Q/K × 4 |
| `<rect stroke='#44f'>` 蓝色内框 | 与漫画忍者风格不协调 | 同上 |
| 2 个中心叠层 `<use href='#Sx'> height='52'` | 对角小花色，冗余 | 同上 |

### 3.5 J 与 K/Q 的镜像差异

| 牌型 | 插图外包装 | 原因 |
|------|-----------|------|
| **J** | 普通 `<g>` | 原版 J 无镜像 |
| **K/Q** | `<g transform='scale(-1,1)'>` | 原版设计左右镜像，人物反向投影 |

肖像路径自动继承父级 transform，K/Q 上会左右镜像——与原始设计的中心人物处理一致。

### 3.6 最终结构验证

```
<svg viewBox='-120 -167 240 334'>
  <rect .../>                        ← 卡牌背景
  <symbol id='Rxx'>...</symbol>      ← 点数符号定义
  <symbol id='S0..S3xx'>...</symbol> ← 花色符号定义
  <use href='#Rxx'.../>              ← 左上角点数
  <use href='#S0xx'.../>             ← 左上角花色
  <g transform='rotate(180)'>        ← 右下角旋转组
    <use href='#Rxx'.../>
    <use href='#S0xx'.../>
  </g>
  <g transform='scale(-1,1)'>        ← K/Q 镜像组 / J 普通 <g>
    <g transform="translate(-82,-130) scale(0.497)">
      ...追踪的肖像路径数据...
    </g>
  </g>
</svg>
```

---

## 四、工具链

```bash
# 依赖安装（一次性）
mkdir C:\Users\candy\AppData\Local\Temp\svg-trace
cd C:\Users\candy\AppData\Local\Temp\svg-trace
npm init -y && npm install imagetracer pngjs

# 执行追踪 + 嵌入
cd E:\01 Code\Godot_v4.6.2\NinKing
node ..\tools\trace_face_portraits.js
```

脚本位置：`E:\01 Code\Godot_v4.6.2\tools\trace_face_portraits.js`

---

## 五、Code Review 检查项

### 5.1 SVG 文件

| 检查项 | 结果 |
|--------|------|
| 无 `<image>` 标签残留 | ✅ 0 个出现 |
| 无蓝色内框 `<rect stroke='#44f'>` | ✅ 已全部移除 |
| 无中心叠层小花色 `<use height='52'>` | ✅ 已全部移除 |
| 4 个角的点数和花色正常 | ✅ `<use>=4` 仅剩角落 |
| 废弃 symbol 是否清理 | ✅ 仅保留 Rxx/S0-S3xx 5 个角落符号 |
| 文件结构完整（闭合标签） | ✅ `</svg>` 存在 |
| J 牌无 scale(-1,1) | ✅ `<g>=3` 含 rotate(180)/普通<g>/transform<g> |
| K/Q 牌有 scale(-1,1) | ✅ 同上，含 scale(-1,1) |
| Godot 导入无崩溃 | ✅ 实际游戏测试通过 |

### 5.2 追踪质量

| 检查项 | 当前 | 备注 |
|--------|------|------|
| 轮廓清晰 | 可接受 | 自动追踪，边缘略有锯齿 |
| 色彩还原 | 16 色量化 | 够用，无怪色 |
| 噪点路径 | 已抑制 | minpathsize=2 过滤 |

若需更高品质 → 调参（`numberofcolors: 24`、`blur: 0.5`）或换源图分辨率。

### 5.3 文档

| 检查项 | 结果 |
|--------|------|
| 方案与实际一致 | ✅ 已更新为此文档 |
| TODO.md 状态 | ✅ V36 标记完成 |
| 回退方法 | `git checkout -- assets/images/cards/4color_deck_by_heratexx/{J,Q,K}*.svg` |

---

## 六、文件清单

| 文件 | 大小 | 类型 |
|------|------|------|
| `face_portraits/jack_portrait.png` | 69 KB | 源 PNG |
| `face_portraits/queen_portrait.png` | 90 KB | 源 PNG |
| `face_portraits/king_portrait.png` | 96 KB | 源 PNG |
| `face_portraits/jack_traced.svg` | 387 KB | 追踪结果（中间件） |
| `face_portraits/queen_traced.svg` | 825 KB | 追踪结果（中间件） |
| `face_portraits/king_traced.svg` | 697 KB | 追踪结果（中间件） |
| `4color_deck_by_heratexx/J{suit}.svg` ×4 | ~388 KB | 最终产物 |
| `4color_deck_by_heratexx/Q{suit}.svg` ×4 | ~827 KB | 最终产物 |
| `4color_deck_by_heratexx/K{suit}.svg` ×4 | ~699 KB | 最终产物 |
