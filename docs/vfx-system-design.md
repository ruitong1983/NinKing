# VFX 底层框架设计文档

> 参考目标：Balatro（小丑牌）2D 像素风格动效
> 引擎：Godot 4.6.2 / 纯 2D
> 设计日期：2026-06-06
> 实现日期：2026-06-06
> 最后更新：2026-06-06 (7轮 Tween/VFX 集成完成)
> 状态：✅ 框架已实现 + 上层对接完成

---

## 设计原则

| 原则 | 含义 |
|------|------|
| **零项目依赖** | 子系统不 import 项目特定类，不引用 FanKingGameState 等 |
| **自初始化** | 每个子系统自己的依赖自己 `new()`，不依赖外部配置 |
| **可独立移植** | 单文件拷到另一个 Godot 项目即用 |
| **参数可覆盖** | 所有默认值通过 setter 或方法参数可调，不写死 |
| **信号通知外部** | 项目特定行为通过信号暴露，外部可选连接 |

---

## 实际文件清单

```
scripts/tween/                            # 动效子系统（全部 class_name，可移植）
├── global_tweens.gd     (147 行) ❌ 不可移植：本项目 Autoload 胶水层
├── tween_fx.gd          (339 行) ✅ 纯静态 Tween 动效工具 (Autoload: TweenFX)
├── screen_shake.gd      ( 78 行) ✅ 屏幕震动系统 (class_name: ScreenShake)
├── hit_stop.gd          ( 57 行) ✅ 顿帧/冻结帧 (class_name: HitStop)
├── card_tilt.gd         ( 84 行) ✅ 卡牌倾斜/物理摊开感 (class_name: CardTilt)
├── count_up.gd          ( 69 行) ✅ 数字滚动 (class_name: CountUp)
├── particle_pool.gd     ( 96 行) ✅ 粒子池 (class_name: ParticlePool)
└── audio_coupler.gd     ( 55 行) ✅ 音效耦合 (class_name: AudioCoupler)

scripts/system/
└── crt_filter.gd        ( 56 行) ✅ CRT 全屏滤镜控制器 (class_name: CRTFilter)

resources/shaders/
├── crt_filter.gdshader  ( 40 行) ✅ CRT 着色器（扫描线+色差+暗角+曲面）
└── card_glow.gdshader   ( 31 行) ✅ 卡牌边缘发光着色器

scenes/dev/
├── vfx_test.tscn        ✅ 独立测试场景（9 个按钮）
└── vfx_test.gd          ( 83 行) ✅ 测试脚本
```

**总计：~875 行脚本 + 71 行 shader**

---

## 全局架构

```
┌─────────────────────────────────────────────────┐
│                 调用方（项目各处）                  │
│    卡牌类 / 结算类 / UI按钮 / 场景切换              │
├─────────────────────────────────────────────────┤
│      GlobalTweens (Autoload — 唯一胶水层)          │
├──────────┬──────────┬──────────┬────────────────┤
│ TweenFX  │ScreenShake│ HitStop  │  CardTilt      │
│ (Autoload│ (实例)    │ (实例)    │  (实例)        │
│  纯静态) │          │          │                │
├──────────┼──────────┼──────────┼────────────────┤
│ CountUp  │ParticlePool│AudioCoupler│ CRTFilter   │
│ (纯静态) │ (实例)   │ (纯静态)   │  (实例)       │
├──────────┴──────────┴──────────┴────────────────┤
│              resources/shaders/                  │
│         crt_filter.gdshader                      │
│         card_glow.gdshader                       │
└─────────────────────────────────────────────────┘
```

---

## Autoload 配置（project.godot 现有条目，无需修改）

```ini
[autoload]
GlobalTweens="*res://scripts/tween/global_tweens.gd"
TweenFX="*res://scripts/tween/tween_fx.gd"
```

---

## 子系统详细设计

### 1. TweenFX（纯静态 Tween 动效工具）

**文件**：`scripts/tween/tween_fx.gd` · Autoload 名 `TweenFX` · 161 行
**class_name**：无（Autoload 已全局可访问）
**状态**：纯静态方法，零实例化

#### API（18 个静态函数，全部返回 Tween 且内置 auto_kill）

| 方法 | 效果 | 适用场景 |
|------|------|---------|
| `pop_in(node, dur?, from_scale?)` | 0 → 弹性放大到 1 | 卡牌入场、按钮出现 |
| `pop_out(node, dur?)` | 弹性缩小到 0 → queue_free | 卡牌删除、UI 关闭 |
| `fade_in(node, dur?)` | alpha 0→1，SINE 缓出 | 通用淡入 |
| `fade_out(node, dur?)` | alpha→0，SINE 缓入 | 通用淡出 |
| `fade_out_then_free(node, dur?)` | 淡出 → queue_free | 淡出清理 |
| `punch_in(node, dur?, peak_scale?)` | ELASTIC 过冲弹入 | "Clear!" 标签、抽奖结果 |
| `toast(node, hold_dur?, ...)` | 淡入→停留→淡出→释放 | Toast 通知 |
| `stagger_slide_in(nodes, stagger?, ...)` | 列表逐项错峰滑入 | 役种列表、卡牌入场 |
| `scale_pop(node, factor?, dur?)` | 一次性 scale 弹跳 | 按钮点击反馈 |
| `shake_node(node, intensity?, dur?)` | 原地左右抖动 | 操作不合法提示 |
| `pulse(node, scale_to?, dur?)` | 放大→缩回循环(无限) | 提示可操作区域 |
| `wobble(node, angle_deg?, dur?)` | 左右摇摆 | 选中确认感 |
| `float_up(node, offset_y?, dur?)` | 向上漂浮 + 淡出 | 得分数字飘出 |
| `slide_in(node, from_dir?, dur?)` | 从指定方向滑入 | UI 面板进入 |
| `slide_out(node, to_dir?, dur?)` | 滑出 + queue_free | UI 面板退出 |
| `color_flash(node, color?, dur?)` | 闪指定颜色后恢复 | 受击/得分瞬间 |
| `card_hover(node, scale_to?, offset_y?, dur?)` | 悬浮放大+上移 | 鼠标悬浮（接受 CanvasItem） |
| `card_unhover(node, original_scale?, original_y?, dur?)` | 悬浮还原 | 鼠标离开（接受 CanvasItem） |

#### 约束
- 内置 **auto_kill 防冲突**：`_active_tweens: Dictionary` (Node→Tween)，重复调用自动 kill 旧补间
- `finished` 信号自动清理字典条目（CONNECT_ONE_SHOT）
- 所有方法开头检查 `is_instance_valid(node)`
- `stagger_slide_in` 不参与 auto_kill（操作数组，每项独立补间）

---

### 2. ScreenShake（屏幕震动）

**文件**：`scripts/tween/screen_shake.gd` · `class_name ScreenShake` · 78 行
**依赖**：Camera2D（延迟绑定）

| 模式 | API | 适用场景 |
|------|-----|---------|
| 一次性触发 | `trigger(intensity, duration)` | 得分爆发、碰撞 |
| 创伤累积 | `add_trauma(amount)` | 连续震动叠加 |

| 参数 | 默认 | 说明 |
|------|------|------|
| max_offset | Vector2(20, 15) | 最大偏移像素 |
| max_rotation | 2.0 | 最大旋转角度（度） |
| decay_rate | 2.5 | trauma 衰减速度/秒 |

- Camera2D 延迟绑定：首次调用时查找 `get_viewport().get_camera_2d()`
- 震动结束后精确恢复原始 camera 位置

---

### 3. HitStop（顿帧/冻结帧）

**文件**：`scripts/tween/hit_stop.gd` · `class_name HitStop` · 57 行

| 方法 | 说明 |
|------|------|
| `freeze(duration?, time_scale?)` | 基础顿帧，不打断之前冻结 |
| `freeze_stackable(duration?, time_scale?)` | 可叠加，最后一个到期才恢复 |
| `cancel()` | 立即恢复 `time_scale = 1.0` |

**time_scale 影响规则**

| 受 time_scale 影响 | 不受影响 |
|---|---|
| TweenFX 入场/悬浮/弹出 | **CountUp 数字滚动** |
| ParticlePool 粒子 | **AudioCoupler 音效** |
| ScreenShake 震动 | |
| CardTilt 倾斜 | |

---

### 4. CardTilt（卡牌倾斜/物理摊开感）

**文件**：`scripts/tween/card_tilt.gd` · `class_name CardTilt` · 84 行
**类型**：`enable_single`/`disable`/`apply_spread` 均接受 `CanvasItem`（兼容 `Node2D` 和 `Control`）

| 模式 | API | 效果 |
|------|-----|------|
| 单卡倾斜 | `enable_single(node)` / `disable(node)` | 单张卡跟随鼠标旋转 |
| 手牌摊开 | `apply_spread(nodes, center_pos?)` | 多张卡以扇形展开 |

---

### 5. CountUp（数字滚动）

**文件**：`scripts/tween/count_up.gd` · `class_name CountUp` · 65 行
**关键约束**：所有 Tween 调用 `set_ignore_time_scale(true)`

| 模式 | API | 效果 |
|------|-----|------|
| 线性递增 | `play(label, from, to, dur?)` | 匀速增长 |
| 缓出递增 | `play_eased(label, from, to, dur?)` | 先快后慢 |
| 金币计数 | `play_gold(label, amount, dur?)` | 带金色闪烁 |

---

### 6. ParticlePool（粒子池）

**文件**：`scripts/tween/particle_pool.gd` · `class_name ParticlePool` · 96 行
**内部类**：`PresetConfig`（粒子预设配置）

| 预设 | 场景 | 表现 |
|------|------|------|
| `"sparkle"` | 得分、升级 | 金色星星 10 个，0.4s |
| `"dust"` | 卡牌落地、弃牌 | 灰白小点 6 个，0.3s |
| `"confetti"` | 通关、大奖 | 彩色碎片 18 个，0.8s |

粒子占位纹理：首次 init 时代码生成 8×8 软边圆点，颜色走 `modulate`。后续换素材无需改代码。

---

### 7. AudioCoupler（音效耦合）

**文件**：`scripts/tween/audio_coupler.gd` · `class_name AudioCoupler` · 55 行

| 模式 | API | 适用场景 |
|------|-----|---------|
| Tween 内联 | `bind_sfx(tween, stream, at_elapsed?)` | "Tween 到 0.3s 响一声" |
| 手动触发 | `play_one_shot(stream, volume_db?)` | 即时播放 |

---

### 8. CRTFilter（全屏滤镜）

**文件**：`scripts/system/crt_filter.gd` · `class_name CRTFilter` · 56 行
**Shader**：`resources/shaders/crt_filter.gdshader` · 40 行

| 参数 | 默认 | 说明 |
|------|------|------|
| enabled | false | 总开关（切换 ColorRect.visible） |
| scanline_intensity | 0.15 | 扫描线深浅 |
| aberration_amount | 0.5 | 色差强度 |
| vignette_amount | 0.3 | 暗角强度 |
| warp_amount | 0.02 | 曲面程度 |
| brightness | 1.1 | 亮度补偿 |

- CanvasLayer 层级 128，覆盖所有 UI
- 场景加载后延迟挂载（`child_entered_tree` 触发）

---

### 9. GlobalTweens（Autoload 胶水层）

**文件**：`scripts/tween/global_tweens.gd` · Autoload 名 `GlobalTweens` · 147 行
**不可移植**：本项目专属胶水层
**类型通知**：`card_hover`/`card_unhover`/`enable_card_tilt`/`disable_card_tilt` 接受 `CanvasItem`（兼容 Node2D 和 Control）

#### 核心 API（调用方只接触 GlobalTweens）

```gdscript
# CRT
GlobalTweens.set_crt_enabled(true)

# 入场/退场
GlobalTweens.pop_in(node) / pop_out(node)
GlobalTweens.fade_in(node) / fade_out(node) / fade_out_then_free(node)
GlobalTweens.slide_in(node, dir) / slide_out(node, dir)
GlobalTweens.stagger_slide_in(nodes, stagger)

# 弹性/弹跳
GlobalTweens.punch_in(node, dur?, peak_scale?)
GlobalTweens.scale_pop(node, factor?)
GlobalTweens.pulse(node, scale_to?)        # 无限呼吸
GlobalTweens.toast(node, hold_dur?)

# 抖动/摇摆
GlobalTweens.shake_node(node, intensity?)
GlobalTweens.wobble(node, angle_deg?)

# 漂浮/闪色
GlobalTweens.float_up(node, offset_y?)
GlobalTweens.color_flash(node, color?)

# 卡牌交互
GlobalTweens.card_hover(node) / card_unhover(node)
GlobalTweens.enable_card_tilt(node) / disable_card_tilt(node)
GlobalTweens.set_hand_spread(cards)

# 震动 & 顿帧
GlobalTweens.screen_shake(intensity?, duration?)
GlobalTweens.do_hit_stop(duration?, time_scale?)

# 数字 & 粒子
GlobalTweens.count_up(label, to_value, duration?)
GlobalTweens.count_up_gold(label, amount, duration?)
GlobalTweens.burst_particles(position, preset?)

# 音效
GlobalTweens.bind_sfx(tween, stream, at_elapsed?)
GlobalTweens.play_sfx(stream, volume_db?)
```

---

## 子系统依赖图

```
GlobalTweens ──┬── TweenFX         (Autoload, 纯静态)
               ├── ScreenShake     (依赖 Camera2D, 延迟绑定)
               ├── HitStop         (操作 Engine.time_scale)
               ├── CardTilt        (操作 CanvasItem.position/rotation)
               ├── CountUp         (依赖 TweenFX.color_flash)
               ├── ParticlePool    (依赖 CPUParticles2D)
               ├── AudioCoupler    (自建 AudioStreamPlayer)
               └── CRTFilter       (依赖 CanvasLayer + ShaderMaterial)
```

---

## 测试场景

`scenes/dev/vfx_test.tscn` — 在 Godot 编辑器中按 F6 运行，9 个按钮逐项验证：

| 按钮 | 触发 |
|------|------|
| Pop In | 随机位置弹出彩色方块 |
| Shake | 屏幕震动 0.15s |
| Hit Stop | 冻结 0.08s |
| Card Tilt | 生成 5 张卡，扇开 + 鼠标跟随倾斜 |
| Count Up | 数字从 0 滚动到随机值 |
| Sparkle | 鼠标位置金色粒子爆发 |
| CRT Toggle | 开关 CRT 滤镜 |
| All Combo | 弹入 + 震动 + 冻结 + 粒子 |

---

## 实现记录

| 子系统 | 状态 | 提交 |
|--------|------|------|
| TweenFX | ✅ | `35d7323` |
| ScreenShake | ✅ | `5c232ea` |
| HitStop | ✅ | `dedc7d0` |
| CRT Filter + Shaders | ✅ | `5351b12` |
| CountUp | ✅ | `1592536` |
| CardTilt | ✅ | `4d25fa8` |
| ParticlePool | ✅ | `bd4b7aa` |
| AudioCoupler | ✅ | `05c58e7` |
| GlobalTweens | ✅ | `7c317d2` |
| 测试场景 | ✅ | `e6d1c3c` |
| scoring_animation 对接 | ✅ | `1565625` |
| tscn 格式修复 | ✅ | `1cb3c8e` |

---

## 待办事项

以下对接点框架已就绪，需在后续开发中逐步接入：

### ✅ 高优先级 — 已完成 2026-06-06

| 事项 | 位置 | 说明 |
|------|------|------|
| ✅ 卡牌入场动效 | `hand_area.gd:animate_deal()` | scale+alpha 错峰弹出（手写 tween，避免与 HBoxContainer 布局冲突） |
| ✅ 手牌悬停效果 | `hand_area.gd` | `card_hover()`/`card_unhover()` |

### ✅ 中优先级 — 已完成 2026-06-06

| 事项 | 位置 | 说明 |
|------|------|------|
| ✅ 结算数字滚动 | `scoring_animation.gd:Phase 4` | `count_up_gold()` 数字滚动+金色闪烁 |
| ✅ 按钮动效 | `main_menu.gd`, `shop_ui.gd` | `card_hover()`/`card_unhover()` + `pulse()` |
| ✅ 宝牌链式 VFX | `scoring_animation.gd:Phase 2` | 每步 `fade_in()`+`punch_in()`，大幅跳跃震屏 |
| 🔲 手牌摊开+倾斜 | `hand_area.gd` | 需自由布局（非 Container），卡牌倾斜类型已拓宽 |

### 🔲 低优先级

| 事项 | 位置 | 说明 |
|------|------|------|
| 粒子素材替换 | `assets/images/effect/particles/` | 美术资源准备好后替换占位纹理 |
| 音效素材接入 | `assets/audio/sound/` | 各动效关键帧绑定实际音效文件 |
| CRT 滤镜开关 | 设置界面 | 提供玩家可选的 CRT 开关选项 |
| 动效强度配置 | 设置界面 | 玩家可调震动/粒子/CRT 强度 |
