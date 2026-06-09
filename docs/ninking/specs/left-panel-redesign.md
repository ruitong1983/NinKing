# LeftPanel 重设计 — 实现规格

> **日期:** 2026-06-09 | **来源:** grill-me 14 轮决策 | **状态:** 待确认

---

## 问题

LeftPanel 380×1080，内容集中在 y=88~624（占 58%），下半部 456px 完全空白。

## 目标

- LeftPanel 内容均匀撑满全高度
- 信息层级清晰：Score > HandType > MatchInfo > AnteInfo
- 控件本身足够饱满（加大字号/高度），减少空洞感
- 改用 VBoxContainer + spacer 自动布局，便于后续扩展

---

## 1. 旧结构（当前）

```
LeftPanel (Control, 380×1080)
├── PanelBg (ColorRect, 380×1080)
├── ChipsMultContainer (HBoxContainer, y=88, 77px)
├── HandTypeLabel (Label, y=189, 33px)
├── ScoreLabel (Label, y=232, 33px)
├── TargetScoreLabel (Label, y=265, 33px)
├── ProgressBar (ProgressBar, y=311, 12px)
├── MatchPanel (Panel, y=383, 135px)
└── AntePanel (Panel, y=542, 82px)
```

## 2. 新结构（目标）

```
LeftPanel (VBoxContainer, 380×1080)
├── PanelBg (ColorRect, 全高背景)
├── Control spacer (SIZE_EXPAND vertical)
├── ScoreCard (Panel, ~200px)              ← 新建，合并计分元素
│   ├── ChipsMultContainer (HBoxContainer)  ← 移入
│   ├── ScoreLabel (Label, 48px)            ← 移入，字号 24→48
│   ├── ProgressBar (28px 高度)             ← 移入，高度 12→28
│   └── TargetScoreLabel (Label, 20px)      ← 移入
├── Control spacer (SIZE_EXPAND vertical)
├── HandTypeRow (HBoxContainer, ~60px)     ← 新建，替代 HandTypeLabel
│   ├── ShadowType (Label, 22px, 暗蓝色)    ← 影
│   ├── FlashType (Label, 22px, 银灰色)    ← 瞬
│   └── DestroyType (Label, 22px, 深红色)  ← 滅
├── Control spacer (SIZE_EXPAND vertical)
├── MatchPanel (Panel, ~160px)             ← 字号加大 + 行间距
│   ├── MatchTitle (Label, 18px 金色)
│   ├── HandsLabel (Label, 24px)
│   ├── RedrawsLabel (Label, 24px)
│   └── GoldLabel (Label, 24px)
├── Control spacer (SIZE_EXPAND vertical)
├── AntePanel (Panel, ~110px)              ← 字号加大 + 行间距
│   ├── BarrierLabel (Label, 24px)
│   └── RoundLabel (Label, 24px)
└── Control spacer (SIZE_EXPAND vertical)
```

### 布局逻辑

- **5 个 spacer + 4 个内容块** → spacer 自动等分剩余空间
- 上下边距 = spacer = inter-block 间距
- 增删块时无需手动重算坐标

---

## 3. 各块详细规格

### 3.1 ScoreCard

```
┌──────────────────────────────────┐
│  0  ×  0                         │  ← ChipsMultContainer (保留现有)
│                                  │
│  忍気  1,234                      │  ← ScoreLabel: "忍気 %d", 48px, 亮色
│  ████████████████████░░░░░░░░    │  ← ProgressBar: 28px 高, 无百分比文字
│  封印 300                         │  ← TargetScoreLabel: "封印 %d", 20px, 灰色
└──────────────────────────────────┘
```

- 面板背景复用 `BarrierTheme` 当前结界 panel 色
- 双层硬边框 (2px 外 + 1px 内)
- 内部 VBoxContainer separation ≈ 12px

### 3.2 HandTypeRow

```
┌──────────────────────────────────┐
│  影: 散牌  │  瞬: 一对  │  滅: 顺子 │
└──────────────────────────────────┘
```

- 三列等宽（`size_flags_horizontal=3`）
- 每列带色标前缀：影=暗蓝 `(0.35,0.55,0.95)` / 瞬=银灰 `(0.75,0.75,0.80)` / 滅=深红 `(0.95,0.30,0.30)`
- 字号 22px
- **数据源:** `HandDisplay._update_dun_type_labels()` 同步更新（当前 HandTypeLabel 未被更新，需要接线）

### 3.3 MatchPanel

- 内部改为 VBoxContainer（当前是 Panel 不带容器，4 个 Label 手动定位）
- 4 行字号从默认→24px（MatchTitle 保持 18px 金色不变）
- 行间距 separation = 10px

### 3.4 AntePanel

- 内部改为 VBoxContainer
- 2 行字号从默认→24px
- 行间距 separation = 10px

---

## 4. 代码变更

### 4.1 Scene: `scenes/ninking/ninking_main.tscn`

| 操作 | 节点 | 说明 |
|------|------|------|
| 修改类型 | `LeftPanel` | Control → VBoxContainer |
| 删除 | `HandTypeLabel` | 替换为 HandTypeRow |
| 新建 | `ScoreCard` (Panel) | 计分合并面板 |
| 新建 | `HandTypeRow` (HBoxContainer) | 三墩牌型行 |
| 新建 | `ShadowType` / `FlashType` / `DestroyType` (Label ×3) | HandTypeRow 子节点 |
| 添加 | 5 个 spacer Control | SIZE_EXPAND 自动分布 |
| 移入 | ChipsMultContainer → ScoreCard | |
| 移入 | ScoreLabel → ScoreCard | |
| 移入 | ProgressBar → ScoreCard | |
| 移入 | TargetScoreLabel → ScoreCard | |
| 调整 | MatchPanel 内部 → VBoxContainer | 加 separation，字号→24 |
| 调整 | AntePanel 内部 → VBoxContainer | 加 separation，字号→24 |
| 调整 | ProgressBar | 高度→28，去除百分比显示 |

### 4.2 `scripts/ninking/ui/ui_manager.gd`

| 变更 | 说明 |
|------|------|
| 保持现有 `@onready` 引用 | %ChipsLabel / %MultLabel / %ScoreLabel / %TargetScoreLabel / %ProgressBar / %HandsLabel / %RedrawsLabel / %GoldLabel / %BarrierLabel / %RoundLabel — 节点名未变，引用有效 |
| 替换 `dun_type_row` | `%HandTypeLabel` → 改为 3 个独立引用：`@onready var shadow_type_label: Label = %ShadowType` 等 |
| 更新 `HandDisplay.setup()` 调用 | 传入 3 个新 label 替代 1 个 dun_type_row |

### 4.3 `scripts/ninking/ui/hand_display.gd`

| 变更 | 说明 |
|------|------|
| `setup()` 签名 | `dun_row: Label` → `shadow_type: Label, flash_type: Label, destroy_type: Label` — 3 个独立参数 |
| `_update_dun_type_labels()` 扩展 | 更新 head/mid/tail 三组自身标签（已有）后，同步更新 LeftPanel 的 3 个 HandTypeRow 标签 |
| `_reset_labels()` | 增加 shadow/flash/destroy 三个标签的清空 |

### 4.4 `docs/ninking/06-ui-layout-reference.md`

- §2 场景树更新 LeftPanel 子结构
- §3.3.2 更新各子区域定义
- §4 引用 ScoreCard / HandTypeRow 新节点

---

## 5. 边界与风险

| 项 | 说明 |
|------|------|
| 结点 `%` 引用 | 所有现有 unique_name 节点不改名，`%ChipsLabel`/`%ScoreLabel` 等引用不受影响 |
| MatchPanel/AntePanel 内部重排 | 当前 4 个 Label 是 Panel 的直接子节点（绝对定位），改为 VBoxContainer 后变为自动排列 — 需要在场景编辑器中操作 |
| HandTypeRow 数据接线 | 当前 `_dun_type_row` 在 HandDisplay 中未被赋值。本次一并修复 |
| UI 主题一致性 | ScoreCard 复用 BarrierTheme 当前结界 panel 色；HandTypeRow 内部 3 色标为固定色值（不随结界变化） |
| 无新脚本文件 | 全部改动在现有 .tscn + 2 个 .gd 文件内 |

---

## 6. 验收标准

- [ ] LeftPanel 4 个内容块均匀分布全高，无明显大片空白
- [ ] ScoreCard 大数字 + 粗进度条居中显示
- [ ] HandTypeRow 三墩牌型正确更新（出牌后可见变化）
- [ ] MatchPanel / AntePanel 字号加大，视觉可读
- [ ] VBoxContainer spacer 自动适应窗口缩放
- [ ] BarrierTheme 结界配色正确应用到 ScoreCard / PanelBg
- [ ] Editor 无报错，游戏运行正常
