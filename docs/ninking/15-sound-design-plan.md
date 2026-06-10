# NinKing 音效设计计划

> **建立日期:** 2026-06-10 | **关联:** [`TODO.md`](TODO.md) · [`04-asset-gap-list.md`](04-asset-gap-list.md) · [`sound_bank.gd`](../../scripts/config/sound_bank.gd)
> **用途:** 指导音效素材寻找、替换、新增、代码接线的完整工作计划。

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
| 游戏 SFX | 17 个 FanKing 占位 (OGG) | 全替换为动画 SFX（日常操作 chiptune + 情绪节点动画戏剧音） |
| UI SFX | 3 个 FanKing 占位 (OGG) | 保留 3 个 + 新增 3 个 |
| **总计 SFX** | **19** | **25-30**（替换 19 + 新增 6-11） |

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
| **接线** | `game_manager._run_scoring_animation()` → CountUp 驱动时每 N 点调用一次 `GlobalTweens.play_sfx(SB.COUNT_TICK)` |
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
| S23 | 忍具使用 | `ninja_gear.ogg` | 改变资源/规则 | `tool equip`, `ninja gear`, `equip click` | Phase B | 规则变更的操作确认 |
| S24 | 琉璃碎裂 | `glass_break.ogg` | 琉璃牌 1/4 销毁 | `glass shatter`, `crack`, `break` | `score_calculator` Phase B | 高风险高回报的听觉刺激 |
| S25 | 鸿运触发 | `lucky_jingle.ogg` | Lucky 20% +mult / 6.7% +gold | `lucky chime`, `jackpot`, `slot win` | `score_calculator` Phase B | 鸿运是"中奖"，听觉应有过山车感 |
| S26 | 放逐销毁 | `banish_fire.ogg` | 放逐令销毁牌 | `fire vanish`, `burn`, `disappear` | Phase B | 销毁操作有重量感 |

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
| BGM1 | **主菜单** | `start_menu_bgm.ogg` | 氛围忍者主题，动画风慢节奏 OST，有旋律性，~60-90s 循环 | `ninja theme`, `anime ambience`, `japanese menu ost` | **P0** | 替换 FanKing 占位 |
| BGM2a | **游戏 軽 (属性 火/水/風)** | `game_bgm_light.ogg` | 动画 OST 中速驱动，配器稀疏：轻打击 + 太鼓 + 偶尔筝装饰 | `anime game light`, `taiko rhythm sparse`, `action ost` | **P0** | 替换 FanKing 占位 |
| BGM2b | **游戏 中 (属性 雷/土/光)** | `game_bgm_mid.ogg` | 同主题，动画 OST 加密：完整弦乐 + 太鼓频繁 + 尺八旋律线 | `anime game mid`, `taiko driving`, `shakuhachi`, `dramatic ost` | **P0** | BGM2a 的密度增强版 |
| BGM2c | **游戏 重 (属性 暗/无)** | `game_bgm_heavy.ogg` | 同主题，动画 OST 全配器：史诗弦乐 + 太鼓连打 + 尺八 + 筝，压迫感 | `anime game intense`, `taiko frenzy`, `tension`, `epic ost` | **P1** | BGM2a 的最强变奏 |
| BGM3 | **商店** | `shop_bgm.ogg` | 轻松明亮，动画日常风短循环 ~30s，筝旋律 + 轻打击 | `shop relaxed`, `merchant jingle`, `anime daily` | **P1** | 新增，原 D6 缺失 |

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

### Phase 1 — 核心体验 (P0) 🎯 目标：玩家第一耳就能感受到动画漫画风格

```
素材寻找: S1-S10 (10 个音效) + BGM1 + BGM2a + BGM2b
代码接线: game_manager.gd + seal_controller.gd 接入
预计工时: 素材 2-3 天 + 接线 0.5 天
```

| 步骤 | 内容 |
|------|------|
| 1.1 | BOOTH 采购 1 个アニメ/和風効果音集 + itch.io 采购 1 个 Anime SFX Pack |
| 1.2 | 筛选符合 S1-S10 的素材，统一命名放入 `assets/audio/sound/game/` |
| 1.3 | 効果音ラボ / Dova-Syndrome 筛选动画风 BGM1 + BGM2a/b |
| 1.4 | 替换 sound_bank.gd 中 19 个旧 preload 路径 → 新文件 |
| 1.5 | 接线：`game_manager._run_scoring_animation()` / `_on_xi_triggered()` / `_intro_timer()` |
| 1.6 | 接线：`seal_controller.finalize_play()` / `_complete_seal()` / `execute_redraw()` |
| 1.7 | 接线：`hand_interaction.gd` 交换完成 |
| 1.8 | 测试：完整一局听全部 P0 音效 |

### Phase 2 — 关卡节点 (P1)

```
素材寻找: S11-S18 (8 个音效) + BGM2c + BGM3
代码接线: shop_ui.gd + MusicManager 扩展
预计工时: 素材 2 天 + 接线 0.5 天
```

| 步骤 | 内容 |
|------|------|
| 2.1 | B11: MusicManager 扩展 `set_game_variation()` (~15 行) |
| 2.2 | BGM3 商店 BGM: Dova-Syndrome 筛选 |
| 2.3 | S11-S18 素材筛选 |
| 2.4 | 接线：`shop_ui` 购买/刷新/进入/离开 |
| 2.5 | 接线：`game_manager._on_seal_started()` Boss 揭晓 + 終焉层 |
| 2.6 | SoundBank 常量重命名（C8），旧常量保留 alias |
| 2.7 | 测试：商店 + Boss 揭晓听全部 P1 音效 |

### Phase 3 — 润色 (P2-P3)

```
素材寻找: S19-S26 + S27-S30 (可选)
代码接线: Phase B-C 功能实装时一起接
预计工时: 分散到 Phase B-C 开发中
```

---

## §7 接线速查表

> 统一接线模式：
> ```gdscript
> const SB = preload("res://scripts/config/sound_bank.gd")
> GlobalTweens.play_sfx(SB.XXX)           # 即时播放
> GlobalTweens.bind_sfx(tween, SB.XXX, 0) # 动效绑定
> ```

| 优先级 | 脚本 | 函数 | 音效 | 备注 |
|--------|------|------|------|------|
| P0 | `game_manager.gd` | `_intro_timer()` | `SB.DEAL` | 用 `bind_sfx` 绑在 stagger_spread tween 上 |
| P0 | `game_manager.gd` | `_run_scoring_animation()` | `SB.GROUP_REVEAL` ×3 | 影(低) / 瞬(中) / 滅(高)，音量递升 |
| P0 | `game_manager.gd` | `_run_scoring_animation()` | `SB.COUNT_TICK` | CountUp 每次递增调用 |
| P0 | `game_manager.gd` | `_on_xi_triggered(xis)` | `SB.XI_FANFARE` / `SB.XI_TRIGGER` | `xis.size() >= 2` → fanfare |
| P0 | `game_manager.gd` | `_on_play_pressed()` | `SB.UI_CLICK` | 出牌确认 |
| P0 | `game_manager.gd` | `_on_redraw_pressed()` | `SB.UI_CLICK` | 换牌模式进入 |
| P0 | `seal_controller.gd` | `execute_redraw()` | `SB.DISCARD` + `SB.REDRAW_POP` | 弃牌时 + 新牌 pop_in 时 |
| P0 | `seal_controller.gd` | `_complete_seal()` (成功) | `SB.SEAL_CLEAR` | 过关 |
| P0 | `seal_controller.gd` | `_complete_seal()` (失败) | `SB.SEAL_FAIL` | 失败 |
| P0 | `score_calculator.gd` | 忍者牌效果触发 | `SB.NINJA_ACTIVATE` | 每张忍者牌触发 |
| P0 | `ui_manager.gd` / `hand_interaction.gd` | 交换完成 | `SB.SWAP` | ~0.1s 极短 |
| P1 | `game_manager.gd` | `_on_seal_started()` | `SB.BOSS_REVEAL` | Boss 名浮现同帧 |
| P1 | `game_manager.gd` | `_on_seal_started()` | `SB.BOSS_FINAL_LAYER` | 仅 `barrier_num == 8` |
| P1 | `game_manager.gd` | `_on_seal_started()` | MusicManager BGM 变奏切换 | `MusicManager.set_game_variation(barrier_num)` |
| P1 | `shop_ui.gd` | `_play_entrance()` | `SB.SHOP_ENTER` + `MusicManager.play_shop_bgm()` | 进入商店 |
| P1 | `shop_ui.gd` | `_on_ability_purchase()` | `SB.UI_COIN` | 购买忍者 |
| P1 | `shop_ui.gd` | `_on_item_purchase()` | `SB.ITEM_PURCHASE` | 购买消耗品 |
| P1 | `shop_ui.gd` | `_on_reroll_pressed()` | `SB.SHOP_REROLL` | 刷新 |
| P1 | `shop_ui.gd` | `_on_continue_pressed()` | `SB.SHOP_EXIT` | 离开商店 |
| P1 | 经济系统 | `gold_changed` delta > 0 | `SB.UI_COIN` | 产金反馈 |
| P2 | Phase B-C 实装时补充 | TBD | S19-S26 | 消耗品/成长/特殊牌 |

---

## §8 文件命名规范

```
assets/audio/
├── music/
│   ├── start_menu_bgm.ogg          # BGM1 — 主菜单
│   ├── game_bgm_light.ogg          # BGM2a — 游戏 軽 (属性 火/水/風)
│   ├── game_bgm_mid.ogg            # BGM2b — 游戏 中 (属性 雷/土/光)
│   ├── game_bgm_heavy.ogg          # BGM2c — 游戏 重 (属性 暗/无)
│   └── shop_bgm.ogg                # BGM3 — 商店
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
    │   ├── discard.ogg             # S8 — 换牌烟遁（替换）
    │   ├── redraw_pop.ogg          # S8 — 换牌瞬身（新增）
    │   ├── ninja_activate.ogg      # S9 — 忍者激活（替换 bao_activate.ogg）
    │   ├── boss_reveal.ogg         # S11 — Boss 揭晓（新增）
    │   ├── boss_final_layer.ogg    # S12 — 終焉压迫层（新增）
    │   ├── shop_enter.ogg          # S13 — 商店进入（新增）
    │   ├── item_purchase.ogg       # S15 — 消耗品购买（新增）
    │   ├── shop_reroll.ogg         # S16 — 刷新（替换 lottery.ogg）
    │   ├── shop_exit.ogg           # S17 — 商店离开（新增）
    │   └── (P2 音效): enchant_cast / star_upgrade / ritual_pulse / growth_tick / ninja_gear / glass_break / lucky_jingle / banish_fire
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

## §9 附录：已删除/合并的 FanKing 遗留

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
