# NinKing 图像素材匹配指南 v3

> **建立日期:** 2026-06-10 | **状态:** v3 实地资产校准（Game Icons 2 已下架→Board Game Icons 替代，文件名映射实测修正）
> **关联:** ~~[`05-image-asset-generation-plan.md`](05-image-asset-generation-plan.md)~~（已删除，旧少年漫画风提示词不再需要）· [`16-art-direction-principles.md`](16-art-direction-principles.md) · [`18-audio-asset-matching-guide.md`](18-audio-asset-matching-guide.md)
>
> **用途:** 指导图像素材的"现成素材包匹配 + AI 兜底生成"两层混合策略。避免重蹈 V23 音频匹配的覆辙。
> **⚠️ 先执行 Phase 0（样板验证），再进入全面匹配/生成。六条核心教训见 `18-audio-asset-matching-guide.md` §11。**

---

## §0 Grill: 当前方案的五个盲区

> 来源：对照 `18-audio-asset-matching-guide.md` §11 六条教训，逐条照镜子。

### 盲区 1：全 AI 生成 = 全自己录音

| 音频做法 | 图片当前做法 (`05-image`) |
|---------|--------------------------|
| 买素材包 (1,433 WAV) → 匹配 20 需求 | 47 张图全部豆包 AI 逐张生成 |

音频的黄金数据：1,433 个现成 WAV 中，**20/20 需求全部找到匹配**。图片有没有类似机会？**有**——但 `05` 文档完全没有"先找现成素材包"这一步。

### 盲区 2：违反铁律 2（素材包先行）

`05` 文档 47 条 AI 提示词全写好了，但：
- 豆包 Seedream 4.0 对「粗黑描边 + cel-shading + 半调网点」三项同时满足的成功率未知
- 47 条 prompt 跨批次风格一致性未验证
- 没跑 Phase 0 统计 → 直接进入执行

### 盲区 3：没区分"可匹配"vs"必须生成"

| 层级 | 特征 | `05` 当前 | 合理策略 |
|------|------|----------|---------|
| 🟢 可匹配 | 通用游戏元素 | ❌ 全部走 AI 生成 | 先找现成素材包 |
| 🔴 必须生成 | 独一无二的设计 | ✅ 正确 | AI 生成，但需 Phase 0 验证 |

花色符号（♠♥♦♣）有几百个现成 poker pack 可选——全走 AI 生成是浪费。

> **v2 决策:** 原 v1 的 Layer 2（"半匹配+后处理"）经审阅已删除。搜索成本 + 逐张手工后处理 > AI 生成成本。详细理由见 §12 附录 A。

### 盲区 4：风格一致性没有量化标准

音频有硬指标：**duration**（ffprobe 客观可测）。图片缺对应的量化验证：
- 描边粗细：2-3px → 怎么测？（ImageMagick edge detection）
- 色调范围：高饱和 → 数值？（HSV S > 0.6）
- 调色板：≤32 色 → 怎么测？（pngquant --colors 32）

### 盲区 5：没有匈牙利算法思维

音频 L3：「贪心算法在候选重叠时退化」。图像同理——47 张独立生成 = 47 种微妙差异。应该有全局一致性方案（统一的 color palette + line weight + shading model），像匈牙利算法确保一文件一需求一样确保全局风格统一。

---

## §1 图像匹配 vs 音频匹配：根本差异

> **为什么不能直接把 `18-audio-asset-matching-guide.md` 的模式照搬到图像？**

| 维度 | 音频 SFX | 图像素材 |
|------|---------|---------|
| **源上下文无关性** | ✅ 高 — sci-fi whoosh = fantasy whoosh | ❌ 低 — Western poker card ≠ manga ninja card |
| **风格可迁移性** | ✅ 高 — 任何包的 click 音都可以用作 UI click | ❌ 低 — 像素风图标放进漫画 UI 直接违和 |
| **候选池大小** | 大 — 一个包 1,433 文件覆盖全需求 | 小 — 没一个包同时有忍者 + 扑克 + 漫画 |
| **客观度量** | duration（ffprobe） | 需额外工具（ImageMagick/color histogram） |
| **核心挑战** | 选哪个文件 | 能不能找到风格匹配的 |

### 1.1 关键结论

> **图像素材不存在 "一个包全覆盖" 的解决方案。** 必须走多源混合策略：现成素材包匹配可通用部分 + AI 生成独特部分 + 后处理统一风格。

---

## §2 市场调研：实际可用的图像素材包

### 2.1 调研方法

搜索了 itch.io / OpenGameArt / Kenney / Game-Icons.net / Adobe Stock / Shutterstock，覆盖：
- 扑克牌/卡牌游戏素材包
- 游戏图标通用包
- 漫画/日式 UI 包
- 漫画特效/粒子纹理包
- 忍者/和风主题包

### 2.2 调研结果总表

| 类别 | 可用包 | 最佳来源 | 授权 | 匹配度 |
|------|--------|---------|------|--------|
| **扑克牌面** (52 张) | ✅ 丰富 | Chequered Ink / OpenGameArt / SVG 仓库 | CC0 / Free Commercial | ⭐⭐⭐⭐⭐ |
| **游戏图标** (🗡️🪙⭐🔥🛡️👑) | ✅ 丰富 | Kenney Game Icons (105+, CC0) + **Kenney Board Game Icons (255+, CC0)** → 双包互补 | CC0 | ⭐⭐⭐⭐⭐ |
| **花色符号** (♠♥♦♣) | ✅ 极其丰富 | Kenney Board Game Icons 内含 `suit_spades/clubs/hearts/diamonds.png` + SVG-cards 提取 | CC0 | ⭐⭐⭐⭐⭐ |
| **漫画集中线纹理** | 🟡 有限 | Shutterstock/Adobe Stock（需购买）+ 少量 itch.io | 需确认 | ⭐⭐⭐ |
| **漫画速度线纹理** | 🟡 有限 | 同上。也可用 Krita 程序化生成 | 需确认 | ⭐⭐⭐ |
| **漫画墨迹飞溅** | 🟡 有限 | 同上 + Krita 笔刷库 | 需确认 | ⭐⭐⭐ |
| **漫画网点纹理** | ✅ 可程序化 | ImageMagick `ordered-dither` → 全可程序化，不需要外部素材 | N/A | ⭐⭐⭐⭐⭐ |
| **和风卷轴/面板边框** | 🔴 极其有限 | itch.io 搜索 `japanese scroll UI` 几乎无结果 | — | ⭐ |
| **忍者主题卡牌底板** | 🔴 不存在 | Ninja × Poker 是项目独特组合 | — | ⭐ |
| **Boss 标志符号** | 🔴 不存在 | 独一无二的设计，无现成包 | — | ⭐ |
| **"忍"字 Logo** | 🔴 不存在 | 必须定制 | — | ⭐ |
| **J/Q/K 漫画人物插图** | 🔴 不存在 | 每花色不同角色，完全定制 | — | ⭐ |

### 2.3 推荐素材包详细列表

#### A. 扑克牌完整牌面

| 来源 | 内容 | 格式 | 授权 | 价格 |
|------|------|------|------|------|
| **SVG-Playing-Cards** (GitHub: `htdebeer/SVG-cards`) | 52 张 + 4 花色 + 背面 | SVG | CC0 / LGPL | 免费 |
| **Chequered Ink** `ci.itch.io/card-games-graphics-pack` | 52 牌面 + 8 背 + 筹码 | PNG 800×1080 | Free Commercial | PWYW ($0+) |
| **OpenGameArt** — 搜索 `playing cards` | 多个 CC0 扑克包 | PNG | CC0 | 免费 |

#### B. 游戏图标

> ⚠️ **Kenney Game Icons 2 已下架（2026-06-10 确认 404）。** 原定由 Game Icons 2 覆盖的 coin/sword/fire 等图标改为 Board Game Icons 提供。

| 来源 | 内容 | 格式 | 授权 | 价格 |
|------|------|------|------|------|
| **Kenney Game Icons** (`kenney.nl`) | 105+ 通用 UI 图标（star/scroll/lock/cross 等） | PNG 50×50(1x)/100×100(2x) + SVG | **CC0** | 免费 |
| **Kenney Board Game Icons** (`kenney.nl`) | 255+ 桌游图标（sword/dollar/fire/crown/shield/suit_*/card_* 等） | PNG 64×64/128×128 | **CC0** | 免费 |
| **Game-Icons.net** | 4,100+ 图标，含全部 NinKing 需要的图标类型 | PNG + SVG，可调色 | CC BY 3.0 | 免费（需署名） |

#### C. 漫画网点（程序化生成，不需要外部包）

```
ImageMagick: convert input.png -ordered-dither h4x4a output.png
```

**结论：** 网点纹理不需要买任何素材包。ImageMagick 一键生成。

#### D. 漫画速度线/集中线（未找到完美包，但可程序化）

实测搜索 `itch.io manga speed lines burst sprite sheet` → 无结果。

缓解方案：
- **Krita 笔刷：** Krita 内置 speed line / focus line 笔刷 → 导出 PNG
- **兜底：** 豆包 AI 生成 3 张粒子纹理（128×128，低风险）

---

## §3 需求分层：两层分类

> 基于 §2 的市场调研结论 + review-plan 审阅 Q1 决策（删除 Layer 2"半匹配+后处理"），将旧 `05-image-asset-generation-plan.md`（已删除）的 47 个 AI 生成项重新分类为两层。

### 3.1 两层分类结果

#### 🟢 Layer 1 — 可从现成素材包匹配（~19 项）

| # | 素材 | `05` 规格 | 可匹配来源 | 节省 AI 额度 |
|---|------|----------|-----------|-------------|
| 1-4 | 4 花色符号 | 56×56 PNG | Kenney / SVG-cards / Chequered Ink 扑克包中提取 | 4 张 |
| 15-24 | 10 忍者图标 | 24×24 PNG | Kenney Game Icons (228 icons, CC0) → 选最接近的 + resize 24×24 + 加粗描边 | 10 张 |
| 45-49 | 5 消耗品图标 | 24×24 PNG | 同上 Kenney pack（备选: Game-Icons.net） | 5 张 |
| **合计** | | | | **~19 张（占原 AI 额度的 40%）** |

> ⚠️ **Kenney 图标风格适配有硬性 Phase 0 闸门。** 3 张样板（coin/sword/star）先测 → 通过才批量匹配。不通过 → 全部走 Layer 3。详见 §12 附录 B。

#### 🔴 Layer 3 — 必须 AI 生成（~28 项）

| # | 素材 | 原因 | 风险等级 |
|---|------|------|---------|
| 5 | 游戏图标 `icon.png` | 豆包「黑桃A+忍刀交叉+集中线」— 独一无二 | 低（单张可反复迭代） |
| 6 | 主菜单背景 `launch_bg.png` | 和风插画→漫画化后处理成本 > AI 生成 | 中 |
| 7 | 牌桌背景 `table_bg.png` | 同上 | 中 |
| 8 | "忍"字 Logo | 纯定制 | 低 |
| 9 | 面板角装饰 9-patch | 和风+漫画コマ边框 → 现成包无匹配 | 中 |
| 10 | 顶栏背景 | 漫画粗描边 UI 横条 | 低 |
| 11-14 | 4 忍者牌底板（按稀有度） | Ninja × Manga × Rarity 色 → 不存在现成包 | 中（批次化模板保证一致） |
| 25 | 卡牌背面 `card_back.png` | 漫画网点+粗黑描边+"忍"字 | 中 |
| 26-28 | 3 漫画粒子纹理 | 集中线 + 墨迹 + 速度线 | 低 |
| 30-40 | Boss 卷轴 + 10 符号 | 完全定制 | 中 |
| 42-44 | 3 消耗品底板 | 符術/星图/禁術类别底板 | 低 |
| **合计** | | | **~28 张 AI** |

### 3.2 对比：当前方案 vs 两层混合方案

| | 当前 `05` 方案 | 两层混合方案 |
|------|-------------|---------|
| AI 生成张数 | **~47 张** | **~28 张**（-40%） |
| 现成素材包 | 0 个 | **2-3 个**（全部 CC0/免费商用） |
| 风格一致性 | AI 跨批次不确定 | Layer 1 包内部一致 + Layer 3 批次化模板 |
| Phase 0 可行性 | 未跑 | 先匹配 3 图标 + 生成 3 样板 → 确认效果 → 批量执行 |
| 总工时 | ~6-7h（纯 AI 生成+后处理） | ~3-4h（匹配 1h + AI 生成 2h + 统一后处理 1h） |

---

## §4 图像匹配执行协议

### 4.1 用户触发

用户说：**"帮我匹配图像素材"** 或 **"执行 19-image 的 Phase 0-3"**

### 4.2 Claude 自动执行步骤

```
Phase 0: 可行性预检（强制，不可跳过）
    a. 下载候选素材包（§2.3 列表）
    b. 提取/列出现有图像文件清单 + 规格
    c. Kenney 图标 Phase 0 闸门（§12 附录 B）:
       取 coin/sword/star 3 张 → resize 24×24 → dilate → pngquant
       → 人眼判过（3/3） → 全部 15 图标走 Layer 1
       → 不通过（0-2/3） → 全部 15 图标降级到 Layer 3
    d. 豆包 AI 生成 3 张样板 (§12 附录 C):
       suit_spade / icon_star / boss_broken_tail
       → 跑 §6.4 的 6 项客观检查
       → 3 张全过 → Go
       → 有不过 → 分析根因 → 修 prompt / 换工具
    e. 输出可行性报告，用户确认后继续

Phase 1: Layer 1 匹配（现成素材包 → 项目）
    Step 1: 下载/确认候选包（Kenney / SVG-cards）
    Step 2: 按 §5 匹配规则逐项找最佳候选
    Step 3: 规格适配（resize/dilate/extract）
    Step 4: 风格统一后处理（§6）
    Step 5: mkdir -p 目标目录 + 复制到项目

Phase 2: Layer 3 AI 兜底生成
    批次化模板生成（§9 Phase 2 模板），每张过 §6.4 检查

Phase 3: 全局风格统一 + 验证
    Step 1: 描边粗细统一（ImageMagick edge detection 验证）
    Step 2: 调色板统一（pngquant --colors 32 验证）
    Step 3: 全部文件存在性 + 规格验证
    Step 4: Godot 编辑器 reload_project
```

---

## §5 Layer 1 匹配规则表

### 5.1 花色符号匹配（4 项）

| id | target | 文件名 | 搜索来源 | 匹配标准 |
|----|--------|--------|---------|---------|
| I1 | 黑桃 ♠ | `suit_spade.png` | SVG-cards / Chequered Ink / Kenney Board Game Icons | 黑桃形状识别度 > 描边粗细 > 尺寸 |
| I2 | 红心 ♥ | `suit_heart.png` | 同上 | 心形识别度 > 颜色 (红) > 描边粗细 |
| I3 | 梅花 ♣ | `suit_club.png` | 同上 | 三叶草形状 > 描边粗细 > 尺寸 |
| I4 | 方块 ♦ | `suit_diamond.png` | 同上 | 菱形识别度 > 颜色 (红) > 描边粗细 |

**后处理流程：**
```
1. 从素材包提取 56×56 或 resize 至 56×56
2. ImageMagick 加粗描边:
   convert input.png \( +clone -alpha extract -morphology Dilate Disk:1.5 \) \
           -alpha off -compose CopyOpacity -composite output.png
3. 调色板统一: pngquant --colors 8 --speed 1 output.png
```

### 5.2 游戏图标匹配（10 忍者图标 + 5 消耗品图标）

> ⚠️ **必须通过 Phase 0 Kenney 闸门（§12 附录 B）才能批量匹配。不通过 → 全部降级到 Layer 3 AI 生成。**
>
> **双包组合：** GI = Game Icons (`E:\tmp\kenney_game_icons\PNG\Black\1x\`, 50×50) · BGI = Board Game Icons (`E:\tmp\kenney_board-game-icons\PNG\Default (64px)\`, 64×64)

| id | `05` 图标 | 文件名 | Kenney 实际文件 | Game-Icons.net 备用 | 备注 |
|----|----------|--------|-----------------|---------------------|------|
| I5 | 金币 $ | `icon_coin.png` | BGI `dollar.png` | `coins`, `cash` | — |
| I6 | 忍刀 | `icon_sword.png` | BGI `sword.png` | `katana`, `blade` | — |
| I7 | × 符号 | `icon_mult.png` | GI `cross.png` | `multiply`, `cross` | 纯文字 "×" 兜底 |
| I8 | 星星 | `icon_star.png` | GI `star.png` | `star`, `sparkle` | — |
| I9 | 火焰 | `icon_fire.png` | BGI `fire.png` 或 `campfire.png` | `fire`, `flame` | — |
| I10 | 扑克牌 | `icon_card.png` | BGI `card.png` | `card`, `playing card` | — |
| I11 | 封印符 | `icon_seal.png` | BGI `lock_closed.png` | `rune`, `magic seal` | — |
| I12 | 王冠 | `icon_crown.png` | BGI `crown_a.png` | `crown`, `royal` | — |
| I13 | 红心 | `icon_heart.png` | BGI `suit_hearts.png` | `heart`, `health` | — |
| I14 | 盾牌 | `icon_shield.png` | BGI `shield.png` | `shield`, `defense` | — |
| I15 | 卷轴 | `icon_scroll.png` | GI `scrollHorizontal.png` | `scroll`, `parchment` | — |
| I16 | 星座 | `icon_constellation.png` | — | `constellation`, `stars` | 🔴 无匹配→Layer 3 |
| I17 | 仪式 | `icon_ritual.png` | — | `ritual`, `magic circle` | 🔴 无匹配→Layer 3 |
| I18 | 升级 | `icon_upgrade.png` | BGI `award.png` 或 GI `arrowUp.png` | `upgrade`, `level up` | — |
| I19 | 变换 | `icon_transform.png` | BGI `cards_shuffle.png` | `swap`, `transform` | — |

> **GI = Kenney Game Icons** (`E:\tmp\kenney_game_icons\PNG\Black\1x\`) · **BGI = Kenney Board Game Icons** (`E:\tmp\kenney_board-game-icons\PNG\Default (64px)\`)

**后处理流程：**
```
1. 从 Kenney pack 选 64×64 PNG
2. ImageMagick resize: convert input.png -resize 24x24 -filter Lanczos output.png
3. 加粗描边（同 §5.1 流程）
4. 调色 — 漫画风只需要黑白 + accent 色（与 BarrierTheme 匹配）
5. pngquant --colors 16 output.png
```

### 5.3 扑克牌面（已有 SVG，不需匹配）

> **已确认：** 项目已使用 `poker/` 的 52 张 SVG 卡牌面（按花色分目录，数字命名）。牌面程序绘制保持不变（`16-art-direction-principles.md` §7.1）。<br>（2026-06-24: 素材从 `4color_deck_by_heratexx/` 切至 `poker/`）
>
> 花色符号替换只需改 `ninking_card.gd` 的 suit 渲染从 SVG 引用改为 PNG 纹理，牌面其余部分不动。

---

## §6 后处理统一规范

### 6.1 描边统一

> **目标：** 所有图像素材的描边视觉重量一致（2-3px 仿手绘 G-pen 感）

```bash
# ImageMagick: 检测当前描边粗细
magick input.png -edge 1 -negate -threshold 50% -format "%[fx:mean*100]" info:

# 如果描边太细 → 加粗（膨胀 alpha 通道模拟描边加粗）
magick input.png \( +clone -alpha extract -morphology Dilate Disk:1.5 \) \
        -alpha off -compose CopyOpacity -composite output.png

# 如果描边太粗 → 用 GIMP 手动精修（AI 无法自动化）
```

### 6.2 调色板统一

```bash
# 限制调色板到 32 色（漫画风 cel-shading 不需要渐变）
pngquant --colors 32 --speed 1 --quality 100 input.png -o output.png

# 验证调色板大小
magick identify -verbose output.png | grep "Colors:"
# 期望: Colors: <= 32
```

### 6.3 网点叠加

```bash
# ImageMagick 网点效果（不需要 GIMP）
magick input.png -ordered-dither h4x4a output.png

# 参数说明:
#   h4x4a = 4×4 halftone dot pattern, anti-aliased
#   适合 56×56 至 200×200 的小尺寸素材
#   大尺寸 (800×500+) 用 h8x8a 避免网点过密
```

> **不再推荐 GIMP CLI 批处理**（Windows bash 下 Script-Fu 嵌套引号极易失败）。如需更精细的网点控制（密度/角度），用 GIMP GUI 手动操作。

### 6.4 风格统一检查清单

| # | 检查项 | 工具 | 标准 |
|---|--------|------|------|
| 1 | 所有 PNG 描边一致 | ImageMagick edge detection | mean edge width 偏差 < 1px |
| 2 | 调色板 ≤ 32 色 | `pngquant --quality 100` + 人工抽检 | 无伪影 |
| 3 | 透明底无误 | `magick identify -verbose output.png \| grep Alpha` | Alpha channel present |
| 4 | 尺寸严格匹配规格 | `magick identify -format "%wx%h" output.png` | 与 §3.1 规格一致 |
| 5 | 无 JPEG 压缩残留 | `magick identify -verbose output.png \| grep "Compression"` | 非 JPEG |
| 6 | Godot import 可用 | 拖入 Godot 编辑器 → Filter=false, Mipmaps=false | 线条锐利 |

---

## §7 执行前强制检查表

> **每次开始图像素材工作前，逐条确认。全部 ✅ 才能进入 Phase 0。**

| # | 检查项 | 状态 |
|---|--------|------|
| 1a | Kenney Game Icons 已下载并解压（`kenney.nl` → Game Icons → Download） | ⬜ |
| 1b | Kenney Board Game Icons 已下载并解压（`kenney.nl` → Board Game Icons → Download） | ⬜ |
| 2 | SVG-cards 或 Chequered Ink 扑克包已下载 | ⬜ |
| 3 | ImageMagick 已安装（`magick --version`） | ⬜ |
| 4 | `pngquant` 已安装（`pngquant --version`） | ⬜ |
| 5 | 豆包/即梦 AI 账号可用（备选：Stable Diffusion / ComfyUI），确认当日配额 | ⬜ |
| 6 | Phase 0 样板计划已定（§12 附录 B + 附录 C） | ⬜ |
| 7 | 输出目录清单已确认（按旧 `05-image-asset-generation-plan.md` §7.4 的文件结构，文档已删除） | ⬜ |
| 8 | 人工眼确认流程已安排（生成/匹配后必须人眼过，不过不标完成） | ⬜ |
| 9 | 目标代码文件已验证存在 — `ninking_card.gd` / `shop_ability_card.gd` / `card_back_generator.gd` — 匹配后需更新 preload 路径 | ⬜ |

---

## §8 标准执行流程（5 阶段）

```
Phase 0: 可行性预检 (30min)
  ├─ 下载 Kenney Game Icons + Kenney Board Game Icons + SVG-cards → 本地
  ├─ Kenney 图标闸门（§12 附录 B）:
  │   取 BGI dollar/sword + GI star → resize 24×24 → dilate → pngquant
  │   → 3/3 通过 → 15 图标走 Layer 1
  │   → 0-2/3 通过 → 15 图标降级到 Layer 3
  ├─ 豆包 AI 生成 3 张样板 (§12 附录 C):
  │   suit_spade / icon_star / boss_broken_tail
  │   → 跑 §6.4 的 6 项客观检查
  │   → 3 张全过 → Go
  │   → 有不过 → 分析根因 → 修 prompt / 换工具
  └─ 输出: 可行性报告（匹配覆盖/生成质量/风险）→ 用户确认

Phase 1: Layer 1 现成包匹配 (1h)
  ├─ 花色符号 4 张: SVG-cards 提取 → resize 56×56 → dilate → pngquant
  ├─ 游戏图标 15 张（如果 Kenney 闸门通过）:
  │   Kenney 选最优 → resize 24×24 → dilate → 统一调色
  ├─ mkdir -p assets/images/cards/suits/ assets/images/ninjas/icons/ assets/images/items/icons/
  ├─ 跑 §6.4 全部 6 项检查
  └─ 复制到项目对应目录

Phase 2: Layer 3 AI 兜底生成 (2h)
  ├─ 4 忍者底板: 同一 prompt 模板 + 仅替换稀有度颜色关键词 → 批次内风格一致
  │   模板: §12 附录 D
  ├─ 11 Boss 素材: 卷轴底板 1 张 + 符号 10 张（同模板批次化）
  ├─ 3 漫画粒子纹理: 集中线 + 墨迹 + 速度线
  ├─ 游戏图标 icon.png + Logo logo_deco.png
  ├─ 背景 2 张 + 顶栏 + 9-patch + 卡背 + 消耗品底板 3 张
  └─ 每张过 §6.4 检查

Phase 3: 全局风格统一 (30min)
  ├─ mogrify 批量描边检查（ImageMagick edge detection）
  ├─ pngquant 批量调色板统一
  ├─ 网点叠加（仅底板/背景/面板类素材）
  └─ Godot 编辑器 reload_project → 确认纹理可识别

Phase 4: 验证 (15min)
  ├─ 全部目标文件存在性检查（对照 §3.1 两层清单）
  ├─ 规格检查（尺寸/格式/透明度）
  ├─ Godot 运行时截图 → 人眼确认整体风格一致
  └─ 输出最终报告: ✅ N / ⚠️ M / ❌ K 项
```

---

## §9 图像匹配打分算法

> 适用于 Layer 1（现成包匹配），类似 `18-audio` §3.4 的打分体系。

### 9.1 打分维度

| 维度 | 权重 | 说明 |
|------|------|------|
| **语义匹配** | +5 | 图标语义完全一致（如 sword→sword） |
| **形状相似度** | +3 | 语义接近（如 katana→sword, rune→seal） |
| **描边粗细** | +2 | 候选图已有粗描边（2-3px），不需要后处理加粗 |
| **色彩** | +1 | 候选图已是单色/高对比（漫画风友好） |
| **授权** | -100 | 授权不明确或不支持商用 → 直接淘汰 |
| **后处理复杂度** | -2 | 需要 >2 步处理的扣分 |

### 9.2 选优逻辑

```
score >= 8  → 🟢 高匹配 → 直接选用
score 5-7  → 🟡 中匹配 → 选用，记录处理时间
score 3-4  → 🟠 低匹配 → 考虑走 Layer 3 AI 生成
score <= 2  → 🔴 不可匹配 → 直接走 Layer 3
0 candidate → ❌ 无候选 → Layer 3
```

### 9.3 输出格式

匹配完成后按以下格式逐项输出：

```markdown
| id | 素材 | 候选来源 | score | 后处理 | 决策 |
|----|------|---------|-------|--------|------|
| I1 | suit_spade | SVG-cards/As.svg | 8 | resize+dilate | 🟢 匹配 |
| I5 | icon_coin | Kenney/coin.png | 9 | resize 24×24 | 🟢 匹配 |
| I17 | icon_ritual | — | 0 | — | 🔴 → AI |
```

---

## §10 后续任务衔接

匹配完成后自动衔接：

| 步骤 | 文件 | 内容 |
|------|------|------|
| L1 | `ninking_card.gd` | suit 渲染从 SVG Unicode → PNG 纹理引用 |
| L2 | `ninking_card.gd`（或匹配执行中新建 `ninja_card_renderer.gd`） | 图标 preload 路径更新为匹配后的实际文件 |
| L3 | `shop_ability_card.gd` | 消耗品图标路径更新 |
| L4 | ~~`05-image-asset-generation-plan.md`~~ | 已删除。更新实施状态：AI 额度从 47→28（旧文档不再维护） |
| L5 | `TODO.md` | V26/V27/V36 状态更新 |

---

## §11 附录

### 附录 A: 为什么砍掉 Layer 2（"半匹配+后处理"）

v1 提出三层分类中的 Layer 2（背景/卡背/底板 8 张 → 找免费素材 + GIMP 漫画滤镜），review-plan 审阅发现：

| # | 问题 | 影响 |
|---|------|------|
| 1 | **搜索成本高** — Unsplash/Pexels 上"和风照片"99% 是摄影作品，经 Posterize+Edge Detect 后变成"糟糕的滤镜效果"，不是漫画插画 | 可能要搜几十张才找到一张可用的 |
| 2 | **后处理不通用** — 每张需要不同的 GIMP 处理链（背景→Posterize+网点、卡背→替换中心图案、底板→调色+网点），无法批量操作 | 8 张 × 手工 = 至少 1h |
| 3 | **质量天花板低** — 照片→漫画化处理的最终效果，不如 AI 从零生成一张漫画 | 投入时间多，产出质量差 |
| 4 | **无法量化** — "后处理难度（低/中/高）"没有客观标准，Claude 无法自主判断 | 每张都要人工决策 |

**Q1 决策（2026-06-10）：** Layer 2 删除，8 项全部并入 Layer 3（AI 生成）。AI 额度从 26→28 张（+8%），但省掉了整个 Layer 2 的搜索+手工流程（-1h）。总工时反而下降。

### 附录 B: Kenney 图标 Phase 0 闸门（硬性标准）

> **Q2 决策（2026-06-10）：** Kenney 方案保留，但设硬性 Phase 0 通过标准。不通过就全部走 AI。
>
> **v3 更新（2026-06-10）：** Game Icons 2 已下架（404），样板改用双包组合：`dollar`+`sword` 来自 Board Game Icons，`star` 来自 Game Icons。

```
Phase 0 图标测试（3 张：dollar / sword / star）:
  1a. BGI dollar.png (64×64) + BGI sword.png (64×64) + GI star.png (50×50)
  1b. 预 resize: star.png 可能需先缩放到 24×24 基线
  2. ImageMagick: resize 24×24 → morphology Dilate Disk:1 → pngquant 16
  3. 人眼判断（与 AI 生成的 suit_spade 并排对比）:

通过条件（3/3 满足）:
  ✅ 形状可识别 — 24×24 下一眼能看出是金币/剑/星星
  ✅ 无糊化 — dilate 后细节未粘连（如星星五个角仍可分辨）
  ✅ 风格不冲突 — 与 AI 生成的 suit_spade 放在一起不违和

结果分支:
  3/3 通过 → 全部 15 个图标走 Kenney (Layer 1)
  2/3 通过 → 失败的 1 张改用 Game-Icons.net 同图标再测一次
  0-1/3 通过 → 全部 15 个图标降级到 Layer 3 AI 生成
```

**备选（Kenney 失败时）：** Game-Icons.net（4,100+ 图标，CC BY 3.0）风格更多样——部分图标本身就是手绘/墨迹风，比 Kenney 统一扁平风更适配漫画：

| 图标 | Game-Icons.net 搜索词 | 可能有手绘感的候选 |
|------|----------------------|-------------------|
| sword | `katana`, `ninja sword` | 日式武器图标通常带笔触 |
| fire | `flame`, `fire` | 火焰图标天然适合粗描边 |
| seal | `rune`, `magic seal` | 符文类图标常见于手绘风 |

### 附录 C: 豆包 AI 样板验证提示词（3 张 Phase 0 测试）

在跑全部 28 张之前，先用这 3 个 prompt 测试豆包的实际风格输出质量：

```
测试 1 — 黑桃花色符号:
"纯黑色扑克牌黑桃(Spade)符号，粗黑描边(3px 仿手绘)，纯白背景，简洁图形，正方形构图。尺寸 512×512。"
通过标准: 描边粗细均匀 ≥ 2px | 形状清晰 | 无网点/渐变/半透明

测试 2 — 星星图标:
"一颗星星图标，金色填充，深黑粗描边(2px)，cel-shading 块面，简洁图形，背景纯白。尺寸 256×256。"
通过标准: 描边 ≥ 2px | cel-shading > 3 层色阶 | 可 resize 到 24×24 不变形

测试 3 — Boss 断尾符号:
"一条断裂的尾巴/脊椎标志符号，黑白单色，粗描边(3px 仿手绘毛笔触感)，墨絵风格，背景纯白。尺寸 512×512。"
通过标准: 单色(无灰阶) | 描边 ≥ 3px | silhouette 识别度
```

**3 张全过 → 进入 Phase 1。失败 → 换 AI 工具或调整关键词。**

### 附录 D: Layer 3 批次化 Prompt 模板

> 保证同类型素材跨批次风格一致。模板 = 固定前缀 + 变量槽。

#### 忍者牌底板（4 张，N/R/SR/UR）

```
固定前缀:
"少年漫画风，日式漫画，小型卡牌底板，粗黑描边（3px 仿手绘 G-pen 感），半调网点底纹（10%），
漫画カード枠风格，四角有小型手里剑装饰，卡面内部明亮凹槽区域（留给文字和图标），
cel-shading 块面，纯平面2D。尺寸 140×196 像素。背景不透明。"

变量槽（仅替换颜色关键词）:
  普通(N): "灰色网点底 + 深灰粗描边"
  稀有(R): "蓝色网点底 + 青色粗描边 + 细银边"
  史诗(SR): "紫色网点底 + 紫色粗描边 + 金边"
  传说(UR): "红色网点底 + 红色粗描边 + 粗金边 + 微弱光晕"

通用负面: "写实, 照片, 3D渲染, 光滑渐变, 像素风, 8-bit, 花哨"
```

#### Boss 标志符号（10 张）

```
固定前缀:
"少年漫画风，日式漫画，Boss 标志符号，墨絵タッチ（水墨笔触感），
单色粗描边（3px 仿手绘太筆），简洁图形化，纯平面2D。
尺寸 200×200 像素。背景完全透明。"

变量槽（仅替换主题描述）:
  断尾: "断裂的尾巴/脊椎，断面有漫画裂缝效果"
  无头: "无头武士剪影，头盔内为空暗影，断裂羽饰"
  独柱: "单根立柱/孤柱"
  ...

通用负面: "写实, 照片, 3D渲染, 光滑渐变, 像素风, 8-bit, 血腥"
```

### 附录 E: ImageMagick 命令速查

```bash
# 批量 resize
mogrify -resize 24x24 -path output_dir/ input_dir/*.png

# 批量加粗描边（膨胀 alpha 通道）
for f in *.png; do
  magick "$f" \( +clone -alpha extract -morphology Dilate Disk:1.5 \) \
          -alpha off -compose CopyOpacity -composite "bold_$f"
done

# 批量调色板限制
pngquant --colors 32 --speed 1 --ext .png *.png

# 批量检测描边粗细
for f in *.png; do
  echo -n "$f: "
  magick "$f" -edge 1 -negate -threshold 50% -format "%[fx:mean*100]" info:
done

# 验证尺寸
magick identify -format "%f: %wx%h\n" *.png
```

### 附录 F: 当前项目图像资产盘点

```
assets/images/
├── cards/
│   ├── 4color_deck_by_heratexx/   ← 旧 52 SVG 牌面（2026-06-24 后不再使用，保留备查）
│   ├── poker/                     ← 52 SVG 牌面（当前使用，按花色分目录/数字命名）
│   ├── card_back.png              ← ✅ Phase 2 AI 漫画风重绘（网点+忍字）
│   ├── card_base_{n,r,sr,ur}.png  ← ✅ Phase 2 AI 4 稀有度底板
│   ├── slot_bg.png                ← 程序绘制槽位背景（保留）
│   └── suits/
│       ├── suit_spade.png         ← ✅ Phase 1 SVG-cards 提取
│       ├── suit_heart.png         ← ✅ Phase 1 SVG-cards 提取
│       ├── suit_club.png          ← ✅ Phase 1 SVG-cards 提取
│       └── suit_diamond.png       ← ✅ Phase 1 SVG-cards 提取
├── ninjas/icons/
│   ├── icon_{star,sword,coin,...}.png ×11  ← ✅ Phase 1+2 图标
├── items/
│   ├── item_base_{fujutsu,seiza,kinjutsu}.png  ← ✅ Phase 2 消耗品底板
│   └── icons/
│       ├── icon_{upgrade,transform,constellation,ritual}.png  ← ✅ Phase 1+2
├── boss/
│   └── boss_{broken_tail,headless,...,chaos}.png ×10  ← ✅ Phase 2 Boss 符号
├── ui/
│   ├── icon.png                   ← ❌ 旧占位未清理（保留）
│   ├── icon_alt.png               ← ✅ Phase 2 游戏图标（备选）
│   ├── logo_deco.png              ← ✅ Phase 2 "忍" Logo
│   ├── top_bar_bg.png             ← ✅ Phase 2 顶栏背景
│   └── panels/
│       └── panel_corner_9patch.png ← ✅ Phase 2 面板角装饰
├── effects/
│   ├── particle_manga_burst.png   ← ✅ Phase 2 集中线粒子
│   ├── particle_manga_ink.png     ← ✅ Phase 2 墨迹粒子
│   └── particle_speed_line.png    ← ✅ Phase 2 速度线
├── background/
│   ├── launch_bg.png              ← ⏸️ 沿用旧占位（未替换）
│   └── table_bg.png               ← ✅ Phase 2 AI 牌桌背景
└── card_placeholders/             ← ⏸️ FanKing 遗留，待清理
```

### 附录 G: 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v1 | 2026-06-10 | 初版。市场调研 + 三层分类 + 混合匹配/生成策略 + 5 阶段流程 + 六条铁律。 |
| v2 | 2026-06-10 | **review-plan 审阅落地。** Q1: Layer 2 删除并入 Layer 3（AI 28 张）；Q2: Kenney 图标加 Phase 0 硬性闸门。A2: GIMP CLI 替换为 ImageMagick 唯一方案。A3: §10 L2 修正 `ninja_card_renderer.gd` 引用。A4: §7 精简。A6: 新增批次化 Prompt 模板（附录 D）。A7: ImageMagick 描边加粗命令修正。 |
| v3 | 2026-06-10 | **实地资产校准。** Game Icons 2 已下架（404）→ Board Game Icons 替代（255+ 图标）。§2.2 游戏图标数量修正 228→105。§5.2 全部 15 行 Kenney 列改为实际文件名（GI/BGI 前缀区分双包来源）。§2.3 新增 Board Game Icons 行。§7 #1 拆为 1a/1b。§12 附录 B Phase 0 闸门适配双包（dollar/sword→BGI, star→GI）。§8 Phase 0 源包名更新。§5.2 脚注新增双包目录速查。 |
| v4 | 2026-06-10 | **Phase 0-3 全线执行完成。** Phase 0 双包闸门通过+豆包样板验证。Phase 1 Layer 1 匹配 16 张部署。Phase 2 Layer 3 AI 31 张生成+部署。Phase 3 后处理：pngquant 批量 45 张 + ordered-dither 13 张 + stroke check。累计交付 47 张到 `assets/images/`。现成包匹配 16 张节省 34% AI 额度。附录 F 资产盘点更新。|
