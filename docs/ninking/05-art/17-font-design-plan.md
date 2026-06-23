# NinKing 字体设计方案

> **最后更新:** 2026-06-23 | **状态:** LXGW WenKai 已部署
> **关联:** [`16-art-direction-principles.md`](16-art-direction-principles.md) §10 附录 B · [`../09-mgmt/TODO.md`](../09-mgmt/TODO.md) C10
>
> **当前实际使用字体:** LXGW WenKai（霞鹜文楷）

---

## §1 背景

### 1.1 为什么要换

| 当前（旧） | 问题 |
|------|------|
| **Press Start 2P** | 像素英文点阵体，与少年漫画风格直接冲突 |
| **凤凰点阵体 12px/16px** | 像素中文点阵体，同上 |
| **站酷妙典体 / 云幽手书** | 过渡方案，已替换 |
| 全局 `manga_theme.tres` | 默认字体 = LXGWWenKai-Medium |

### 1.2 目标

> 使用 **LXGW WenKai（霞鹜文楷）** 作为统一字体族，Medium 字重用于 UI/标题，Regular 字重用于正文/描述。
>
> LXGW WenKai 是基于开源字体「霞鹜文楷」的中文字体，风格介于楷体与黑体之间，兼具书法韵味与屏幕可读性。

---

## §2 字体需求清单

| # | 用途 | 风格要求 | 覆盖字符 | 当前使用 |
|---|------|---------|---------|---------|
| F1 | **UI 默认字体（中等）** | 清晰有力，适合按钮/标题/数字 | CJK + Latin + 数字 | `LXGWWenKai-Medium.ttf` → `manga_theme.tres` 默认字体 |
| F2 | **正文/描述字体（常规）** | 同族常规字重，小字号可读 | CJK + Latin + 数字 | `LXGWWenKai-Regular.ttf`（待场景引用） |
| F3 | **拟声词手写体** | 手書き風，不规则（P2 待定） | CJK + Latin | 未实现，见附录 A 备选 |

### 2.1 字号速查

| 场景 | 字号 | 使用字体 |
|------|------|---------|
| 分数（`ChipsLabel` / `MultLabel`） | 48-64px | F1 Medium |
| 按钮文字 | 18-24px | F1 Medium |
| 标题（`HandTypeLabel`） | 28px | F1 Medium |
| 面板标签 | 16-20px | F1 Medium |
| 卡牌角标（点数+花色） | 18px | F1 Medium |
| 卡牌描述（忍者牌效果） | 12-14px | F2 Regular |
| 信息文字（`AnteLabel`等） | 14-18px | F2 Regular |
| 拟声词弹出 | 32-48px | F3 手写体（待定） |

---

## §3 当前字体

### 3.1 F1 + F2：LXGW WenKai（霞鹜文楷）

> **OFL 开源字体。** Medium + Regular 双字重，CJK 全覆盖。

| 属性 | Medium | Regular |
|------|--------|---------|
| **文件名** | `LXGWWenKai-Medium.ttf` | `LXGWWenKai-Regular.ttf` |
| **字重** | Medium（≈500） | Regular（≈400） |
| **大小** | ~25 MB | ~25 MB |
| **授权** | SIL Open Font License 1.1 | 同左 |
| **来源** | [GitHub: lxgw/LxgwWenKai](https://github.com/lxgw/LxgwWenKai) | 同左 |
| **覆盖** | CJK + Latin + 数字 + 标点 | 同左 |

### 3.2 F3（待定）

见附录 A 备选手写体。当前 F3 未实现，仅保留接口。

---

## §4 获取指南

### 4.1 下载链接

| 字体 | 下载地址 |
|------|---------|
| LXGW WenKai (Latest) | `https://github.com/lxgw/LxgwWenKai/releases` |

从 GitHub Releases 下载 `.ttf` 文件，放入 `assets/fonts/`。导入后将自动生成 `.import` 文件。

### 4.2 授权确认清单

| 字体 | 许可证 | 可商用 | 可嵌入 | 需署名 |
|------|--------|--------|--------|--------|
| LXGW WenKai | SIL OFL 1.1 | ✅ | ✅ | ❌（建议鸣谢） |

---

## §5 文件存放

### 5.1 文件结构（当前实际）

```
assets/fonts/
├── LXGWWenKai-Medium.ttf       # F1 — 默认 UI 字体（manga_theme.tres）
├── LXGWWenKai-Regular.ttf      # F2 — 正文常规（备用）
```

> 所有旧字体（Press Start 2P / 凤凰点阵体 / Source Han Sans / 站酷妙典体 / ZY-yunyoushoushu-TC）已清理，`legacy/` 目录已删除。

---

## §6 Theme 配置（当前实际）

### 6.1 manga_theme.tres

| 属性 | 值 |
|------|-----|
| **资源路径** | `res://assets/themes/manga_theme.tres` |
| **默认字体** | `res://assets/fonts/LXGWWenKai-Medium.ttf` |
| **默认字号** | 16px |
| **按钮 StyleBox** | StyleBoxFlat 三态（normal/hover/pressed），硬边框 |
| **面板 StyleBox** | StyleBoxFlat 深色背景 + 金色边框 |
| **字体色** | 按钮 `(0.95, 0.95, 0.9)` 亮色，hover 白色 |

### 6.2 使用场景

| 场景文件 | 引用方式 |
|---------|---------|
| `ninking_main.tscn` | `theme = manga_theme.tres` |
| `ninking_launcher.tscn` | `theme = manga_theme.tres` |
| `debug_ninking_main.tscn` | `theme = manga_theme.tres` |
| `continue_panel.tscn` | `theme = manga_theme.tres` |
| `shop.tscn` | `theme = manga_theme.tres` |
| `main_menu.gd` | `load("res://assets/themes/manga_theme.tres")` |

---

## §7 历史记录

| 日期 | 变更 |
|------|------|
| 2026-06-10 | 初始方案：思源黑体 SC Heavy + Regular |
| 2026-06-11 | C10 实施：下载 Source Han Sans + 创建 manga_theme.tres |
| 2026-06-16 | 切换到站酷妙典体 `mianfeiziti.com.ttf` 作为临时默认字体 |
| 2026-06-22 | 下载 `6132695.ttf`（云幽手书 ZY-yunyoushoushu-TC），未完成替换 |
| 2026-06-23 | 切换到 **LXGW WenKai** — Medium 为默认 UI 字体，Regular 为正文备用。清理全部旧字体 |
