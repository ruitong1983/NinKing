# 游戏回放日志运维指南

> **最后更新:** 2026-06-18
> **系统版本:** v1.0
> **对应代码:** `scripts/ninking/logging/game_logger.gd`

---

## 1. 日志系统概述

`game_logger.gd` 是一个 RefCounted 静态工具类（**无 class_name**，通过 `const GameRunLogger = preload("res://scripts/ninking/logging/game_logger.gd")` 引用），记录每次游戏 run 的操作序列到 JSON 文件，用于 Bug 复现和历史分析。

### 记录范围

| 记录 | 不记录 |
|------|--------|
| 14 种预定义事件（Run/封印/发牌/排列/交换/出牌/商店/忍具/结算） | 鼠标移动、悬停等细粒度 UI 事件 |
| 关键节点的全量游戏状态快照 | 帧级性能数据 |
| 高频操作的增量状态快照 | 调试日志（print/debug） |
| 自定义事件（兜底扩展点） | 游戏资产/纹理内容 |

### 技术要点

- **存储:** `user://logs/`，永不自动删除
- **格式:** 单文件 JSON，一个 run 一个文件
- **回放:** 配套 HTML 查看器（`ninja-game-replay.html`）
- **开关:** `GameRunLogger.enabled = false` 可全局关闭

---

## 2. 日志文件管理

### 存储位置

`user://logs/` 在各操作系统上的实际路径：

| 系统 | 路径 |
|------|------|
| **Windows** | `%APPDATA%\Godot\app_userdata\NinKing\logs\` |
| **macOS** | `~/Library/Application Support/Godot/app_userdata/NinKing/logs/` |
| **Linux** | `~/.local/share/godot/app_userdata/NinKing/logs/` |

> **运行时查看:** 在 Godot 输出窗口顶部 GameLogger 启动提示中有完整路径。

### 命名规范

```
{timestamp}_{outcome}_{run_id}.json
```

- `timestamp`: ISO 时间戳（如 `2026-06-18_10-30-00`）
- `outcome`: `game_over` 或 `victory`
- `run_id`: 自动生成的唯一标识（基于启动时间）

例: `2026-06-18_10-30-00_game_over_2026-06-18_10-30-00.json`

### JSON 顶层结构

```json
{
  "run_id": "2026-06-18_10-30-00",
  "version": "1.0",
  "started_at": 1750300000.0,
  "ended_at": 1750300500.0,
  "outcome": "game_over",
  "deck_name": "标准牌组",
  "entries": [ ... ]
}
```

### 生命周期策略

| 策略 | 说明 |
|------|------|
| **自动删除** | ❌ 永不 — 日志为问题排查保留 |
| **推荐清理** | 定期手动删除过期日志（如只保留最近 30 天） |
| **安全删除** | 直接删 `.json` 文件即可，不影响游戏运行 |
| **禁用日志** | 代码中 `GameRunLogger.enabled = false`，运行时零开销 |

---

## 3. 回放查看器使用

### 文件位置

```
docs/ninking/ninja-game-replay.html
```

> 独立的单页 HTML/JS/CSS 应用，无服务端依赖。

### 使用方法

1. **打开:** 用浏览器（Chrome/Edge/Firefox）直接打开 `ninja-game-replay.html`
2. **加载日志:** 将 `.json` 日志文件拖入页面中间的拖放区域
3. **导航:**
   - 左侧时间线: 点击事件跳转
   - 键盘快捷键: `←` 上一步 / `→` 下一步 / `Home` 第一步 / `End` 最后一步
4. **查看:** 右侧展示 3×3 卡牌网格、状态栏（结界/封印值/分数/金币/出牌次数/领主）、计分详情、喜触发信息

### 高级功能

| 功能 | 方法 |
|------|------|
| URL 参数加载 | `ninja-game-replay.html?log=https://example.com/log.json` |
| 多文件 | 重新拖入新文件自动替换 |

---

## 4. 事件参考表

### 事件一览

| # | 事件名 | 触发时机 | Snapshot | 调用方 |
|---|--------|---------|----------|--------|
| 1 | `run_started` | 新游戏开始（选择牌组后） | 全量 | `game_state.gd` |
| 2 | `seal_started` | 进入新封印 | 全量 | `game_state.gd` |
| 3 | `cards_dealt` | 每次出牌前发 9 张 | 无 | `game_state.gd`, `debug_controller.gd` |
| 4 | `auto_arranged` | AI 自动重排 | 无 | `game_state.gd`, `debug_controller.gd` |
| 5 | `card_swapped` | 交换两张牌位置 | 无 | `seal_controller.gd`, `debug_controller.gd` |
| 6 | `play_prepared` | 出牌计分计算完成（动画前） | 无 | `seal_controller.gd`, `debug_controller.gd` |
| 7 | `play_executed` | 出牌完成（状态变更后） | 增量 | `seal_controller.gd`, `debug_controller.gd` |
| 8 | `seal_completed` | 封印通关 | 全量 | `seal_controller.gd` |
| 9 | `shop_entered` | 进入商店 | 无 | `seal_controller.gd` |
| 10 | `ninja_acquired` | 获得忍者 | 无 | `shop_manager.gd` |
| 11 | `item_purchased` | 购买道具 | 无 | `shop_manager.gd` |
| 12 | `game_over` | 游戏结束（失败） | 全量 | `game_state.gd`, `debug_controller.gd` |
| 13 | `victory` | 通关胜利 | 全量 | `game_state.gd` |
| 14 | 自定义 | 兜底扩展点 | 可选 | 任意 |

### Snapshot 策略

| 类型 | 包含字段 | 使用场景 |
|------|---------|----------|
| **全量** (`_build_full_gs_snapshot`) | barrier_num, seal_idx, current_score, target_score, plays_remaining, gold, deck_name, seal_lord_name, hand(9张), ninjas, star_chart_levels | 关键节点: run_started, seal_started, seal_completed, game_over, victory |
| **增量** (`_build_delta_gs_snapshot`) | current_score, target_score, plays_remaining, gold, hand(9张) | 高频操作: play_executed |

### 触发忍者序列化格式（`play_prepared` 事件）

```json
{
  "id": "n_g01",
  "name": "虎头"
}
```

> `ninja_triggers` 数组由 `score_calculator.gd` 的 `triggered_ids` 追踪生成，标记所有在本轮出牌中触发的忍者（含 chips/mult/x_mult/x_stack 效果）。不含仅储存/scaling/工具类忍者。
> **调用链路:** `analyze_effects()` → `triggered_ids` → `play_data.summary.triggered_ids` → `game_logger.gd on_play_prepared` → `ninja_triggers`

### 卡牌序列化格式

```json
{
  "suit": "HEARTS",
  "rank": "ACE",
  "display": "A♥",
  "enhancement": "bonus_chips",
  "seal": "red_seal",
  "edition": "foil"
}
```

> `enhancement`/`seal`/`edition` 仅在非 NONE 时出现。

### 手牌序列化格式

```json
{
  "head": [ /* 3 张牌 */ ],
  "mid": [ /* 3 张牌 */ ],
  "tail": [ /* 3 张牌 */ ]
}
```

### 忍者序列化格式

```json
{
  "id": "n_g01",
  "name": "虎头",
  "effect": { "group": "head", "chips": 30, ... }
}
```

---

## 5. JSON Schema 参考

### 顶层文件

```
{
  "run_id":      String,    // 唯一 run 标识
  "version":     String,    // 日志格式版本（当前 "1.0"）
  "started_at":  Number,    // 开始时间（UNIX 时间戳）
  "ended_at":    Number,    // 结束时间（UNIX 时间戳）
  "outcome":     String,    // "game_over" | "victory"
  "deck_name":   String,    // 使用的牌组名称
  "entries":     Array      // 事件条目列表
}
```

### 事件条目

```
{
  "ts":         Number,     // 记录时间（UNIX 时间戳）
  "seq":        Number,     // 递增序号（从 1 开始）
  "event":      String,     // 事件名
  "elapsed_ms": Number,     // 距开始毫秒数
  "detail":     Object,     // 事件详情（结构因事件而异）
  "gs?":        Object      // 可选：游戏状态快照
}
```

### 全量快照

```
{
  "barrier_num":         Number,
  "seal_idx":            Number,
  "current_score":       Number,
  "target_score":        Number,
  "plays_remaining":     Number,
  "gold":                Number,
  "current_deck_name":   String,
  "current_seal_lord_name": String,
  "hand":                Object,   // { head, mid, tail }
  "ninja_count":         Number,
  "ninjas":              Array,    // [{ id, name, effect }]
  "star_chart_levels":   Object    // { handType: level }
}
```

---

## 6. 常见问题排查

### 日志未生成

| 症状 | 可能原因 | 检查方法 |
|------|---------|----------|
| 输出窗口无 GameLogger 提示 | `enabled = false` | 确认 `GameRunLogger.enabled` 为 `true` |
| 有提示但无 .json 文件 | `_finalize_run` 未触发 | 确认游戏正常结束（game_over/victory）而非强杀进程 |
| Debug 场景无日志 | 退出未调 finalize | 检查 `_on_back_pressed()` 是否有 `on_game_over` 调用 |
| 日志文件为空 | 文件写入失败 | 检查 Godot 输出错误面板的 `push_error` |

### JSON 文件无法在回放查看器打开

| 症状 | 可能原因 | 解决方法 |
|------|---------|----------|
| 拖拽无反应 | 文件非 `.json` 扩展名 | 确认文件名以 `.json` 结尾 |
| 解析错误 | JSON 包含特殊字符/循环引用 | 用 `JSON.parse()` 手动验证 |
| 查看器空白 | 浏览器版本过低 | 使用 Chrome/Edge/Firefox 最新版 |

### IDE 集成

| 场景 | 方法 |
|------|------|
| VS Code 打开日志目录 | `code %APPDATA%/Godot/app_userdata/NinKing/logs/` |
| 快速打开最近日志 | 按修改时间排序取第一个 |
| 多日志对比 | 用 diff 工具对比两个 JSON 的 entries 数组 |

---

## 7. 如何扩展

### 新增事件类型

在 `game_logger.gd` 添加新的公共方法：

```gdscript
## 15) my_custom_event — 示例
static func on_my_event(param1: String, param2: int) -> void:
    if not enabled or not _run_started:
        return
    _add_entry("my_event", {
        "param1": param1,
        "param2": param2,
    })
```

在调用方 `preload` 后一行调用：

```gdscript
const GameRunLogger = preload("res://scripts/ninking/logging/game_logger.gd")
GameRunLogger.on_my_event("value", 42)
```

### 新增序列化类型

```gdscript
static func _serialize_new_type(obj) -> Dictionary:
    return {
        "field1": obj.field1,
        "field2": obj.field2,
    }
```

### 新增插桩点

1. 在目标文件顶部加 `const GameRunLogger = preload("res://scripts/ninking/logging/game_logger.gd")`
2. 在需要记录的位置调用 `GameRunLogger.on_xxx()`
3. 同步更新 `DOCUMENT_MAP.md §9.1` 的插桩分布表

---

## 附录：相关文件索引

| 文件 | 说明 |
|------|------|
| `scripts/ninking/logging/game_logger.gd` | 日志系统核心代码 |
| `docs/ninking/ninja-game-replay.html` | HTML 回放查看器 |
| `docs/ninking/DOCUMENT_MAP.md §9` | 文档依赖映射（日志系统） |
| `docs/ninking/09-mgmt/TODO.md Phase L` | 日志系统工作清单 |
