# 疑难问题解决手册

> **建立日期:** 2026-06-14 | **最后更新:** 2026-06-14
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

## §4 占位

> 后续遇到新问题在此补充。
