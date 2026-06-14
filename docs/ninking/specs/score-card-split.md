# ScoreCard 拆分 — HandTypePanel + ScorePanel

> **日期:** 2026-06-13 | **来源:** grill-me | **状态:** ✅ 已实施

---

## 目标

将 ScoreCard（LeftPanel 上半 0→50%）拆为两个独立 Panel，分离"牌型+列分解明细"与"总分配对进度"。

## 场景树变更

### 删除

- `ScoreCard` (Panel, 0→50%) — 原 unique_name `%ScoreCard`
- `ScoreCardVBox` (VBoxContainer) — 原内部容器

### 新增

```
HandTypePanel (Panel, 0→25%, StyleBoxFlat_score_card)
├── material: ShaderMaterial (panel_edge_fade, 运行时挂载)
└── HandTypeVBox (VBoxContainer, anchors=full, offset_left=8, offset_right=-200, separation=8)
    ├── HandTypeRow      ← 移入 (3 阵营行 影/瞬/滅)
    ├── ColumnSpacer     ← 移入 (4px)
    └── ColumnTypeRow    ← 移入 (3 列行 左/中/右)

ScorePanel (Panel, 25%→50%, StyleBoxFlat_score_card)
├── material: ShaderMaterial (panel_edge_fade, 运行时挂载)
└── ScoreVBox (VBoxContainer, anchors=full, offset_left=8, offset_right=-200, separation=8)
    ├── ColXiLabel       ← 移入
    ├── ScoreLabel       ← 移入
    ├── ProgressBar      ← 移入
    └── TargetScoreLabel ← 移入
```

两个 Panel 均复用 `StyleBoxFlat_score_card`（content_margin=16, 暗绿底色）。

## 代码变更

### `ui_manager.gd`

删除第 40 行：
```gdscript
@onready var score_card: Panel = %ScoreCard
```

### `game_manager.gd`

第 67 行替换：
```gdscript
# 旧
make_fade.call(ui.score_card)
# 新
make_fade.call(ui.left_panel.get_node("HandTypePanel"))
make_fade.call(ui.left_panel.get_node("ScorePanel"))
```

## 不变项

- 所有 `%` unique_name Label 引用（ColXiLabel、ShadowType、ScoreLabel 等）保持不变
- `HandTypeRow` / `ColumnTypeRow` 保持 `layout_mode=2`
- 计分动画序列（Phase 1 行 → Phase 2 列 → Phase 3 喜公式）无影响
- `hand_type_labeler.gd` / `animation_handler.gd` / `debug_controller.gd` 无变更

## 涉及文件

| 文件 | 操作 |
|------|------|
| `scenes/ninking/ninking_main.tscn` | 场景树重构 |
| `scenes/ninking/debug_ninking_main.tscn` | 同步重构 |
| `scripts/ninking/ui/ui_manager.gd` | 删 1 行 |
| `scripts/ninking/ui/game_manager.gd` | 改 1 行 |

## 验证点

- [ ] Launcher → 主界面：不崩溃
- [ ] 左面板 ink-bleed 渐隐在两个新 Panel 上均生效
- [ ] ColXiLabel / ScoreLabel / ProgressBar 正常显示更新
- [ ] HandTypeRow 3 行阵营 + ColumnTypeRow 3 行列正常显示
- [ ] 计分动画 Phase 1-4 完整播放
