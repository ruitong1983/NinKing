---
name: effect-design
description: 任何视觉/动效/Shader/材质效果的设计请求 — 走五步决策树产出方案，确认后实现并入库
---

# 特效设计 · Skill

> **决策框架全书 → `docs/design-decision-framework.md`**
> **Tween 速查 → `docs/tween-library-reference.md`** · **Shader 速查 → `docs/shader-library-reference.md`** · **素材注册表 → `scripts/ninking/asset_registry.gd`**

## 触发条件

以下情况**必须**触发此 skill：
- 卡牌/面板/UI 元素的入场、出场、消散动画
- 选中高亮、悬停反馈、稀有度闪光等强调效果
- 受击抖动、闪白、色差、故障等操作反馈
- 灰度、暗角、纸张纹理、色调叠加等氛围滤镜
- Boss 战过渡、关卡切换、故障爆发等全屏转场
- 计分滚动、进度条填充、喜爆发等数据展示动效
- 任何涉及 `ShaderMaterial` / `create_tween()` / 视觉纹理素材的设计需求

以下情况**不需**触发：
- 只有文字/标签内容变更，不涉及动效或视觉样式
- 纯代码重构（不改变视觉效果）

## 执行流程

```
用户提出效果需求
    │
    ├─ ① 效果定性
    │   ├─ 这是什么类型？(出现/消失 / 强调/高亮 / 受击/反馈 / 氛围/滤镜 / 过渡/转场 / 信息展示 / 持续循环)
    │   ├─ 是一次性还是持续？是元素内部还是全屏？需要操作触发吗？
    │   └─ 参阅: docs/design-decision-framework.md §2
    │
    ├─ ② 查三库 — 盘家底
    │   ├─ Tween → docs/tween-library-reference.md §场景速查
    │   ├─ Shader → docs/shader-library-reference.md §场景速查
    │   └─ 素材 → scripts/ninking/asset_registry.gd + 21-ui-interaction-enhancements.md
    │        按效果类型优先查对应方向（详见 §3 针对性查库路线）
    │
    ├─ ③ 评估缺口
    │   ├─ ✅ 已有 API 直接覆盖 → 直接调用，零新增
    │   ├─ 🟡 接近但缺一块 → 扩展已有子系统（加 uniform/方法重载）
    │   ├─ 🟡 组合实现 → 组合 2-3 个现有 API，写一个组合函数存入最相关子系统
    │   └─ 🔴 全新需求 → 新建 .gdshader + *_fx.gd 子系统 → 第⑤步
    │
    ├─ ④ 方案选择 — 多路径时选最优
    │   ├─ 纯 Tween > Tween+Shader > 新建子系统（轻量优先）
    │   ├─ 能扩展就不新建、能不动纹理就不动
    │   ├─ 检查同一节点是否已挂其他 ShaderMaterial（后挂覆盖先挂）
    │   ├─ 检查方案是否符合 Kenney 暖纸风/治愈漫画画风
    │   └─ 检查按钮动效是否统一走 ButtonStyles
    │
    └─ ⑤ 输出方案 + 入库落地
        ├─ 按 Spec-First 输出方案（涉及文件/改动概要/理由/影响面）
        ├─ 若需要新素材 → 确认素材路径并记入 asset_registry.gd
        └─ 实现后更新对应速查文档（tween/shader-library-reference.md §场景速查）
```

## 输出格式

```markdown
### 特效方案：[效果名称]

**效果定性：** [类型] — [一次性/持续]

**方案：**
- Shader: `GlobalShaders.xxx(node, params)` / 新建 `XxxFX`
- Tween: `GlobalTweens.xxx()` / 新建方法
- 素材: [无 / 路径说明]

**代码示意：**
```gdscript
# 调用示例
```

**入库项：**
- [ ] `docs/tween-library-reference.md` §场景速查 追加
- [ ] `docs/shader-library-reference.md` §组件表 + §场景速查 追加
- [ ] `shaders/sources/SOURCES.md` 状态更新
```

## 参考导航

| 需要什么 | 看哪里 |
|---------|--------|
| 五步决策树详细版 + 效果分类 + 映射表 + 案例 | `docs/design-decision-framework.md` |
| 当前全部 Tween API 场景速查 | `docs/tween-library-reference.md` §场景速查 |
| 当前全部 Shader API 场景速查 | `docs/shader-library-reference.md` §场景速查 |
| 按钮样式/入口动效 API | `scripts/ninking/ui/button_styles.gd` |
| 面板/光标/StyleBox 素材规范 | `docs/ninking/05-art/21-ui-interaction-enhancements.md` |
| 闪光/帧框/图标路径 | `scripts/ninking/asset_registry.gd` |
| Kenney 暖纸风改造范围 | `docs/ninking/09-mgmt/specs/kenney-beige-ui-transformation.md` |
| Tween 补间安全清单 | `docs/tween-library-reference.md` §5 |

## 一致性底线

无论方案多简单，每次输出前过这三问：

1. ✋ **所有按钮走 `ButtonStyles` 了吗？**（严禁手写 `add_theme_stylebox_override`）
2. 🔲 **面板纹理 9 宫格 8px + NEAREST 过滤了吗？**
3. 🗑️ **用完 `remove_all_shaders` / `cleanup` 了吗？**（防止材质泄漏）
