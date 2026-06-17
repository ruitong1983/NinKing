# 文档同步 · Skill

## 概述

确保代码变更后，受影响的文档同步更新。每次修改非纯代码时执行。

## 触发条件

以下情况**必须**触发此 skill：
- 用户说 "更新文档" / "文档同步" / "同步docs" / "update docs"
- 用户在代码变更后说 "测试看看" / "看看效果"（隐含需要确认文档同步）
- CLAUDE.md 的 task table 中标记了 `update-docs`
- 修改了游戏机制/数值/UI布局/关卡/经济

以下情况**不需**触发：
- 纯修复拼写/代码 bug（不涉及设计变更）
- 纯重构（不改外部行为/接口/数值）

## ⚡ 过滤规则：排除测试相关文档

> `docs/ninking/testing/` 目录下的文件（测试用例/测试脚本/测试计划）**默认不纳入**文档同步检查。
>
> **背景：** 测试数据（`ninja-test-full.csv`）和测试脚本（`gen_test_v2.py` 等）由专门的测试流程（`ninja-test` skill）维护，不需要在每次设计变更时同步。
>
> **例外：** 如果用户明确说"同步测试文档"或"更新测试数据"，则不受此规则限制，仍需按 DOCUMENT_MAP.md 完整检查。

## 工作流程

```
代码变更完成
    │
    ├─ 1. 读 DOCUMENT_MAP.md
    │     查找当前改动代码对应的"影响文档"列
    │
    ├─ 2. ⚡ 过滤测试文档
    │     从影响文档列表中移除 docs/ninking/testing/ 下的文件
    │     （除非用户明确要求同步测试文档）
    │
    ├─ 3. 逐项对比
    │     对每个受影响文档：
    │       Read 文档内容 → 对比代码实际行为/数值 → 判断是否需要更新
    │     标记为: ✅ 无需更新 / 🔴 需要更新 / 🟡 建议更新
    │
    ├─ 4. 输出清单给用户确认
    │     格式：
    │       📋 文档同步清单
    │       [文档路径] — 🔴 需要更新: 变更说明
    │       [文档路径] — ✅ 已是最新
    │     ⚡ 被过滤的 testing/ 文档数量: N 个（如需更新请说"同步测试文档"）
    │
    └─ 5. 用户确认后逐文件更新
          + 加时间戳（格式：YYYY-MM-DD）
          + 更新 DOCUMENT_MAP.md 的"变更记录"（如新增文件映射）
```

## 核心依据

**唯一对照表：** `docs/ninking/DOCUMENT_MAP.md`

> 此表按代码文件组织，列出每份代码对应的所有受影响文档。不依赖记忆，不依赖经验判断。

## 操作示例

```markdown
### 例：修改了 ninja_data.gd (忍者牌数值变更)

1. 查 DOCUMENT_MAP.md §1.2 → 影响文档（共 5 项）:
   - `02-cards/11-ninja-cards.md` 🔴 — 卡牌表需要更新数值
   - `03-economy/14-economy-and-progression.md` 🟡 — 价格未变则无需更新
   - ~~`testing/ninja-test-full.csv` 🔴~~ ⚡ 已过滤（测试文档）
   - ~~`testing/automated-formula-testing.md` 🟡~~ ⚡ 已过滤（测试文档）
   - `ninja_card_viewer.html` 🟡 — pre-commit 自动更新

2. ⚡ 过滤掉 2 个 testing/ 文档（如需同步测试数据请说"同步测试文档"）

3. Read 剩余文档，逐项确认差异

4. 更新 + 加时间戳
```

## 通用检查清单

每次执行时逐项确认（排除 `testing/` 文件 — 除非用户明确要求同步测试文档）：

- [ ] 改动的代码在 DOCUMENT_MAP.md 中是否有映射？
- [ ] 卡片数据/效果变更 → `02-cards/11-ninja-cards.md` 同步？
- [ ] 消耗品变更 → `02-cards/12-consumable-cards.md` 同步？
- [ ] 计分公式/算法变更 → `01-gameplay/06-complete-redesign.md` 同步？
- [ ] 关卡/Boss 变更 → `01-gameplay/13-blinds-and-bosses.md` 同步？
- [ ] 经济/价格变更 → `03-economy/14-economy-and-progression.md` 同步？
- [ ] UI 布局/节点变更 → `04-ui/06-ui-layout-reference.md` 同步？
- [ ] UI 信号/UIManager API 变更 → `06-tech/ui-signal-architecture.md` 同步？
- [ ] 状态机/游戏流程变更 → `06-tech/03-technical-design.md` 同步？
- [ ] Debug 场景同步 → 检查 `debug_ninking_main.tscn` 是否需要一致修改？
- [ ] 存档格式变更 → `07-data/game-save-schema.md` 同步？
- [ ] 文档加了时间戳？
- [ ] ⚡ 移除了多少 testing/ 文档？输出时告知用户数量
