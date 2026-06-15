---
title: Fake3D 卡牌 VFX 集成方案
status: implemented (Phases 1-4 complete)
created: 2026-06-15
source: https://github.com/Fulafu-ai/Godot4-Fake3D-Card-Game-UI-Demo (MIT)
---

# Fake3D 卡牌 VFX 集成方案

## 1. 概述

将 Fulafu-ai 的 Godot4-Fake3D-Card-Game-UI-Demo（MIT 许可）中的核心着色器效果及补间能力引入 NinKing，替换/补充现有视觉效果。本方案包含：

| # | 效果 | 类型 | 来源文件 | 对现有方案的影响 |
|---|------|------|---------|----------------|
| 1 | **fake3d 透视着色器** | shader | `fake3d.gdshader` | 新增，**覆盖** `card_glow.gdshader` |
| 2 | **fake3d_flash 辉光着色器** | shader | `fake3d_flash.gdshader` | 替代 card_glow，提供通用闪光能力 |
| 3 | **dissolve2d 溶解消散** | shader | `dissolve2d.gdshader` | 新增**独立 API**，不替代 `pop_out()` |
| 4 | **arc+elastic 弧线补间** | TweenFX 扩展 | `card_UI.gd` `to_pos()` type 3/4 | 新增 `TweenFX.move_arc()` |
| 5 | **动态阴影（光源跟随）** | _process | `card_UI.gd` `_handle_light_and_shadow()` | 新增 Shadow 子节点 |

**不采纳项：**
- ❌ 鼠标视差倾斜 → 已有 `CardTilt.enable_single()`
- ❌ 扇形布局 → 已有 `CardTilt.apply_spread()` / `TweenFX.stagger_spread()`
- ❌ SAT 选择框 → 本项目 3×3 网格选牌，不需要
- ❌ Shake+颜色flash → 已有 `shake_node()` + `color_flash()` 组合
- ❌ 多卡叠放拖拽 → 已有 Card Framework

---

## 2. 着色器导入

### 2.1 目录结构

所有新着色器统一放入 `shaders/fake3d/`，与原 `shaders/card_glow.gdshader` 同级：

```
shaders/
├── card_glow.gdshader          ← 将被 fake3d_flash 替代，暂保留
├── panel_edge_fade.gdshader    ← 已有，不动
└── fake3d/
    ├── fake3d.gdshader          ← 基础透视着色器
    ├── fake3d_flash.gdshader    ← 辉光/闪光着色器（替代 card_glow）
    ├── fake3d_shadow.gdshader   ← 3D 阴影着色器
    └── dissolve2d.gdshader      ← 溶解消散着色器
```

### 2.2 fake3d.gdshader — 基础透视

```gdscript
// License: MIT — Hei
// Godot canvas_item shader that "fakes" 3D camera perspective on 2D cards
// Uses rotation matrix + perspective projection via tan(fov/360 * PI)
```

**移植注意：** 原 shader 带绿幕去除（`delete_color` / `delete_tolerance`），NinKing 的卡片无绿幕需求，可移除或保留（默认 `vec3(0.0, 0.5, 0.5)` 不会误杀）。

**Uniform 清单：**

| uniform | 类型 | 默认值 | 说明 |
|---------|------|--------|------|
| `fov` | float | 90 | 视野角度，控制透视强度 |
| `cull_back` | bool | true | 剔除背面（不可见时 discard） |
| `y_rot` | float | 0.0 | Y 轴旋转（材质旋转，非节点 rotation） |
| `x_rot` | float | 0.0 | X 轴旋转 |
| `inset` | float | 0.0 | 缩放防止旋转裁剪 |
| `delete_color` | vec3 | (0,0.5,0.5) | 绿幕色，可忽略 |
| `delete_tolerance` | float | 0.2 | 绿幕容差 |

**挂载方式：** 材质挂在 `Card` Control 本体上，子节点 TextureRect 继承渲染。

### 2.3 fake3d_flash.gdshader — 辉光/闪光（替代 card_glow）

**为什么替代 card_glow：**
- `card_glow.gdshader` 只做金色边缘脉冲，功能单一
- `fake3d_flash` 内置 3D 透视 + 三种闪光模式（纯色/彩虹/渐变）+ 遮罩 + 条带动画 + 颜色筛选
- `fake3d_flash` 用 `use_flash` uniform 开关控制，关闭时退化为 `fake3d.gdshader` 的行为
- 不需要 flash 时直接用 `fake3d.gdshader` 更省性能

**Uniform 清单（fake3d 基础 + 闪光扩展）：**

| uniform | 类型 | 默认值 | 说明 |
|---------|------|--------|------|
| `use_flash` | bool | false | 闪光开关 |
| `flash_filter_type` | int | 0 | 0=不筛选 1=排除色 2=只处理色 |
| `filter_color` | vec3 | (1,1,1) | 筛选参考色 |
| `flash_type` | int | 0 | 0=纯色 1=彩虹 2=渐变纹理 |
| `pure_flash_color` | vec4 | (1,1,1,1) | 纯色闪光颜色 |
| `gradient_texture` | sampler2D | — | 渐变贴图（type=2 时） |
| `mask_texture` | sampler2D | — | 遮罩贴图 |
| `speed` | float | 0.1 | 旋转因子速度 |
| `stripe_spacing` | float | 6.5 | 条纹密度 |
| `stripe_width` | float | 1.5 | 条纹宽度 |
| `intensity` | float | 0.5 | 闪光强度 |
| `angle` | float | 45.0 | 闪光角度（度） |

**项目内使用场景：**
- `VisualState.SWAP_SOURCE` → `use_flash=true`, 纯色蓝光
- `VisualState.REDRAW_TARGET` → `use_flash=true`, 纯色红光
- 出牌选中 → `use_flash=true`, type=2 金色渐变（GoldenGlow）
- 稀有度卡牌 → 配置不同的 `intensity` 和 `speed`

### 2.4 dissolve2d.gdshader — 溶解消散（独立 API）

**不替代 `TweenFX.pop_out()`：** `pop_out()` 是 scale→0 + queue_free，轻量快速。dissolve 是带燃烧边缘的完整消散动画，用于"退场仪式感"场景。

**Uniform 清单：**

| uniform | 类型 | 默认值 | 说明 |
|---------|------|--------|------|
| `dissolve_texture` | sampler2D | — | 噪声纹理（驱动消散图案） |
| `dissolve_value` | float | — | 消散进度，1=可见→0=消失 |
| `burn_border_size` | float | 0.0~1.0 | 燃烧边框宽度 |
| `burn_color` | vec4 | (1,1,1,1) | 燃烧边缘颜色，默认橙红 |

**挂载注意：**
- 材质挂在 Card 的 `Control` 本体
- 子节点的 `TextureRect` 需设置 `use_parent_material = true`
- 噪声纹理每张卡 randomization：`noise.noise.seed = randi()`

**项目内使用：**
- `NinjaBarNode._animate_out()` 中，替代 fade+scale 的消失方式
- 卡牌出售/退场演出
- 非必要退场用 `pop_out()`（快），仪式性退场用 `dissolve_out()`（慢）

### 2.5 fake3d_shadow.gdshader — 3D 阴影

**与原 Shadow Shader 的差异：**
- 原 `fake3d_shadow` 支持 `selected` 模式（金色高亮阴影）和普通黑阴影
- 与 `fake3d.gdshader` 共享相同的旋转矩阵，确保阴影跟随卡面透视

**NinKing 使用方式：**
- 不作为独立节点，而是集成到 `fake3d_flash.gdshader` 或作为独立的 Shadow `TextureRect` 子节点
- Phase 1 暂不导入，Phase 3 中配合动态阴影一起做

---

## 3. TweenFX 扩展

### 3.1 arc+elastic 弧线补间 `move_arc()`

在 `scripts/tween/tween_fx.gd` 中新增以下函数：

```gdscript
## 弧线弹性补间：前 73% 沿贝塞尔弧线线性运动，后 27% 弹性归位。
## start_pos: 起始位置（global）
## end_pos: 目标位置（global）
## control_offset: 控制点偏移量（垂直方向），越大曲线弧度越大
## duration: 总时长
## 返回 Tween，可 await .finished
static func move_arc(
    node: CanvasItem,
    end_pos: Vector2,
    control_offset: float = 0.5,
    duration: float = 0.5
) -> Tween
```

**算法：**
```gdscript
# 两阶段补间（与 Fake3D demo `to_pos() type 4` 一致）：
# 1. 贝塞尔弧线运动（73% 时长，TRANS_LINEAR）
#    - 计算控制点 perpendicular 偏移
#    - tween_method 驱动 _update_bezier_position
# 2. 弹性归位（27% 时长，TRANS_ELASTIC EASE_OUT）
#    - tween_method 从 0.73 继续到 1.0
```

**内部函数：**
```gdscript
static func _bezier_cubic(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2
static func _calculate_control_points(start: Vector2, end: Vector2, intensity: float) -> Array[Vector2]
```

**Domain 注册：** 注册到 `"position"` domain，与现有 `slide_in`/`shake_node` 共享防冲突组。

**使用场景：**
- 出牌动画（从手位到结算位）
- 忍者卡登场（从牌组位置弹射到忍者栏）
- 商店购买卡牌飞入手中
- 排序/重排时的弧线位移

### 3.2 dissolve 封装 `dissolve_out()`

在 `scripts/tween/tween_fx.gd` 中新增：

```gdscript
## 溶解消散：噪声驱动 + 燃烧边缘。独立 API，不替代 pop_out。
## 需要材质预先挂载 dissolve2d.gdshader。
static func dissolve_out(
    node: CanvasItem,
    duration: float = 1.0,
    burn_border_size: float = 0.2,
    burn_color: Color = Color(1.0, 0.4, 0.1, 1.0)
) -> Tween
```

不参与 auto_kill（消散过程通常不打断），返回 Tween 可 await。

---

## 4. 材质策略

### 4.1 Shader 分层

fake3d / fake3d_flash / dissolve2d 都是 `shader_type canvas_item`，不能同时挂在一个 `material` 槽位上。解决策略：

| 卡片类型 | 默认材质 | 闪辉时换材质 | 消散时换材质 |
|---------|---------|-------------|-------------|
| NinKingCard | `fake3d.gdshader` | `fake3d_flash.gdshader` | `dissolve2d.gdshader` |
| NinjaInventoryCard | `fake3d.gdshader` | `fake3d_flash.gdshader` | `dissolve2d.gdshader` |

**实现方式：**
- 每种卡牌持有 2 个 `ShaderMaterial` 预制资源（.tres）：`fake3d_mat.tres` / `flash_mat.tres` / `dissolve_mat.tres`
- 需要切换时用 `material = flash_mat`，完成后恢复
- 与 `VisualState` 集成：`set_visual_state(SWAP_SOURCE)` 时自动切换为 flash 材质并配置蓝色闪光参数

### 4.2 dissolve 的 use_parent_material

```gdscript
# dissolve 时子节点材质继承
texture_rect.use_parent_material = true
material = dissolve_mat
# tween dissolve_value
tween.tween_property(material, "shader_parameter/dissolve_value", 0.0, duration).from(1.0)
# 完成后恢复
tween.finished.connect(func():
    texture_rect.use_parent_material = false
    material = default_mat
)
```

### 4.3 现有 card_glow 退役流程

引入 fake3d_flash 并验证功能覆盖后：
1. 所有引用 `card_glow.gdshader` 的代码改为使用 `fake3d_flash.gdshader`（`use_flash=true`, `flash_type=0`, 金色）
2. 确认无引用后删除 `shaders/card_glow.gdshader`

---

## 5. 实施计划

### Phase 1 — 着色器导入 + 资源预制（1-2 天）

```
1. 创建 shaders/fake3d/ 目录
2. 复制 fake3d.gdshader（MIT, Hei）→ shaders/fake3d/fake3d.gdshader
3. 复制 fake3d_flash.gdshader（MIT, Hei）→ shaders/fake3d/fake3d_flash.gdshader
4. 复制 dissolve2d.gdshader（MIT, Hei）→ shaders/fake3d/dissolve2d.gdshader
5. 为 NinKingCard / NinjaInventoryCard 创建默认材质的 .tres 预制
   - res://resources/materials/ninja_card_fake3d.tres
   - res://resources/materials/ninja_card_flash.tres
   - res://resources/materials/ninja_card_dissolve.tres
6. 所有 .gdshader 文件 UTF-8 无 BOM, LF 换行 ✅
```

**涉及文件：** 仅新增，不修改现有 `.gd`。

### Phase 2 — TweenFX 扩展（1 天）

```
1. TweenFX 新增 move_arc() + 内部辅助函数
2. TweenFX 新增 dissolve_out()
3. GlobalTweens 新增同名委托方法
4. 更新 docs/tween-library-reference.md 场景速查表
```

**涉及文件：**
- `scripts/tween/tween_fx.gd` — 扩展
- `scripts/tween/global_tweens.gd` — 扩展
- `docs/tween-library-reference.md` — 同步

### Phase 3 — 卡牌集成 + 替换 card_glow（2-3 天）

```
1. NinKingCard._ready() 挂 fake3d 材质，替换 card_glow
2. NinjaInventoryCard._ready() 挂 fake3d 材质
3. VisualState SWAP_SOURCE / REDRAW_TARGET → 改为 flash 材质 + 配置颜色
4. Card hover 时动态调整 y_rot 轻微倾斜（与 CardTilt.rotation 协同）
5. 动态阴影：新增 Shadow TextureRect 子节点 + _process 光源跟随
6. 删除 shaders/card_glow.gdshader
```

**涉及文件：**
- `scripts/ninking/ui/ninking_card.gd`
- `scripts/ninking/ui/ninja_inventory_card.gd`
- `scenes/ninking/ninking_card.tscn`
- `shaders/card_glow.gdshader`（删除）

### Phase 4 — dissolve 场景接入（1 天）

```
1. NinjaBarNode._animate_out() 可选 dissolve 消失路径
2. 忍者撤销/替换时 dissolve 退场
3. 商店出售卡牌 dissolve 效果
```

### Phase 5 — 清理与文档（0.5 天）

```
1. docs/vfx-system-design.md 同步更新
2. docs/tween-library-reference.md 最终检查
3. 废弃的 card_glow 资源清理
```

---

## 6. 材质资源预制（.tres）

### ninja_card_fake3d.tres

```gdscript
ShaderMaterial:
  shader = preload("res://shaders/fake3d/fake3d.gdshader")
  shader_parameter/fov = 90.0
  shader_parameter/inset = 0.0
  shader_parameter/cull_back = true
  # y_rot / x_rot 运行时由代码驱动
```

### ninja_card_flash.tres

```gdscript
ShaderMaterial:
  shader = preload("res://shaders/fake3d/fake3d_flash.gdshader")
  shader_parameter/fov = 90.0
  shader_parameter/use_flash = false  # 默认关闭，选中时设 true
  shader_parameter/flash_type = 0     # 纯色
  shader_parameter/pure_flash_color = Color(1.0, 0.82, 0.0, 0.7)  # 金色（与原 card_glow 一致）
  shader_parameter/intensity = 0.5
  shader_parameter/stripe_spacing = 6.5
  shader_parameter/stripe_width = 1.5
```

### ninja_card_dissolve.tres

```gdscript
ShaderMaterial:
  shader = preload("res://shaders/fake3d/dissolve2d.gdshader")
  shader_parameter/dissolve_texture = preload("res://path/to/noise_texture.tres")
  shader_parameter/burn_border_size = 0.2
  shader_parameter/burn_color = Color(1.0, 0.4, 0.1, 1.0)  # 橙红
```

---

## 7. 与现有系统的交互

### 7.1 与 CardTilt 的关系

| 维度 | CardTilt（现有） | Fake3D shader（新增） |
|------|----------------|---------------------|
| 操作对象 | `node.rotation`（Z 轴空间旋转） | `shader_parameter/x_rot/y_rot`（纹理透视） |
| 视觉效果 | 卡牌在 2D 平面上旋转 | 卡面纹理在 3D 视角下透视变形 |
| 互斥？ | ❌ 不互斥，协同工作 | joint 效果：卡牌在桌面上旋转 + 卡面纹理随视角透视 |

**协同效果：手牌扇形摊开时，每张卡有 Z 轴旋转（CardTilt），同时卡面因透视略有 Y 轴旋转（Fake3D），模仿真实桌面观感。**

### 7.2 与 Card Framework 的关系

| 框架 API | 影响 | 说明 |
|---------|------|------|
| `card_container.on_card_pressed(self)` | 无影响 | 纯渲染增强，不涉及容器逻辑 |
| `set_faces(front, back)` | 无影响 | 仍操作 TextureRect.texture，shader 读取 TEXTURE 不变 |
| `_handle_mouse_pressed/released` | 无影响 | 点击逻辑不变 |
| `DraggableState.HOVERING` | 可选增强 | 进入 HOVERING 时设置轻微 y_rot 视差 |
| `move(target_pos, 0)` | 无影响 | 位置动画由 Tween 控制，shader 被动渲染 |

### 7.3 与现有 Tween/VFX 框架的关系

| 现有 API | 冲突 | 说明 |
|---------|------|------|
| `pop_in()` | ❌ 不冲突 | 仍用于基础入场，scale 动画不受 shader 影响 |
| `pop_out()` | ❌ 不冲突 | quick退场，dissolve_out 是独立的仪式性退场 |
| `card_hover()` | ❌ 不冲突 | 悬浮放大 + 上移，与 fake3d 透视叠加 |
| `card_glow.gdshader` | 🔴 被替代 | 验证覆盖后删除 |
| `Color(Color.GOLD, 0.15)` | ❌ 不冲突 | 纯色 modulate flash 与 shader flash 可并存 |

---

## 8. 性能注意事项

- **fake3d.gdshader** 是 vertex + fragment 运算，每帧在 GPU 计算旋转矩阵。同时渲染 ~20 张卡牌时完全可接受
- **fake3d_flash.gdshader** 比 fake3d 多约 50% fragment 运算（条纹+遮罩+颜色混合）。建议只对"选中/高亮"中的卡牌启用 `use_flash=true`，其他卡保持 `use_flash=false` 或使用 `fake3d.gdshader`
- **dissolve2d.gdshader** 运行时间短（仅消散动画期间），对持续帧率无影响
- 在 `hide()` 或 `visible=false` 的卡牌上，Godot 不会执行 fragment shader

---

## 9. 许可证

所有从 [Godot4-Fake3D-Card-Game-UI-Demo](https://github.com/Fulafu-ai/Godot4-Fake3D-Card-Game-UI-Demo) 复制的着色器文件均标注 **MIT License — Hei** 并保留原注释。
TweenFX 扩展代码（`move_arc()` / `dissolve_out()`）为 NinKing 项目原创，保留本项目许可证。

---

## 10. 附录：关键代码参考

### 10.1 Fake3D demo `card_UI.gd` 中可参考的代码片段

#### 贝塞尔弧线补间（`to_pos() type 4`）

```gdscript
# 两阶段弧线运动
var start_pos = global_position
var control_points = calculate_control_points(start_pos, final_pos, 0.5)

# Phase 1: 弧线（73% 时长，LINEAR）
tween_pos.set_trans(Tween.TRANS_LINEAR)
tween_pos.tween_method(_update_bezier_position.bind(start_pos, cp[0], cp[1], final_pos), 0.0, 0.73, 0.3 * _time)

# Phase 2: 弹性归位（27% 时长，ELASTIC）
tween_pos.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
tween_pos.tween_method(_update_bezier_position.bind(start_pos, cp[0], cp[1], final_pos), 0.73, 1.0, 0.7 * _time)
```

#### 控制点计算

```gdscript
func calculate_control_points(start: Vector2, end: Vector2, intensity: float) -> Array:
    var direction = (end - start).normalized()
    var distance = start.distance_to(end)
    var perpendicular = Vector2(-direction.y, direction.x) * intensity
    var control1 = start + direction * (distance * 0.3) + perpendicular * (distance * 0.5)
    var control2 = start + direction * (distance * 0.7) + perpendicular * (distance * 0.3)
    return [control1, control2]
```

#### 动态阴影 + 闪光角度

```gdscript
func _handle_light_and_shadow(delta: float) -> void:
    var center: Vector2 = get_viewport_rect().size / 2.0
    var distance: float = global_position.x + size.x * scale.x / 2 - center.x

    shadow.position.x = lerp(0.0, shadow_offset_max * sign(distance), abs(distance / center.x))
    var flash_angle = rad_to_deg(Vector2.UP.angle_to(global_position - center)) - rotation
    card_texture.material.set("shader_parameter/angle", flash_angle)
```

#### 溶解消散

```gdscript
func to_dissolve(dissolve_value: float, time: float = 2.0) -> void:
    card_texture.use_parent_material = true
    card_back_texture.use_parent_material = true

    var noise: NoiseTexture2D = material.get("shader_parameter/dissolve_texture")
    noise.noise.seed = randi()

    tween_dissolve = create_tween().set_trans(Tween.TRANS_CUBIC)
    tween_dissolve.tween_property(material, "shader_parameter/dissolve_value", dissolve_value, time).from(1.0)
    tween_dissolve.parallel().tween_property(shadow.material, "shader_parameter/alpha", 0.0, time * 0.7)
    tween_dissolve.tween_callback(queue_free)
```

### 10.2 NinKing 已有 vs 新增对照

| 能力 | 已有 | 新增方案 |
|------|------|---------|
| 卡牌材质 | 无 shader | `fake3d.gdshader`（透视变形） |
| 选中高亮 | `modulate` 纯色 | `fake3d_flash.gdshader`（动态条纹+渐变） |
| 消失效果 | `pop_out()` scale→0 | `dissolve_out()` 燃烧消散 + `pop_out()` 保留 |
| 卡牌位移 | position tween | `move_arc()` 弧线弹性补间 |
| 阴影 | StyleBoxFlat shadow | 动态 Shadow node + 光源跟随（Phase 3） |
| 卡牌倾斜 | `CardTilt` rotation | + fake3d `x_rot/y_rot` 透视（叠加） |
