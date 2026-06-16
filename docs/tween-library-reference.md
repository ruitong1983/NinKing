# Tween & VFX 库参考手册

> 最后更新：2026-06-16 | 源码：`scripts/tween/`
>
> **铁律：实现任何 Tween/VFX 前，必须先查本文档。确认已有 API 是否覆盖需求，避免手写 `create_tween()`。**
>
> **安全：写补间代码前必查 §5 补间安全清单（8 项高频 bug 速查表）。**

---

## 架构总览

```
GlobalTweens (autoload, 胶水层)
├── TweenFX (autoload, 静态工具函数) ─── 18 个基础补间函数
├── ScreenShake ─── Camera2D 震动
├── ParticlePool ─── CPU 粒子预设爆发
├── HitStop ─── 顿帧/冻结帧
├── AudioCoupler ─── 动效-音效耦合
├── CardTilt ─── 卡牌倾斜/手牌摊开
├── CountUp ─── 数字滚动（线性/缓出/多段/计分行，BounceScore 内部依赖）
└── BounceScore ─── 计分弹性着陆（蓄力→过冲→弹跳→ProgressBar→闪色）
```

| 组件 | 文件 | 类型 | 定位 |
|------|------|------|------|
| **GlobalTweens** | `scripts/tween/global_tweens.gd` | autoload | 统一入口，对外 API 全部通过它调用 |
| **TweenFX** | `scripts/tween/tween_fx.gd` | autoload（静态类） | 基础补间：淡入淡出、弹入弹出、缩放、抖动、滑入滑出、闪色、悬浮 |
| **ScreenShake** | `scripts/tween/screen_shake.gd` | class_name | Camera2D 震动（单次 + 创伤累积） |
| **ParticlePool** | `scripts/tween/particle_pool.gd` | class_name | CPUParticles2D 预设爆发 |
| **HitStop** | `scripts/tween/hit_stop.gd` | class_name | 顿帧：冻结 time_scale 后平滑恢复 |
| **AudioCoupler** | `scripts/tween/audio_coupler.gd` | class_name | Tween 内联音效 + 一次性音效 |
| **CardTilt** | `scripts/tween/card_tilt.gd` | class_name | 卡牌随鼠标倾斜 + 手牌扇形摊开 |
| **CountUp** | `scripts/tween/count_up.gd` | class_name | Label 数字递增/多段滚动/计分行（play_multi / play_score） |
| **BounceScore** | `scripts/tween/bounce_score.gd` | RefCounted (preload) | 计分弹性着陆：蓄力→过冲暴涨→缩放弹跳→ProgressBar延迟→ColXiLabel闪+PanelBg发光 |

---

## 场景速查（从这里开始！）

按"想做什么"直接找对应的 `GlobalTweens.xxx()` 调用：

### 卡牌/UI 交互

| 场景 | 调用 | 说明 |
|------|------|------|
| 卡牌/面板弹入 | `GlobalTweens.pop_in(node, 0.3)` | scale 0.1→1，BACK 缓出 |
| 卡牌/面板弹出+释放 | `GlobalTweens.pop_out(node, 0.2)` | scale→0.01 + queue_free |
| 淡入显示 | `GlobalTweens.fade_in(node, 0.3)` | alpha 0→1，SINE 缓出 |
| 淡出隐藏 | `GlobalTweens.fade_out(node, 0.3)` | alpha→0，SINE 缓入 |
| 淡出+自动释放 | `GlobalTweens.fade_out_then_free(node, 0.3)` | 淡出后 queue_free |
| 一次性缩放弹跳 | `GlobalTweens.scale_pop(node, 1.2, 0.2)` | scale 过冲→1.0，BACK 缓出 |
| 弹性冲入（大 overshoot） | `GlobalTweens.punch_in(node, 0.4, 1.5)` | ELASTIC scale 过冲回弹 |
| Toast 通知 | `GlobalTweens.toast(label, 1.5)` | 淡入→停留→淡出→释放 |
| 列表逐项错峰入场 | `GlobalTweens.stagger_slide_in(nodes, 0.12, 0.3)` | 淡入+左滑，每项间隔 stagger |
| 弧线弹性补间 | `GlobalTweens.move_arc(node, target_pos, 0.5, 0.5)` | 贝塞尔弧线+弹性归位 |
| 溶解消散 | `GlobalTweens.dissolve_out(node, 1.0, 0.2, Color.ORANGE)` | 需预先挂载 dissolve2d shader |
| 忍者触发 | `GlobalTweens.ninja_trigger(node, 0.6)` | Balatro 风弹起→wobble→squash 落回，auto_kill domain "ninja" |
| Shader 参数单次补间 | `GlobalTweens.tween_shader_param(node, material, "param", to_val, 0.15)` | 将 ShaderMaterial 的 shader_parameter 补间到目标值 |
| Shader 参数脉冲循环 | `GlobalTweens.shader_pulse(node, material, "param", 0.5, 0.9, 0.8)` | 在 min/max 间循环呼吸，EASE_IN_OUT_SINE，适用于自发光/传奇呼吸 |
| 卡牌 hover 放大 | `GlobalTweens.card_hover(node, Vector2(1.05,1.05), -4.0)` | scale+上浮 |
| 卡牌 unhover 还原 | `GlobalTweens.card_unhover(node, Vector2.ONE, 0.0)` | scale+位置归位 |
| 卡牌倾斜追踪鼠标 | `GlobalTweens.enable_card_tilt(node)` | 每帧跟随鼠标旋转 |
| 取消卡牌倾斜 | `GlobalTweens.disable_card_tilt(node)` | Tween 回正 |
| 手牌扇形摊开 | `GlobalTweens.set_hand_spread(cards, center)` | 弧形布局+微倾斜 |
| 卡牌中心散开（卷轴展开） | `GlobalTweens.stagger_spread(nodes, center, 400, 40, 0.06, 0.3)` | 弧位计算→归位中心→stagger 弹入。忍者主题发牌 |
| 数字滚动（计数） | `GlobalTweens.count_up(label, to_val, 0.5)` | 线性递增 |
| 数字滚动（金币） | `GlobalTweens.count_up_gold(label, amount, 0.6)` | 缓出+金色闪烁 |
| 多段数字滚动（通用） | `GlobalTweens.play_multi(label, segments, per_tick)` | 多段独立 easing，tick 合并 |
| 计分行滚动 | `GlobalTweens.play_score(label, chips, mult, result, 0.5, per_tick)` | "chips × mult = result" chips+mult 并行滚动 → 再滚 result，7-tier 分值驱动，pitch 递升(0.88→1.22) |

### 战斗反馈

| 场景 | 调用 | 说明 |
|------|------|------|
| 屏幕震动 | `GlobalTweens.screen_shake(0.15, 0.1)` | 单次 Camera2D 震动 |
| 顿帧/冻结帧 | `GlobalTweens.do_hit_stop(0.06, 0.05)` | time_scale→0.05，平滑恢复 |
| 粒子爆发 | `GlobalTweens.burst_particles(pos, "sparkle")` | 预设：sparkle/dust/confetti |
| 动效绑定音效 | `GlobalTweens.bind_sfx(tween, stream, 0.0)` | Tween 播放到指定秒触发音效 |
| 播放一次性音效 | `GlobalTweens.play_sfx(stream, 0.0)` | 创建 AudioStreamPlayer 播放 |

### 视觉滤镜

| 场景 | 调用 | 说明 |
|------|------|------|
| ⛔ ~~开关 CRT 滤镜~~ (已移除) | — | V24 移除，漫画风不再需要 |

---

## 1. GlobalTweens — 统一入口（autoload）

**文件：** `scripts/tween/global_tweens.gd`

**不要直接调子系统。所有 VFX 都通过 GlobalTweens 调用。** 它是胶水层，内部持有各子系统实例，提供统一 API。

### 1.1 基础补间 & 卡牌动效

```gdscript
# 弹入弹出（委托给 TweenFX）
GlobalTweens.pop_in(node: Node, duration: float = 0.3) -> Tween
GlobalTweens.pop_out(node: Node, duration: float = 0.2) -> Tween

# 淡入淡出（委托给 TweenFX）
GlobalTweens.fade_in(node: CanvasItem, duration: float = 0.3) -> Tween
GlobalTweens.fade_out(node: CanvasItem, duration: float = 0.3) -> Tween
GlobalTweens.fade_out_then_free(node: CanvasItem, duration: float = 0.3) -> Tween

# 缩放弹跳（委托给 TweenFX）
GlobalTweens.scale_pop(node: Node, factor: float = 1.2, duration: float = 0.2) -> Tween
GlobalTweens.punch_in(node: Node, duration: float = 0.4, peak_scale: float = 1.5) -> Tween

# Toast & 列表入场（委托给 TweenFX）
GlobalTweens.toast(node: CanvasItem, hold_duration: float = 1.5, fade_in_dur: float = 0.2, fade_out_dur: float = 0.3) -> Tween
GlobalTweens.stagger_slide_in(nodes: Array, stagger: float = 0.12, dur: float = 0.3, slide_offset: float = 30.0) -> void

# 悬浮（委托给 TweenFX）
GlobalTweens.card_hover(node: CanvasItem, scale_to: Vector2 = Vector2(1.05, 1.05), offset_y: float = -4.0) -> Tween
GlobalTweens.card_unhover(node: CanvasItem, original_scale: Vector2 = Vector2.ONE, original_y: float = 0.0) -> Tween

# 倾斜追踪（委托给 CardTilt）
GlobalTweens.enable_card_tilt(node: CanvasItem) -> void     # 开启 per-frame 鼠标追踪
GlobalTweens.disable_card_tilt(node: CanvasItem) -> void    # Tween 回正 + 停止追踪
GlobalTweens.set_hand_spread(cards: Array, center_pos: Vector2 = Vector2.ZERO) -> void  # 扇形摊开

# 中心散开 — 卷轴展开（委托给 TweenFX）
GlobalTweens.stagger_spread(nodes: Array, center_pos: Vector2, radius: float = 400.0, spread_angle_deg: float = 40.0, stagger: float = 0.06, dur: float = 0.3) -> void  # 弧位计算→归位中心→stagger 弹入
```

**CardTilt 可调参数**（在 `card_tilt.gd` 中修改）：
- `tilt_strength: float = 0.03` — 倾斜强度
- `spread_angle: float = 8.0` — 摊开扇形角度（度）
- `spread_radius: float = 400.0` — 摊开半径
- `lerp_speed: float = 12.0` — 倾斜过渡速度

### 1.2 震动 & 顿帧

```gdscript
# 屏幕震动（委托给 ScreenShake）
GlobalTweens.screen_shake(intensity: float = 0.15, duration: float = 0.08) -> void
GlobalTweens.shake_screen(intensity: float = 0.15, duration: float = 0.08) -> void  # 别名

# 顿帧（委托给 HitStop）
GlobalTweens.do_hit_stop(duration: float = 0.06, time_scale: float = 0.05) -> void
```

**ScreenShake 额外能力**（如需直接使用 `ScreenShake` 实例）：
- `add_trauma(amount: float)` — 创伤累积模式，每次叠加，quadratic 衰减
- 可调参数：`max_offset: Vector2 = Vector2(20, 15)`, `max_rotation: float = 2.0`, `_decay_rate: float = 2.5`

**HitStop 额外能力**（如需直接使用 `HitStop` 实例）：
- `freeze(duration, time_scale)` — 基础顿帧
- `freeze_stackable(duration, time_scale)` — 可堆叠顿帧（不覆盖更强的冻结）
- `cancel()` — 取消所有顿帧

### 1.3 数字滚动

```gdscript
# 委托给 CountUp
GlobalTweens.count_up(label: Label, to_value: int, duration: float = 0.5, prefix: String = "", suffix: String = "") -> Tween
GlobalTweens.count_up_gold(label: Label, amount: int, duration: float = 0.6, prefix: String = "", suffix: String = "") -> Tween

# 多段滚动（v5 新增）
GlobalTweens.play_multi(label: Label, segments: Array[Dictionary], per_tick: Callable = Callable()) -> Tween
GlobalTweens.play_score(label: Label, chips: int, mult: int, result: int, duration: float = 0.5, per_tick: Callable = Callable()) -> Tween
```

**`play_multi`** — 通用多段数字滚动。一条 tween_method 驱动多段数值按 `delay` 顺序启动，独立 easing + milestone tick 检测，每帧最多一次 `per_tick(pitch)` 回调。segment 结构：
- `{"value": int, "duration": float, "delay": float?, "ticks": int?, "ease": int?, "trans": int?}` — 从 0 滚到 value，延迟 delay 后启动，独立 easing（默认 EASE_OUT CUBIC），ticks 为音效里程碑数
- `{"text": String}` — 静态分隔符文本，始终渲染

**`play_score`** — 计分行快捷包装。格式 `"chips × mult = result"`，**chips+mult 并行滚动**（同时启动，duration 取两者较大值），然后顺序滚动 result，7-tier 分值驱动（阈值 20/100/200/400/800/1600），tick 沿 cubic-out 曲线 milestone 分布（稀疏→密集），pitch 递升(0.88→1.22, +0.05/tick)。result 到达时自动 `FX.color_flash(label, Color.GOLD, 0.15)`。

**CountUp 额外能力**（如需直接使用）：
- `CountUp.play(label, from_value, to_value, duration, prefix, suffix, per_tick)` — 线性递增
- `CountUp.play_eased(label, from_value, to_value, duration, prefix, suffix, per_tick)` — EASE_OUT CUBIC 缓出
- `CountUp.play_gold(label, amount, duration, prefix, suffix, per_tick)` — 缓出 + 到达时金色闪烁
- `CountUp.play_multi(label, segments, per_tick)` — 多段滚动（自动 kill 同 label 旧补间）
- `CountUp.play_score(label, chips, mult, result, duration, per_tick)` — 计分行快捷包装

所有 CountUp 方法内部设置 `set_ignore_time_scale(true)`，HitStop 不影响数字滚动。

### 1.4 粒子

```gdscript
# 委托给 ParticlePool
GlobalTweens.burst_particles(position: Vector2, preset: String = "sparkle") -> void
```

**预设列表：**

| 预设 | 数量 | 寿命 | 颜色 | 扩散角 | 速度范围 |
|------|------|------|------|--------|----------|
| `"sparkle"` | 10 | 0.4s | 金色 (1, 0.843, 0) | 90° | 40–100 |
| `"dust"` | 6 | 0.3s | 灰色 (0.7, 0.7, 0.7) | 30° | 20–60 |
| `"confetti"` | 18 | 0.8s | 金色 GOLD | 120° | 60–150 |
| `"shuriken"` | 8 | 0.35s | 铁灰 (0.35,0.35,0.4) | 360° | 60–130 |
| `"sakura"` | 12 | 0.7s | 淡粉 (0.95,0.65,0.75) | 150° | 30–90 |

**自定义粒子**（直接使用 ParticlePool）：
```gdscript
ParticlePool.burst_custom(position, amount, lifetime, color, texture, spread, velocity_min, velocity_max)
```

### 1.5 Shader 参数动效

```gdscript
# Shader 参数单次补间（委托给 TweenFX）
GlobalTweens.tween_shader_param(context_node: Node, material: ShaderMaterial, param_name: String, to_value: Variant, duration: float = 0.15) -> Tween

# Shader 参数脉冲（无限循环，委托给 TweenFX）
GlobalTweens.shader_pulse(context_node: Node, material: ShaderMaterial, param_name: String, min_val: float, max_val: float, cycle_duration: float = 0.8) -> Tween
```

- `tween_shader_param`：将 `material.shader_parameter/<param_name>` 从当前值补间到 `to_value`。EASE_OUT SINE。auto_kill domain `"shader_param|<name>"`。适用于悬停加速/恢复 shader 参数。
- `shader_pulse`：无限循环在 `min_val ↔ max_val` 之间，EASE_IN_OUT SINE，半周期 = `cycle_duration / 2`。auto_kill domain `"shader_pulse|<name>"`。适用于呼吸发光等持续性动效。

**注意：** `context_node` 必须是在场景树中的节点（用于 `create_tween()`），而 `material` 可以是独立的 ShaderMaterial 实例。这允许对非 Node 的材质资源做属性补间。

**使用场景：** 忍者卡牌稀有度材质（Foil/Holo/Polychrome）的悬停加速和传奇呼吸脉冲均通过这两个 API 实现，无需手写 `create_tween()`。

### 1.6 音效耦合

```gdscript
# 在 Tween 播放到 at_elapsed 秒时触发音效
GlobalTweens.bind_sfx(tween: Tween, stream: AudioStream, at_elapsed: float = 0.0) -> void

# 立即播放一次性音效
GlobalTweens.play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void
```

**注意：** `bind_sfx` 需要 tween 的 parent 节点在场景树中。`play_sfx` 自动挂到 root 播放，finished 后自动 queue_free。

### 1.6 ⛔ CRT 滤镜（已移除 V24）

CRT 扫描线/色差/暗角效果已在 V24 中移除，漫画风不再需要。

---

## 2. TweenFX — 基础补间函数（autoload，静态类）

**文件：** `scripts/tween/tween_fx.gd`

**核心特征：**
- 18 个纯静态函数，`TweenFX.xxx()` 直接调用
- 全部返回 `Tween` 对象，可 `await .finished`
- **内置 auto_kill 防冲突**：所有返回 Tween 的函数默认 `auto_kill=true`，重复调用自动 kill 旧补间
- 无状态管理、无 TweenManager、无 Animations 枚举
- 独立可移植：单文件拷走即用，零依赖

### 2.1 淡入/淡出

```gdscript
TweenFX.fade_in(node: CanvasItem, duration: float = 0.3) -> Tween
TweenFX.fade_out(node: CanvasItem, duration: float = 0.3) -> Tween
TweenFX.fade_out_then_free(node: CanvasItem, duration: float = 0.3) -> Tween
```

- `fade_in`：先设 alpha=0，SINE 缓出到 alpha=1
- `fade_out`：SINE 缓入淡出到 alpha=0
- `fade_out_then_free`：淡出后在 `tween_callback` 中 `queue_free`
- ⚠️ `fade_in` 会强制覆盖当前 alpha，如需从当前 alpha 过渡，手写 `tween_property("modulate:a", ...)`

`TweenFX.toast(node: CanvasItem, hold_duration: float = 1.5, fade_in_dur: float = 0.2, fade_out_dur: float = 0.3) -> Tween`

Toast 通知全流程：自动设 alpha=0 → 淡入 → 停留 `hold_duration` 秒 → 淡出 → `queue_free`。

### 2.2 弹入/弹出

```gdscript
TweenFX.pop_in(node: Node, duration: float = 0.3, from_scale: Vector2 = Vector2(0.1, 0.1)) -> Tween
TweenFX.pop_out(node: Node, duration: float = 0.2) -> Tween
```

- `pop_in`：scale 从 `from_scale` → 1.0，BACK EASE_OUT
- `pop_out`：scale → 0.01 + `queue_free`，BACK EASE_IN
- ⚠️ `pop_out` 内置 `tween_callback(queue_free)`，**不需要**节点保留时改用 `fade_out` 或手写

`TweenFX.punch_in(node: Node, duration: float = 0.4, peak_scale: float = 1.5) -> Tween`

ELASTIC 弹性过冲弹入。从当前 scale 冲到 `peak_scale`（60% 时长）再回弹到 1.0（40% 时长）。不修改起始 scale，调用方如需从小 scale 开始，自行设置 `node.scale` 后调用。

### 2.3 抖动/摇摆

```gdscript
TweenFX.shake_node(node: Control, intensity: float = 4.0, duration: float = 0.25) -> Tween
TweenFX.wobble(node: Node2D, angle_deg: float = 5.0, duration: float = 0.3) -> Tween
```

- `shake_node`：Control 专用，X 轴随机位移抖动，SINE 缓动循环，结束后归位
- `wobble`：Node2D 专用，三段式 rotation 摇摆 → 归零

### 2.4 脉冲/漂浮/缩放弹跳

```gdscript
TweenFX.pulse(node: Node, scale_to: Vector2 = Vector2(1.1, 1.1), duration: float = 0.6) -> Tween
TweenFX.scale_pop(node: Node, factor: float = 1.2, duration: float = 0.2) -> Tween
TweenFX.float_up(node: Node2D, offset_y: float = -40.0, duration: float = 0.8) -> Tween
```

- `pulse`：无限循环 scale 脉冲（`set_loops()` 无参数 = 无限）
- `scale_pop`：一次性 scale 弹跳（factor → 1.0），BACK EASE_OUT，两段式（60% up + 40% settle）
- `float_up`：Y 轴上浮 + alpha 淡出 + `queue_free`（飘字/粒子消散）

### 2.5 滑入/滑出

```gdscript
enum SlideDir { LEFT, RIGHT, UP, DOWN }

TweenFX.slide_in(node: Control, from_dir: SlideDir = SlideDir.UP, duration: float = 0.3) -> Tween
TweenFX.slide_out(node: Control, to_dir: SlideDir = SlideDir.DOWN, duration: float = 0.25) -> Tween
```

- 基于 viewport 尺寸全屏滑入/滑出
- `slide_in`：从屏幕外滑到原位，BACK EASE_OUT
- `slide_out`：滑出屏幕 + `queue_free`

`TweenFX.stagger_slide_in(nodes: Array, stagger: float = 0.12, dur: float = 0.3, slide_offset: float = 30.0) -> void`

列表逐项错峰入场。每项设 alpha=0、左移 `slide_offset` px，然后间隔 `i * stagger` 秒后并行淡入+右滑归位。fire-and-forget，不返回 Tween。

`TweenFX.stagger_spread(nodes: Array, center_pos: Vector2, radius: float = 400.0, spread_angle_deg: float = 40.0, stagger: float = 0.06, dur: float = 0.3) -> void`

卡牌从中心向弧位散开（卷轴展开效果）。单张居中，多张沿圆弧均匀分布（Y 轴压缩模拟透视）。全部归位到中心 → stagger 延迟后 BACK EASE_OUT 弹入目标弧位（position + scale + alpha 并行）。fire-and-forget，不返回 Tween。不参与 auto_kill。

**可调参数：**
- `radius` — 弧位半径，默认 400
- `spread_angle_deg` — 总展开角（度），默认 40°
- `stagger` — 每张间隔延迟，默认 0.06s
- `dur` — 位移动画时长，默认 0.3s

### 2.6 闪色

```gdscript
TweenFX.color_flash(node: CanvasItem, color: Color = Color.WHITE, duration: float = 0.1) -> Tween
```

- 设置 modulate = color，然后 SINE 缓动渐变回原始 modulate

### 2.7 卡牌悬浮

```gdscript
TweenFX.card_hover(node: CanvasItem, scale_to: Vector2 = Vector2(1.05, 1.05), offset_y: float = -4.0, duration: float = 0.15) -> Tween
TweenFX.card_unhover(node: CanvasItem, original_scale: Vector2 = Vector2.ONE, original_y: float = 0.0, duration: float = 0.15) -> Tween
```

- 并行 scale + Y 位移，BACK EASE_OUT
- 接受 `CanvasItem`（兼容 `Node2D` 和 `Control`），Button/Label 等 UI 节点直接可用
- 通常通过 `GlobalTweens.card_hover/card_unhover` 调用，与 CardTilt 配合

### 2.8 忍者触发（Balatro 风格打击感强化）

```gdscript
TweenFX.ninja_pop_trigger(node: Node, duration: float = 0.6) -> Tween
```

忍者触发组合动画（Balatro 小丑牌风格强化）：弹起 → 停顿 → squash 落回。
- Phase 1 (0-0.10s): scale 1.0→1.35 + y -18px + rotation ±3° wobble（EASE_OUT QUAD，并行，snappy pop）
- Phase 2 (0.10-0.18s): 短暂峰值停留 → rotation 反向 -2° wobble
- Phase 3 (0.18-0.48s): squash 压缩 0.85 → ELASTIC 弹性归位 1.0 + y 归位（BACK EASE_OUT）+ rotation 归零
- 内部管理 pivot_offset + rotation，自动恢复
- auto_kill domain: `"ninja"`（与 scale/position/modulate/rotation 隔离）
- 配合白闪→金闪+屏幕震动+粒子爆发可获得 Balatro 风完整打击感
- 通常通过 `GlobalTweens.ninja_trigger(node)` 调用

### 2.9 Shader 参数动效

```gdscript
TweenFX.tween_shader_param(context_node: Node, material: ShaderMaterial, param_name: String, to_value: Variant, duration: float = 0.15) -> Tween
TweenFX.shader_pulse(context_node: Node, material: ShaderMaterial, param_name: String, min_val: float, max_val: float, cycle_duration: float = 0.8) -> Tween
```

- `tween_shader_param`：单次补间。将 `material.shader_parameter/<param_name>` 从当前值补间到 `to_value`。EASE_OUT SINE。auto_kill domain `"shader_param|<name>"`。通过 `context_node` 创建 Tween（必须在场景树中），材质实例参数独立。
- `shader_pulse`：无限循环脉冲。在 `min_val ↔ max_val` 之间 EASE_IN_OUT SINE 往复，半周期 = `cycle_duration / 2`。auto_kill domain `"shader_pulse|<name>"`。适用于呼吸发光等持续性动效。

**设计理由：** shader_parameter 是 `set_shader_parameter(key, value)` 方法而非属性，但 Godot 4 支持 `shader_parameter/` 前缀的属性语法。这两个函数利用此语法直接对 ShaderMaterial 资源做属性补间，无需手写 `tween_method` + lambda。

**使用场景：** 忍者卡牌稀有度材质（Uncommon 金属箔 / Rare 全息 / Legendary 极光闪粉）的悬停加速和传奇呼吸脉冲。卡牌只存一个 `_flash_mat` 引用，主面和边框共享同一材质实例，一通补间同时影响两层。

---

## 3. VFX 子系统参考

以下子系统由 GlobalTweens 内部实例化，**一般通过 GlobalTweens 调用**。仅在需要高级功能时直接使用。

### 3.1 ScreenShake — Camera2D 震动

**文件：** `scripts/tween/screen_shake.gd` | class_name: `ScreenShake`

```gdscript
# 单次触发（GlobalTweens 封装）
GlobalTweens.screen_shake(intensity: float = 0.15, duration: float = 0.08)

# 创伤累积模式（直接使用实例）
GlobalTweens.shake.add_trauma(0.3)  # 每次 hit 叠加，quadratic 衰减
```

**可调参数**（修改实例属性）：
```gdscript
GlobalTweens.shake.max_offset = Vector2(20, 15)   # 最大位移
GlobalTweens.shake.max_rotation = 2.0              # 最大旋转(度)
GlobalTweens.shake._decay_rate = 2.5               # 创伤衰减速度
```

### 3.2 ParticlePool — 粒子预设

**文件：** `scripts/tween/particle_pool.gd` | class_name: `ParticlePool`

```gdscript
# 预设爆发
GlobalTweens.burst_particles(pos, "sparkle")

# 自定义爆发（直接使用实例）
GlobalTweens.particles.burst_custom(pos, amount, lifetime, color, texture, spread, vel_min, vel_max)
```

所有粒子自动 `one_shot=true`，`finished` 后 `queue_free`。

### 3.3 HitStop — 顿帧

**文件：** `scripts/tween/hit_stop.gd` | class_name: `HitStop`

```gdscript
# 基础（GlobalTweens 封装）
GlobalTweens.do_hit_stop(0.06, 0.05)

# 高级（直接使用实例）
GlobalTweens.hit_stop.freeze(0.06, 0.05)              # 基础顿帧
GlobalTweens.hit_stop.freeze_stackable(0.06, 0.05)    # 可堆叠（不覆盖更强的冻结）
GlobalTweens.hit_stop.cancel()                         # 取消全部
```

- 恢复为平滑 Tween（`set_ignore_time_scale(true)` 确保不受自身影响）
- 底层操作 `Engine.time_scale`

### 3.4 AudioCoupler — 音效耦合

**文件：** `scripts/tween/audio_coupler.gd` | class_name: `AudioCoupler`

```gdscript
# Tween 内联音效
GlobalTweens.bind_sfx(tween, stream, at_elapsed)

# 一次性音效
GlobalTweens.play_sfx(stream, volume_db)
```

- `bind_sfx`：创建一个忽略 time_scale 的子 tween，在 `at_elapsed` 秒后触发音效
- `play_sfx`：创建 AudioStreamPlayer 挂到 root，播放完毕后 `queue_free`

### 3.5 CardTilt — 卡牌倾斜

**文件：** `scripts/tween/card_tilt.gd` | class_name: `CardTilt`

```gdscript
GlobalTweens.enable_card_tilt(node)           # 开启追踪
GlobalTweens.disable_card_tilt(node)          # 停止 + 回正
GlobalTweens.set_hand_spread(cards, center)    # 扇形摊开
```

- `enable_single(node: CanvasItem)`：开始 `_process` 追踪，每帧根据鼠标相对位置计算 rotation
- `disable(node: CanvasItem)`：Tween rotation→0 + 从追踪列表移除（列表空时自动 `set_process(false)`）
- `apply_spread(nodes: Array, center_pos)`：单张居中，多张弧形排列（Y 轴压缩模拟透视）。接受 `CanvasItem` 数组
- 类型已拓宽为 `CanvasItem`，`Control` 节点也可使用倾斜追踪

### 3.6 CountUp — 数字滚动

**文件：** `scripts/tween/count_up.gd` | class_name: `CountUp` | 292 行

```gdscript
# 线性递增
CountUp.play(label, from_val, to_val, duration, prefix, suffix, per_tick) -> Tween

# 缓出递增（先快后慢）
CountUp.play_eased(label, from_val, to_val, duration, prefix, suffix, per_tick) -> Tween

# 金币滚动（缓出 + 金色闪烁）
CountUp.play_gold(label, amount, duration, prefix, suffix, per_tick) -> Tween

# 多段滚动 — 一条 tween 驱动多段数值，各段独立 delay/easing/ticks
CountUp.play_multi(label, segments: Array[Dictionary], per_tick: Callable) -> Tween

# 计分行快捷包装 — 7-tier 分值驱动 chips+mult 并行→顺序 result
CountUp.play_score(label, chips: int, mult: int, result: int, _duration_unused: float = 0.5, per_tick: Callable) -> Tween
```

所有方法 `set_ignore_time_scale(true)`。重复调用同 label 自动 `kill()` 旧补间（per-label 字典追踪）。

**`play_multi` 详解：**

单条 `tween_method(float t, 0.0, max_dur, max_dur)` 驱动，master tween 无 easing（线性 t），各 segment 在回调内部独立计算 `seg_elapsed = max(0, t - delay)` → `ease(seg_elapsed/dur, curve)` → 渲染。自然实现 tick 合并：每帧最多一次 `per_tick(pitch)` 回调。

segment 结构：
```gdscript
[
    {"value": 11, "duration": 0.5, "delay": 0.0, "ticks": 6, "ease": Tween.EASE_OUT, "trans": Tween.TRANS_CUBIC},
    {"text": " × "},                                     # 文本段：静态，始终渲染
    {"value": 3,  "duration": 0.4, "delay": 0.55, "ticks": 4},  # delay 控制顺序启动
    {"text": " = "},
    {"value": 33, "duration": 0.6, "delay": 1.0,  "ticks": 8},  # result 段 ticks 更多 → 更长音效
]
```

特性：
- `delay` 字段控制段启动时机，实现顺序滚动（非同时）
- `ticks` 字段控制音效里程碑数，均匀分布在 easing 曲线上（`floor(eased * ticks)`）
- 零值段跳过 tween，直接渲染 "0"
- easing 映射：EASE_OUT+CUBIC → curve=2.0, EASE_OUT+QUAD → curve=1.0, EASE_IN → curve=-1.0
- `per_tick` 回调仅在 label.text 实际变化且 milestone 推进时触发

**`play_score` 详解：**

7-tier 分值驱动计分行。内部按 result 值查表确定各段 ticks 数 + dt + gap_bonus，构建 5 段 `[chips, " × ", mult, " = ", result]`。chips 和 mult 同时启动（`mult_delay=0.0`），duration 取两者较大值 `maxf(chips_dur, mult_dur)`，然后 result 顺序启动。

| Tier | result | chips ticks | mult ticks | result ticks | 总 tick 数 | 总时长 |
|------|--------|-------------|------------|--------------|-----------|--------|
| T0 | <20 | 3 | 2 | 3 | 8 | ~1.4s |
| T1 | 20-99 | 4 | 3 | 4 | 11 | ~1.8s |
| T2 | 100-199 | 6 | 4 | 6 | 16 | ~2.9s |
| T3 | 200-399 | 7 | 5 | 8 | 20 | ~3.4s |
| T4 | 400-799 | 9 | 6 | 10 | 25 | ~4.5s |
| T5 | 800-1599 | 10 | 7 | 12 | 29 | ~5.5s |
| T6 | 1600+ | 11 | 8 | 14 | 33 | ~6.6s |

Tick 分布在 cubic-out 曲线上，稀疏→密集 + pitch 递升(0.88→1.22, +0.05/tick)。chips 和 mult 并行滚动（同 delay=0 启动），result 在两者中较长的 duration 结束后 + gap1 延迟启动。gap_bonus 随 tier 递增(0.00→0.10)拉大 chips+mult → result 的停顿。result 到达目标时链式追加 `FX.color_flash(label, Color.GOLD, 0.15)` 金色闪烁。

### 3.7 BounceScore — 计分弹性着陆

**文件：** `scripts/tween/bounce_score.gd` | 用法：`const BounceScore = preload(...)` → `BounceScore.play(...)`

```gdscript
# 计分时一次性调用，打包全部动效：
BounceScore.play(
    score_label,     # Label — 主分数 Label
    progress_bar,    # ProgressBar — 进度条
    col_xi_label,    # Label — 列喜预览 Label (金闪)
    panel_bg,        # ColorRect — 左侧面板背景（发光）
    old_score,       # int — 旧分数
    new_score,       # int — 新分数
    barrier_color,   # Color — 结界强调色（面板发光）
    bounce_sfx       # AudioStream = null — 峰值音效（可选）
)
```

**时序：** 蓄力白闪(0.08s) → 数字过冲+scale暴涨(0.58s, 1.6×, 30%过冲) → 过冲回落(0.08s) → 弹簧恢复(0.12s, TRANS_BACK) → 延迟(0.10s) → ProgressBar滑动+Chips/Mult金色闪+PanelBg结界色闪(0.25s)。总时长 ~1.2s。

**内部依赖：** `TweenFX.color_flash`（闪色）。数字滚动由自身 `tween_method` 实现，不依赖 CountUp。

**不触发时：** `old_score == new_score` → 直接 set text 返回。`new_score < old_score` → 简单线性 count 无弹跳。

### 3.8 CRTFilter — CRT 后处理 ⛔ 已移除

**文件：** `scripts/system/crt_filter.gd` | class_name: `CRTFilter`

```gdscript
GlobalTweens.set_crt_enabled(true)     # 开关
GlobalTweens.crt.set_scanline(0.5)     # 扫描线强度
GlobalTweens.crt.set_aberration(0.3)   # 色差强度
GlobalTweens.crt.set_vignette(0.4)     # 暗角强度
GlobalTweens.crt.set_warp(0.1)         # 扭曲强度
GlobalTweens.crt.set_brightness(1.0)   # 亮度
```

- 通过 CanvasLayer (layer=128) + ColorRect + ShaderMaterial 实现
- 依赖 `res://resources/shaders/crt_filter.gdshader`
- 场景加载后自动挂载（`child_entered_tree` CONNECT_ONE_SHOT）

---

## 4. 使用规范

### 4.1 优先原则

1. **先查场景速查表**（§场景速查），找到对应的 `GlobalTweens.xxx()` 调用
2. 若场景速查表未覆盖，再查后续 API 列表
3. 仅在所有已有 API 均不匹配时才手写 `create_tween()`
4. 手写后评估是否应抽象为新的库方法（见 §4.4）

### 4.2 await 模式

```gdscript
# TweenFX 函数返回 Tween，可 await .finished
await TweenFX.pop_in(panel, 0.3).finished
await TweenFX.slide_out(panel, TweenFX.SlideDir.DOWN, 0.25).finished

# GlobalTweens 返回 Tween 的函数同理
await GlobalTweens.pop_in(card, 0.3).finished
await GlobalTweens.count_up(label, 100, 0.5).finished

# ⚠️ 不可 await 的函数（返回 void）
# GlobalTweens.screen_shake / shake_screen
# GlobalTweens.do_hit_stop
# GlobalTweens.burst_particles
# GlobalTweens.enable_card_tilt / disable_card_tilt / set_hand_spread
# GlobalTweens.bind_sfx / play_sfx
```

### 4.3 防冲突（auto_kill）

所有返回 `Tween` 的函数默认 `auto_kill=true`。重复调用同一节点时，自动 `kill()` 旧补间再创建新的，**无需手动存引用**：

```gdscript
# ✅ 简洁写法（auto_kill 默认开启）
func _on_mouse_entered() -> void:
    GlobalTweens.card_hover(self)

func _on_mouse_exited() -> void:
    GlobalTweens.card_unhover(self, Vector2.ONE, 0.0)
```

```gdscript
# 需要同一节点同时运行多个独立补间 — 直接写即可，不同 domain 自动隔离
GlobalTweens.color_flash(node, Color.RED, 0.15)   # modulate domain，不影响 scale
GlobalTweens.scale_pop(node, 1.2, 0.2)             # scale domain，不影响 modulate
```

**实现原理：** TweenFX 内部维护 `_active_tweens: Dictionary`，以复合键 `"%d_%s" % [node.get_instance_id(), domain]` 追踪补间。**同一 node 不同 domain（如 `"modulate"` vs `"scale"`）互不冲突**，不再需要手动传 `auto_kill=false` 来并行运行不同属性的补间。创建新补间前 `_kill_tracked(node, domain)` kill 同 domain 旧补间，新补间 `finished` 时自动清理字典条目。

Domain 分配：`fade_in/fade_out/toast/color_flash` → `"modulate"`，`pulse/pop_in/punch_in/scale_pop` → `"scale"`，`slide_in/slide_out/shake_node` → `"position"`，`card_hover/unhover` → `"hover"`，`wobble` → `"rotation"`，`float_up` → `"float"`。

**信号处理器防重入**（async await 场景）仍需 `_guard` 标志位：

```gdscript
var _anim_guard: bool = false

func _on_animation_triggered() -> void:
    if _anim_guard:
        return
    _anim_guard = true
    await GlobalTweens.pop_in(self, 0.3).finished
    _anim_guard = false
```

### 4.4 调用规范（铁律）

- **外部代码只调 `GlobalTweens.xxx()`**，不直接调 `TweenFX` 或子系统
- `TweenFX` 是纯函数库，`GlobalTweens` 是唯一对外入口
- 例外：`toast_manager.gd` 等 autoload 间为避免初始化顺序问题，可 preload `tween_fx.gd` 直接调 `FX.xxx()`

### 4.5 新增方法规范

- 基础补间（弹入/抖动/滑入等通用动画）→ 放入 **TweenFX**（静态函数）
- 需要 per-frame 追踪或状态管理 → 新建或扩展现有 **class_name 子系统**
- GlobalTweens 添加委托方法暴露给外部
- 新增后**必须同步更新本文档**

### 4.6 已知限制

- `stagger_slide_in` 不参与 auto_kill（操作数组，每项独立补间）
- TweenFX `pop_out` / `slide_out` / `float_up` 内置 `queue_free`，不适合"退场后复用"场景
- `AudioCoupler.play_one_shot` 返回的 AudioStreamPlayer 需要调用方自行加入场景树
- `bind_sfx` 依赖 tween 的 parent 节点在场景树中
- 粒子系统使用占位纹理（程序生成的 8×8 径向渐变圆），替换为真实纹理可调用 `burst_custom`

---

## 5. 补间安全清单（写补间代码前必查）

以下 8 项是项目实践中发现的高频补间 bug：

| # | 检查项 | 错误症状 | 修复 |
|---|--------|---------|------|
| 1 | 信号处理器有 `await`？ | 重入 → 双重释放节点 | 入口加 `_guard` 标志位防重入 |
| 2 | 快速重复 `create_tween()`？ | 多补间争夺同一属性，闪烁 | 存引用，`kill()` 旧补间再创建 |
| 3 | `move_to` 前刚重新父子化？ | 节点飞到错误坐标 | 用局部 `position`（非 `global_position`） |
| 4 | 设置函数中调补间，节点可能不在树中？ | `"data.tree" is null` 崩溃 | 加 `if is_inside_tree():` 守卫 |
| 5 | 伤害/死亡补间是否冲突？ | 闪白与消失竞争 | `if _is_dying: return` 阻止伤害处理 |
| 6 | 异步 `_hide` 在 mouse_exited 中不加 `await`？ | 弹出/弹入同时播放 | 显示前 `kill()` 隐藏补间 + null 哨兵检查 |
| 7 | `fade_in` 后紧跟 `fade_out` 同一属性？ | `fade_in` 被 `fade_out` 覆盖 | 移除 `fade_in`，直接设 alpha=1.0 |
| 8 | 补间快速重入？ | 捕获中间 modulate/scale 值 | `kill()` 旧补间再创建 |

**一般原则：**
- 任何补间调用前，确认节点在场景树中（`is_inside_tree()`），否则 `create_tween()` 崩溃
- 任何可能被重复触发的补间，存储引用并在创建新补间前 `kill()` 旧的
- 重新父子化操作后，始终使用局部坐标做补间，不混用 `global_position`
- 信号处理器中的异步补间，始终用守卫标志位防止重入

---

## 附录 A：为什么没有 TweenHelper

`scripts/system/tween_helper.gd` 在当前版本中**不存在**。设计文档中描述的战斗反馈函数（`flash_white`, `fly_arc`, `float_up_then_free`, `stagger_fade_in` 等）尚未实现。

如需这些能力，有两种路径：
1. **按需添加**：用到哪个就实现哪个，放入 TweenFX（静态函数）或新建子系统
2. **批量实现**：创建 `TweenHelper` 静态类，按文档 API 实现战斗反馈函数

当前项目实际使用的战斗反馈通过 GlobalTweens 的 `screen_shake` + `do_hit_stop` + `burst_particles` 组合实现。

---

## 附录 B：手写 Tween 的合理场景

以下场景现有库**结构性无法覆盖**，保持手写 `create_tween()` 是合理的：

| 场景 | 原因 |
|------|------|
| `tween_method()` per-frame 回调 | 引擎级 API，库只能包装不能替代 |
| 多阶段 chain+parallel 序列 | Godot 原生 `chain()`/`parallel()` 已足够 |
| SceneTree 级生命周期 | `get_tree().create_tween()` 节点 free 后仍存活 |
| 随机参数粒子爆发 | 现有 `burst_custom` 不支持随机角度/距离/大小组合 |
| 自定义缓动曲线 | 需要特定 Tween.TRANS_* / EASE_* 组合时 |
| TweenFX 与 GlobalTweens 不覆盖的节点类型 | 如 TileMap、Camera2D（除震动外） |
