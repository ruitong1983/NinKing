# NinKing 字体设计方案

> **建立日期:** 2026-06-10 | **状态:** 方案待确认
> **关联:** [`16-art-direction-principles.md`](16-art-direction-principles.md) §10 附录 B · [`../09-mgmt/TODO.md`](../09-mgmt/TODO.md) C10
>
> **用途:** 指导漫画风字体选型、获取、命名、导入、配置的完整计划。

---

## §1 背景

### 1.1 为什么要换

| 当前 | 问题 |
|------|------|
| **Press Start 2P** | 像素英文点阵体，与少年漫画风格直接冲突 |
| **凤凰点阵体 12px/16px** | 像素中文点阵体，同上 |
| 全局 `pixel_theme.tres` | 默认字体 = 凤凰点阵体 16px，必须替换 |

### 1.2 目标

> 替换为 **漫画ゴシック体（Gothic/黑体）** 为主 + **手写体** 为辅的字体体系。
>
> 少年漫画的字体惯例：对话框/标题用粗ゴシック（黑体），拟声词用手書き（手写体）。

---

## §2 字体需求清单

| # | 用途 | 风格要求 | 覆盖字符 | 示例场景 | 优先级 |
|---|------|---------|---------|---------|--------|
| F1 | **UI 默认字体（粗体）** | 粗ゴシック，笔画有力，高对比 | CJK + Latin + 数字 | 按钮文字、分数、标题、数字 | **P0** |
| F2 | **正文/描述字体（常规）** | 同族常规字重，清晰可读 | CJK + Latin + 数字 | 卡牌描述、标签、信息文字 | **P0** |
| F3 | **拟声词手写体** | 手書き風，不规则，有能量感 | CJK + Latin | 漫画拟声词弹出（「討つ！」「喜！」） | P2 |

### 2.1 字号速查

| 场景 | 字号 | 使用字体 |
|------|------|---------|
| 分数（`ChipsLabel` / `MultLabel`） | 48-64px | F1 粗体 |
| 按钮文字 | 18-24px | F1 粗体 |
| 标题（`HandTypeLabel`） | 28px | F1 粗体 |
| 面板标签 | 16-20px | F2 常规 |
| 卡牌角标（点数+花色） | 18px | F1 粗体 |
| 卡牌描述（忍者牌效果） | 12-14px | F2 常规 |
| 信息文字（`AnteLabel`等） | 14-18px | F2 常规 |
| 拟声词弹出 | 32-48px | F3 手写体 |

---

## §3 推荐字体

### 3.1 F1 + F2：思源黑体（Source Han Sans）

> **首选方案。** 一个字族覆盖全部需求（多字重 + CJK + Latin）。

| 属性 | 值 |
|------|-----|
| **字体名** | 思源黑体 (Source Han Sans / Noto Sans CJK) |
| **字重** | Heavy（粗体=F1）+ Regular（常规=F2） |
| **语言子集** | **SC (简体中文)** — 目标玩家为中文用户，字形正确性优先。漫画感通过字重+排版营造 |
| **文件** | `SourceHanSansSC-Heavy.otf` + `SourceHanSansSC-Regular.otf` |
| **大小** | ~5-8MB / 每个字重 |
| **授权** | **SIL Open Font License 1.1** — 免费，可商用，可嵌入游戏 |
| **来源** | GitHub: `adobe-fonts/source-han-sans` |
| **覆盖** | CJK 统一表意文字 + 日文假名 + Latin + 数字 + 标点 |

**为什么 SC 而不是 JP：**
- 目标玩家为中文用户，SC 字形的简体中文文本才是正确的阅读体验
- 日文术语（結界、討伐、忍気）在 SC 子集中同样涵盖（同源 CJK），不丢字
- 漫画感通过 Heavy 粗体 + 字号对比 + UI 特效层营造，不需要牺牲字形正确性

### 3.2 F1 备选：Anton（仅英文/数字）

> 如果在 Source Han Sans Heavy 下觉得英文字不够有力，可用 Anton 作为**按钮/数字节点的 font_override**。

| 属性 | 值 |
|------|-----|
| **字体名** | Anton |
| **风格** | 极粗无衬线，收缩字宽，高冲击力 |
| **覆盖** | Latin + 数字 + 标点（**无 CJK**） |
| **大小** | ~80KB |
| **授权** | **SIL Open Font License 1.1** |
| **来源** | Google Fonts: `fonts.google.com/specimen/Anton` |

### 3.3 F3：Yusei Magic（手書き風）

> 拟声词手写体首选。日本手書き风格，不规则笔触，少年漫画拟声词弹出专用。

| 属性 | 值 |
|------|-----|
| **字体名** | Yusei Magic |
| **风格** | 手書き風，粗放不规则，能量感强，少年漫拟声词标准风格 |
| **覆盖** | 日文假名 + Latin + 数字 + 部分 CJK（中文简体覆盖有限） |
| **大小** | ~4MB |
| **授权** | **SIL Open Font License 1.1** |
| **来源** | Google Fonts: `fonts.google.com/specimen/Yusei+Magic` |

**P2 使用说明：** 拟声词弹出使用独立 `FontFile` 资源引用此字体，不走全局 Theme 的 fallback 链。日文拟声词（「討つ！」「喜！」）完全覆盖。中文拟声词如超出 Yusei Magic 字符集，回退到 F1 思源黑体 Heavy。

---

## §4 获取指南

### 4.1 下载链接

| 字体 | 下载地址 |
|------|---------|
| Source Han Sans SC Heavy | `https://github.com/adobe-fonts/source-han-sans/raw/release/OTF/SimplifiedChinese/SourceHanSansSC-Heavy.otf` |
| Source Han Sans SC Regular | `https://github.com/adobe-fonts/source-han-sans/raw/release/OTF/SimplifiedChinese/SourceHanSansSC-Regular.otf` |
| Anton | `https://fonts.google.com/specimen/Anton` → "Download family" |
| Yusei Magic | `https://fonts.google.com/specimen/Yusei+Magic` → "Download family" |

### 4.2 授权确认清单

| 字体 | 许可证 | 可商用 | 可嵌入 | 需署名 |
|------|--------|--------|--------|--------|
| Source Han Sans | SIL OFL 1.1 | ✅ | ✅ | ❌（建议鸣谢） |
| Anton | SIL OFL 1.1 | ✅ | ✅ | ❌ |
| Yusei Magic | SIL OFL 1.1 | ✅ | ✅ | ❌ |

> SIL OFL 1.1 允许自由使用、嵌入、再分发，只要不单独转售字体本身。游戏内嵌入完全合规。

---

## §5 文件命名与存放

### 5.1 文件结构

```
assets/fonts/
├── source_han_sans_sc_heavy.otf      # F1 — UI 粗体（默认字体）
├── source_han_sans_sc_regular.otf    # F2 — 正文常规
├── yusei_magic_regular.ttf           # F3 — 拟声词手写体（P2）
│
├── anton_regular.ttf                 # (可选) F1 备选 — 英文数字覆盖
│
└── legacy/                           # 旧字体保留（后续清理）
    ├── press_start_2p.ttf            # 像素英文（废弃）
    ├── vonwaon_bitmap_12px.ttf       # 像素中文（废弃）
    └── vonwaon_bitmap_16px.ttf       # 像素中文（废弃）
```

### 5.2 命名规则

- **全小写 snake_case**，英文描述 + 字重后缀
- 格式：`{family}_{subset}_{weight}.{ext}`
- 例：`source_han_sans_sc_heavy.otf`、`yusei_magic_regular.ttf`
- 旧字体移入 `legacy/` 子目录保留，待确认无引用后删除

---

## §6 Godot 导入配置

> 以下为参考配置。实际操作：将字体文件放入 `assets/fonts/` 后，在 Godot 编辑器中选中字体文件，在 **Import** 面板中设置对应参数。`.import` 文件由 Godot 自动生成，不需手动编写。

### 6.1 F1 — 默认粗体

```ini
# source_han_sans_sc_heavy.otf.import
antialiasing=1              # 漫画风不禁用抗锯齿（像素字体才关）
generate_mipmaps=false
disable_embedded_bitmaps=true
allow_system_fallback=false # 不依赖系统字体
hinting=1                   # 轻度微调
subpixel_positioning=1      # 允许子像素定位（平滑）
oversampling=0.0
Fallbacks=["res://assets/fonts/source_han_sans_sc_regular.otf"]  # 缺字回退到常规体
```

### 6.2 F2 — 正文常规

```ini
# source_han_sans_sc_regular.otf.import
antialiasing=1
hinting=1
subpixel_positioning=1
oversampling=0.0
Fallbacks=["res://assets/fonts/yusei_magic_regular.ttf"]  # 极端缺字回退（P2 才导入，Phase 1 可留空）
```

### 6.3 F3 — 手写体（P2）

```ini
# yusei_magic_regular.ttf.import
antialiasing=1
hinting=1
subpixel_positioning=1
oversampling=0.0
Fallbacks=["res://assets/fonts/source_han_sans_sc_regular.otf"]  # 中文缺字回退到常规体
```

### 6.4 与像素字体的关键差异

| 设置 | 旧（像素字体） | 新（漫画字体） | 原因 |
|------|--------------|--------------|------|
| `antialiasing` | **0 (关)** | **1 (开)** | 漫画字体需要平滑边缘 |
| `subpixel_positioning` | **0 (关)** | **1 (开)** | 同上 |
| `disable_embedded_bitmaps` | false (保留点阵) | true | 使用矢量轮廓 |

---

## §7 Theme 配置

### 7.1 当前 → 目标

| 资源 | 当前 | 目标 |
|------|------|------|
| `pixel_theme.tres` 默认字体 | `vonwaon_bitmap_16px.ttf` | `source_han_sans_jp_heavy.otf` |
| 默认字号 | 16px | 16px（不变） |
| 按钮字体色 | `(0.85, 0.85, 0.9)` | 需评估：漫画风可能略暗，`(0.15, 0.15, 0.15)` 深黑 |

### 7.2 Theme 替换

> **新建** `manga_theme.tres`（不是重命名 `pixel_theme.tres`）。旧 Theme 保留作为 StyleBox 三态按钮等配置参考，新建 Theme 从头配置漫画风默认字体+字号。
>
> 场景引用更新：将 `.tscn` 中 `theme = ExtResource("pixel_theme_uid")` 改为指向 `manga_theme.tres` 的 UID。

### 7.3 回退链

```
source_han_sans_sc_heavy.otf   (默认粗体)
  └─ source_han_sans_sc_regular.otf  (缺字回退)
       └─ yusei_magic_regular.ttf    (极端回退，P2 导入)
```

> **注意：** Yusei Magic 的 import 中 Fallbacks 回指 Regular，但 Regular 的 Fallbacks 不指回 Yusei Magic（避免循环）。字体加载时 Godot 优先用默认字体找字，找不到才沿 fallback 链单向查找，不会循环。

### 7.4 节点级字体覆盖（可选优化）

| 节点 | 覆盖字体 | 理由 |
|------|---------|------|
| `ChipsLabel` / `MultLabel` | 字号 48-64，不做字体覆盖 | F1 粗体已够有力 |
| `ScoreLabel` / 数字类 | 可选覆盖为 Anton（英文数字） | 如果 F1 的数字不够冲击 |
| 卡牌描述 | 字号 12-14，覆盖为 F2 Regular | 小字号粗体可读性差 |
| `BTN_*` 按钮 | 字号 18-24，F1 粗体 | 默认即可 |

---

## §8 分阶段计划

### Phase 1 — 核心替换 (P1)

```
目标: 下载 + 导入 + 配置 F1/F2，替换全局 Theme 默认字体
估时: 1h
```

| 步骤 | 内容 | 估时 |
|------|------|------|
| 1.1 | 下载 Source Han Sans SC Heavy + Regular → `assets/fonts/` | 5min |
| 1.2 | 在 Godot 编辑器中配置字体 Import 参数（按 §6.1/§6.2） | 5min |
| 1.3 | 创建 `manga_theme.tres`：默认字体 = F1 Heavy，字号 16px | 10min |
| 1.4 | 设置 fallback 链：Heavy → Regular | 5min |
| 1.5 | 场景节点引用新的 `manga_theme.tres` | 10min |
| 1.6 | 游戏内测试：检查中文/日文/英文/数字显示效果 | 15min |
| 1.7 | 旧字体移入 `legacy/`，不删除 | 5min |
| 1.8 | ~~更新 `04-asset-gap-list.md` §3~~ 文档已删除，状态见 TODO.md | — |

### Phase 2 — 细调 (P1)

```
目标: 字号微调、节点覆盖、按钮配色调整
估时: 0.5h
```

| 步骤 | 内容 |
|------|------|
| 2.1 | 逐节点检查字号/可读性（卡牌描述 12-14px、标签 14-18px） |
| 2.2 | 如英文数字冲击力不足 → 下载 Anton → 数字节点覆盖 |
| 2.3 | 按钮字体色调整（漫画风深黑 vs 当前亮色） |
| 2.4 | `manga_theme.tres` 同步调整 StyleBox（配合漫画风 UI 组件规范） |

### Phase 3 — 手写体 (P2)

```
目标: 下载 + 配置 F3，供拟声词弹出使用
估时: 0.5h
触发: P2 拟声词功能开发时
```

| 步骤 | 内容 |
|------|------|
| 3.1 | 下载 Yusei Magic → `assets/fonts/` |
| 3.2 | 在 Godot 编辑器中配置字体 Import 参数（按 §6.3） |
| 3.3 | 在 `comic_text_pop()` 中独立加载此字体（不进入全局 fallback） |
| 3.4 | 测试拟声词日文假名 + 中文回退渲染 |

---

## §9 验收标准

| 场景 | 期望效果 |
|------|---------|
| 分数数字 48-64px | 粗ゴシック体，笔画有力，不虚不糊 |
| 按钮文字 18-24px | 清晰可辨，深黑笔画，与亮色按钮底色高对比 |
| 卡牌角标 18px | 点数+花色符号清晰，不混乱 |
| 卡牌描述 12-14px | 常规字重下可读，笔画不粘连 |
| 中文/日文混排 | 简体中文 SC 字形 + 日文术语，风格统一，无字形错乱 |
| 中英混排 | 无大小参差、基线偏移 |
| 拟声词 32-48px | 手書き風，粗放不规则，少年漫能量感（P2） |

---

## §10 附录

### 附录 A: 备选字体速查

| 字体 | 替代 | 风格 | 授权 | 大小 | 备注 |
|------|------|------|------|------|------|
| M PLUS 1p Heavy | F1 | 日本ゴシック | OFL | ~5MB | 更日系，CJK 覆盖不如思源全 |
| Bebas Neue | F1 Lat | 极粗英文 | OFL | ~50KB | 比 Anton 更窄，需确认数字风格 |
| Noto Sans CJK JP | F1/F2 | 同思源 | OFL | ~8MB | Google 发布版，与思源同源 |
| 站酷快乐体 | F3 备选 | 中文手写 | CC0-ish | ~2MB | 偏稚趣，中文拟声词备选 |
| M PLUS Rounded 1c | F3 备选 | 圆角ゴシック | OFL | ~3MB | 偏可爱，可能不够"热血" |
| LXGW WenKai | F3 备选 | 中文楷体 | OFL | ~5MB | CJK 全覆盖但偏书法，不如 Yusei Magic 狂放 |

### 附录 B: 旧字体清理时机

> 旧字体（`press_start_2p.ttf` + `vonwaon_bitmap_*.ttf`）在 Phase 1 先移入 `legacy/`，**不立即删除**。
>
> 删除时机：新字体全局替换后，经过一局完整游戏测试（Launcher→主界面→发牌→計分→商店→Boss→过关），确认所有文字渲染正常后删除。
>
> 预计 Phase 1 完成后 1-2 天。

### 附录 C: 与 Figma 设计稿的字体对应

> 如果将来在 Figma 中做 UI 设计稿，Figma 内对应使用以下字体测试效果：

| Godot 字体 | Figma 等效（Google Fonts 可用） |
|-----------|-------------------------------|
| Source Han Sans SC Heavy | Noto Sans SC Bold / M PLUS 1p Bold |
| Source Han Sans SC Regular | Noto Sans SC Regular / M PLUS 1p Regular |
| Yusei Magic | Yusei Magic（Google Fonts 有） |
| Anton | Anton（Google Fonts 有） |
