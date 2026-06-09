# NinKing 图像素材管理

> 最后更新: 2026-06-08

---

## 1. 背景图片

| 文件名 | 路径 | 规格 | 用途 | 引用位置 | 状态 |
|---|---|---|---|---|---|
| `launch_bg.png` | `assets/images/background/` | 1920×1080, PNG | 主菜单背景 | `ninking_launcher.tscn` → LaunchBg | ✅ 占位 (FanKing) |
| `table_bg.png` | `assets/images/background/` | 1920×1080, PNG | 牌桌背景 | `ninking_main.tscn` → GameBg | ✅ 占位 (FanKing) |

---

## 2. UI 图片

| 文件名 | 路径 | 规格 | 用途 | 引用位置 | 状态 |
|---|---|---|---|---|---|
| `icon.png` | `assets/images/ui/` | —, PNG | 游戏图标 | 项目设置 `application/config/icon` | ✅ 占位 (FanKing) |
| `logo_deco.png` | `assets/images/ui/` | —, PNG | Logo 装饰图 | 暂未引用 | ✅ 占位 (FanKing) |

---

## 3. 卡牌占位 (麻将图, 不可用于正式游戏)

> **全部位于 `assets/images/card_placeholders/`，正式发布前需替换为扑克牌美术。**

| 文件名 | 规格 | 状态 |
|---|---|---|
| `Bamboo1.png` ~ `Bamboo9.png` | 麻将条子 | ⚠️ 占位 |
| `Characters1.png` ~ `Characters9.png` | 麻将万子 | ⚠️ 占位 |
| `Circles1.png` ~ `Circles9.png` | 麻将筒子 | ⚠️ 占位 |
| `East.png` / `South.png` / `West.png` / `North.png` | 麻将风牌 | ⚠️ 占位 |
| `Green.png` / `Red.png` / `White.png` | 麻将箭牌 | ⚠️ 占位 |
| `mahjong_20x28.png` / `mahjong_32x32.png` | 麻将图集 | ⚠️ 占位 |

---

## 4. 待制作素材

### P0 — 可玩必需

| 素材 | 数量 | 规格 | 说明 |
|---|---|---|---|
| 扑克牌正面 | 52 | 80×120, 像素风 PNG | ♠♥♦♣ 四种花色 × 13 点数 |
| 卡牌背面 | 1 | 80×120, 像素风 PNG | 统一背面图案 |
| 小丑牌槽位背景 | 1 | 100×140, 像素风 PNG | 带边框的槽位底板 |
| 像素中文字体 | 1 | 12~16px .ttf/.fnt | UI 标签 / 牌面数字 |

### P1 — 完整体验

| 素材 | 数量 | 规格 | 说明 |
|---|---|---|---|
| 卡牌选中高亮 | 1 | 80×120, 半透明红 PNG | 选中叠加层 |
| 卡牌补齐高亮 | 1 | 80×120, 半透明绿 PNG | 补牌叠加层 |
| 按钮背景(普通) | 1 | 可拉伸, 像素风 PNG | 9-slice |
| 按钮背景(按下) | 1 | 可拉伸, 像素风 PNG | 9-slice |
| 商店面板背景 | 1 | 可拉伸, 深色调 PNG | 9-slice |
| 顶部信息栏背景 | 1 | 1920×60, 半透明深色 PNG | 小丑牌栏背景 |
| `pixel_theme.tres` | 1 | Godot Theme | 全局像素风主题 |

### P2 — 润色

| 素材 | 数量 | 规格 | 说明 |
|---|---|---|---|
| 游戏 Logo | 1 | 512×128, PNG | NINKING 像素艺术字 |
| Logo 背景装饰 | 1 | — | 替换 FanKing 占位 |

---

## 5. 补完计划

| 阶段 | 内容 | 预估 |
|---|---|---|
| Phase 1 | 52 张卡牌 + 背面 + icon + 像素字体 + pixel_theme | 可玩 |
| Phase 2 | 按钮素材 + UI 背景 + 高亮叠加 | 完整体验 |
| Phase 3 | Logo + 装饰 + 全部 FanKing 占位替换 | 正式发布 |

---

## 6. 命名规范

- 背景: `{name}_bg.png` — 如 `table_bg.png`
- 卡牌: `card_{suit}_{rank}.png` — 如 `card_spade_a.png`
- UI 组件: `{name}.png` — 如 `button_normal.png`
- 图标: `icon_{name}.png` — 如 `icon_coin.png`
- 全部小写 `snake_case`
