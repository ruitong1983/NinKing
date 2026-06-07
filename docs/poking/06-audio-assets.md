# Poking 音频素材管理

> 最后更新: 2026-06-08
> 音频统一由 `scripts/config/sound_bank.gd` 管理，外部通过 `GlobalTweens.play_sfx(SB.XXX)` 调用。

---

## 1. BGM

| SoundBank 常量 | 文件 | 路径 | 用途 | 使用场景 | 状态 |
|---|---|---|---|---|---|
| `MENU_BGM` | `start_menu_bgm.wav` | `assets/audio/music/` | 主菜单背景音乐 | 主菜单 / 结算界面 | ✅ 占位 (FanKing) |
| `GAME_BGM` | `main_game_bgm.wav` | `assets/audio/music/` | 游戏背景音乐 | 关卡进行中 | ✅ 占位 (FanKing) |
| — | — | — | 商店 BGM | 商店界面 | ❌ 缺失 (P3) |

---

## 2. 游戏 SFX

| SoundBank 常量 | 文件 | 路径 | 用途 | 触发时机 | 状态 |
|---|---|---|---|---|---|
| `DRAW` | `draw.ogg` | `sound/game/` | 抽牌 | 牌库补牌到手中 | ✅ 占位 (FanKing) |
| `DISCARD` | `discard.ogg` | `sound/game/` | 弃牌 | 换牌时丢弃选中卡牌 | ✅ 占位 (FanKing) |
| `DEAL` | `deal.ogg` | `sound/game/` | 发牌 | 开局发 8 张手牌 | ✅ 占位 (FanKing) |
| `SELECT` | `select.ogg` | `sound/game/` | 选牌 | 点击手牌选中/取消 | ✅ 占位 (FanKing) |
| `SWAP` | `swap.ogg` | `sound/game/` | 换牌 | 执行换牌操作 | ✅ 占位 (FanKing) |
| `HU` | `hu.ogg` | `sound/game/` | 牌型揭示 | 出牌后揭示牌型 | ✅ 占位 (FanKing) |
| `YAKU_REVEAL` | `yaku_reveal.ogg` | `sound/game/` | 牌型计分 | 揭示牌型分值 | ✅ 占位 (FanKing) |
| `COUNT_TICK` | `count_tick.ogg` | `sound/game/` | 计分跳动 | 分数逐帧累加 | ✅ 占位 (FanKing) |
| `BAO_ACTIVATE` | `bao_activate.ogg` | `sound/game/` | 小丑激活 | 小丑牌效果触发 | ✅ 占位 (FanKing) |
| `LEVEL_CLEAR` | `level_clear.ogg` | `sound/game/` | 过关 | 累计得分 ≥ 目标 | ✅ 占位 (FanKing) |
| `LEVEL_FAIL` | `level_fail.ogg` | `sound/game/` | 失败 | 次数用完未达标 | ✅ 占位 (FanKing) |
| `EXPLOSION` | `explosion.ogg` | `sound/game/` | 特效爆炸 | VFX 爆炸动画 | ✅ 占位 (FanKing) |
| `LOTTERY` | `lottery.ogg` | `sound/game/` | 商店摇奖 | 商店进货展示 | ✅ 占位 (FanKing) |
| `HOVER` | `hover.ogg` | `sound/game/` | 悬停 | 鼠标悬停可交互元素 | ✅ 占位 (FanKing) |

---

## 3. UI SFX

| SoundBank 常量 | 文件 | 路径 | 用途 | 触发时机 | 状态 |
|---|---|---|---|---|---|
| `UI_CLICK` | `ui_click.ogg` | `sound/ui/` | 按钮点击 | 通用 UI 按钮按下 | ✅ 占位 (FanKing) |
| `UI_COIN` | `ui_coin.ogg` | `sound/ui/` | 金币 | 金币增加 / 购买 | ✅ 占位 (FanKing) |
| `UI_ERROR` | `ui_error.ogg` | `sound/ui/` | 错误提示 | 操作无效 / 余额不足 | ✅ 占位 (FanKing) |

---

## 4. 音频规格要求

| 参数 | BGM | SFX |
|---|---|---|
| 格式 | WAV / OGG | OGG |
| 采样率 | 44100 Hz | 44100 Hz |
| 声道 | 立体声 | 单声道 |
| 位深 | 16-bit | 16-bit |
| 时长 | 循环无缝 | < 3 秒 |
| 音量 | -12 dB | -6 dB (峰值) |

---

## 5. 待补充音效

| 素材 | 用途 | 优先级 | 说明 |
|---|---|---|---|
| 商店 BGM | 商店界面背景音乐 | P3 | 轻松/欢快风格, 30s 循环 |
| 出牌音效 | 点击"出牌"按钮 | P2 | 当前可能复用 HU |
| 卡牌翻转 | 换牌时卡牌翻转动画音效 | P2 | 配合 Tween 动画 |

---

## 6. 扑克专属替换计划

> **当前全部音效来自 FanKing 麻将游戏占位，正式发布前需替换为扑克主题音效。**

| 原 FanKing 音效 | 替换方向 | 优先级 |
|---|---|---|
| `draw` / `deal` | 扑克牌滑动/发牌声 | P1 |
| `select` | 扑克牌点击/拿起声 | P1 |
| `swap` / `discard` | 扑克牌丢出/弃牌声 | P1 |
| `hu` / `yaku_reveal` | 牌型揭示音 (保留概念, 换音色) | P1 |
| `count_tick` | 筹码/计分跳动声 | P2 |
| `level_clear` | 过关庆祝音 | P2 |
| `level_fail` | 失败音 (保留概念, 换音色) | P2 |
| `bao_activate` | 小丑激活弹簧/喇叭声 | P2 |
| `ui_click` / `ui_coin` / `ui_error` | 可保留, 替换为更清脆版本 | P3 |
| `explosion` | 可保留 | P3 |
| `lottery` | 商店摇奖/老虎机声 | P2 |
| BGM | 复古爵士 / 钢琴扑克风 | P2 |

---

## 7. 命名规范

- BGM: `{scene}_bgm.{format}` — 如 `shop_bgm.ogg`
- SFX: `sfx_{action}.{format}` — 如 `sfx_card_draw.ogg`
- UI: `ui_{action}.{format}` — 如 `ui_button_click.ogg`
- 全部小写 `snake_case`
