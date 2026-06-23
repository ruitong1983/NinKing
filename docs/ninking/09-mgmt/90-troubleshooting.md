# 疑难问题解决手册

> **建立日期:** 2026-06-14 | **最后更新:** 2026-06-22 (§17)
> **用途:** 记录开发中遇到的非显而易见的坑及其解决方案，避免重复踩坑。

## §1 素材替换后"缺少依赖项"

**现象：** 用外部工具替换 `.png` / `.wav` 等导入资源后，Godot 编辑器弹出"缺少依赖项"对话框，`get_editor_errors` 报 `Failed loading resource: res://...`。

**根因：** Godot 的 `.import` 文件记录了源文件的哈希值。外部替换后哈希不匹配 → Godot 标记 `valid=false` → 场景中引用该 UID 的节点无法加载资源。

**修复步骤：**
1. 删除该资源的 `.import` 文件和 `.godot/imported/` 中的对应缓存（`.ctex` + `.md5`）
2. 删除 `.godot/editor/filesystem_cache10`
3. Reload Project → Godot 自动重新导入，生成新 `.import`（UID 会变）
4. 用新 UID 更新所有 `.tscn` / `.tres` 中的 `uid://` 引用

**预防：** 始终在 Godot 编辑器的 FileSystem dock 中拖入替换，Godot 会自动处理导入和 UID 维护。

**实例：** 2026-06-14 `table_bg.png` 替换，UID `uid://0cfwiaafax62` → `uid://deelue8r4tqif`，影响 3 个场景。

---

## §2 Debug 场景 Label `mouse_entered` 不触发

**现象：** 动态创建的 `Label`（嵌套在 `VBoxContainer` → `HBoxContainer` → `Label`）的 `mouse_entered` / `mouse_exited` 信号不触发。

**根因：** `Label` 默认 `mouse_filter = MOUSE_FILTER_PASS`，在深层嵌套的容器层级中，鼠标事件可能被父容器截获，`mouse_entered` 不会可靠触发。

**修复：** 显式设置 `label.mouse_filter = Control.MOUSE_FILTER_STOP`。

**实例：** 2026-06-14 Debug 面板星图 hover tooltip，`debug_controller.gd:_rebuild_star_chart()`。

---

## §3 execute_game_script 编译失败

**现象：** 调用 `execute_game_script` 返回 `Script compilation failed: Parse error`，即使代码看起来正确。

**原因：**
1. 项目中其他脚本存在编译错误时会污染全局编译状态
2. 脚本中包含不被支持的语法（如某些 Unicode 字符）
3. 编辑器正在打开的脚本被外部修改后未重新解析

**解决：**
- 先 `validate_script` 检查关键脚本无编译错误
- 简化 `execute_game_script` 代码到最小可复现单元
- `reload_project` 后重试

---

## §4 TextureRect.EXPAND_IGNORE_SIZE 纹理原生分辨率溢出

**现象：** TextureRect 设为 `expand_mode = EXPAND_IGNORE_SIZE` 后，纹理按原始分辨率绘制，无视 `stretch_mode`，导致纹理溢出 TextureRect 边界（例如 500×700 的忍者卡在 125×175 的卡片中显示为巨大图片）。

**根因：** Godot 4 的 `EXPAND_IGNORE_SIZE` 行为与名称一致——忽略 TextureRect 的尺寸约束，完全以纹理的原始像素分辨率渲染。常见的误用场景：

| 场景 | 纹理原始尺寸 | TextureRect 尺寸 | 结果 |
|------|-------------|-----------------|------|
| 忍者卡 (PNG) | 500×700 | 125×175 | 溢出 4 倍 |
| 卡牌 SVG | 240×334 (viewBox) | 140×196 | 溢出 ~1.7 倍 |
| `card_back.png` | 1728×2304 | 140×196 | 溢出 ~12 倍 |

即使显式设置了 `size = Vector2(W, H)` 或调用 `_update_card_size()`，`EXPAND_IGNORE_SIZE` 仍然无视之。

**解决方案（三选一，推荐 ①）：**

① **运行时缩放纹理（推荐，已用于忍者卡/扑克牌/附魔选牌）**
   ```gdscript
   var img: Image = tex.get_image()
   if img and (img.get_width() != int(target_width) or img.get_height() != int(target_height)):
       img.resize(int(target_width), int(target_height), Image.INTERPOLATE_LANCZOS)
       tex = ImageTexture.create_from_image(img)
   set_faces(tex, null)
   ```
   `INTERPOLATE_LANCZOS` 缩放质量最高，适合缩小。缩小的纹理直接匹配 TextureRect 尺寸，`EXPAND_IGNORE_SIZE` 不再产生视觉溢出。

② **改用 EXPAND_KEEP_SIZE + 调整 custom_minimum_size**
   - `EXPAND_KEEP_SIZE` 让 `stretch_mode` 生效，但 `custom_minimum_size` 会被纹理尺寸锁定，无法让 TextureRect 小于纹理。

③ **用 SubViewport 预渲染缩放**
   - 适合需要保持原始纹理用于其他用途的场景，但不必要地复杂。

**注意：** `get_image()` 只对非 VRAM 纹理（SVG 渲染结果、`ImageTexture`、普通加载的 `Texture2D`）返回有效数据。压缩纹理（`.dds` / VRAM 压缩导入的 PNG）返回空 `Image`。

**受影响的类：** `ninja_inventory_card.gd`、`ninking_card.gd`、`enchant_target_selector.gd`（2026-06-15 全面修复）。

### 姊妹坑：默认 EXPAND_KEEP_SIZE 导致的布局溢出

**现象：** FrameOverlay TextureRect 程序化创建时没设 `expand_mode`，默认值 `EXPAND_KEEP_SIZE` 让 `minimum_size` 锁定为纹理原生尺寸（500×700），导致框和插画缩放不一致——框的布局尺寸和插画不匹配，在弹窗中呈现"忍者比框小"的视觉效果。

**根因：** `TextureRect` 的默认 `expand_mode` 是 `EXPAND_KEEP_SIZE`（0），表示纹理原生尺寸参与布局计算。对于作为叠层/覆盖的 TextureRect（如卡牌框），纹理尺寸不应影响布局——必须显式设为 `EXPAND_IGNORE_SIZE`。

**规律：** 本项目中所有 TextureRect 的尺寸都是由父节点/锚点决定的固定值，没有任何一处需要纹理尺寸来自动决定布局。因此 **`EXPAND_KEEP_SIZE` 在本项目没有适用场景**，每次依赖默认值都是 bug。

**预防：** 新建 TextureRect 时，紧跟一行 `.expand_mode = TextureRect.EXPAND_IGNORE_SIZE`。详见 CLAUDE.md 规范。

**实例：** 2026-06-15 `card_detail_popup.gd` + `ninja_inventory_card.gd` FrameOverlay，两处都是程序化创建 TextureRect 后漏设 expand_mode。

---

## §5 `await score_tw.finished` 信号已过期间步死锁

**现象：** 计分动画 Phase1 第 0 行正常显示（手牌类型+分数），但第 1-3 行和 3 列均无数字，动画卡死。控制台输出停在 `>> await:score_tw.finished`，无后续。

**根因：** Godot 4 的 `await signal` 在信号已发射后再 `await` 会**永远挂起**——信号不会重发。

在计分动画 Phase1 中，时序冲突：
```
t=0.00: play_score 创建 Tween，持续 1.26s（result=29, tier 1）
t=1.26: Tween 完成 → finished 信号已发射 ✅
t=1.37: pop_delay 定时器（硬编码 1.2×1.2×0.95=1.368s）到期
t=1.37: await score_tw.finished ← ⚠️ 信号在 0.108s 前就发过了！永远等不到
```

`pop_delay = 1.2 × 1.2 × 0.95 = 1.368s` 是一个固定估算值，而 Tween 的实际持续时间取决于 score tier（`_score_tier()` 根据结果值动态计算）。只要 Tween 持续 < pop_delay，就会触发此 bug。

**错误模式：**
```gdscript
# ❌ 先等固定 timer，再 await 信号
var pop_delay: float = 1.2 * 1.2 * 0.95
await tree.create_timer(pop_delay).timeout
# ⚠️ 此时 tween 可能已结束，finished 信号已错过
if score_tw != null:
    await score_tw.finished  # 永远卡死！
```

**修复：** 调换顺序——**先 await tween 完成，再做后续动画**：
```gdscript
# ✅ 先等 tween 自然完成
if score_tw != null:
    await score_tw.finished

# ✅ tween 完成后再做强调动画（punch_in）
if is_instance_valid(sl):
    GlobalTweens.punch_in(sl, 0.25, 1.5)
```

**关键原则：** Godot 4 中，`await some_signal` 必须保证信号**尚未发射**或**还会再次发射**。如果信号是一次性的且可能在 `await` 执行前已发射，就会死锁。Tween.finished、Timer.timeout 等一次性信号尤其危险。

**受影响的文件：** `scripts/ninking/ui/animation_handler.gd` Phase 1（rows）和 Phase 2（columns）各一处。

**实例：** 2026-06-15 计分动画三行三列空白，`animation_handler._run_scoring_animation()`。

---

## §6 `setup()` 在 `_ready()` 前调用导致节点引用为 null

**现象：** 场景实例化的节点中，`_ready()` 里初始化的变量（如 `frame_overlay = $FrameOverlay`）在外部调 `setup()` 时为 `null`，导致视觉缺失（忍者栏框不显示、TextureRect 设纹理报 Nil 错误）。

**根因：** 调用方在 `add_child()` **之前**调用了 `setup()`，而 `_ready()` 只在节点加入场景树后才触发：

```
# ninja_bar_node.gd:_make_slot()
var card := NINJA_CARD_SCENE.instantiate() as NinjaInventoryCard
card.setup(...)              # ← _ready() 还没触发！节点引用全是 null
# ...
_container.add_card(card)    # ← 这里才触发 _ready()
```

同理，从场景实例化时 `check_and_set_textures()`（解析 `front_face_texture`/`back_face_texture` 的 `$FrontFace/TextureRect` 路径）也在 `Card._ready()` 中，不经过 `_ready()` 就不会执行。

注意：`instantiate()` 创建的节点及其子节点**物理上已存在**（`$` 路径可用），只是 `_ready()` 尚未执行。与其等待 `_ready()` 自动赋值，不如显式解析引用。

**修复模式（已在 `ninja_inventory_card.gd` 实施）：**

1. **节点引用提前解析** — 在 `_ensure_face_nodes()` 末尾加引用赋值：
   ```gdscript
   if frame_overlay == null:
       frame_overlay = $FrameOverlay if has_node("FrameOverlay") else null
   ```

2. **入口函数调 `_ensure_face_nodes()`** — `setup()` 和 `setup_shop()` 顶部调用，不依赖 `_ready()`：
   ```gdscript
   func setup(ninja_name: String, data: Dictionary) -> void:
       _ensure_face_nodes()   # ← 提前解析所有子节点引用
       check_and_set_textures()   # ← 提前解析 texture rect 引用
       _apply_rarity_frame(data.get("rarity", "common"))
       # ...
   ```

3. **`_ready()` 中重入安全** — `_ready()` 仍调 `_ensure_face_nodes()`，但 `has_node()`/`== null` 守卫使其成为 no-op：
   ```gdscript
   func _ready() -> void:
       _ensure_face_nodes()  # 安全重入
       # ...
       frame_overlay = $FrameOverlay  # 冗余但无害的引用赋值
   ```

**预防清单：**
- 所有在外部调用 `setup()` / `init()` 的类，如果使用了 `_ready()` 才解析的节点引用，必须提前解析
- 入口函数（`setup()` / `init()`）中调 `_ensure_face_nodes()` 作为防御
- `_ensure_face_nodes()` 末尾类成员赋值，让后续逻辑（`_apply_rarity_frame` / `set_faces`）不依赖 `_ready` 时序
- `_ready()` 中避免覆盖 `setup()` 已设的值（如 `frame_overlay.visible`）

**受影响的类：** `ninja_inventory_card.gd`（`frame_overlay` / `front_face_texture` / `back_face_texture`）。

**实例：** 2026-06-15 C29 统一忍者卡场景，`ninja_bar_node.gd:_make_slot()` `setup()` 在 `add_card()` 前调用导致忍者栏框不显示。

---

## §7 RichTextLabel 默认 `scroll_active = true` 导致多余滚动条

**现象：** 动态创建的 `RichTextLabel` 明明只有一行文本，却显示一条垂直滚动条。

**根因：** `RichTextLabel` 在 Godot 4 中默认 `scroll_active = true`。当标签高度小于字体实际行高时，内容超出可视区域 → 滚动条自动出现。

常见触发场景——字号和标签高度不匹配：
```gdscript
# ❌ 高度 26px 但字号 24px：行高 ≈28-30px > 26px → 滚动条出现
rtl.size = Vector2(300, 26)
rtl.add_theme_font_size_override("normal_font_size", 24)
```

**修复（同时做两件事）：**
```gdscript
# ✅ ① 显式关闭滚动条
rtl.scroll_active = false
# ✅ ② 同时放大高度给行高留足空间（24px 字号 → 32px 高度）
rtl.size = Vector2(300, 32)
```

**规律：** 创建 `RichTextLabel` 时只要内容不会动态增长，就应当 **显式设 `scroll_active = false`**。依赖默认值在本项目中总是 bug——本项目没有需要滚动条的 RichTextLabel 使用场景。

**预防：** GDScript 中新建 RichTextLabel 时，紧跟在 `RichTextLabel.new()` 之后的配置链中包含 `rtl.scroll_active = false`。

**受影响的类：** `card_detail_popup.gd`（`_build_effect_row()` 中 1 处）。

**实例：** 2026-06-16 右键忍者牌详情弹窗，手里剑忍者牌的 "+10 筹码" 效果行显示多余滚动条。

---

## §8 Card Framework Drop 处理不触发的调试套路

**现象：** 拖拽卡牌松开后，卡牌没有落到目标位置，而是弹回原位；调试打印显示 `_on_drag_dropped` 中遍历容器时 `check_card_can_be_dropped` 返回 `false`，或 `get_partition_index` 返回 -1。

**排查步骤（自底向上）：**

1. **`release_holding_cards()` 是否被调用？** — 检查 `NinKingCard._handle_mouse_released()` 是否走了 `super._handle_mouse_released()` → `Card._handle_mouse_released()` → `card_container.release_holding_cards()`。如果重写了 `_handle_mouse_released` 却没调 `super`，或 `card_container` 为 null，就不会触发 drop 处理。

2. **`_holding_cards` 是否为空？** — `release_holding_cards()` 内部检查 `_holding_cards.is_empty()` 提前返回。`hold_card()` 在 `Card._enter_state(HOLDING)` 中调用，如果卡片没正确进入 HOLDING 状态（例如 `can_be_interacted_with = false`），`_holding_cards` 为空，`_on_drag_dropped` 不会被调用。

3. **`card_container_dict` 是否包含目标容器？** — `CardManager._on_drag_dropped` 遍历 `card_container_dict` 找第一个接受 drop 的容器。如果容器没有注册（`_find_and_register_card_manager()` 失败，`card_manager` 为 null），dict 为空 → 所有卡牌执行 `return_card()`。

4. **`check_card_can_be_dropped` 为什么返回 false？**

   | 检查点 | 失败原因 | 修复 |
   |--------|----------|------|
   | `enable_drop_zone` | 未启用 | 设 `enable_drop_zone = true` 或保留默认值 |
   | `drop_zone` 为 null | `_initialize_drop_zone()` 未执行 | 确保 `CardManager` 在场景树中位于 CardContainer 上方 |
   | `accept_types` | 不包含 `"card"` | `drop_zone.init(self, [CardManager.CARD_ACCEPT_TYPE])` |
   | `check_mouse_is_in_drop_zone()` | sensor 太小/位置不对 | 检查 `_update_target_positions()` 中 `drop_zone.set_sensor_size_flexibly(size, Vector2.ZERO)` 是否调用，`size` 是否有效 |
   | `_card_can_be_added()` | 容量检查误拒同容器重排 | 对于同容器拖放，检查卡片是否已在 `_held_cards` 中；全部已存在则跳过容量检查 |

5. **`get_partition_index()` 返回错误索引？** — 基类 `CardContainer.get_partition_index()` 只返回 `drop_zone.get_vertical_layers()`（列索引 0-2），不包含行信息。对于网格容器必须覆盖：
   ```gdscript
   func get_partition_index() -> int:
       var col := drop_zone.get_vertical_layers()
       var row := drop_zone.get_horizontal_layers()
       if col < 0 or row < 0:
           return -1
       return row * COLS + clampi(col, 0, COLS - 1)
   ```

6. **`swap_two_cards` 在非 PLAYING 状态不触发？** — `SealController.swap_cards()` 内部有状态守卫：
   ```gdscript
   if gs.current_state != NinKingGameState.State.PLAYING:
       return  # ← Debug/菜单界面下直接返回，不 emit hand_swapped
   ```
   调试场景（MAIN_MENU 状态）下，`hand_swapped` 信号不会被 emit → `swap_two_cards` 不触发。`move_cards()` 中需添加回退：
   ```gdscript
   SealController.swap_cards(NinKingGameState, src_idx, index)
   if NinKingGameState.current_state != NinKingGameState.State.PLAYING:
       swap_two_cards(src_idx, index)  # 直接做视觉交换
   ```

**预防：** 添加 Card Framework drop 支持的自定义容器时，按以上 6 步逐一验收。第一次集成时在 `check_card_can_be_dropped` 加 `print()` 定位最快。

**实例：** 2026-06-16 B17 手牌拖拽交换修复，上述第 4、5、6 项全部踩坑。

---

## §9 卡牌交换后行列/喜标签不刷新

**现象：** 在手牌区交换两张牌后（点击交换或拖拽交换），行标签（影/瞬/滅）、列标签（Col0-2）、喜检测标签均不更新，仍显示交换前的牌型。

**根因：** `HandCardContainer.swap_two_cards()` 只做视觉层面的卡牌交换（移动节点、更新 `_held_cards`），但**没有发出任何信号通知 UI 层刷新标签**。在 Debug 场景下问题更严重——`SealController.swap_cards()` 内部有状态守卫 `if gs.current_state != PLAYING: return`，Debug 场景的状态是 `MAIN_MENU`，`hand_swapped` 信号永远不会发出，标签刷新链路完全断掉。

**修复（两处）：**

1. **`hand_card_container.gd:swap_two_cards()`** — 末尾添加 `layout_changed.emit()`，确保每次视觉交换后都通知监听方。
   ```gdscript
   tgt_card.move(src_target, 0.0)
   src_card.move(tgt_target, 0.0)

   layout_changed.emit()  # ← 新增
   ```

2. **`debug_controller.gd`** — 监听 `_card_grid.layout_changed` 信号，从 CardGrid 的实际卡牌数据同步 `_slot_data` 并刷新标签：
   ```gdscript
   # _ready() 中
   _card_grid.layout_changed.connect(_on_grid_layout_changed)

   func _on_grid_layout_changed() -> void:
       var cards: Array = _card_grid._held_cards
       if cards.size() != 9:
           return
       for i: int in range(9):
           var c = cards[i]
           if c is NinKingCard and c.playing_card_data != null:
               _slot_data[i] = c.playing_card_data
       _preview_dun_labels()
       _update_button_states()
   ```

**设计要点：** Debug 场景的数据模型（`_slot_data`）与主场景（`NinKingGameState.hand`）不同。主场景通过 `hand_swapped` → `HandTypeLabeler.update_all(hand)` 读取 `gs.hand` 刷新标签；Debug 场景没有 `gs.hand`，必须从 CardGrid 的实际卡片数据反推。`layout_changed` 信号适合做这种"不管数据源是什么，UI 层需要知道布局变了"的通知。

**排查方法论：** 当怀疑信号链路断裂时，沿链路逐节点加 `print()` → 运行 → 看 Output 面板。哪个 `print` 没出现，断点就在上一环。避免纯静态分析耗光回合。

**受影响的文件：** `hand_card_container.gd`、`debug_controller.gd`

**实例：** 2026-06-17 Debug 场景交换卡牌后行列/喜标签不刷新。

---

## §10 Button disabled 样式不生效

**现象：** 按钮设置了 `theme_override_styles/disabled = SubResource("StyleBoxFlat_xxx")`，bg_color 设了半透明灰度色，但按钮禁用后仍然显示正常（红色/明亮），灰色样式未出现。

**根因（两坑）：**

### 坑 A：按钮 `disabled` 属性从未被设为 `true`

`theme_override_styles/disabled` 只控制**禁用时的外观**，但按钮本身必须 `button.disabled = true` 才会切换到这个样式。如果代码中没有把按钮设为禁用（只做了功能性 return），灰色样式永远不会显示。

```
# ❌ 只阻止行为，不改按钮状态
func _on_play_pressed() -> void:
    if not _is_legal():
        _set_status("约束不满足")
        return   # 按钮仍是 enabled 状态，显示 normal 样式

# ✅ 同时更新按钮状态
func _update_button_states() -> void:
    var can_play: bool = _check_legal()
    _play_btn.disabled = not can_play   # 触发 disabled 样式切换
```

**排查：** 在 `_update_button_states()`（或等效更新按钮状态的位置）检查 `disabled` 属性是否根据条件正确设置。

### 坑 B：`disabled` 样式被其他 theme_override 覆盖

如果同时设置了 `theme_override_styles/normal` 和 `theme_override_styles/disabled`，但 normal 样式中 bg_color 的 alpha = 1.0，而 disabled 样式中 bg_color 的 alpha = 0.5，但仍显示 full color——先检查坑 A。

**修复：** `_update_button_states()` 或等效函数中，确保约束/条件不满足时显式设 `btn.disabled = true`。

**实例：** 2026-06-18 Debug 场景 `debug_controller.gd` `_update_button_states()` 只检查牌数(≠9)，不检查约束(ascending head≤mid≤tail)，导致非法排列时按钮状态正确(禁用)但 visual 始终显示 normal 样式。修复：加入约束检查后 `disabled = true` 正确触发，灰色样式生效。

---

## §11 ScoreResult.chips_sum / mult_sum 未赋值导致 debug 场景显示 "0 × 1 = 总分"

**现象：** Debug 场景打完一轮后，左边栏总分标签显示 `"0 × 1 = 120"`（或类似格式），第一个数始终为 0，中间始终为 1，只有等号后的总分正确。主场景不受影响。

**根因：** `ScoreResult` 声明了 `chips_sum: int = 0` 和 `mult_sum: int = 0` 两个字段，但全项目**没有任何代码给它们赋值** — 永远是默认值 0。

Debug 场景的 `_update_score_display()`（`debug_controller.gd:490`）直接用这两个字段格式化：

```gdscript
_score_label.text = "%d ×%d = %d" % [
    result.chips_sum,               # 始终 0
    max(result.mult_sum, 1),        # max(0, 1) → 始终 1
    result.total_score              # 正确
]
```

主场景不受影响是因为它使用 `UIManager._score_subtotal`（动画流程中累计的行+列总分）和 `_score_xi`（全局喜×倍率），不涉及 `chips_sum`/`mult_sum`。

**修复：** 在 `ScoreCalculator.calculate()` 和 `calculate_with_summary()` 的 `result.breakdown` 之前各加两行：

```gdscript
result.chips_sum = result.head_chips + result.mid_chips + result.tail_chips
result.mult_sum = result.head_mult + result.mid_mult + result.tail_mult
```

**受影响的文件：** `scripts/ninking/score/score_calculator.gd`（+4 行）、`scripts/ninking/debug/debug_controller.gd:490`（消费端）。

**实例：** 2026-06-18 用户报告 debug 场景左边栏总分显示 `"0 × 1 = 总分"`。

---

## §12 外部编辑 .gd 文件后 Godot 报 "hides a global script class"

**现象：** 用外部工具（Node.js / VS Code 等）修改 GDScript 文件后，Godot 编辑器的 `validate_script` 报 `Parse Error: Class "XXX" hides a global script class`，但实际只有一处 `class_name` 定义。

**根因：** 外部编辑保存后，Godot 的脚本缓存未及时刷新。编辑器创建一个临时副本（PID 号如 `-9223367996364212366.gd`）来解析新内容，旧缓存仍保留 → 解析器认为存在两个同名的全局脚本类。

**修复：** 在 Godot 编辑器中执行一次 **Project → Reload Current Project**（或通过 MCP 调用 `reload_project`），即可刷新缓存消除误报。若 persist，在 Godot 中 **关闭并重新打开** 受影响的脚本文件再 Reload。

**注意：** `read_script` MCP 命令返回 LF 行尾（不管磁盘是 CRLF），`validate_script` 在该文件上可能持续报错，但不影响实际加载 —— `load()` 和 `execute_editor_script` 都能正常使用。

**实例：** 2026-06-18 `score_calculator.gd` 经 Node.js 外部编辑后持续报 Class "ScoreCalculator" hides a global script class，Reload Project 后消除。

## §13 JSON.parse 返回的 Dictionary 是只读的

**现象：** 运行时报 `Dictionary is in read-only state`，栈追踪指向 `_read_json()` 或 `load_progress()` 中尝试写入字典的行。

**根因：** Godot 4 的 `JSON.parse()` 返回的 `json.data` 是只读 Dictionary。调用方直接修改它（如 `data["total_runs"] += 1`）会触发 `Dictionary is in read-only state` 错误。嵌套字典也是只读的。

**修复：** `_read_json()` 返回前做深拷贝：
```gdscript
return (json.data as Dictionary).duplicate(true)
```

**影响范围：** 所有基于 `_read_json()` 的函数：`load_run()`、`load_progress()`。如果调用方需要修改返回的数据，必须使用可写副本。

**实例：** 2026-06-18 `save_manager.gd:99` — `record_run_result()` 试图写入 `load_progress()` 返回的只读字典。修复见 `save_manager.gd:131`。

---

## §14 scale≠1 时设置 global_position 导致动画后位置偏移

**现象：** 卡片在 scale=0.1（待 pop-in 状态）时设置 `card.global_position = target_pos`，pop_in 动画将 scale 变为 1.0 后，卡片实际渲染位置与 target_pos 不符（偏高/头部被截断）。

**根因：** Godot 的 `global_position` setter 在反向计算 `local_position` 时会将当前 scale 和 pivot_offset 纳入变换矩阵。在 scale=0.1 + pivot_offset=(62.5, 87.5) 时算出的 `local_position` **只在 scale=0.1 下正确**。动画将 scale 变为 1.0 后，`local_position` 不再对应期望的全局位置，卡片发生视觉跳跃。

实测数据（6 张忍者牌）：
```
scale=0.1 时设 global_position.y=20
  → Godot 反算出 local_position.y=-68.75（parent_gp.y=10）
scale→1.0 后实际渲染位置 = 10 + (-68.75) = -58.75
  → 比目标位置高了 78.75px
```

**修复：** 设置 `global_position` 前临时将 scale 置为 1.0，算完再恢复：
```gdscript
var saved_scale := card.scale
card.scale = Vector2.ONE
card.global_position = target_pos
card.scale = saved_scale
```

**涉及文件：** `scripts/ninking/ui/ninja_bar_container.gd:_update_target_positions()`

**影响范围：** 所有在非 1.0 scale 下设置 `global_position` 后通过 Tween 恢复 scale 的场景。应遵循"设 global_position 前先归一化 scale"的原则。

**实例：** 2026-06-18 `ninja_bar_container.gd:108-119` — NinjaBar 忍者牌初始定位。此修复对 NinjaBarContainer 全局生效（主场景 + Debug 场景）。

---

## §15 点击卡牌后位置微小偏移

**现象：** 鼠标左键点击手牌区卡牌（不拖拽，仅单击），卡牌释放后位置与点击前不符，偏移若干像素（~6-9px）。

**根因：** Card Framework 的 `DraggableObject` 状态机在 `HOLDING → IDLE` 转换时故意不重置 position（`_exit_state(HOLDING)` 注释: "Reset visual effects but preserve position for return_card() animation"）。position 预期由拖放流程的 `return_card()` 恢复。

但在同容器同 index 的释放场景（点击不放拖），`CardManager._on_drag_dropped()` 检测到卡牌落在同一容器的同一位置后调用 `HandCardContainer.move_cards()` → `src_idx == index` → 直接 `return true`（no-op），卡牌的 position 从未被恢复到正确的网格坐标。

完整链路：
```
HOVERING → (click) → HOLDING (position 跟随鼠标)
  → (release) → IDLE (position 不重置)
    → release_holding_cards() → _on_drag_dropped()
      → HandCardContainer.move_cards() → same-index no-op
        → position 停留在 HOLDING 期间的鼠标位置 ✗
```

**修复：** `hand_card_container.gd:135-140` — 同 index 释放时，调用 `cards[0].move()` 将卡牌 tween 动画移回正确的网格坐标，而不是直接返回：

```gdscript
if src_idx == index:
    # Same slot — restore card to correct grid position
    # (click without drag leaves card at HOLDING position)
    var target := global_position + _card_local_pos(index)
    cards[0].move(target, 0.0)
    return true
```

**调试方法：** 在 `DraggableObject._handle_mouse_pressed()`、`_handle_mouse_released()`、`Card._handle_mouse_released()`、`CardContainer.release_holding_cards()`、`CardManager._on_drag_dropped()`、`HandCardContainer.move_cards()` 沿链路加 `print()` 追踪 position 变化即可定位。

**受影响的文件：** `scripts/ninking/ui/hand_card_container.gd`

**实例：** 2026-06-18 用户报告左键点击卡牌后卡牌有少许偏移。日志确认 position 从 (322, 24) 变到 (328.39, 32.89)，偏移 +6.4×+8.9 像素。

---

## §16 NinjaBarContainer 视口大小 sensor 导致手牌拖放被忍者栏劫持

**现象：** 加载开局配置（5 张忍者牌）后，在手牌区拖拽交换手牌（`NinKingCard`），松手后卡牌没有留在手牌容器内，而是跑到了忍者栏中。

**根因（双重缺陷）：**

1. **DropZone sensor 覆盖整个视口** — `NinjaBarContainer._update_target_positions()` 将 drop zone 的 sensor 设为 `get_viewport_rect().size` + offset `-global_position`，使 sensor 的全局矩形等于整个视口。`check_mouse_is_in_drop_zone()` 对忍者栏**永远返回 `true`**，无论鼠标实际在哪里。

2. **`_card_can_be_added()` 无条件通过** — `NinjaBarContainer._card_can_be_added()` 返回 `true` 不检查卡牌类型，任何卡牌（包括 `NinKingCard`）都能被忍者栏接受。

`CardManager._on_drag_dropped()` 遍历 `card_container_dict`（无序 Dictionary）调用 `check_card_can_be_dropped()`，**第一个返回 `true` 的容器获得卡牌**。因为忍者栏 sensor 视口覆盖 + 类型检查缺失，只要 Dictionary 迭代顺序中 `NinjaBarContainer` 排在 `HandCardContainer` 前面，手牌就会落入忍者栏。

完整链路：
```
HandCardContainer.move_cards() → super.move_cards()
  → release_holding_cards() → _on_drag_dropped()
    → 遍历 card_container_dict:
        NinjaBarContainer.check_card_can_be_dropped()
          → check_mouse_is_in_drop_zone() → true (sensor = 全视口)
          → _card_can_be_added() → true (无类型检查)
        → ⚠️ 忍者栏抢先接受 NinKingCard
```

**修复（两文件三处）：**

1. **`ninja_bar_container.gd:_update_target_positions()`** — sensor 从整个视口缩小为容器自身尺寸：
   ```gdscript
   # Before (BUG)
   var vp_rect := get_viewport_rect()
   drop_zone.set_sensor_size_flexibly(vp_rect.size, -global_position)
   
   # After (FIX)
   drop_zone.set_sensor_size_flexibly(size, Vector2.ZERO)
   ```

2. **`ninja_bar_container.gd:_card_can_be_added()`** — 添加类型守卫，只接受 `NinjaInventoryCard`：
   ```gdscript
   func _card_can_be_added(cards: Array) -> bool:
       for c in cards:
           if not c is NinjaInventoryCard:
               return false
       return true
   ```

3. **`hand_card_container.gd:_card_can_be_added()`** — 同样添加类型守卫，只接受 `NinKingCard`（纵深防御）。

**设计原则：**
- **DropZone sensor 必须严格限制为容器自身大小**。视口大小的 sensor 是反模式——它会在 Dictionary 无序迭代中随机劫持其他容器的拖放事件。
- **每个 `CardContainer` 子类必须在 `_card_can_be_added()` 中做类型守卫**，拒绝不属自己管理的卡牌类型。这是纵深防御，即使 sensor 正确也不应跳过。

**排查方法论：** 当卡牌"落错容器"时，在两处加 `print()` 最快定位：
1. `CardManager._on_drag_dropped()` 中打印 `check_card_can_be_dropped()` 返回 `true` 的是哪个容器
2. 可疑容器的 `check_mouse_is_in_drop_zone()` 打印 sensor 的全局矩形

**受影响的文件：** `scripts/ninking/ui/ninja_bar_container.gd`（主修）、`scripts/ninking/ui/hand_card_container.gd`（防御加固）

**实例：** 2026-06-20 加载 5 忍开局配置后拖拽交换手牌，手牌随机进入忍者栏。sensor 全局矩形 = `Rect2(0, 0, 1920, 1080)`（整个视口），confirm_root 的 drop zone sensor 缩小为 `Rect2(container_pos, container_size)` 后问题消失。

---

## §17 `StyleBoxTexture.patch_margin_*` 不能直接属性赋值

**现象：** 运行时报错 `Invalid assignment of property or key 'patch_margin_left' with value of type 'int' on a base object of type 'StyleBoxTexture'`。

```gdscript
# ❌ 两种方式都失败
var s := StyleBoxTexture.new()
s.patch_margin_left = 8                  # 方式 A: 属性赋值 → Invalid assignment
s.set_patch_margin(SIDE_LEFT, 8)         # 方式 B: 方法调用 → Nonexistent function
```

**根因：** Godot 4.6.2 中 `StyleBoxTexture`（继承 `StyleBox`）的 `patch_margin_*` 属性虽然会在编辑器中显示，但在运行时通过 GDScript 无法直接赋值或通过 `set_patch_margin()` 方法设置。这是一个引擎绑定层面的问题。

**修复：** 使用 `set()` 方法通过属性名字符串赋值：

```gdscript
# ✅ 正确
var s := StyleBoxTexture.new()
s.set("patch_margin_left", 8)
s.set("patch_margin_top", 8)
s.set("patch_margin_right", 8)
s.set("patch_margin_bottom", 8)
```

**注意：** `patch_margin_*` 属性值单位是像素，Kenney UI 纹理边角约 5px，推荐 8px 缓冲。

**实例：** 2026-06-22 Kenney UI 暖纸风改造中，所有 StyleBoxTexture 的 patch_margin 设置均使用 `s.set("patch_margin_*", 8)`。涉及文件：`main_menu.gd`、`barrier_theme.gd`、`shop_ui.gd`、`shop_slot.gd`。

---

## §18 Fake3D shader 忽略 MODULATE — 父级 modulate 无效

**现象：** 对 `NinKingCard` 设 `pc.modulate = Color(0.35, 0.35, 0.35, 0.65)` 后，卡牌渲染仍为全亮度，无任何变暗/灰色效果。同理，任何通过 `modulate` 实现的视觉反馈（悬停变暗、禁用灰色、闪烁提示）在带 fake3d 材质的卡牌上均不生效。

**根因：** `fake3d.gdshader`（及 `fake3d_flash.gdshader`、`fake3d_shadow.gdshader`）的 `fragment()` 直接写 `COLOR = texture(TEXTURE, uv + 0.5)`，覆盖了 Godot 4 内置的 `MODULATE` 运算：

```glsl
void fragment(){
    // ...
    COLOR = texture(TEXTURE, uv + 0.5);    // ← GODOT 的 MODULATE 被覆盖
    COLOR.a *= step(max(abs(uv.x), abs(uv.y)), 0.5);
    // ...
    // 缺少: COLOR *= MODULATE;
}
```

Godot 4 的 `canvas_item` shader 中，`MODULATE` 是一个 built-in `vec4` uniform，包含该 CanvasItem 及其所有祖先的 `modulate` 累积值。shader 写入 `COLOR` 后不再自动乘 `MODULATE`。默认（无自定义 shader）时 Godot 自动处理，任何自定义 shader 只要写 `COLOR = ...` 就必须显式乘 `MODULATE`。

**附加：shader vertex 修改导致尺寸膨胀**

fake3d 的 vertex 阶段 `VERTEX += (UV - 0.5) / TEXTURE_PIXEL_SIZE * t * (1.0 - inset)` 会基于纹理像素尺寸叠加顶点偏移。即使无旋转（x_rot=0, y_rot=0），无旋转时的像素偏移使渲染尺寸约等于纹理像素尺寸的 2 倍，而非 TextureRect 的设定尺寸。这对牌库面板的缩略图卡牌（期望 63×88）影响明显。

**修复（两处，2026-06-23 B26）：**

1. **Shaders** — 三个 fake3d shader 的 `fragment()` 末尾加 `COLOR *= MODULATE;`：
   ```glsl
   void fragment(){
       // ... 原有色彩/闪光/阴影处理 ...
       COLOR *= MODULATE;  // ← 恢复父级 modulate
   }
   ```
   - `fake3d.gdshader:71` — 绿幕清除后加
   - `fake3d_flash.gdshader:199` — **所有闪光效果处理完后才加**（见下方 ⚠️ 坑点）
   - `fake3d_shadow.gdshader:77` — 阴影处理完成后加

2. **`ninking_card.gd:_apply_fake3d_material()`** — 非交互卡牌（`can_be_interacted_with == false`）跳过 fake3d 材质，同时消除尺寸膨胀和 modulate 问题：
   ```gdscript
   func _apply_fake3d_material() -> void:
       if not _fake3d_mat:
           return
       if not can_be_interacted_with:
           return  # deck viewer / debug 卡牌不需要 fake3d
       # ...
   ```

⚠️ **`COLOR *= MODULATE` 的放置顺序陷阱（专坑 flash shader）：**

给带闪光/特效的 shader 加 `COLOR *= MODULATE` 时，**必须放在所有特效处理之后**，而非之前。错误地放在前面会导致：

1. 闪光 `mix(COLOR.rgb, flash_color, flash)` 在已调暗的基色上混合 → 闪光偏暗
2. 闪光滤镜 `distance(COLOR.rgb, filter_color)` 比较已调制颜色而非原始纹理 → 滤镜误匹配

**规律：** `COLOR *= MODULATE` 在 fragment 中应始终放在所有 COLOR 写操作**之后**（最后一个赋值），作为最终输出调制。

**实例：** 2026-06-23 code-review 发现 `fake3d_flash.gdshader` 首次修复时把 `COLOR *= MODULATE` 放在了绿幕清除后、闪光效果前，导致稀有度闪光被调暗。经 review 确认后移至末尾修复。

**受影响范围：** 所有应用了 fake3d 材质的卡牌（手牌 `NinKingCard`、商店卡 `NinjaInventoryCard`、牌库面板 `DeckViewerController`）。`modulate` 在所有场景下恢复正常。

**排查方法论：** 当 `modulate` 对某个节点无效时，检查该节点或其子节点是否应用了自定义 `canvas_item` shader，且 shader 中是否有 `COLOR = texture(...)` 或类似赋值。如有，确认是否在赋值后乘了 `MODULATE`。

**实例：** 2026-06-23 B26，牌库面板 `deck_viewer_controller.gd` 对已出牌设 `pc.modulate = Color(0.35, 0.35, 0.35, 0.65)` 无效 — fake3d shader 覆盖 COLOR 导致 modulate 丢失。同时 deck viewer 卡牌不旋转（x_rot=0, y_rot=0）时 vertex 偏移使卡牌虚大。两修复联合生效。