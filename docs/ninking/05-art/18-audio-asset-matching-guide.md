# NinKing 音效自动匹配规范 v3

> **素材包:** Epic Stock Media「Anime Game - Universal Sound Sets Library」(1,433 WAV)
> **目标:** Claude Code CLI 读取本文档后，可**全自动**完成扫描→匹配→筛选→转换→重命名→复制。
> **前置依赖:** `ffprobe` + `ffmpeg` + `python3` + `numpy` + `scipy`（PATH 可用），素材包已解压到 `$PACK_DIR`
>
> **✅ 执行状态:** 2026-06-10 已按 v2 规范执行完成。20/20 需求匹配成功。v3 新增 Phase 0 预检 + 匈牙利算法 + §11 复盘教训。
> **⚠️ 任何人再次执行音频匹配前，必须先读 §11。**

---

## §1 自动化流水线总览

```
Phase 1: 扫描 → 列出素材包全部 .wav + ffprobe duration → scan.log
Phase 2: 匹配 → 按 §3 规则表对每个需求打分排序 → matches.log
Phase 3: 转换 → ffmpeg WAV→OGG + 重命名 + 复制到项目目录
Phase 4: 验证 → 检查全部目标文件存在 + duration 在容许范围
```

**Claude 执行入口:** 用户提供 `PACK_DIR` 路径后，Claude 按本文档规则自主执行全部 4 阶段，无需人工试听。

---

## §2 Phase 1 — 扫描素材包

### 2.1 生成文件清单

```bash
PACK_DIR="E:/GameAssets/Audio/EpicStockMedia_AnimeGame"
find "$PACK_DIR" -name "*.wav" -type f > /tmp/ninking_pack_files.txt
echo "Total WAV files: $(wc -l < /tmp/ninking_pack_files.txt)"
```

### 2.2 获取每个文件的 duration

```bash
# 生成 duration 索引（耗时 ~30s for 1433 files）
> /tmp/ninking_pack_durations.txt
while IFS= read -r f; do
    d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f" 2>/dev/null)
    echo "$d|$f"
done < /tmp/ninking_pack_files.txt >> /tmp/ninking_pack_durations.txt
```

### 2.3 生成可搜索索引

```bash
# 格式: duration_sec|filename_lowercase|full_path
while IFS='|' read -r dur path; do
    base=$(basename "$path" .wav | tr '[:upper:]' '[:lower:]' | tr '_ ' '-')
    dir=$(dirname "$path" | tr '[:upper:]' '[:lower:]')
    echo "$dur|$base|$path|$dir"
done < /tmp/ninking_pack_durations.txt > /tmp/ninking_pack_index.txt
```

### 2.4 核对实际目录结构

```bash
# 列出素材包一级子目录（可能与 UCS 标准有差异，必须实际扫描）
find "$PACK_DIR" -maxdepth 1 -type d | sort
```

---

## §3 Phase 2 — 自动匹配规则

### 3.1 匹配规则数据格式

每条需求定义为一个规则对象：

```yaml
id: S1
target: deal.ogg
target_dir: assets/audio/sound/game/
search_dirs:        # 按优先级排序的搜索目录
  - whooshes
  - movement
  - effect
filename_patterns:  # 正则，越靠前权重越高（匹配 +3 分）
  - 'swish|swoosh|whoosh'
  - 'card|paper|slide|breeze|wind|air'
duration_min: 0.05   # 秒
duration_max: 0.25
duration_ideal: 0.12
duration_weight: 2   # duration 不匹配扣 N 分
neg_patterns:        # 排除正则（命中则跳过）
  - 'heavy|large|deep|boom|explosion|scream'
```

### 3.2 自动打分逻辑

Claude 对每个需求执行以下算法：

```bash
# 1. 收集候选文件（从指定 search_dirs 中按 filename_patterns 匹配）
# 2. 对每个候选计算分数:
#    score = Σ(filename_pattern_match * 3) - Σ(neg_pattern_match * 10) - |duration - duration_ideal| * duration_weight
# 3. 选最高分，输出匹配日志
```

**打分优先级:** 排除词命中 = 直接淘汰 > 关键词命中数 > duration 接近度

---

## §3.3 完整匹配规则表

### P0 — 核心体验（11 个文件）

| id | target | search_dirs (优先级↓) | filename_patterns | dur (s) | neg_patterns | 备注 |
|----|--------|----------------------|-------------------|---------|-------------|------|
| S1 | `deal.ogg` | whooshes, movement, effect | `(swish\|swoosh\|whoosh).*(light\|soft\|short\|fast)` → `(card\|paper\|slide\|breeze\|pass)` → `.*` | 0.05–0.25 | heavy, large, deep, boom, explosion, long, slow | 9连播不烦人，取最短最轻的 |
| S2 | `group_reveal.ogg` | combat, impact, effect, magic/general | `(impact\|hit\|strike\|boom\|thud\|drum).*(short\|medium)` → `(heavy\|power).*hit` → `.*` | 0.15–0.60 | explosion, gun, laser, sword, slash, scream | 需要打击感，但不要武器音 |
| S3 | `count_tick.ogg` | ui, item, effect | `(click\|tap\|tick\|pop).*(short\|light\|quick)` → `(button\|select\|confirm)` → `.*` | 0.01–0.10 | heavy, deep, boom, long, error, deny | 极短清脆 |
| S4a | `xi_trigger.ogg` | magic/general, power-ups, item | `(chime\|bell\|sparkle\|ding\|ring).*(bright\|light\|short)` → `(magic\|success).*(tingle\|twinkle)` → `.*` | 0.15–0.45 | heavy, deep, fanfare, long, dark, evil | 单音叮咚感 |
| S4b | `xi_fanfare.ogg` | power-ups, magic/buff, effect | `(fanfare\|jingle\|success\|triumph\|level-up).*(short\|quick)` → `(power-up\|buff).*(bright)` → `.*` | 0.40–1.20 | fail, dark, evil, loop | 上行华丽感 |
| S5 | `seal_clear.ogg` | power-ups, magic/buff, effect, combat | `(victory\|triumph\|complete\|success\|fanfare)` → `(power-up\|level-up).*(big\|major)` → `.*` | 1.50–3.50 | fail, loop, short | 最长最华丽 |
| S6 | `seal_fail.ogg` | combat, impact, effect | `(fail\|death\|downer\|defeat\|heavy).*(hit\|impact)` → `(dark\|low\|deep).*(boom)` → `.*` | 0.80–2.00 | victory, success, bright, chime, light | 低沉下行 |
| S7 | `swap.ogg` | whooshes, movement, effect, ui | `(swoosh\|swish\|swipe\|slide\|shuffle).*(light\|soft\|short\|quick)` → `(card\|paper).*(move)` → `.*` | 0.03–0.18 | heavy, deep, boom, explosion, long | **最轻最短**，不限次操作 |
| S8a | `discard.ogg` | magic/general, effect, whooshes | `(poof\|puff\|smoke\|vanish\|disappear\|dust)` → `(magic).*(fade\|appear)` → `.*` | 0.10–0.30 | explosion, heavy, boom, fire, scream | "噗"烟遁 |
| S8b | `redraw_pop.ogg` | whooshes, magic/general, movement | `(pop\|appear\|teleport\|materialize\|whoosh).*(in\|quick\|fast)` → `(magic).*(appear\|blink)` → `.*` | 0.08–0.25 | heavy, explosion, vanish, disappear, long | "唰"瞬身出现 |
| S9 | `ninja_activate.ogg` | power-ups, magic/buff, magic/electric | `(activate\|spark\|power-up\|enhance\|buff).*(short\|quick\|light)` → `(electric\|energy).*(pulse\|spark)` → `.*` | 0.15–0.50 | long, fanfare, victory, loop | 金属闪光+嗡鸣 |
| S10 | `ui_click.ogg` | ui, item, effect | `(click\|button\|tap\|confirm\|select).*(short\|light)` → `(press\|trigger).*(ui)` → `.*` | 0.02–0.12 | heavy, deep, long, error, deny, buzz | 操作确认 |

### P1 — 关卡节点 + UI 通用（9 个文件）

| id | target | search_dirs (优先级↓) | filename_patterns | dur (s) | neg_patterns | 备注 |
|----|--------|----------------------|-------------------|---------|-------------|------|
| S11 | `boss_reveal.ogg` | combat, effect, explosions | `(tension\|suspense\|reveal\|ominous\|drum).*(hit\|roll)` → `(heavy\|deep).*(boom\|impact)` → `.*` | 1.50–3.00 | bright, chime, sparkle, magic | 蓄力→重击 |
| S12 | `boss_final_layer.ogg` | environmental, power-auras, magic/general | `(drone\|heartbeat\|dark\|ominous\|rumble\|tension)` → `(ambient\|aura).*(dark\|deep\|evil)` → `.*` | 2.00–5.00 | bright, chime, fanfare, short | 低频嗡鸣 |
| S13 | `shop_enter.ogg` | ui, effect, item | `(open\|enter\|welcome\|reveal\|door).*(light\|soft\|short)` → `(transition\|panel).*(in)` → `.*` | 0.25–0.80 | heavy, combat, explosion, fail, error | 温暖欢迎感 |
| S14 | `ui_coin.ogg` | ui, item, power-ups | `(coin\|cash\|money\|purchase\|kaching).*(short)` → `(collect\|pickup).*(coin\|gold)` → `.*` | 0.15–0.50 | error, deny, heavy | 金币叮当 |
| S15 | `item_purchase.ogg` | item, magic/buff, power-ups | `(magic\|shimmer\|enchant\|treasure\|star).*(pickup\|get)` → `(item\|special).*(acquire)` → `.*` | 0.20–0.60 | coin, cash, heavy, error | 比S14多魔法感 |
| S16 | `shop_reroll.ogg` | whooshes, effect, movement | `(shuffle\|spin\|refresh\|whoosh).*(fast\|quick\|short)` → `(card\|deck).*(shuffle)` → `.*` | 0.25–0.70 | heavy, explosion, deep, long | 洗牌翻飞 |
| S17 | `shop_exit.ogg` | ui, effect, whooshes | `(close\|exit\|shut\|back).*(short\|soft)` → `(transition\|panel).*(out)` → `.*` | 0.20–0.60 | heavy, explosion, combat | 与S13对称 |
| UIE | `ui_error.ogg` | ui, effect, combat | `(error\|deny\|buzz\|wrong\|invalid).*(short)` → `(block\|reject\|bounce)` → `.*` | 0.08–0.30 | bright, sparkle, success, chime | "嘟"否定 |

---

## §3.4 关键词评分权重

匹配时对文件名逐词计分（大小写不敏感）：

| 匹配类型 | 分数 | 说明 |
|---------|------|------|
| 第一个 pattern 组命中 | +5 | 最佳匹配（精确语义） |
| 第二个 pattern 组命中 | +3 | 次选匹配（接近语义） |
| 第三个 pattern 组命中（fallback `.*`） | +1 | 兜底（在正确目录即可） |
| 每个 neg_pattern 命中 | -20 | 直接淘汰（除非无其他候选） |
| duration 偏离 ideal 每 0.1s | -1 | 越接近 ideal 分数越高 |
| 文件在 `search_dirs[0]` | +2 | 首选目录加分 |
| 文件在 `search_dirs[1]` | +1 | 次选目录加分 |

**选优逻辑:** 
- `score >= 5` → 高置信度，直接选用
- `score 2-4` → 中置信度，选用但记录 warning
- `score <= 1` → 低置信度，选用但记录 ⚠️ 建议人工复听
- 候选 0 → 记录 ❌ 标记为 MISSING

---

## §4 Phase 3 — 转换与复制

### 4.1 转换命令模板

```bash
# 对每个匹配结果：
SRC="<匹配到的源文件完整路径>"
DST="E:/01 Code/Godot_v4.6.2/NinKing/<target_dir>/<target_filename>"
ffmpeg -i "$SRC" -c:a libvorbis -q:a 6 "$DST" -y
```

### 4.2 转换参数

| 参数 | 值 | 原因 |
|------|-----|------|
| codec | `libvorbis` | Godot 推荐 |
| quality | `-q:a 6` | ~192kbps，游戏 SFX 黄金平衡 |
| overwrite | `-y` | 允许覆盖（重复运行时） |
| 采样率 | 不指定（保持源 96kHz） | Godot 会做运行时混音 |

### 4.3 旧占位文件清理

新文件覆盖写入时自动替换。不再需要的旧 FanKing 文件名（`hu.ogg`/`yaku_reveal.ogg`/`bao_activate.ogg`/`level_clear.ogg`/`level_fail.ogg`/`lottery.ogg`/`draw.ogg`）保留在磁盘上，待 `sound_bank.gd` 更新后手动删除或放入 `legacy/` 归档。

---

## §5 Phase 4 — 验证

### 5.1 文件存在性检查

```bash
# 列出所有期望的目标文件
EXPECTED=(
    "assets/audio/sound/game/deal.ogg"
    "assets/audio/sound/game/group_reveal.ogg"
    "assets/audio/sound/game/count_tick.ogg"
    "assets/audio/sound/game/xi_trigger.ogg"
    "assets/audio/sound/game/xi_fanfare.ogg"
    "assets/audio/sound/game/seal_clear.ogg"
    "assets/audio/sound/game/seal_fail.ogg"
    "assets/audio/sound/game/swap.ogg"
    "assets/audio/sound/game/discard.ogg"
    "assets/audio/sound/game/redraw_pop.ogg"
    "assets/audio/sound/game/ninja_activate.ogg"
    "assets/audio/sound/game/boss_reveal.ogg"
    "assets/audio/sound/game/boss_final_layer.ogg"
    "assets/audio/sound/game/shop_enter.ogg"
    "assets/audio/sound/game/item_purchase.ogg"
    "assets/audio/sound/game/shop_reroll.ogg"
    "assets/audio/sound/game/shop_exit.ogg"
    "assets/audio/sound/ui/ui_click.ogg"
    "assets/audio/sound/ui/ui_coin.ogg"
    "assets/audio/sound/ui/ui_error.ogg"
)
PROJ="E:/01 Code/Godot_v4.6.2/NinKing"
for f in "${EXPECTED[@]}"; do
    if [ -f "$PROJ/$f" ]; then
        d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$PROJ/$f" 2>/dev/null)
        echo "✅ $f (${d}s)"
    else
        echo "❌ MISSING: $f"
    fi
done
```

### 5.2 Duration 验证

对照 §3.3 规则表的 `dur` 列，检查每个文件实际 duration 是否在 `duration_min` ~ `duration_max` 范围内。超出范围的标记 ⚠️。

---

## §6 Claude 执行协议

### 6.1 用户触发

用户说：**"素材包在 `<路径>`，帮我匹配音效"**

### 6.2 Claude 自动执行步骤

```
Step 0: Phase 0 可行性预检（强制，不可跳过）
    a. 扫描素材包: find + ffprobe 全量获取 duration
    b. 生成统计摘要:
       - duration 分布 (min / p5 / p50 / p95 / max)
       - 目录结构 (实际目录名列表)
       - 文件名高频词 top 30
    c. 对照 §3.3 需求表的 duration 范围:
       - 覆盖率 < 50% 的需求 → 标记 ⚠️ 放宽范围
       - 覆盖率 = 0 的需求 → 标记 ❌ 建议人工寻找或换素材包
    d. 输出可行性报告，用户确认后继续

Step 1: 确认 PACK_DIR 路径存在
Step 2: 执行 §2.1-2.3 扫描命令 → 生成 /tmp/ninking_pack_index.txt
Step 3: 执行 §2.4 → 列出实际目录结构 → 如果与 §7 假设目录名不符，做 fuzzy map
Step 4: 对 §3.3 表中每个需求:
    a. grep 候选文件（按 search_dirs 顺序）
    b. 用 ffprobe duration 过滤
    c. 按 §3.4 权重打分
    d. 用匈牙利算法求全局最优分配（禁止多个需求共用同一源文件）
    e. 记录匹配日志
Step 5: 输出匹配摘要表（每个需求: score + 选中文件 + confidence + top 3 备选）
Step 6: 等待用户确认（或用户说"自动执行"则跳过确认）
Step 7: 执行 §4 转换+复制命令
Step 8: 执行 §5 验证
Step 9: 输出最终报告（✅ N 个 / ⚠️ M 个 / ❌ K 个）
```

### 6.3 人工介入触发条件

| 条件 | 行为 |
|------|------|
| Phase 0 覆盖率 = 0 的需求 | **暂停**，要求用户决策（放宽范围 / 换素材包 / 标记为 MISSING） |
| Phase 0 覆盖率 < 50% 的需求 | 输出 ⚠️ 列表 + 放宽后的范围建议，用户确认后继续 |
| 匈牙利算法无合法解 | 放宽唯一性约束，输出共享文件的需求列表，人工选择 |
| 任意需求 top 1 score <= 1 | 输出候选列表，要求人工选择 |
| 目录名与 §7 假设不符 | 先做 fuzzy map，输出映射表确认 |

---

## §7 素材包实际目录映射

> ⚠️ 以下为**假设结构**（基于 UCS 标准 + itch.io 描述）。
> **实际扫描优先级更高。** Claude 必须先执行 `find "$PACK_DIR" -maxdepth 1 -type d`，再用实际目录名覆盖下表的 `search_dirs` 引用。

### 7.1 假设目录 → 规则表引用

| 规则表 `search_dirs` 名 | 可能的实际目录名（大小写不敏感模糊匹配） |
|--------------------------|------------------------------------------|
| `whooshes` | Whooshes, Whoosh, whoosh, Wooshes, Motion_Whoosh |
| `movement` | Movement, Movements, Motion, Move |
| `effect` | Effect, Effects, FX, Transitions, Stingers |
| `combat` | Combat, Battle, Fight, Melee |
| `impact` | Impact, Impacts, Hits, Strikes |
| `ui` | UI, User_Interface, Menu, Interface |
| `item` | Item, Items, Pickup, Pickups, Collectible |
| `magic` | Magic, Spell, Spells, Magical |
| `magic/general` | Magic/General, Magic_General, Magical/General（如果无子目录则回退到 Magic/ 根） |
| `magic/buff` | Magic/Buff, Magic_Buff, Buff, Buffs |
| `magic/electric` | Magic/Electric, Magic_Electric, Electric, Electricity, Lightning |
| `power-ups` | Power_Ups, PowerUps, Power-Ups, Power_Up, Boost, Charge |
| `explosions` | Explosions, Explosion, Blast, Blasts |
| `environmental` | Environmental, Ambient, Ambience, Atmosphere, Environment |
| `power-auras` | Power_Auras, PowerAuras, Auras, Aura |

### 7.2 Fuzzy Map 自动生成

```bash
# 当扫描到的实际目录名与假设不匹配时，Claude 使用以下逻辑:
# 1. 取实际目录名的 lowercase 版本
# 2. 去掉下划线/连字符 → 纯字母
# 3. 与 §7.1 的「可能的实际目录名」列做包含匹配
# 4. 若匹配成功 → 使用实际目录名替换 search_dirs 引用
# 5. 若匹配失败 → 标记该目录为 UNMAPPED，跳过其中文件
```

---

## §8 由本文档衍生的后续任务

匹配完成后，Claude 自动衔接以下工作：

| 步骤 | 文件 | 内容 |
|------|------|------|
| L2 | `scripts/config/sound_bank.gd` | 更新 17 个旧 preload + 新增 ~10 个常量，旧常量保留 alias |
| L3 | `game_manager.gd` / `seal_controller.gd` / `shop_ui.gd` / `hand_interaction.gd` | 按 `15-sound-design-plan.md` §7 接线速查表添加 `play_sfx()` 调用 |
| C8 | `sound_bank.gd` | 忍者主题常量重命名（HU→GROUP_REVEAL, YAKU_REVEAL→XI_TRIGGER 等） |

---

## §9 附录：不依赖素材包的备选清单

如果某需求在 Anime Game 包中 score <= 1（找不到好匹配），按以下顺序回退：

| 需求 | 回退来源 | 搜索方式 |
|------|---------|---------|
| 和风打击音（S2/S5/S11） | 効果音ラボ (soundeffect-lab.info) | 戦闘 → 剣・刀 / 攻撃 |
| 清脆 chime（S4a/S15） | 効果音ラボ | 演出・アニメ → 閃光 / 魔法 |
| BGM 变奏（BGM2a/b/c） | DOVA-SYNDROME (dova-s.jp) | 搜索 "和風" "戦闘" "緊迫" |
| 太鼓/铃（S2 备选） | freesound.org | 搜索 "taiko hit" / "japanese bell" |

效果音ラボ文件为 MP3 格式，需同様用 ffmpeg 转 OGG。Claude 可用 `WebFetch` 工具抓取类别页面获取下载链接。

---

## §10 执行日志 — 2026-06-10

### 执行环境

| 项 | 值 |
|----|-----|
| PACK_DIR | `E:/01 Code/Godot_v4.6.2/Anime_Game_24bit/Anime_Game_24bit/Anime_Game_24bit` |
| 机器 | Windows 11, bash (Git for Windows) |
| ffprobe | 可用 |
| ffmpeg | 可用 (libvorbis) |
| 执行模式 | 半自动（Phase 1-2 自动打分 → 人工去重确认 → Phase 3-4 自动转换验证） |

### Phase 1 扫描结果

| 步骤 | 命令 | 结果 |
|------|------|------|
| 1.1 文件清单 | `find -name "*.wav"` | 1,433 WAV |
| 1.2 duration 扫描 | `ffprobe` 全量 1,433 文件 | 1,433/1,433 获取成功 |
| 1.3 索引生成 | awk 联合 duration + 路径 | `/tmp/ninking_final_verified.txt` |
| 1.4 实际目录 | Combat, Effect, Emote, Environmental, Explosions, Impact, Item, Lasers Guns, Magic/{Buff,Electric,Fire,General,Water}, Misc, Movement, Power Auras, Power Ups, UI, Whooshes | 17 目录 |

### Phase 2 匹配摘要

| 需求 | 目标文件 | 匹配分数 | 置信度 | 选中源文件 |
|------|---------|---------|--------|-----------|
| S1 | deal.ogg | 5 | 🟡 中 | WHSH_Movement Blink Quick Swish 01 |
| S2 | group_reveal.ogg | 5 | 🟢 高 | IMPT_Combat Cute Punch Pow Impact 01 |
| S3 | count_tick.ogg | 4 | 🟡 中 | UI_Scifi Blip Short 01 |
| S4a | xi_trigger.ogg | 4 | 🟡 中 | MGB_Magic Buff Shimmer 01 |
| S4b | xi_fanfare.ogg | 6 | 🟢 高 | PUP_Power Up Success 01 |
| S5 | seal_clear.ogg | 4 | 🟡 中 | PUP_Bright Success Shimmer 01 |
| S6 | seal_fail.ogg | 4 | 🟡 中 | IMPT_Heavy Muffled Impact 01 |
| S7 | swap.ogg | 5 | 🟡 中 | WHSH_Movement Blink Swish 02 |
| S8a | discard.ogg | 4 | 🟡 中 | MGB_Magic Pop Shimmer 03 |
| S8b | redraw_pop.ogg | 4 | 🟡 中 | WHSH_Effect Blink Dash Flicker 01 |
| S9 | ninja_activate.ogg | 4 | 🟡 中 | MGE_Magic Electric Spark Flicker 01 |
| S10 | ui_click.ogg | 4 | 🟡 中 | UI_Scifi Blip 03 |
| S11 | boss_reveal.ogg | 7 | 🟢 高 | EXP_Dark Ominous Reveal 01 |
| S12 | boss_final_layer.ogg | 4 | 🟡 中 | MGG_Magic General Ominous Debuff Shimmer 01 |
| S13 | shop_enter.ogg | 4 | 🟡 中 | ITM_Collect Acquire Bright 01 |
| S14 | ui_coin.ogg | 4 | 🟡 中 | UI_Clean Glass Tap 01 |
| S15 | item_purchase.ogg | 6 | 🟢 高 | ITM_Loot Chest Equip Gain 01 |
| S16 | shop_reroll.ogg | 4 | 🟡 中 | WHSH_Movement Smooth Slide Swish 01 |
| S17 | shop_exit.ogg | 4 | 🟡 中 | WHSH_Movement Quick Slide Tight Filter 04 |
| UIE | ui_error.ogg | 4 | 🟡 中 | MGE_Magic Electric Buzzing Malfunction 01 |

### 人工去重日志

初次自动匹配发现多处冲突，手动解决：

| 冲突 | 解决方式 |
|------|---------|
| S16 = S17 (同一源文件) | S17 改配同系列不同变体 (04 vs 01) |
| S3/S10/S13/S14/S17/UIE 全部倾向 UI_Scifi Blip | 手动分配不同 UI 文件和系列变体 |
| S1/S7 同系列 whoosh | 分配不同变体 (01 vs 02) |
| S4a/S8a 同系列 magic buff | 分配不同变体 (01 vs 03) |

### Phase 3 转换

```bash
# 统一转换命令
ffmpeg -i "$SRC" -c:a libvorbis -q:a 6 "$DST" -y -loglevel error
```
20/20 转换成功，0 失败。

### Phase 4 验证

- 20/20 目标文件存在 ✅
- 全部 duration 在扩展后的容许范围内
- Godot 编辑器 `reload_project` 完成，新 .ogg 可被引擎识别

### 执行偏差 vs 规范

| 规范要求 | 实际执行 | 原因 |
|---------|---------|------|
| Phase 2 全自动 | 增加人工去重环节 | awk v1 打分导致多个需求倾向同一文件 |
| duration 范围严格匹配 | 放宽所有范围 | Anime Game 包整体偏长（无 <0.2s 音效） |
| while-read 逐个 ffprobe | 改用 awk 批量 join | Windows bash 下 while 循环极慢 |
| 规则表 duration 目标 0.05-0.25s | 实际 0.25-0.59s | S1 deal 包内最短 whoosh 为 0.58s |

### 规范修正 (v3，已并入 §11)

原 4 条修正建议已合并至 §11 防护机制中。

---

## §11 复盘教训与防护机制

> **来源:** V23 执行复盘（2026-06-10），7-9 回合完成 20 需求匹配。
> **目的:** 避免下次同类任务重蹈覆辙。**每次执行音频匹配前，必须先读本章。**

### 11.1 六条核心教训

| # | 教训 | 一句话 | 本次代价 |
|---|------|--------|---------|
| **L1** | **文本匹配 ≠ 听觉匹配** | 文件名是素材包作者的命名习惯，不是客观音色描述。同一个 "click" 可能是机械声、气泡声、电子合成音。正则无法区分 | 多个 UI 音匹配到"气泡按钮声"而非点击声 |
| **L2** | **规范先于素材 = 纸上谈兵** | 在拿到素材包之前写的 duration 范围和目录假设，与实际包内容严重脱节（包内无 <0.2s 音效 vs 规范要求 0.05s） | 2-3 轮浪费在反复放宽 duration 范围 |
| **L3** | **贪心算法在候选重叠时退化** | 每条需求独立选最高分 → 6 条需求全选同一个文件。必须用匈牙利算法做全局最优分配 | 人工去重 5 处冲突，最密集的一条文件被 6 个需求争抢 |
| **L4** | **置信度标签未经校准 = 虚假信心** | score ≥ 5 标"高置信度"是基于关键词命中数，不是基于实际听感。S11 高置信度是运气好（文件名恰好描述准确），不是方法论成功 | 标签误导决策，低分项可能实际听感更好 |
| **L5** | **没有 Phase 0 = 边飞边修** | 执行协议从扫描开始，没有"这个包能满足需求吗？"的事前检查。正确的第一步是跑统计摘要 vs 需求对照 | 跑完 Phase 1-2 才发现根本问题，回退成本翻倍 |
| **L6** | **Windows bash 不适合 per-file 循环** | while-read 每行 fork 子进程，1433 文件 × 3 进程 = 极慢。awk 批量处理是唯一正确选择 | Phase 1 分三次才凑齐全部 duration |

### 11.2 AI 执行规范的铁律

> **以下三条是写给人/AI 协作规范的硬规则，违反则下次必然重蹈覆辙。**

#### 铁律 1：规范的写法决定了执行的质量

| 禁止 | 替代 |
|------|------|
| "需要打击感" | `spectral_centroid < 4000Hz AND attack_time < 50ms` |
| "清脆叮咚感" | 导出 top 3 候选的 1s preview → 人工试听 |
| "最长最华丽" | `duration > 1.5s AND rms_energy > -15dB` |
| "瞬身出现" | 同"叮咚感" — 主观感受必须人工确认 |

**原则:** 如果一条标准无法用 `ffprobe` / `librosa` / `essentia` 客观测量，它就是**人类判断**，必须走人工试听流程，不能用正则近似。

#### 铁律 2：素材包先行

```
错误流程: 写规范 → 买素材 → 执行匹配 → 撞墙 → 修规范
正确流程: 买素材 → 跑 Phase 0 统计 → 对照需求写/修规范 → 执行匹配
```

Phase 0 必须输出三个数字，缺一不可：

| 统计量 | 含义 | 阈值 |
|--------|------|------|
| **duration 覆盖率** | 需求 duration 范围内有多少候选 | < 50% → 必须放宽 |
| **关键词命中率** | 需求关键词在文件名中的命中比例 | < 20% → 需要新增关键词或换目录 |
| **唯一性风险指数** | 共享同一 top 候选的需求数 / 总需求数 | > 0.3 → 必须用匈牙利算法 |

#### 铁律 3：全局优化，不贪心

匹配问题的数学本质是 **Assignment Problem**（二分图最大权匹配）：

- **禁止** 对每条需求独立 `grep | sort | head -1`
- **必须** 构建 20×N 代价矩阵，用匈牙利算法 (`linear_sum_assignment`) 求全局最优
- **硬约束** 一个源文件最多分配给一个需求

参考实现框架（Python）：

```python
import numpy as np
from scipy.optimize import linear_sum_assignment

def build_cost_matrix(requirements, candidates):
    """构建 M×N 代价矩阵，越低越好"""
    M, N = len(requirements), len(candidates)
    cost = np.full((M, N), 999.0)  # 默认极大代价 = 不可匹配
    
    for i, req in enumerate(requirements):
        for j, cand in enumerate(candidates):
            if not meets_hard_constraints(req, cand):
                continue  # 保持 999 = 不可匹配
            cost[i, j] = (
                - keyword_score(req, cand) * 10      # 关键词命中（越高越好 → 取负）
                + duration_penalty(req, cand) * 3     # duration 偏离惩罚
                + dir_mismatch_penalty(req, cand) * 2 # 目录不匹配惩罚
            )
    return cost

# 匈牙利算法求全局最优
row_ind, col_ind = linear_sum_assignment(cost_matrix)
```

### 11.3 执行前强制检查表

> **每次音频匹配任务，在写第一行代码之前，逐条确认以下清单。全部 ✅ 才能进入 Phase 0。**

| # | 检查项 | 状态 |
|---|--------|------|
| 1 | 素材包已获取并解压到本地 | ⬜ |
| 2 | 需求表（类似 §3.3）已有，每条有明确的功能描述和 duration 预期 | ⬜ |
| 3 | `ffprobe` + `ffmpeg` 可用（`which ffprobe ffmpeg`） | ⬜ |
| 4 | Python 3 + `numpy` + `scipy` 可用（匈牙利算法） | ⬜ |
| 5 | Windows 环境已确认：脚本用 awk 或 Python，禁止 per-file 子进程循环 | ⬜ |
| 6 | 输出目录已确认（`/tmp/` vs `/e/tmp/` 映射已处理） | ⬜ |
| 7 | 人工试听流程已安排（preview 片段导出命令已就绪） | ⬜ |

### 11.4 下次执行的标准流程

```
Phase 0: 可行性预检 (10min)
  ├─ find + ffprobe 全量 → duration 分布直方图
  ├─ 文件名高频词 top 30 vs 需求关键词 → 覆盖率
  ├─ 目录结构 vs 规范假设 → fuzzy map
  └─ 输出: 可行性报告（覆盖率/风险/建议调整）→ 用户确认

Phase 1: 扫描 (5min)
  └─ awk 批量 join → pack_profile.json（不写 while-read）

Phase 2: 匹配 (一次跑完，不迭代)
  ├─ Python 构建代价矩阵
  ├─ 匈牙利算法全局最优分配
  └─ 输出: assignments.json + top-3 备选

Phase 2b: 人工试听 (仅边缘 case)
  ├─ ffmpeg 导出 top-3 的 1s preview OGG
  └─ 人听 → 选择 → 更新 assignments.json

Phase 3: 转换 (全自动)
  └─ ffmpeg WAV→OGG libvorbis -q:a 6

Phase 4: 验证 (全自动)
  └─ 文件存在 + duration 范围检查
```

### 11.5 已知工具链限制

| 限制 | 影响 | 缓解 |
|------|------|------|
| 无 `librosa` / `essentia` | 无法做频谱/attack/rms 客观分析 | 匹配仍基于文本+duration；关键需求走人工试听 |
| Windows bash while-read 慢 | 逐文件处理不可行 | awk 或 Python 批量处理 |
| Write/Bash 路径不一致 | `/tmp/` 映射混淆 | 统一用项目内 `.tmp/` 目录 |
| AI 无法试听 | 主观音色判断不可能 | 导出 preview 片段给人听；客观标准用 duration + 目录 + 关键词 |

### 11.6 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v1 | 2026-06-10 (初版) | 初始匹配规范，基于素材包假设编写 |
| v2 | 2026-06-10 (执行前) | 补充 §6 执行协议 + §7 目录映射 + §8 后续任务 |
| v3 | 2026-06-10 (执行后) | 基于实际执行结果：§6 增加 Step 0 Phase 0 预检 + 匈牙利算法硬约束 + §11 六条教训 + 铁律 + 检查表 + 标准流程。**任何人再次执行音频匹配前，必须先读 §11。** |
