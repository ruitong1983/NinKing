# 疑难问题解决手册

> **建立日期:** 2026-06-14 | **最后更新:** 2026-06-15
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
