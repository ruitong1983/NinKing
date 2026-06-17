# NinKing 音效设计计划

> **建立日期:** 2026-06-10 | **最后更新:** 2026-06-17
> **关联:** [`../09-mgmt/TODO.md`](../09-mgmt/TODO.md) · [`sound_bank.gd`](../../scripts/config/sound_bank.gd) · [`18-audio-asset-matching-guide.md`](18-audio-asset-matching-guide.md)
> **用途:** 指导音效素材寻找、替换、新增、代码接线的完整工作计划。
>
> **✅ V23 素材替换状态:** 20/20 音效已从 Epic Stock Media「Anime Game」包自动匹配并转换为 OGG。详见 §10 执行记录。
> **🎮 彩蛋: `cat/`** — 2026-06-17 新增 15 个猫叫音效 (OGG)，随机替换 NINJA_ACTIVATE 作为计分触发放猫叫彩蛋。详见 §11。

---

## §1 风格定义

> **2026-06-10 更新:** 对齐 `16-art-direction-principles.md` §5，风格从「和风 Chiptune 融合」改为「动画 SFX」向。

| 维度 | 决策 |
|------|------|
| **方向** | **动画 SFX** — 日本动画/漫画风格音效库，强调戏剧性冲击与情绪表达 |
| **参考作品** | 日本 TV 动画音效库、动画电影（『鬼灭之刃』『咒术回战』等）、『街头霸王 6』漫画特效音 |
| **核心音色** | whoosh（快速移动）/ impact（重击）/ sparkle（闪光）/ dramatic sting（紧张弦乐短句）/ 太鼓/铃（和风点缀） |
| **分层策略** | **日常操作层** — 短促清脆音（保留 Chiptune 精确反馈感，< 0.3s）；**情绪节点层** — 动画戏剧音效（whoosh/sting/impact，0.3-3s）；**环境层** — 动画 OST 风 BGM 循环 |
| **核心原则** | 高频操作 = 低存在感（不烦人），情绪节点 = 高戏剧张力（动画感），BGM 循环无缝 + 属性变奏 |

---

## §2 素材来源指南

### 搜索关键词速查

```
日语: アニメ効果音, 漫画効果音, バトル, 衝撃, 閃光, 緊迫, 勝利, 敗北
      忍者, 太鼓, 尺八, 鈴, 煙, 術, 和風, 刀
英语: anime sfx, manga sound effect, battle whoosh, impact hit,
      dramatic sting, victory jingle, suspense drum, sparkle chime,
      cartoon pop, comic sfx, shuriken, smoke puff, japanese bell
```

### 分级来源

| 层级 | 来源 | 用途 | 预算 | 链接 |
|------|------|------|------|------|
| 🥇 主力 | **BOOTH** アニメ効果音集 / 和風効果音集 | 和风特色音效（太鼓/铃/烟遁）+ 动画战斗音效（whoosh/impact/sting） | ¥500-1500 | `booth.pm/ja/browse/3D-ゲーム素材-効果音` |
| 🥇 主力 | **itch.io** Anime SFX Pack / Manga Sound Effects | 覆盖 80% 通用操作音（发牌/交换/UI/计分）+ 动画过渡音 | $5-15 | `itch.io/game-assets/tag-sfx+anime+manga` |
| 🥈 补充 | **効果音ラボ** | 免费高品质单品（和楽器/戦闘/自然/アニメ効果音） | 免费（需署名） | `soundeffect-lab.info` |
| 🥈 补充 | **Dova-Syndrome** | 免费 BGM + SFX，存量极大，动画风 OST 丰富 | 免费（需署名） | `dova-s.jp` |
| 🥈 补充 | **Pocket Sound** | UI/打击音效质量高，动画常用短促音多 | 免费（需署名） | `pocket-se.info` |
| 🥉 兜底 | **SONNISS GDC Bundles** | 高质量爆炸/过渡/环境音 | 免费 | `sonniss.com/gameaudiogdc` |
| 🥉 兜底 | **Freesound** | 单品补漏（搜 `taiko` `koto` `shakuhachi`） | 免费（看许可） | `freesound.org` |

### 推荐采购顺序

```
1. BOOTH → 搜 "アニメ効果音" + "和風効果音" → 1-2 个包覆盖动画战斗音 + 和风点缀
2. itch.io → 搜 "Anime SFX Pack" (JDWasabi / Shapeforms) → $5-10 搞定通用操作层
3. 効果音ラボ → 搜单品补缺口（アニメ風の衝撃音/閃光音/緊迫BGM）
4. Dova-Syndrome → 动画风 OST BGM 筛选 + 属性变奏
```

---

## §3 音频资源总览

### 现状 vs 目标

| 类别 | 现状 | 目标 |
|------|------|------|
| BGM | 2 首 FanKing 占位 (WAV) | 4 首忍者主题 OGG（菜单 + 游戏 3 段变奏 + 商店） |
| 游戏 SFX | ✅ **已替换** — 17 个动画 SFX (OGG) 来自 Anime Game Pack | 全替换为动画 SFX（日常操作 chiptune + 情绪节点动画戏剧音） |
| UI SFX | ✅ **已替换** — 3 个动画 SFX (OGG) 来自 Anime Game Pack | 保留 3 个 + 新增 3 个 |
| **彩蛋 SFX** | ✅ **已就绪** — 15 个猫叫音效 (OGG) 来自 Freesound/Dragon Studio 等 | 随机替换 NINJA_ACTIVATE（计分触发放猫叫） |
| **总计 SFX** | **35/35 ✅**（核心 20 + P2 8 + 彩蛋 15，部分 @pending） | **35+**（持续补充） |

### SoundBank 常量重命名（忍者主题）

> C8 — 旧 FanKing 遗留名改为忍者主题名，旧常量保留 alias 到接线完成。

| 旧常量 | 新常量 | 说明 |
|--------|--------|------|
| `DRAW` | `DRAW` | ✅ 保留 |
| `DISCARD` | `DISCARD` | ✅ 保留 |
| `DEAL` | `DEAL` | ✅ 保留 |
| `SELECT` | `SELECT` | ✅ 保留 |
| `SWAP` | `SWAP` | ✅ 保留 |
| `HOVER` | `HOVER` | ✅ 保留 |
| `HU` | `GROUP_REVEAL` | 组揭示（原「和了」→忍者主题） |
| `YAKU_REVEAL` | `XI_TRIGGER` | 喜触发（原「役揭示」→忍者主题） |
| `BAO_ACTIVATE` | `NINJA_ACTIVATE` | 忍者牌激活（原「爆发」→忍者主题） |
| `COUNT_TICK` | `COUNT_TICK` | ✅ 保留 |
| `EXPLOSION` | `EXPLOSION` | ✅ 保留 |
| `LEVEL_CLEAR` | `SEAL_CLEAR` | 封印达成 |
| `LEVEL_FAIL` | `SEAL_FAIL` | 封印失败 |
| `LOTTERY` | `SHOP_REROLL` | 商店刷新 |
| `UI_CLICK` | `UI_CLICK` | ✅ 保留 |
| `UI_COIN` | `UI_COIN` | ✅ 保留 |
| `UI_ERROR` | `UI_ERROR` | ✅ 保留 |

---

## §4 音效详细清单

> **接线位置** 精确到 `脚本 : 函数`。接线代码统一为：
> ```gdscript
> const SB = preload("res://scripts/config/sound_bank.gd")
> GlobalTweens.play_sfx(SB.XXX)
> ```

### P0 — 核心体验（立刻做，10 个）

#### S1. 发牌 — 牌依次滑入

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/game/deal.ogg`（替换） |
| **描述** | 轻 paper swish × N，9 张 stagger 播放。利用 `stagger_spread` 的 tween 逐张 `bind_sfx` |
| **关键词** | `card swish`, `paper slide light`, `whoosh soft` |
| **时长** | ~0.15s |
| **接线** | `game_manager._intro_timer()` → `stagger_spread` 产生 tween → `GlobalTweens.bind_sfx(tween, SB.DEAL, 0.0)` |
| **价值** | 每回合开始的听觉锚点，9 连发 stagger 有"洗牌发牌"满足感 |

#### S2. 组揭示 — 影→瞬→滅 依次揭示

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/game/group_reveal.ogg`（替换 `hu.ogg`） |
| **描述** | 3 段递进打击：影(低 taiko hit)→瞬(中 taiko+koto)→滅(高 taiko+koto+bell)，音高/密度递升 |
| **关键词** | `taiko hit`, `drum impact`, `koto pluck`, `japanese bell` |
| **时长** | 3 段各 ~0.2s，总 ~0.6s |
| **接线** | `game_manager._run_scoring_animation()` → 组揭示阶段对每组分 3 次调用 `GlobalTweens.play_sfx(SB.GROUP_REVEAL, vol_offset)` |
| **价值** | 给玩家"三组依次结算"的听觉节奏感，音高递升暗示 影≤瞬≤滅 |

#### S3. 计分跳动 — 数字递增

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/game/count_tick.ogg`（替换） |
| **描述** | 短促清脆 tap/tick 音，可加速重复播放 |
| **关键词** | `tick`, `tap`, `coin count`, `wood hit light`, `anime tap`, `cartoon tick` |
| **时长** | ~0.05s |
| **接线** | `animation_handler._sfx_tick(pitch)` → `GlobalTweens.play_sfx(SB.COUNT_TICK, 0.0, pitch)`，由 CountUp.play_multi milestone 检测驱动，pitch 递升(0.88→1.22, +0.05/tick) |
| **价值** | 分数跳动的满足感，数字每跳一下有一个听觉反馈 |

#### S4. 喜触发 — 单喜 / 双喜+

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/game/xi_trigger.ogg`（替换 `yaku_reveal.ogg`）+ `assets/audio/sound/game/xi_fanfare.ogg`（新增） |
| **描述** | 单喜 → `xi_trigger`：脆铃 chime ~0.3s。双喜+ → `xi_fanfare`：短 fanfare swell ~0.8s |
| **关键词** | `japanese bell`, `furin`, `chime bright`, `success jingle`, `fanfare short` |
| **时长** | ~0.3s / ~0.8s |
| **接线** | `game_manager._on_xi_triggered(xis)` → `GlobalTweens.play_sfx(SB.XI_FANFARE if xis.size() >= 2 else SB.XI_TRIGGER)` |
| **价值** | 喜是 NinKing 关键差异化机制，触发瞬间必须有听觉奖赏，双喜+用更强的 fanfare 强化多喜叠加的兴奋感 |

#### S5. 过关 — 封印达成

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/game/seal_clear.ogg`（替换 `level_clear.ogg`） |
| **描述** | 和风胜利短乐句：筝上行 → 铃铛连响 → 太鼓收尾，~2-3s |
| **关键词** | `victory jingle japanese`, `taiko celebration`, `koto melody short`, `success fanfare` |
| **时长** | ~2.5s |
| **接线** | `seal_controller._complete_seal()` → `GlobalTweens.play_sfx(SB.SEAL_CLEAR)` |
| **价值** | 核心情绪 payoff，封印达成是每轮最大正反馈节点 |

#### S6. 失败 — 封印失败

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/game/seal_fail.ogg`（替换 `level_fail.ogg`） |
| **描述** | 阴沉尺八低音 → 断弦（琴弦崩断）+ 余韵嗡鸣，~1.5s |
| **关键词** | `shakuhachi low`, `string break`, `fail tension`, `taiko dead` |
| **时长** | ~1.5s |
| **接线** | `seal_controller._complete_seal()` 失败分支 → `GlobalTweens.play_sfx(SB.SEAL_FAIL)` |
| **价值** | 永久死亡下的情绪重击，断弦音 = 听觉化的"你失败了" |

#### S7. 交换 — 拖拽微调

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/game/swap.ogg`（替换） |
| **描述** | 轻卡片滑动声，~0.1s，非干扰性 |
| **关键词** | `card slide`, `paper shuffle soft`, `light tap` |
| **时长** | ~0.12s |
| **接线** | `ui_manager.gd` / `hand_interaction.gd` — 交换完成时 → `GlobalTweens.play_sfx(SB.SWAP)` |
| **价值** | 不限次操作，音效必须极轻极短，否则高频重复烦人 |

#### S8. 换牌 — 烟遁消失 + 瞬身出现

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/game/discard.ogg`（替换，加新文件 `redraw_pop.ogg`） |
| **描述** | 烟遁 → 短 poof / smoke puff ~0.2s。瞬身 → pop appear / whoosh in ~0.15s |
| **关键词** | `smoke puff`, `poof`, `teleport`, `ninja vanish`, `pop appear`, `whoosh in` |
| **时长** | ~0.2s + ~0.15s |
| **接线** | `seal_controller.execute_redraw()` → 弃牌时 `GlobalTweens.play_sfx(SB.DISCARD)` + 新牌 pop_in 时 `GlobalTweens.play_sfx(SB.REDRAW_POP)` |
| **价值** | 最「忍者」的操作，配合已有 V11 VFX（fade_out+dust → pop_in），音效应呼应忍术遁走→瞬身的动画 |

#### S9. 忍者牌激活

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/game/ninja_activate.ogg`（替换 `bao_activate.ogg`） |
| **描述** | 短促金属闪光 + 能量嗡鸣，~0.3s |
| **关键词** | `shuriken spark`, `energy pulse`, `activate`, `power up light`, `metal ting` |
| **时长** | ~0.3s |
| **接线** | `score_calculator.gd` — 忍者牌效果触发时 → `GlobalTweens.play_sfx(SB.NINJA_ACTIVATE)` |
| **价值** | 忍者牌提供被动加成，需要轻微的听觉确认"你的牌在干活" |

#### S10. 出牌按键

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/ui/ui_click.ogg`（替换） |
| **描述** | 清脆按钮按击，漫画风 UI 确认音，~0.08s |
| **关键词** | `click`, `button press`, `tap confirm`, `anime click`, `cartoon select` |
| **时长** | ~0.08s |
| **接线** | `game_manager._on_play_pressed()` → `GlobalTweens.play_sfx(SB.UI_CLICK)`（已有 `main_menu.gd` 用同样常量） |
| **价值** | 操作确认，高频使用，必须极短 |

---

### P1 — 关卡节点（第二批，8 个）

#### S11. Boss 封印揭晓

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/game/boss_reveal.ogg`（新增） |
| **描述** | 太鼓滚奏（tension）→ 短停 → 重击（Boss 名浮现瞬间）→ 余韵嗡鸣，~2s |
| **关键词** | `taiko roll`, `drum tension`, `bass hit deep`, `suspense reveal`, `ominous` |
| **时长** | ~2.0s |
| **接线** | `game_manager._on_seal_started()` — Boss 名 scale_pop 同帧 → `GlobalTweens.play_sfx(SB.BOSS_REVEAL)` |
| **价值** | 每个結界的情绪高点——「哪个 Boss 来了？」悬疑→揭晓弧线 |

#### S12. 終焉 Boss 额外压迫层

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/game/boss_final_layer.ogg`（新增） |
| **描述** | 低沉持续嗡鸣 + 心跳鼓声，疊加在 S11 之上，属性 无 (Ante 8 / 終焉) 专用 |
| **关键词** | `deep drone`, `heartbeat drum`, `final boss tension`, `dark ambient` |
| **时长** | ~3.0s |
| **接线** | `game_manager._on_seal_started()` — `if barrier_num == 8:` → 与 `SB.BOSS_REVEAL` 同时播放 |
| **价值** | 終焉是最终 Boss，额外听觉压迫层标记"这是终点" |

#### S13. 商店进入

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/game/shop_enter.ogg`（新增） |
| **描述** | 门帘拉开 + 铃铛轻响，~0.5s |
| **关键词** | `shop enter`, `door chime`, `bell light`, `curtain open` |
| **时长** | ~0.5s |
| **接线** | `shop_ui._play_entrance()` → `GlobalTweens.play_sfx(SB.SHOP_ENTER)` |
| **价值** | 商店是安全区+奖励区，进入的音效给玩家从"紧张战斗"到"放松购物"的情绪切换 |

#### S14. 购买忍者牌

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/ui/ui_coin.ogg`（替换） |
| **描述** | 清脆金币 + 确认叮咚，~0.3s |
| **关键词** | `coin pay`, `purchase confirm`, `cash register light`, `kaching` |
| **时长** | ~0.3s |
| **接线** | `shop_ui._on_ability_purchase()` → `GlobalTweens.play_sfx(SB.UI_COIN)` |
| **价值** | 购买 = 金币 + 获得能力，区分于普通 UI |

#### S15. 购买消耗品（附魔/星图/秘仪）

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/game/item_purchase.ogg`（新增） |
| **描述** | S14 金币声 + 额外魔法 shimmer 层，~0.4s |
| **关键词** | `magic shimmer`, `enchant sparkle`, `item get`, `star chime` |
| **时长** | ~0.4s |
| **接线** | `shop_ui._on_item_purchase()` → `GlobalTweens.play_sfx(SB.ITEM_PURCHASE)` |
| **价值** | 消耗品与忍者的购买反馈区分，帮助建立"花多少钱买什么类型"的潜意识认知 |

#### S16. 商店刷新

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/game/shop_reroll.ogg`（替换 `lottery.ogg`） |
| **描述** | 牌翻飞声 + 重洗声（card shuffle），~0.5s |
| **关键词** | `card shuffle fast`, `reroll whoosh`, `deck shuffle`, `refresh` |
| **时长** | ~0.5s |
| **接线** | `shop_ui._on_reroll_pressed()` → `GlobalTweens.play_sfx(SB.SHOP_REROLL)` |
| **价值** | 刷新 = 牌组洗牌意象，洗牌声是自然的听觉匹配 |

#### S17. 商店离开

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/game/shop_exit.ogg`（新增） |
| **描述** | 门帘合上 + 短促过渡音，~0.4s |
| **关键词** | `door close`, `transition short`, `curtain close` |
| **时长** | ~0.4s |
| **接线** | `shop_ui._on_continue_pressed()` → `GlobalTweens.play_sfx(SB.SHOP_EXIT)` |
| **价值** | 离开商店进入下一封印的过渡，与 S13 进入形成对称 |

#### S18. 金币变动（产金效果触发）

| 字段 | 内容 |
|------|------|
| **文件** | `assets/audio/sound/ui/ui_coin.ogg`（已有） |
| **描述** | 与 S14 同一音效，金币增加时播放 |
| **关键词** | 同 S14 |
| **时长** | ~0.3s |
| **接线** | `seal_controller._collect_play_gold()` 或 `NinKingGameState.gold_changed` 信号 → delta > 0 时播放 |
| **价值** | 产金效果是经济系统关键反馈，金币声 = 即时的"赚到了" |

---

### P2 — 中级玩家（第三批，8 个）

| # | 名称 | 文件 | 触发 | 关键词 | 接线位置 | 价值 |
|----|------|------|------|--------|---------|------|
| S19 | 附魔使用 | `enchant_cast.ogg` | 买后选目标→应用 | `enchant cast`, `magic apply`, `buff sparkle` | `shop_ui` → enchant flow (Phase B) | 附魔是消耗品核心，使用时有仪式感 |
| S20 | 星图升级 | `star_upgrade.ogg` | 购买→选牌型→升级 | `star chart`, `upgrade chime`, `constellation` | `shop_ui` → star chart flow (Phase B) | 升级成功确认 |
| S21 | 秘仪生效 | `ritual_pulse.ogg` | 购买即全局生效 | `arcane pulse`, `ritual low`, `global effect` | `shop_ui` → ritual flow (Phase C) | 全局效果的震撼感 |
| S22 | 修炼成长 | `growth_tick.ogg` | 出牌/换牌后累积触发 | `level up light`, `growth tick`, `progress` | `seal_controller` → scaling (B10) | 长期成长的积累反馈 |
| S23 | 忍法使用 | `ninja_gear.ogg` | 改变资源/规则 | `tool equip`, `ninja gear`, `equip click` | Phase B | 规则变更的操作确认 |
| S24 | 琉璃碎裂 | `glass_break.ogg` | 琉璃牌 1/4 销毁 | `glass shatter`, `crack`, `break` | `score_calculator` Phase B | 高风险高回报的听觉刺激 |
| S25 | 鸿运触发 | `lucky_jingle.ogg` | Lucky 20% +mult / 6.7% +gold | `lucky chime`, `jackpot`, `slot win` | `score_calculator` Phase B | 鸿运是"中奖"，听觉应有过山车感 |
| S26 | 放逐销毁 | `banish_fire.ogg` | 放逐令销毁牌 | `fire vanish`, `burn`, `disappear` | Phase B | 销毁操作有重量感 |

    │
    ├── cat/
    │   ├── beetpro-meou-cat-sound-effect-18-11098.ogg          # 猫叫彩蛋
    │   ├── dragon-studio-cartoon-cat-meow-487661.ogg           # 猫叫彩蛋
    │   ├── dragon-studio-cat-meow-401729.ogg                   # 猫叫彩蛋
    │   ├── freesound_community-cat-meow-6226.ogg               # 猫叫彩蛋
    │   ├── ribhavagrawal-cat-meowing-type-01-293291.ogg        # 猫叫彩蛋
    │   ├── ribhavagrawal-cat-meowing-type-02-293290.ogg        # 猫叫彩蛋
    │   ├── soulfuljamtracks-cat-meow-1-fx-323465.ogg           # 猫叫彩蛋
    │   ├── soulfuljamtracks-cat-meow-6-fx-323468_cut.ogg       # 猫叫彩蛋（已裁剪）
    │   ├── sound_garage-cat-meow-11-fx-306193.ogg              # 猫叫彩蛋
    │   ├── sound_garage-cat-meow-12-fx-306191_cut.ogg          # 猫叫彩蛋（已裁剪）
    │   ├── soundreality-cat-meow-fx-461188_cut.ogg             # 猫叫彩蛋（已裁剪）
    │   ├── virtual_vibes-real-cat-sound-effect-383821_cut.ogg  # 猫叫彩蛋（已裁剪）
    │   ├── yodguard-cute-soft-cat-meow-3-535482.ogg            # 猫叫彩蛋
    │   ├── yodguard-cute-soft-cat-meow-4-535483.ogg            # 猫叫彩蛋
    │   └── yoursperfectguy-cute-puppy-sound-effect-sfx-1-336356_cut.ogg  # 猫叫彩蛋（已裁剪）
    │
---

### P3 — 润色（远期，若干）

| # | 名称 | 说明 | 备注 |
|----|------|------|------|
| S27 | 环境氛围音 | 太鼓余韵 / 风声 / 叶响 循环 | 低音量垫底，可选 |
| S28 | 稀有牌出现 | 商店刷出 rare 牌时特殊 jingle | 类似 Balatro 稀有牌闪光音 |
| S29 | 結界过渡 | Ante 变化时的简短过渡音 | 难度爬升的听觉标志 |
| S30 | UI hover 细化 | 悬停不同元素用不同 pitch 的 hover | 当前用单一 hover 音，可加变体 |

---

## §5 BGM 清单

| # | 用途 | 文件 | 描述 | 关键词 | 优先级 | 备注 |
|----|------|------|------|--------|--------|------|
| BGM1 | **主菜单** | `start_menu_bgm.wav` (Ogg→替换中) | 氛围忍者主题，动画风慢节奏 OST，有旋律性，~60-90s 循环 | `ninja theme`, `anime ambience`, `japanese menu ost` | **P0** | 替换 FanKing 占位（当前为旧 26s WAV） |
| BGM2a | **游戏 軽 (属性 火/水/風)** | `game_bgm_light.mp3` | 动画 OST 中速驱动，配器稀疏：轻打击 + 太鼓 + 偶尔筝装饰 | `anime game light`, `taiko rhythm sparse`, `action ost` | **P0** | DOVA-SYNDROME ✅ |
| BGM2b | **游戏 中 (属性 雷/土/光)** | `game_bgm_medium.mp3` | 同主题，动画 OST 加密：完整弦乐 + 太鼓频繁 + 尺八旋律线 | `anime game mid`, `taiko driving`, `shakuhachi`, `dramatic ost` | **P0** | DOVA-SYNDROME ✅ |
| BGM2c | **游戏 重 (属性 暗/无)** | `game_bgm_heavy.mp3` | 同主题，动画 OST 全配器：史诗弦乐 + 太鼓连打 + 尺八 + 筝，压迫感 | `anime game intense`, `taiko frenzy`, `tension`, `epic ost` | **P1** | DOVA-SYNDROME ✅ |
| BGM3 | **商店** | `dova_Cooler Ninjari Ninjarous miaster.mp3` | 轻松明亮，动画日常风短循环 ~30s，筝旋律 + 轻打击 | `shop relaxed`, `merchant jingle`, `anime daily` | **P1** | DOVA-SYNDROME ✅ |

### BGM 实现要点

- **MusicManager 扩展**（B11）：新增 `set_game_variation(barrier: int)` 方法
  - 属性 火/水/風 (Ante 1-3) → `_game_bgm_light`
  - 属性 雷/土/光 (Ante 4-6) → `_game_bgm_mid`
  - 属性 暗/无 (Ante 7-8) → `_game_bgm_heavy`
  - 切换走 `_crossfade_to()` 实现无缝过渡
- 触发点：`game_manager._on_seal_started()` 中判断 `barrier_num` 调用
- 商店 BGM：`MusicManager.play_shop_bgm()` 在 `shop_ui._play_entrance()` 中调用

---

## §6 分阶段计划

### Phase 1 — 核心体验 (P0) ✅ 全部完成 (2026-06-14)

```
✅ 素材替换: S1-S10 + S11-S18 (20 个音效) — 已完成 (2026-06-10)
✅ 代码接线: animation_handler.gd + game_manager.gd + shop_handler.gd + hand_interaction.gd
✅ BGM 素材: DOVA-SYNDROME 4 首 (game light/medium/heavy + shop) — 已完成 (B11)
✅ SoundBank 更新: C8 常量重命名 + C16 商店常量 + C17-C20 补充 — 已完成
```

| 步骤 | 内容 | 状态 |
|------|------|------|
| 1.1 | ~~BOOTH 采购~~ → 实际使用 Epic Stock Media「Anime Game」Pack (itch.io, $69, 1,433 WAV) | ✅ |
| 1.2 | 自动匹配 S1-S18 + UIE 共 20 需求 → 全部匹配成功 (详见 §10) | ✅ |
| 1.3 | ffmpeg WAV→OGG 转换 (`libvorbis -q:a 6` ~192kbps) → 复制到 `assets/audio/sound/` | ✅ |
| 1.4 | BGM 素材寻找 — DOVA-SYNDROME 3 首战忍BGM + 1 首商店BGM | ✅ |
| 1.5 | C8 SoundBank 常量忍者主题重命名 + C16 新增商店常量 | ✅ |
| 1.6 | 接线 → `animation_handler.gd`(GROUP_REVEAL/COUNT_TICK/NINJA_ACTIVATE/XI_TRIGGER/XI_FANFARE/SEAL_CLEAR/SEAL_FAIL) + `game_manager.gd`(DEAL/BOSS_REVEAL/BOSS_FINAL_LAYER/XI_FANFARE) | ✅ |
| 1.7 | 接线 → `shop_handler.gd`(SHOP_EXIT/ITEM_PURCHASE/UI_COIN/SHOP_REROLL/UI_ERROR) + `ui_manager.gd`(MusicManager.play_shop_bgm) | ✅ |
| 1.8 | 接线 → `hand_interaction.gd`(SELECT/SWAP×2) + `ninja_bar_node.gd`(DEAL/SWAP/SEAL_FAIL) + `card_detail_popup.gd`(SELECT) | ✅ |
| 1.9 | B11 MusicManager `set_game_variation(barrier)` BGM 3 段变奏自动切换 | ✅ |

### Phase 2 — 关卡节点 (P1) ✅ 全部完成 (2026-06-14)

```
素材寻找: S11-S18 (8 个音效) + BGM2c + BGM3 — 全部从 Anime Game Pack 匹配完成
代码接线: shop_handler.gd + ui_manager.gd + game_manager.gd + MusicManager
```

| 步骤 | 内容 | 状态 |
|------|------|------|
| 2.1 | B11: MusicManager 扩展 `set_game_variation()` + `play_shop_bgm()` + `play_menu_bgm()` | ✅ |
| 2.2 | BGM3 商店 BGM: DOVA-SYNDROME "Cooler Ninjari Ninjarous miaster" | ✅ |
| 2.3 | S11-S18 素材筛选 + V23 匹配 + WAV→OGG 转换 | ✅ |
| 2.4 | 接线：`shop_handler.gd` 购买/刷新/进入/离开 + `ui_manager.gd` show_shop BGM | ✅ |
| 2.5 | 接线：`game_manager._on_seal_started()` Boss 揭晓 + 終焉层 + BGM变奏 | ✅ |
| 2.6 | C8 SoundBank 常量重命名 + 旧 alias 保留 | ✅ |
| 2.7 | 全流程音效测试通过 | ✅ |

### Phase 3 — P2 SFX 素材匹配与接线 (正在进行)

```
素材来源: Anime Game Pack (剩余 1,413 未用 WAV) — 优先自匹配
代码接线: 随 Phase B-C 功能实装时一起接
```

| 步骤 | 内容 | 状态 |
|------|------|------|
| 3.1 | S19 enchant_cast — Magic General Buff Positive 01 (1.35s) | ✅ |
| 3.2 | S20 star_upgrade — Power Up Bright Successful Crash Shimmer 01 (1.05s) | ✅ |
| 3.3 | S21 ritual_pulse — Magic Buff Negative Debuff 01 (2.06s) | ✅ |
| 3.4 | S22 growth_tick — UI Cute Success Emote Sine Blip 01 (0.82s) | ✅ |
| 3.5 | S23 ninja_gear — Effect Eureka Moment 01 (0.73s) | ✅ |
| 3.6 | S24 glass_break — Effect Glassy Thin Pops 03 (1.69s) | ✅ |
| 3.7 | S25 lucky_jingle — Power Up Positive Successful Deep Crisp Wobble 01 (1.07s) | ✅ |
| 3.8 | S26 banish_fire — Magic Fire Beam Burning Blast 01 (2.25s) | ✅ |

### Phase 4 — 菜单 BGM 替换 (P1)

```
BGM1 主菜单: start_menu_bgm.wav (26s) 仍是旧 FanKing 占位，需替换为 DOVA-SYNDROME 或同类免费素材
```

| 步骤 | 内容 | 状态 |
|------|------|------|
| 4.1 | DOVA-SYNDROME 搜索"和風 メニュー" / "japanese menu" 候选 | ⬜ |
| 4.2 | 候选试听确认 → WAV/MP3 下载 | ⬜ |
| 4.3 | 替换 `assets/audio/music/start_menu_bgm.wav` + music_manager.gd load 路径 | ⬜ |

### Phase 5 — P3 润色 (远期)

```
素材寻找: S27-S30 (可选)
预计工时: 分散到 Phase E-F 开发中
```

| 步骤 | 内容 | 状态 |
|------|------|------|
| 5.1 | S27 环境氛围音 — 太鼓余韵/风声/叶响循环 | ⬜ |
| 5.2 | S28 稀有牌出现 — 商店 rare 牌 jingle | ⬜ |
| 5.3 | S29 結界过渡 — Ante 变化过渡音 | ⬜ |
| 5.4 | S30 UI hover 细化 — 多 pitch 变体 | ⬜ |

---

## §7 接线速查表 (2026-06-15 同步)

> 统一接线模式：
> ```gdscript
> const SB = preload("res://scripts/config/sound_bank.gd")
> GlobalTweens.play_sfx(SB.XXX)           # 即时播放
> GlobalTweens.bind_sfx(tween, SB.XXX, 0) # 动效绑定
> ```

### P0 — 核心体验（全部接线完成 ✅）

| 脚本 | 函数 | 音效 | 备注 |
|------|------|------|------|
| `game_manager.gd` | `_intro_timer()` → PLAYING | `SB.DEAL` | C17 |
| `animation_handler.gd` | Phase 1 逐卡揭示 | `SB.GROUP_REVEAL` ×3 | 影/瞬/滅，音高递升 |
| `animation_handler.gd` | `_sfx_tick(pitch)` | `SB.COUNT_TICK` | BounceScore milestone 驱动，pitch 递升 |
| `animation_handler.gd` | 喜弹出 | `SB.XI_TRIGGER` / `SB.XI_FANFARE` | 单喜 trigger，双喜+ fanfare |
| `animation_handler.gd` | 胜败判定 | `SB.SEAL_CLEAR` / `SB.SEAL_FAIL` | 过关/失败 |
| `animation_handler.gd` | 忍者牌激活（每张忍牌触发） | `SB.CAT_MEOWS[rand_idx]` round-robin 随机猫叫 | 替换 NINJA_ACTIVATE，详情见 §11 |
| `animation_handler.gd` | 三段汇总全局提示 | `SB.NINJA_ACTIVATE` | 保留原冲击音，与猫叫区分 |
| `hand_interaction.gd` | 卡牌选中 | `SB.SELECT` | C20 |
| `hand_interaction.gd` | 交换完成(点击+拖拽) | `SB.SWAP` | ~0.1s 极短 |
| `ninja_bar_node.gd` | 忍者弹入/移除 | `SB.DEAL` / `SB.SEAL_FAIL` / `SB.SWAP` | 弹入/移除/重排 |
| `card_detail_popup.gd` | 右键详情打开 | `SB.SELECT` | |
| `nin_king_tween.gd` | 商店入口墨线画 | `SHOP_ENTER`(whoosh_sfx 参数) | 通过参数传入，非直接 SB 常量 |

### P1 — 关卡节点 + 商店（全部接线完成 ✅）

| 脚本 | 函数 | 音效 | 备注 |
|------|------|------|------|
| `game_manager.gd` | `_on_seal_started()` | `SB.BOSS_REVEAL` + `SB.BOSS_FINAL_LAYER` | barrier≥8 时叠加最终层 |
| `game_manager.gd` | `_on_seal_started()` | `MusicManager.set_game_variation(barrier)` | B11 BGM 三变奏 |
| `game_manager.gd` | `_play_gold_settlement()` | `SB.UI_COIN` | 金币飞入结算 |
| `ui_manager.gd` | `show_shop()` | `MusicManager.play_shop_bgm()` | R1 修复 |
| `shop_handler.gd` | `on_purchase_requested()` — 成功 | `SB.ITEM_PURCHASE` + `SB.UI_COIN` | |
| `shop_handler.gd` | `on_purchase_requested()` — 失败 | `SB.UI_ERROR` | 槽位满 / 金币不足 |
| `shop_handler.gd` | `on_item_purchase_requested()` — 成功 | `SB.ITEM_PURCHASE` + `SB.UI_COIN` | |
| `shop_handler.gd` | `on_item_purchase_requested()` — 失败 | `SB.UI_ERROR` | 金币不足 |
| `shop_handler.gd` | `_purchase_star_chart()` — 成功 | `SB.ITEM_PURCHASE` + `SB.UI_COIN` | |
| `shop_handler.gd` | `_purchase_star_chart()` — 失败 | `SB.UI_ERROR` | 金币不足 |
| `shop_handler.gd` | `on_reroll_requested()` — 失败 | `SB.UI_ERROR` | 金币不足刷新 |
| `shop_handler.gd` | `on_reroll_requested()` — 成功 | `SB.SHOP_REROLL` | |
| `shop_handler.gd` | `on_continue_requested()` | `MusicManager.set_game_variation(barrier)` | 恢复游戏 BGM |
| `nin_king_tween.gd` | `play_shop_exit()` | `SB.SHOP_EXIT` | 退场时序 Phase 2 开头 |

### P2 — 待匹配 + 接线（8 个空缺 ⬜）

| # | 名称 | 文件 | 触发 | 来源目录 |
|---|------|------|------|---------|
| S19 | 附魔使用 | `enchant_cast.ogg` | 附魔使用 | Magic/Buff + Magic/General |
| S20 | 星图升级 | `star_upgrade.ogg` | 星图购买 | Power Ups |
| S21 | 秘仪生效 | `ritual_pulse.ogg` | 秘仪购买 | Power Auras + Magic/Buff |
| S22 | 修炼成长 | `growth_tick.ogg` | 出牌/换牌后 scaling | UI |
| S23 | 忍法使用 | `ninja_gear.ogg` | 忍法效果触发 | Item + Effect |
| S24 | 琉璃碎裂 | `glass_break.ogg` | 琉璃牌销毁 | Impact + Explosions |
| S25 | 鸿运触发 | `lucky_jingle.ogg` | Lucky 效果触发 | Power Ups + Emote |
| S26 | 放逐销毁 | `banish_fire.ogg` | 放逐令销毁牌 | Magic/Fire + Explosions |

### @unused 已归档

| 常量 | 文件 | 说明 |
|------|------|------|
（手替え系统已全线移除，DISCARD/REDRAW_POP 音效一并归档）

---

## §8 文件命名规范

```
assets/audio/
├── music/
│   ├── start_menu_bgm.wav                          # BGM1 — 主菜单（旧占位，待替换）
│   ├── game_bgm_light.mp3                          # BGM2a — 游戏 軽 (属性 火/水/風)
│   ├── game_bgm_medium.mp3                         # BGM2b — 游戏 中 (属性 雷/土/光)
│   ├── game_bgm_heavy.mp3                          # BGM2c — 游戏 重 (属性 暗/无)
│   └── dova_Cooler Ninjari Ninjarous miaster.mp3   # BGM3 — 商店
│
└── sound/
    ├── game/
    │   ├── deal.ogg                # S1 — 发牌 swish（替换）
    │   ├── group_reveal.ogg        # S2 — 组揭示（替换 hu.ogg）
    │   ├── count_tick.ogg          # S3 — 计分 tick（替换）
    │   ├── xi_trigger.ogg          # S4 — 单喜 chime（替换 yaku_reveal.ogg）
    │   ├── xi_fanfare.ogg          # S4 — 双喜+ fanfare（新增）
    │   ├── seal_clear.ogg          # S5 — 过关（替换 level_clear.ogg）
    │   ├── seal_fail.ogg           # S6 — 失败（替换 level_fail.ogg）
    │   ├── swap.ogg                # S7 — 交换滑动（替换）
    │   ├── (discard.ogg → legacy)  # S8 — @unused 手替え取消
    │   ├── (redraw_pop.ogg → legacy) # S8 — @unused 手替え取消
    │   ├── ninja_activate.ogg      # S9 — 忍者激活（替换 bao_activate.ogg）
    │   ├── boss_reveal.ogg         # S11 — Boss 揭晓（新增）
    │   ├── boss_final_layer.ogg    # S12 — 終焉压迫层（新增）
    │   ├── shop_enter.ogg          # S13 — 商店进入（新增）
    │   ├── item_purchase.ogg       # S15 — 消耗品购买（新增）
    │   ├── shop_reroll.ogg         # S16 — 刷新（替换 lottery.ogg）
    │   ├── shop_exit.ogg           # S17 — 商店离开（新增）
    │   ├── enchant_cast.ogg          # S19 — 附魔使用（素材就绪 P2）
│   ├── star_upgrade.ogg          # S20 — 星图升级（素材就绪 P2）
│   ├── ritual_pulse.ogg          # S21 — 秘仪生效（素材就绪 P2）
│   ├── growth_tick.ogg           # S22 — 修炼成长（素材就绪 P2）
│   ├── ninja_gear.ogg            # S23 — 忍法使用（素材就绪 P2）
│   ├── glass_break.ogg           # S24 — 琉璃碎裂（素材就绪 P2）
│   ├── lucky_jingle.ogg          # S25 — 鸿运触发（素材就绪 P2）
│   └── banish_fire.ogg           # S26 — 放逐销毁（素材就绪 P2）
    │
    └── ui/
        ├── ui_click.ogg            # 按钮点击（替换）
        ├── ui_coin.ogg             # 金币（替换）
        └── ui_error.ogg            # 错误提示（替换）
```

### 命名规则

- **全小写 snake_case**，不可用中文/空格/特殊字符
- BGM 用 `.ogg`（Godot 推荐音频格式）
- SFX 用 `.ogg`（替换现有 `.ogg` 占位）
- 文件描述动作/结果，不用设备名词（`group_reveal.ogg` 好于 `taiko_hit.ogg`）
- 同一操作的多个变体用后缀 `_light` / `_mid` / `_heavy` 或 `_a` / `_b`

---

## §10 执行记录 — V23 音效匹配 (2026-06-10)

### 匹配概要

| 指标 | 数值 |
|------|------|
| 素材包 | Epic Stock Media「Anime Game - Universal Sound Sets Library」 |
| 源文件数 | 1,433 WAV (24-bit) |
| 匹配需求 | 20 (P0 11 + P1 9) |
| 匹配成功 | 20/20 ✅ |
| 转换格式 | OGG (`libvorbis -q:a 6`, ~192kbps) |
| 自动化工具 | awk 打分引擎 + ffprobe + ffmpeg |
| 匹配规范 | `18-audio-asset-matching-guide.md` v2 |

### P0 核心体验 (11 文件)

| id | target | 时长 | 源文件 | 置信度 | 备注 |
|----|--------|------|--------|--------|------|
| S1 | `deal.ogg` | 0.59s | WHSH_Movement Blink Quick Swish 01 | 🟡 中 | 包内无 <0.2s whoosh。swish+light 关键词命中 |
| S2 | `group_reveal.ogg` | 0.64s | IMPT_Combat Cute Punch Pow Impact 01 | 🟢 高 | 短impact+打击感，combat 目录优先匹配 |
| S3 | `count_tick.ogg` | 0.25s | UI_Scifi Blip Short 01 | 🟡 中 | 包内最短UI音。scifi blip 音色近似 tick |
| S4a | `xi_trigger.ogg` | 1.32s | MGB_Magic Buff Shimmer 01 | 🟡 中 | 魔法 shimmer 有铃铛质感，比设计时长偏长 |
| S4b | `xi_fanfare.ogg` | 0.91s | PUP_Power Up Success 01 | 🟢 高 | power-up + success 精确命中，上行华丽 |
| S5 | `seal_clear.ogg` | 1.51s | PUP_Bright Success Shimmer 01 | 🟡 中 | bright+success+shimmer。偏短但音色明亮 |
| S6 | `seal_fail.ogg` | 0.75s | IMPT_Heavy Muffled Impact 01 | 🟡 中 | heavy+muffled=低沉下行感，combar→impact 目录 |
| S7 | `swap.ogg` | 0.58s | WHSH_Movement Blink Swish 02 | 🟡 中 | 与 S1 同系列不同变体(01 vs 02) |
| S8a | `discard.ogg` | 1.24s | MGB_Magic Pop Shimmer 03 | 🟡 中 | magic pop≈poof 烟遁感，偏长 |
| S8b | `redraw_pop.ogg` | 0.80s | WHSH_Effect Blink Dash Flicker 01 | 🟡 中 | dash+flicker≈瞬身出现，whoosh 感 |
| S9 | `ninja_activate.ogg` | 1.11s | MGE_Magic Electric Spark Flicker 01 | 🟡 中 | electric+spark=能量激活，metal ting 替代 |
| S10 | `ui_click.ogg` | 0.29s | UI_Scifi Blip 03 | 🟡 中 | 包内次短UI音，与 S3 不同变体 |

### P1 关卡节点 + UI (9 文件)

| id | target | 时长 | 源文件 | 置信度 | 备注 |
|----|--------|------|--------|--------|------|
| S11 | `boss_reveal.ogg` | 2.15s | EXP_Dark Ominous Reveal 01 | 🟢 高 | **完美匹配**: dark+ominous+reveal 全关键词命中 |
| S12 | `boss_final_layer.ogg` | 3.01s | MGG_Magic General Ominous Debuff Shimmer 01 | 🟡 中 | ominous+dark 氛围，低频嗡鸣感 |
| S13 | `shop_enter.ogg` | 1.08s | ITM_Collect Acquire Bright 01 | 🟡 中 | collect+acquire≈获得物品，bright=温暖 |
| S14 | `ui_coin.ogg` | 1.11s | UI_Clean Glass Tap 01 | 🟡 中 | glass tap 清脆感≈金币，偏长但音色对 |
| S15 | `item_purchase.ogg` | 1.05s | ITM_Loot Chest Equip Gain 01 | 🟢 高 | **完美匹配**: loot+gain=获得消耗品 |
| S16 | `shop_reroll.ogg` | 1.04s | WHSH_Movement Smooth Slide Swish 01 | 🟡 中 | slide+swish≈洗牌翻飞 |
| S17 | `shop_exit.ogg` | 1.05s | WHSH_Movement Quick Slide Tight Filter 04 | 🟡 中 | 与 S16 不同变体(04 vs 01)，close/exit 语义 |
| UIE | `ui_error.ogg` | 0.97s | MGE_Magic Electric Buzzing Malfunction 01 | 🟡 中 | buzzing+malfunction≈错误否定，偏长但拒绝感对 |

### 已知限制

| # | 限制 | 影响 | 缓解 |
|---|------|------|------|
| L1 | 包内无 <0.2s 超短音效 | S3 count_tick (0.25s) / S10 ui_click (0.29s) 偏长 | 选取包内最短可用，高频操作容忍度内 |
| L2 | 无纯和风乐器音（太鼓/铃/尺八/筝） | S2/S5 缺乏和风特色 | 采用通用动画打击/胜利音替代，和风点缀待 BOOTH 补充 |
| L3 | 包内 whoosh ~0.5-1.2s 为主 | S1/S7 偏长（spec 目标 0.05-0.25s） | 选取最短可用变体，实际听感可接受 |
| L4 | 无 anime 人声/喊叫 | 无法做角色语音 | 非当前需求范围，P2+ 考虑 |

### 旧文件归档

17 个 FanKing 占位文件已备份至 `assets/audio/sound/legacy_placeholders/`，待 C8 SoundBank 更新 + L3 接线完成后清理。

### 后续待办

| 步骤 | 内容 | 关联 |
|------|------|------|
| C8 | `sound_bank.gd` 常量重命名（§3 映射表） | TODO.md C8 |
| L2 | `sound_bank.gd` 新增 P0+P1 preload 常量 | §8 |
| L3 | 全量接线 (§7 速查表 17 处) | §7 |
| B11 | MusicManager BGM 3 段变奏 | TODO.md B11 |

以下 FanKing 占位音效在替换后不再存在对应文件：

| 旧文件 | 说明 |
|--------|------|
| `hu.ogg` | → `group_reveal.ogg`（组揭示） |
| `yaku_reveal.ogg` | → `xi_trigger.ogg`（喜触发） |
| `bao_activate.ogg` | → `ninja_activate.ogg`（忍者激活） |
| `level_clear.ogg` | → `seal_clear.ogg`（封印达成） |
| `level_fail.ogg` | → `seal_fail.ogg`（封印失败） |
| `lottery.ogg` | → `shop_reroll.ogg`（商店刷新） |
| `explosion.ogg` | → 保留为通用特效音（P2 特殊牌等复用） |
| `draw.ogg` | → 可能合并入 `deal.ogg`（发牌时同时可用） |

---

## §11 🎮 彩蛋：计分猫叫音效

> **实装日期:** 2026-06-17 | **设计:** Grill 9 轮 → review-plan 审阅通过 → 实装
> **关联:** [`sound_bank.gd`](../../scripts/config/sound_bank.gd) · [`animation_handler.gd`](../../scripts/ninking/ui/animation_handler.gd)
> **素材来源:** Freesound / Dragon Studio / SoundGarage / SoulfulJamTracks 等，CC0 许可

### 设计目标

- 计分时每张忍者牌触发 → 播放随机猫叫代替原 `NINJA_ACTIVATE`
- 同一次评分流程内不重复（round-robin），播完 15 只后重置
- 三段汇总后的全局忍者提示（`animation_handler.gd:285`）**保留原 `NINJA_ACTIVATE`**

### 实现细节

| 组件 | 内容 |
|------|------|
| **素材** | `assets/audio/sound/cat/` — 15 个 `.ogg`（原始 MP3/WAV 已清除） |
| **常量** | `sound_bank.gd` → `CAT_MEOWS: Array[AudioStream]` |
| **音效池** | `animation_handler._run_scoring_animation()` 顶部声明 `_unplayed_cats = SB.CAT_MEOWS.duplicate()` |
| **播放** | 每张忍牌循环内 → `if _unplayed_cats.is_empty(): _unplayed_cats = SB.CAT_MEOWS.duplicate()` → `randi()` 选索引 → `play_sfx()` → `remove_at()` |
| **重叠** | fire-and-forget（同原 `NINJA_ACTIVATE`），多张连发时放任重叠 |
| **全局提示** | `animation_handler.gd:285` 三段汇总后 → 保留 `GlobalTweens.play_sfx(SB.NINJA_ACTIVATE)` |

### 维护指南

- **新增猫叫音效**：将 `.ogg` 放入 `assets/audio/sound/cat/` → 在 `sound_bank.gd` 的 `CAT_MEOWS` 数组中追加 `preload` 行
- **移除猫叫音效**：从目录删除文件 → 从 `CAT_MEOWS` 数组移除对应行 → 在 Godot 编辑器中 Reimport 目录
- **替换为其他彩蛋**：只需替换 `assets/audio/sound/cat/` 下的文件（保持 `.ogg` 格式），无需改代码

### 素材清单

15 个猫叫文件，来源如下：

| # | 文件名 | 来源 | 说明 |
|---|--------|------|------|
| 1 | `beetpro-meou-cat-sound-effect-18-11098.ogg` | BeetPro | 标准猫叫 |
| 2 | `dragon-studio-cartoon-cat-meow-487661.ogg` | Dragon Studio | 卡通猫叫 |
| 3 | `dragon-studio-cat-meow-401729.ogg` | Dragon Studio | 真实猫叫 |
| 4 | `freesound_community-cat-meow-6226.ogg` | Freesound Community | 社区猫叫 |
| 5 | `ribhavagrawal-cat-meowing-type-01-293291.ogg` | Ribhav Agrawal | 类型 1 |
| 6 | `ribhavagrawal-cat-meowing-type-02-293290.ogg` | Ribhav Agrawal | 类型 2 |
| 7 | `soulfuljamtracks-cat-meow-1-fx-323465.ogg` | SoulfulJamTracks | 猫叫 1 |
| 8 | `soulfuljamtracks-cat-meow-6-fx-323468_cut.ogg` | SoulfulJamTracks | 猫叫 6（已裁剪） |
| 9 | `sound_garage-cat-meow-11-fx-306193.ogg` | Sound Garage | 猫叫 11 |
| 10 | `sound_garage-cat-meow-12-fx-306191_cut.ogg` | Sound Garage | 猫叫 12（已裁剪） |
| 11 | `soundreality-cat-meow-fx-461188_cut.ogg` | SoundReality | 猫叫（已裁剪） |
| 12 | `virtual_vibes-real-cat-sound-effect-383821_cut.ogg` | Virtual Vibes | 真实猫叫（已裁剪） |
| 13 | `yodguard-cute-soft-cat-meow-3-535482.ogg` | YodGuard | 软猫叫 3 |
| 14 | `yodguard-cute-soft-cat-meow-4-535483.ogg` | YodGuard | 软猫叫 4 |
| 15 | `yoursperfectguy-cute-puppy-sound-effect-sfx-1-336356_cut.ogg` | YoursPerfectGuy | ~~狗叫~~ 实际是猫叫（已裁剪） |

> **注:** `_cut` 后缀文件为原始素材裁剪了前导静音/尾音，时长约 1s。
> **许可:** 全部为 CC0 / 免费可商用，发布前确认各平台署名要求。
