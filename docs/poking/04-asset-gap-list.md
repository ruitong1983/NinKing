# Poking 素材缺口清单

## 状态: 图像/音频已从 FanKing 占位复制，卡牌/字体仍需自制

---

## 1. 扑克牌美术

> **现状: 已复制 FanKing 麻将牌图到 `card_placeholders/` 占位，不可用于正式游戏。**

| 素材 | 数量 | 规格 | 优先级 | 状态 |
|---|---|---|---|---|
| 52 张标准扑克牌正面 | 52 | 80×120 像素, 像素风, PNG | **P0** | ❌ |
| 卡牌背面 | 1 | 80×120 像素, 像素风, PNG | **P0** | ❌ |
| 卡牌选中高亮叠加 | 1 | 80×120, 半透明红色, PNG | P1 | ❌ |
| 卡牌补齐高亮叠加 | 1 | 80×120, 半透明绿色, PNG | P1 | ❌ |

### 牌面设计方向

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

| 字体 | 用途 | 优先级 |
|---|---|---|
| 像素中文字体 (12px~16px) | UI 标签、牌面数字、提示文字 | **P0** |
| 像素英文/数字字体 (标题用) | POKING 标题大字 | P1 |

### 推荐

- 中文像素字体: 方正像素12、Zpix、或自制 BitmapFont
- 英文像素字体: Press Start 2P, m3x6, 或类似风格
- Godot 支持 BitmapFont (.fnt) 和 TrueType (.ttf/.otf)

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

> 动效框架已完整复用 FanKing，无需额外采购，仅需接入调用。

---

## 6. 主题文件

| 文件 | 用途 | 优先级 |
|---|---|---|
| `assets/themes/pixel_theme.tres` | 全局像素风主题（字体/颜色/按钮样式） | **P0** |

### 主题关键配置

- Default Font: 像素中文字体
- Font Size: 主 UI 18~24px, 标题 32~48px
- Button StyleBox: 像素风边框
- Color Palette: 深绿底 + 金色文字 + 白色卡牌

---

## 实施阶段

### Phase 1 — 可玩 (P0)
52 张卡牌 + 卡牌背面 + icon + 像素字体 + pixel_theme.tres

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
| 扑克牌 | Button 显示花色+点数文字 (如 "A♠")，场景中已实现 |
| 主菜单背景 | `background/launch_bg.png` (FanKing 占位) |
| 牌桌背景 | `background/table_bg.png` (FanKing 占位) |
| 游戏图标 | `ui/icon.png` (FanKing 占位) |
| 音效 | 全部 19 个 (FanKing SFX/BGM 占位)，`sound_bank.gd` 已配置 |
| 字体 | Godot 默认字体 |
| 按钮 | Godot 默认 Button 样式 |
| 小丑牌槽位 | Panel + Label (场景已实现) |
