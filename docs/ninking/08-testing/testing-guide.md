# NinKing 游戏测试指南（Godot MCP Pro）

> **用途：** Godot MCP Pro 测试前必读。避免卡流程、节省回合。
> **更新：** 2026-06-10（v2 — 按钮文本/命令语法已对照源码核实）

---

## 0. 测试前必读

### MCP 工具的两个域

| 域 | 工具 | 前提 |
|----|------|------|
| **编辑器** | `open_scene`, `get_scene_tree`, `update_property`, etc. | 场景在编辑器中打开即可 |
| **运行时** | `execute_game_script`, `find_ui_elements`, `simulate_mouse_click`, `get_game_screenshot` | **必须先 `play_scene` 运行游戏！** |

> ⚠️ 最常见的错误：用 `open_scene` 打开场景后直接调 `find_ui_elements` → 啥也找不到，因为游戏没在跑。

### 标准测试流程

```
play_scene (mode="main")
  → await 等场景加载 + _ready() 完成
  → execute_game_script 检查状态
  → find_ui_elements 找到按钮坐标
  → simulate_mouse_click 点击
  → get_game_screenshot 确认画面
```

### 等待机制

```gdscript
// MCP 每步之间没有自动等待，需要在 execute_game_script 里手动 await：
execute_game_script: "await get_tree().create_timer(1.5).timeout; _mcp_print('done')"

// 或者等待一帧：
execute_game_script: "await get_tree().process_frame; _mcp_print('ok')"
```

---

## 1. 场景流转图

```
  play_scene mode="main"
      │
      ▼
┌─────────────────────────────────┐
│ Launcher (ninking_launcher.tscn)│  ← project.godot main_scene
│ main_menu.gd                    │
│                                 │
│  [开始游戏] → 牌组选择面板      │
│     ├─ 标准牌组 (唯一可用)      │
│     ├─ 暗夜牌组 (灰色/不可点)   │
│     └─ 赤阳牌组 (灰色/不可点)   │
│     → [确认] → start_new_run()  │
│     → change_scene → 主游戏     │
│                                 │
│  [继续游戏] → 存档确认 → 确认   │
│     → continue_run()            │
│     → change_scene → 主游戏     │
│                                 │
│  [设置] (disabled)              │
│  [退出游戏] → quit()            │
└─────────────┬───────────────────┘
              │ NinKingGameState.current_state = SEAL_INTRO
              ▼
┌─────────────────────────────────┐
│ 主游戏 (ninking_main.tscn)      │
│ game_manager.gd + ui_manager    │
│                                 │
│ 状态流转:                       │
│ ① SEAL_INTRO (2秒结界标题展示)  │
│ ② PLAYING (手牌操作)            │
│    └→ 出牌 → ③ SCORING (动画)   │
│         → 回到② 或 → ④         │
│ ④ SEAL_COMPLETE → [进入商店]    │
│ ⑤ GAME_OVER / VICTORY          │
└─────────────┬───────────────────┘
              │ change_scene → shop.tscn
              ▼
┌─────────────────────────────────┐
│ 商店 (shop.tscn)                │
│ shop_ui.gd + ShopManager       │
│                                 │
│ [刷新] $5 重新生成商品          │
│ [继续闯关 ▶] → _start_seal()   │
│   → change_scene → 主游戏       │
└─────────────────────────────────┘
```

## 2. 状态机速查

`NinKingGameState.State` 枚举（autoload: `NinKingGameState`）：

| 状态 | 值 | 进入条件 | 界面表现 |
|------|-----|---------|---------|
| `MAIN_MENU` | 0 | 引擎启动时初始值（实际未被使用） | - |
| `SEAL_INTRO` | 1 | `_begin_seal_phase()` | 结界标题 + 封印目标 + Boss名 |
| `PLAYING` | 2 | SEAL_INTRO 后 2 秒 | 9张手牌、操作按钮 |
| `SCORING` | 3 | 点击"出牌" | 计分动画覆盖层 |
| `SEAL_COMPLETE` | 4 | 分数达标 | 奖励 + "进入商店"按钮 |
| `SHOP` | 5 | `go_to_shop()` | 商店场景 |
| `GAME_OVER` | 6 | 出牌次数用尽 | 失败面板 |
| `VICTORY` | 7 | 通过8结界 | 胜利面板 |

## 3. 按钮文本对照表

> 实际文本来自 `.tscn` 源码，与 `find_ui_elements` 返回一致。

### Launcher 场景

| 按钮 | scene text | unique_name | 状态 |
|------|-----------|-------------|------|
| 开始游戏 | `"开始游戏"` | `%StartBtn` | 始终可用 |
| 继续游戏 | `"继续游戏"` | `%ContinueBtn` | 有存档时可用 |
| 设置 | `"设置"` | `%SettingsBtn` | 永远 disabled |
| 退出游戏 | `"退出游戏"` | `%QuitBtn` | 始终可用 |

### 主游戏场景

| 按钮 | scene text | unique_name | 说明 |
|------|-----------|-------------|------|
| 討伐 | `"討\n伐"` | `%PlayBtn` | 约束满足时可用 |
| 陣形 | `"陣\n形"` | `%AiRearrangeBtn` | PLAYING状态可用 |
| 牌库 | `"牌库: N"` | `%DeckBtn` | 查看牌库面板 |
| 进入商店 | `"进入商店"` | `%ToShopButton` | SEAL_COMPLETE 时可见 |
| 重新开始 | `"重新开始"` | `%RetryButton` | GAME_OVER/VICTORY 时可见 |

### 商店场景

| 按钮 | scene text | unique_name | 说明 |
|------|-----------|-------------|------|
| 刷新 | `"刷新"` | `%RerollBtn` | 金币≥$5时可用 |
| 继续 | `"继续闯关  ▶"` | `%ContinueBtn` | 始终可用 |

---

## 4. MCP 测试命令速查

### 4.1 启动游戏

```
// 方式A: 从 Launcher 正常进入（推荐）
play_scene: mode="main"

// 方式B: 直接跳到主游戏（调试用，需手动初始化 — 见 §4.3）
play_scene: mode="res://scenes/ninking/ninking_main.tscn"

// 方式C: 直接跳到商店（调试用）
play_scene: mode="res://scenes/ninking/shop.tscn"
```

### 4.2 基本状态检查

```gdscript
// 一键诊断（复制到 execute_game_script）
var g = NinKingGameState
_mcp_print("state=" + str(g.current_state) + " (0=menu 1=intro 2=play 3=score 4=complete 5=shop 6=over 7=victory)")
_mcp_print("barrier=" + str(g.barrier_num) + "/8 seal=" + str(g.seal_idx) + " (0=修罗 1=明王 2=夜叉)")
_mcp_print("score=" + str(g.current_score) + "/" + str(g.target_score))
_mcp_print("plays=" + str(g.plays_remaining) + " redraws=" + str(g.redraws_remaining) + " gold=" + str(g.gold))
_mcp_print("hand=" + str(g.hand.size()) + " cards ninjas=" + str(g.owned_ninjas.size()))
```

### 4.3 跳过 Launcher 直接进入主游戏

```
// 步骤1: 运行 Launcher 场景（提供 autoload 环境）
play_scene: mode="main"

// 步骤2: 等待加载后手动初始化并跳转
execute_game_script: "
NinKingGameState.current_deck_name = 'standard'
NinKingGameState.barrier_num = 1
NinKingGameState.seal_idx = 0
NinKingGameState.gold = 8
NinKingGameState.owned_ninjas.clear()
NinKingGameState.owned_items.clear()
NinKingGameState._start_seal()
get_tree().change_scene_to_file('res://scenes/ninking/ninking_main.tscn')
"
// 说明: _start_seal() 现在是同步的，会设好 SEAL_INTRO 状态 + 发牌。
// game_manager._ready() → _intro_timer() → 2秒后自动进入 PLAYING。
```

### 4.4 从 Launcher 正常点击进入主游戏

```
// 1. 等待 Launcher 动画完成（闪屏0.8s + 按钮滑入0.4s）
execute_game_script: "await get_tree().create_timer(1.5).timeout; _mcp_print('Launcher ready')"

// 2. 找到"开始游戏"按钮坐标
find_ui_elements: type_filter="Button"
// 返回: [{text:"开始游戏", center:{x:..., y:...}, ...}, ...]

// 3. 点击"开始游戏"
simulate_mouse_click: x=<center_x> y=<center_y>

// 4. 等待牌组面板弹出(0.25s)
execute_game_script: "await get_tree().create_timer(0.4).timeout; _mcp_print('panel shown')"

// 5. 牌组面板"确认"按钮在屏幕中央 (960, ~540)，点击确认
// 先用 find_ui_elements 找到"确认"按钮的坐标
find_ui_elements: type_filter="Button"
simulate_mouse_click: x=<confirm_x> y=<confirm_y>

// 6. 场景切换到主游戏，等待加载 + intro 2s
execute_game_script: "await get_tree().create_timer(3.0).timeout; _mcp_print('game ready')"

// 7. 确认进入 PLAYING
execute_game_script: "_mcp_print('state=' + str(NinKingGameState.current_state))"
// 期望: state=2 (PLAYING)
```

### 4.5 主游戏操作

```
// === 討伐 ===
// 找到"討\n伐"按钮 → 点击
find_ui_elements: type_filter="Button"
// 找到 text 含"討"的按钮
simulate_mouse_click: x=<x> y=<y>

// === 陣形 ===
// 找到 text="陣\n形" 的按钮 → 点击
simulate_mouse_click: x=<x> y=<y>

// === 交换 ===
// 方法A: 点击第一张牌 → 再点击第二张牌
// 方法B: 拖拽（需计算落点坐标）
```

### 4.6 状态快速跳转（调试用）

```gdscript
// 跳过 intro 直接进入 PLAYING
execute_game_script: "NinKingGameState._transition_to(NinKingGameState.State.PLAYING)"

// 直接过关（需先有合法排列，然后点討伐）
execute_game_script: "
NinKingGameState.current_score = NinKingGameState.target_score - 1
NinKingGameState.emit_score_updated()
"
// → 点击討伐 → 这轮会刚好达标 → SEAL_COMPLETE

// 直接跳到商店
execute_game_script: "
NinKingGameState._transition_to(NinKingGameState.State.SHOP)
get_tree().change_scene_to_file('res://scenes/ninking/shop.tscn')
"

// 加金币
execute_game_script: "
NinKingGameState.gold += 100
NinKingGameState.gold_changed.emit(NinKingGameState.gold)
"
```

## 5. 测试检查清单

### 5.1 Launcher

- [ ] 场景加载，4个按钮可见（闪屏0.8s后滑入）
- [ ] "开始游戏" → 牌组面板弹出（半透明遮罩+中央面板）
- [ ] 标准牌组高亮选中，暗夜/赤阳灰色不可点击
- [ ] "确认" → `change_scene_to_file` → 主游戏场景
- [ ] "继续游戏" → 无存档时显示 Toast "没有可继续的存档"
- [ ] "退出游戏" → 退出

### 5.2 主游戏 — 结界 Intro

- [ ] 结界标题 + 封印目标显示（~2秒）
- [ ] Boss 名出现时: CRT vignette + 畸变 → scale_pop → 恢复
- [ ] 2秒后进入 PLAYING，显示 9 张手牌

### 5.3 主游戏 — 操作

- [ ] 手牌分三组：影(3张)/瞬(3张)/滅(3张)
- [ ] 点击牌A→再点牌B = 交换位置
- [ ] 约束不满足时显示红色提示（影勢過強/滅力不足/重排三道）
- [ ] 约束满足时提示消失，討伐按钮可用
- [ ] "换\n牌" → 选牌 → 二次确认 → 弃旧抽新
- [ ] "陣\n形" → 自动排列
- [ ] "牌库" → 牌库查看面板

### 5.4 计分动画

- [ ] 覆盖层出现 → 牌型标签滑入 → 分数 CountUp
- [ ] 过关: 樱花粒子 + hit_stop + punch_in
- [ ] 继续: overlay淡出 → 重新发牌
- [ ] 失败: 红色闪烁 + CRT畸变 → GAME_OVER

### 5.5 商店

- [ ] 商品入场动画（面板上滑 + 卡牌 scale 弹出）
- [ ] 金币显示 = 当前持有
- [ ] 忍者槽位显示 (N/5)
- [ ] 购买忍者 → 扣金币 + 刷新槽位
- [ ] 槽位满时购买 → Toast "槽位已满"
- [ ] "刷新" → 扣$5 → 重新生成
- [ ] "继续闯关 ▶" → 返回主游戏 + 进入下一封印

## 6. 常见陷阱

### 6.1 卡在 SEAL_INTRO 不进 PLAYING

**症状：** 画面显示结界标题，永远不进手牌界面。

**原因：** `_begin_seal_phase()` 的 await timer 被 `change_scene_to_file` 销毁（已修复：timer 移至 `game_manager._intro_timer()`）。

**急救：**
```gdscript
execute_game_script: "NinKingGameState._transition_to(NinKingGameState.State.PLAYING)"
```

### 6.2 Launcher 按钮点不动

**可能原因：**
1. 动画未完成 — 按钮 `modulate.a=0`，需等 ~1.2s（闪屏0.8s + slide_in 0.4s）
2. 按钮 disabled — "设置"永久disabled，"继续游戏"无存档时disabled
3. `find_ui_elements` 未在运行时调用

**诊断：**
```gdscript
execute_game_script: "
await get_tree().create_timer(1.5).timeout
var btn = Engine.get_main_loop().current_scene.get_node_or_null('%StartBtn')
if btn:
    _mcp_print('btn disabled=' + str(btn.disabled) + ' visible=' + str(btn.visible) + ' modulate=' + str(btn.modulate))
else:
    _mcp_print('btn not found — wrong scene?')
"
```

### 6.3 直接运行 ninking_main.tscn 空白/报错

**原因：** `game_manager._ready()` 需要 `NinKingGameState` 已初始化（手牌/target_score等），直接运行主场景跳过了 `start_new_run()`。

→ 用 §4.3 的两步法。

### 6.4 商店"继续"后卡住

**原因：** 同 6.1 — `_start_seal()` → `_begin_seal_phase()` 后 scene change 丢 timer。

→ 同上急救，或确保已更新到最新代码（已修复）。

### 6.5 截图时机

```gdscript
// 截图前确保渲染完成
execute_game_script: "await get_tree().process_frame; _mcp_print('ok')"
get_game_screenshot

// 动画中间态截图 → 等动画结束
execute_game_script: "await get_tree().create_timer(0.5).timeout"
get_game_screenshot
```

### 6.6 `find_ui_elements` 返回空

**原因：**
1. 游戏未通过 `play_scene` 运行（仅在编辑器中 `open_scene`）
2. 场景还在加载（_ready 未完成）
3. UI 元素 `visible=false`

**检查：**
```
get_game_screenshot  // 先看看画面是不是预期场景
```

### 6.7 `execute_game_script` 报错 "Invalid get index"

**常见原因：** 引用了不在当前场景的节点。

```gdscript
// 错误: 在 Launcher 场景访问 %PlayBtn（只在主游戏场景存在）
// 正确: 先确认当前场景
_mcp_print(Engine.get_main_loop().current_scene.scene_file_path)
```

## 7. 手牌调试命令

```gdscript
// 查看完整手牌
for i in range(NinKingGameState.hand.size()):
    var c = NinKingGameState.hand[i]
    var group = "影" if i<3 else ("瞬" if i<6 else "滅")
    _mcp_print(group + "[" + str(i%3) + "]: suit=" + str(c.suit) + " rank=" + str(c.rank))

// 查看当前排列评分
var a = NinKingGameState.current_arrangement
if a:
    _mcp_print("影: type=" + str(a.head_eval.hand_type) + " str=" + str(a.head_eval.strength))
    _mcp_print("瞬: type=" + str(a.mid_eval.hand_type) + " str=" + str(a.mid_eval.strength))
    _mcp_print("滅: type=" + str(a.tail_eval.hand_type) + " str=" + str(a.tail_eval.strength))
    _mcp_print("Legal: " + str(a.is_legal()))

// 查看列分
var cols = NinKingGameState.current_col_evals
if cols.size() == 3:
    for i in range(3):
        _mcp_print("Col" + str(i) + ": type=" + str(cols[i].hand_type) + " str=" + str(cols[i].strength))
```

## 8. 场景与 Autoload 速查

### 场景文件

| 场景 | 路径 | 根脚本 | 关键 unique_name |
|------|------|--------|-------------------|
| Launcher | `res://scenes/ninking/ninking_launcher.tscn` | `main_menu.gd` | `%StartBtn`, `%ContinueBtn`, `%SettingsBtn`, `%QuitBtn` |
| 主游戏 | `res://scenes/ninking/ninking_main.tscn` | `game_manager.gd` | `%UIManager` (内含所有按钮和标签) |
| 商店 | `res://scenes/ninking/shop.tscn` | `shop_ui.gd` | `%GoldLabel`, `%RerollBtn`, `%RerollLabel`, `%AbilityRow`, `%ItemRow`, `%ContinueBtn`, `%NextLevelHint`, `%NinjaSlotLabel`, `%ShopPanel` |

### Autoload

| 名称 | 类 | 用途 |
|------|-----|------|
| `NinKingGameState` | Node | 核心状态：手牌/分数/金币/状态机/信号 |
| `GlobalTweens` | Node | Tween 委托（fade/slide/particle/crt/shake） |
| `MusicManager` | Node | BGM/SFX |
| `ToastManager` | Node | Toast 提示浮层 |
| `ConfigManager` | Node | 配置持久化 |
| `MCPGameBridge` | Node | MCP ↔ Godot 通信 |

---

> **提示：** 测试前先跑 §4.2 的诊断命令，确认状态正确后再操作 UI。省下的时间比读这个文档多得多。
