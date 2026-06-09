# NinKing 素材缺口清单

## 状态: 图像/音频已从 FanKing 占位复制，卡牌/字体仍需自制

> **📋 图像生成方案已制定 → [`05-image-asset-generation-plan.md`](05-image-asset-generation-plan.md)**
> 用豆包 AI 分三阶段生成全部图像素材，含详细提示词。

---

## 1. 扑克牌美术

> **现状: 已复制 FanKing 麻将牌图到 `card_placeholders/` 占位，不可用于正式游戏。**

| 素材 | 数量 | 规格 | 优先级 | 状态 |
|---|---|---|---|---|
| 52 张标准扑克牌正面 | 52 | 程序绘制 140×196, 仿扑克牌面 (白色圆角8px+角标18px+中央花色56px+右下180°镜像) | **P0** | ✅ 程序绘制 |
| 卡牌背面 | 1 | 程序绘制 140×196, 像素风, PNG | **P0** | ❌ |
| 卡牌选中高亮叠加 | 1 | 程序绘制, modulate 变色 | P1 | ✅ 程序实现 |
| 卡牌补齐高亮叠加 | 1 | 程序绘制, modulate 变色 | P1 | ✅ 程序实现 |

### 牌面设计方向

> **已实现**:  程序绘制牌面。
> 参考 Figma 卡面设计: 角标 (8,6) 22×47 / 右下角标 (110,143) 22×47, 对称边距 8+6+8+6px。

**牌面规格 (140×196, 5:7 标准扑克比例):**

| 元素 | 规格 | 位置 |
|------|------|------|
| 底色 | #FAF8F2 奶油白 | 全牌面 |
| 圆角 | 8px 半径 | 四角 |
| 边框 | 1px #333333 | 外轮廓 |
| 底部阴影 | 0→15% 黑色渐变, 6px高 | 底部边缘 |
| 左上角标 | 18px, 点数
花色, Label 36×44 | (8, 6) |
| 中央花色 | 56px, 居中 | (0,0) 填满卡面 |
| 右下角标 | 18px, 与左上相同内容, 180° 旋转 | (96, 146) 对称 |

**花色颜色:**
- 红桃♥ / 红方♦ → #CC1A1A (红)
- 黑桃♠ / 梅花♣ → #1A1A1A (黑)

**未完成:**
- 复古像素风格 (8-bit / 16-bit 风格)
- 花色: ♠ ♥ ♦ ♣ 用像素绘制
- 点数: A, K, Q, J, 10~2 用像素字体
- 人牌 (J/Q/K): 简化的像素人物头像
- 颜色: 黑桃♠梅花♣ — 深色底; 红心♥方块♦ — 暖色底

---

## 2. UI 素材

> **现状: 已从 FanKing 复制 icon.png / logo_deco.png / table_bg.png / launch_bg.png 占位。**

| 素材 | 规格 | 优先级 | 状态 |
|---|---|---|---|
| 游戏图标 (icon.png) | 256×256, PNG | **P0** | ✅ 占位 |
| 主菜单背景 (launch_bg.png) | 1920×1080 | P1 | ✅ 占位 |
| 牌桌背景 (table_bg.png) | 1920×1080 | P1 | ✅ 占位 |
| Logo 装饰 (logo_deco.png) | — | P2 | ✅ 占位 |
| 小丑牌槽位背景 | 100×140, 像素风边框, PNG | **P0** | ❌ |
| 按钮背景 (普通) | 可拉伸, 像素风, PNG | P1 | ❌ |
| 按钮背景 (按下) | 可拉伸, 像素风, PNG | P1 | ❌ |
| 商店面板背景 | 可拉伸, 深色调, PNG | P1 | ❌ |
| 顶部信息栏背景 | 1920×60, 半透明深色, PNG | P1 | ❌ |

---

## 3. 字体

| 字体 | 用途 | 优先级 | 状态 |
|---|---|---|---|
| 像素英文字体 (Press Start 2P) | UI 标签、牌面数字、英文/数字 | **P0** | ✅ 已导入 |
| 像素中文字体 (凤凰点阵体 12px) | 中文 UI 标签/按钮文字 | **P0** | ✅ 已导入 |

### 已导入

**Press Start 2P** (OFL 1.1):
- 文件: `assets/fonts/press_start_2p.ttf` (115KB)
- 来源: Google Fonts (CodeMan38)
- 优化网格: 8, 16, 24, 32, 40, 48, 56, 64, 72
- 导入设置: 抗锯齿=关, 子像素定位=关, Mipmap=关
- 已设为 `pixel_theme.tres` 默认字体
- 回退字体: 凤凰点阵体 12px (处理 CJK 字符)

**凤凰点阵体 12px** (CC0 公共领域):
- 文件: `assets/fonts/vonwaon_bitmap_12px.ttf` (1.5MB)
- 来源: TimothyQiu (itch.io)
- 优化网格: 12, 24, 36, 48, 60, 72
- 导入设置: 抗锯齿=关, 子像素定位=关, 嵌入位图=保留
- 已配置为 Press Start 2P 的 CJK 回退字体

**凤凰点阵体 16px** (CC0, 附加):
- 文件: `assets/fonts/vonwaon_bitmap_16px.ttf` (1.9MB)
- 优化网格: 16, 32, 48, 64
- 备用较大字号像素中文

---

## 4. 音频素材

> **状态: 已从 FanKing 拷贝占位音效 (19 个文件)，`sound_bank.gd` 已更新路径。**

| 素材 | 占位文件 | 状态 |
|---|---|---|
| 主菜单 BGM | `music/start_menu_bgm.wav` | ✅ 占位 |
| 游戏 BGM | `music/main_game_bgm.wav` | ✅ 占位 |
| 商店 BGM | — | ❌ 缺失 (P3) |
| 抽牌 | `sound/game/draw.ogg` | ✅ 占位 |
| 换牌 | `sound/game/swap.ogg` | ✅ 占位 |
| 选牌 | `sound/game/select.ogg` | ✅ 占位 |
| 发牌 | `sound/game/deal.ogg` | ✅ 占位 |
| 牌型揭示 | `sound/game/hu.ogg` | ✅ 占位 |
| 计分跳动 | `sound/game/count_tick.ogg` | ✅ 占位 |
| 过关 | `sound/game/level_clear.ogg` | ✅ 占位 |
| 失败 | `sound/game/level_fail.ogg` | ✅ 占位 |
| 商店摇奖 | `sound/game/lottery.ogg` | ✅ 占位 |
| 按钮点击 | `sound/ui/ui_click.ogg` | ✅ 占位 |
| 金币 | `sound/ui/ui_coin.ogg` | ✅ 占位 |
| 错误提示 | `sound/ui/ui_error.ogg` | ✅ 占位 |
| 特效爆炸 | `sound/game/explosion.ogg` | ✅ 占位 |
| 悬停 | `sound/game/hover.ogg` | ✅ 占位 |
| 小丑激活 | `sound/game/bao_activate.ogg` | ✅ 占位 |
| 牌型计分 | `sound/game/yaku_reveal.ogg` | ✅ 占位 |
| 弃牌 | `sound/game/discard.ogg` | ✅ 占位 |

---

## 5. 动画/VFX

| 效果 | 实现方式 | 优先级 |
|---|---|---|
| 卡牌翻转（换牌时） | Tween (已复用 FanKing card_tilt) | P1 |
| 计分数字跳动 | Tween (已复用 FanKing count_up) | P1 |
| 过关庆祝粒子 | Tween (已复用 FanKing particle_pool) | P2 |
| 小丑牌激活闪烁 | Shader (已复用 card_glow.gdshader) | P2 |
| 屏幕震动（Boss关） | screen_shake (已复用) | P3 |
| CRT 扫描线效果 | crt_filter.gd (已复用) | P1 |
| 发牌卷轴展开 (V10) | `TweenFX.stagger_spread()` — 中心→弧位散开 | **P1** ✅ |
| 换牌烟遁+瞬身 (V11) | `ui_manager.gd` — fade_out+dust → punch_in | **P1** ✅ |
| 计分粒子主题化 (V12) | sparkle→shuriken, confetti→sakura | **P2** ✅ |
| 过关屏风转场 (V13) | `game_manager.gd` — fade_out → change_scene | **P1** ✅ |
| Boss 墨字浮现 (V14) | `game_manager.gd` — CRT vignette+aberration + scale_pop | **P2** ✅ |
| ParticlePool 扩展 (V9) | shuriken(铁灰十字星) + sakura(淡粉柔点) 预设 | **P0** ✅ |

> V9-V14 忍者主题交互优化已完成（2026-06-09）。新增 `stagger_spread` API、2 个粒子预设、换牌/过关/Boss VFX。全部走 GlobalTweens/TweenFX 入口，零手写 create_tween()。

---

## 6. 主题文件

| 文件 | 用途 | 优先级 |
|---|---|---|
| `assets/themes/pixel_theme.tres` | 全局像素风主题（字体/颜色/按钮样式） | **P0** | ✅ 已创建 |

### 主题关键配置

- Default Font: 像素中文字体
- Font Size: 主 UI 18~24px, 标题 32~48px
- Button StyleBox: 像素风边框
- Color Palette: 深绿底 + 金色文字 + 白色卡牌

---

## 实施阶段

### Phase 1 — 可玩 (P0)
52 张卡牌 + 卡牌背面 + icon + 像素英文字体 (✅) + 像素中文字体 (✅) + pixel_theme.tres (✅)

### Phase 2 — 完整体验 (P1)
按钮素材 + UI 背景 + 卡牌高亮 + VFX 接入
- 音频: 已有占位 (来自 FanKing)，后续替换为扑克风格

### Phase 3 — 润色 (P2-P3)
商店 BGM + 过关特效 + Boss 关效果 + 扑克专属音频替换

---

## 临时占位方案

在素材到位前，使用以下临时方案:

| 资源 | 占位方式 |
|---|---|
| 扑克牌 | 程序绘制牌面 (140×196, 8px圆角, 18px角标+56px中央花色+右下180°镜像, `ninking_card.gd`) |
| 主菜单背景 | `background/launch_bg.png` (FanKing 占位) |
| 牌桌背景 | `background/table_bg.png` (FanKing 占位) |
| 游戏图标 | `ui/icon.png` (FanKing 占位) |
| 音效 | 全部 19 个 (FanKing SFX/BGM 占位)，`sound_bank.gd` 已配置 |
| 字体 | Godot 默认字体 |
| 按钮 | Godot 默认 Button 样式 |
| 小丑牌槽位 | Panel + Label (场景已实现) |
