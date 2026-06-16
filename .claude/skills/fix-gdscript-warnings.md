# fix-gdscript-warnings

消除 GDScript reload 时产生的未使用变量/参数告警。

## 触发

用户说 "消除告警" / "fix warnings" / 或直接粘贴 Godot 编辑器输出的 `UNUSED_VARIABLE` / `UNUSED_PARAMETER` 警告。

## 告警模式

```
W 0:00:03:196   GDScript::reload: The local variable "X" is declared but never used in the block.
                 If this is intended, prefix it with an underscore: "_X".
  <GDScript 错误> UNUSED_VARIABLE
  <GDScript 源文件>file.gd:行号 @ GDScript::reload()

W 0:00:03:481   GDScript::reload: The parameter "X" is never used in the function "f()".
                 If this is intended, prefix it with an underscore: "_X".
  <GDScript 错误> UNUSED_PARAMETER
  <GDScript 源文件>file.gd:行号 @ GDScript::reload()
```

## 修复策略

1. **读文件** → 定位到警告行号
2. **判断**：
   - 变量随后被用到但 linter 误判 → 不改
   - 变量是遗留的分数计算/中间值，可能以后有用 → 加 `_` 前缀
   - 变量明显是死代码（如 `var gf = gain` 紧接着直接用 `gain`）→ 删掉整行
3. **批量修复**：同一区块内的同类未用变量一次性全修，避免逐个报警
4. **不修**：逻辑仍在使用中、只是写法绕过了变量的情况（先确认确实不用）

## 常见文件

| 文件 | 典型问题 |
|------|---------|
| `hand_type_labeler.gd` | 分墩 chips/mult/card_chips 计算后未赋值给 label |
| `animation_handler.gd` | 中间变量声明后直接用了原始值 |
| `shop_slot.gd` | `apply_barrier_theme(_colors)` 兼容包装器 |
