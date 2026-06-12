# 忍者牌测试方案 — 样稿

> **日期:** 2026-06-12 | **范围:** 无条件通用(2卡) + 组别定向(2卡) = 10 个测试用例
> **目的:** 确认 CSV 格式、字段布局、计算逻辑后再批量产出全部 ~120+ 行

---

## 一、CSV 列定义（54列）

每行 = 一个完整测试用例，列出全部计算中间值以便核验。

```
列1-5:   card_id,card_name,rarity,test_no,test_desc
列6-8:   head_cards,mid_cards,tail_cards
列9-14:  head_type,mid_type,tail_type, head_type_code,mid_type_code,tail_type_code
列15-22: col0_type,col1_type,col2_type, col0_x,col1_x,col2_x,col_x_stack,xi_triggered
列23:    triggered                  ← 该忍者是否触发(true/false)
列24-32: nc_head_chips,nc_head_mult,nc_head_x, nc_mid_chips,nc_mid_mult,nc_mid_x, nc_tail_chips,nc_tail_mult,nc_tail_x
                                   ← 忍者牌对各组的chips/mult/×mult贡献
列33-38: head_card_chips,head_hand_chips,head_chips_total, head_hand_mult,head_mult_total, head_score
列39-44: mid_card_chips,mid_hand_chips,mid_chips_total, mid_hand_mult,mid_mult_total, mid_score
列45-50: tail_card_chips,tail_hand_chips,tail_chips_total, tail_hand_mult,tail_mult_total, tail_score
列51-54: total_raw,col_x_product,xi_x_product,final_score
```

---

## 二、10 个测试用例详解

### 符号说明
- `无忍→有忍` = 无忍者时得分 → 带该忍者时得分
- ✅ Δ = 效果验证差额

### 2.1 n_001 手里剑 — unconditional +10 chips 到全组

| 字段 | T1 全散牌基准 | T2 混牌型 |
|------|:-----------:|:--------:|
| test_desc | 全散牌+列2同花顺×16验证+10chips | 头散+中散+尾同花顺+无列分 |
| head_cards | ♣5 ♥9 ♠3 | ♠2 ♥4 ♣7 |
| mid_cards | ♦6 ♥10 ♣4 | ♠5 ♥6 ♦9 |
| tail_cards | ♣2 ♥8 ♦A | ♠J ♥Q ♦K |
| head_type | 散牌(0) | 散牌(0) |
| mid_type | 散牌(0) | 散牌(0) |
| tail_type | 散牌(0) | 同花顺(4) |
| col0/1/2 | 散/同花顺/散 | 散/散/散 |
| col_x_stack | [16] | [] |
| xi | (无) | (无) |
| head_chips | 17+5=22→**32** | 13+5=18→**28** |
| head_mult | 1→**1** | 1→**1** |
| **head_score** | **22→32** | **18→28** |
| mid_chips | 20+5=25→**35** | 20+5=25→**35** |
| mid_mult | 1→**1** | 1→**1** |
| **mid_score** | **25→35** | **25→35** |
| tail_chips | 21+5=26→**36** | 30+50=80→**90** |
| tail_mult | 1→**1** | 5→**5** |
| **tail_score** | **26→36** | **400→450** |
| total_raw | 73→**103** | 443→**513** |
| col_x_product | ×16 | ×1 |
| **final_score** | **1,168→1,648** | **443→513** |
| ✅ Δ | (+30chips)×16=+480 ✓ | (+10+10+50)=+70 ✓ |

### 2.2 n_002 苦无 — unconditional +4 mult 到全组

| 字段 | T1 头豹子+列豹子×32 | T2 全散牌纯+mult |
|------|:-----------------:|:--------------:|
| test_desc | 头豹子×大列分,验证+4mult | 三组散牌×全×1,纯+4mult |
| head_cards | ♠Q ♥Q ♦Q | ♠2 ♥5 ♦9 |
| mid_cards | ♠5 ♥6 ♣7 | ♣4 ♠7 ♥10 |
| tail_cards | ♦8 ♥9 ♣10 | ♣3 ♠6 ♥8 |
| head_type | 豹子(5) | 散牌(0) |
| mid_type | 顺子(2) | 散牌(0) |
| tail_type | 顺子(2) | 散牌(0) |
| col0/1/2 | 散/散/豹子 | 散/散/散 |
| col_x_stack | [32] | [] |
| xi | (无) | (无) |
| head_chips | 30+100=130→**130** | 16+5=21→**21** |
| head_mult | 8→**+4=12** | 1→**+4=5** |
| **head_score** | **1,040→1,560** | **21→105** |
| mid_chips | 18+20=38→**38** | 21+5=26→**26** |
| mid_mult | 3→**+4=7** | 1→**+4=5** |
| **mid_score** | **114→266** | **26→130** |
| tail_chips | 27+20=47→**47** | 17+5=22→**22** |
| tail_mult | 3→**+4=7** | 1→**+4=5** |
| **tail_score** | **141→329** | **22→110** |
| total_raw | 1,295→**2,155** | 69→**345** |
| col_x_product | ×32 | ×1 |
| **final_score** | **41,440→68,960** | **69→345** |
| ✅ Δ | head+520,mid+152,tail+188,总+860×32=+27,520 ✓ | +276=(21+26+22)×4 ✓ |

### 2.3 n_g01 虎头 — +5 mult 仅头组, 条件: 头≤对子(hand_type≤1)

| 字段 | T1 触发:头散牌 | T2 边界触发:头对子 | T3 不触发:头顺子 |
|------|:------------:|:---------------:|:--------------:|
| test_desc | 头散牌(0)≤对子→触发 | 头对子(1)≤对子→触发 | 头顺子(2)>对子→不触发 |
| head_cards | ♠9 ♥10 ♣Q | ♠8 ♥8 ♣J | ♠5 ♥6 ♦7 |
| mid_cards | ♠8 ♥8 ♣J | ♠9 ♥10 ♣Q | ♣9 ♥10 ♠J |
| tail_cards | ♦J ♦Q ♦K | ♠K ♥♠？ |

Wait, I'm using duplicate ranks. In T1 head has ♣Q and mid has ♠8 ♥8 ♣J... and tail has ♦J ♦Q ♦K. So I'm using J, Q, and 8 multiple times. Different suits is fine! Let me check:

T1: head uses ♠9 ♥10 ♣Q. mid uses ♠8 ♥8 ♣J. tail uses ♦J ♦Q ♦K.
- Q: ♣Q(head) and ♦Q(tail) — different suits, OK
- J: ♣J(mid) and ♦J(tail) — different suits, OK
- 8: ♠8 ♥8(mid) — same rank OK, different suits OK
- No other duplicates ✓

T2: head ♠8 ♥8 ♣J. Wait, already used ♠8 ♥8 ♣J in T1 mid! That's a problem if I keep both T1 and T2 as different tests. But since these are separate test cases (different rows), they don't share a card pool. Each row is its own 52-card pool.

So for T2 I need to use different cards. Let me redesign.

Actually, for a sample showing format, let me just clearly separate them.

Let me entirely redesign both T2 and T3 for n_g01 with fresh cards.

**n_g01 T2 — 头对子(边界触发):**
```
head: ♣J ♦J ♥3   → 对子J hand_type=1 ≤1 ✅
mid:  ♠4 ♥6 ♣8   → 散牌 hand_type=0
tail: ♦Q ♦K ♦A   → 同花顺QKA hand_type=4
```

Strength:
head(J,J,3): sorted 3,J(11),J(11) → 对子J. str=1×100+110+11+1(♣)=222
mid(♠4♥6♣8): 4,6,8 → 散牌. str=0+80+6+4(♠)=90
tail(Q,K,A=12,13,14): 同花顺. str=4×100+140+13+2(♦)=555

90 ≤ 222 ≤ 555 → 头=90(原中), 中=222(原头), 尾=555

New arrangement:
```
头: ♠4 ♥6 ♣8    → 散牌 hand_type=0 ✅ ≤1 触发！
中: ♣J ♦J ♥3    → 对子J hand_type=1
尾: ♦Q ♦K ♦A    → 同花顺QKA hand_type=4
```

Hmm, this makes head 散牌 again, not 对子. I want head to be 对子.

Let me rearrange differently so that the 对子 group is the weakest:

Actually, with 对子 strength = 222, and 散牌 = 90, I can't have 对子 be head AND satisfy 头≤中≤尾.

Let me use different cards where 对子 is the weakest:

```
head: ♠2 ♥2 ♣9   → 对子2 hand_type=1 ✅ ≤1
mid:  ♠5 ♥7 ♣10  → 散牌 hand_type=0
tail: ♦J ♦Q ♦K   → 同花顺JQK hand_type=4
```

Strength:
head(2,2,9): 对子2. str=1×100+90+2+4(♠)=196
mid(5,7,10): 散牌. str=0+100+7+4(♠)=111
tail(J,Q,K=11,12,13): 同花顺. str=4×100+130+12+2(♦)=544

111 ≤ 196 ≤ 544 → 头=111(散牌), 中=196(对子2), 尾=544(同花顺)

Again 散牌 is head, not 对子. The issue is that 对子 always has higher strength than 散牌.

Let me think differently. If I want head to be 对子, the lowest strength 对子 must still be lower than or equal to mid's strength. I need mid to also be 对子 (or higher) with higher strength.

```
head: ♠2 ♥2 ♣5   → 对子2, high=5, str=1×100+50+2+4=156
mid:  ♠4 ♥4 ♣8   → 对子4, high=8, str=1×100+80+4+4=188
tail: ♦J ♦Q ♦K   → 同花顺, str=544
```

156 ≤ 188 ≤ 544 ✓

Now head IS 对子! And 对子 ≤ 1 → triggers n_g01.

```
列0: ♠2 ♠4 ♦J → 2,4,11 散牌×1
列1: ♥2 ♥4 ♦Q → 2,4,12 散牌×1
列2: ♣5 ♣8 ♦K → 5,8,13 散牌×1
col_x_stack = []
```

Xi: head not flush(♠♥♣), mid not flush(♠♥♣), tail flush(♦♦♦) → not all 3 → no 三清.
Other xi: none.

Score (no ninja):
head: card=2+2+5=9, hand_chips=10(pair), mult=2 → 19×2=38
mid: card=4+4+8=16, hand_chips=10(pair), mult=2 → 26×2=52
tail: card=10+10+10=30, hand_chips=50(SF), mult=5 → 80×5=400
total_raw = 38+52+400 = 490

With n_g01 (+5 mult head):
head: 19×(2+5)=19×7=133
mid: same=52
tail: same=400
total = 133+52+400 = 585
Δ: 19×5=95 ✓

OK good. Now T3 (不触发):

**n_g01 T3 — 头顺子(不触发):**
```
head: ♠2 ♥3 ♣4   → 顺子2-3-4 hand_type=2 >1 → ❌不触发
mid:  ♠5 ♥6 ♣7   → 顺子5-6-7 hand_type=2
tail: ♦J ♦Q ♦K   → 同花顺JQK hand_type=4
```

Strength:
head(2,3,4): 顺子. str=2×100+40+3+1(♣)=244
mid(5,6,7): 顺子. str=2×100+70+6+4(♠)=280
tail(11,12,13): 同花顺. str=4×100+130+12+2=544

244 ≤ 280 ≤ 544 ✓ Wait, head(244) ≤ mid(280) ≤ tail(544) ✓

列0: ♠2 ♠5 ♦J → 2,5,11 散牌
列1: ♥3 ♥6 ♦Q → 3,6,12 散牌
列2: ♣4 ♣7 ♦K → 4,7,13 散牌
col_x_stack = []

Xi: none (no flush groups)

Score:
head: card=2+3+4=9, hand_chips=20(straight), mult=3 → 29×3=87
mid: card=5+6+7=18, hand_chips=20(straight), mult=3 → 38×3=114
tail: 30+50=80, mult=5 → 80×5=400
total_raw = 87+114+400=601

With n_g01 (❌不触发):
Same as above = 601 ✓

This works! Now I have all 3 for n_g01.

OK, now let me finalize the n_g02 cases and produce the full sample document.

For n_g02 T1 (尾同花顺触发):
```
head: ♠2 ♥5 ♦9   → 散牌 str=0+90+5+4=99
mid:  ♣4 ♥7 ♠10  → 散牌 str=0+100+7+1=108
tail: ♦J ♦Q ♦K   → 同花顺JQK hand_type=4 ✅ ≥4 触发
```
col0=♠2♣4♦J: 2,4,11 散牌
col1=♥5♥7♦Q: 5,7,12 散牌
col2=♦9♠10♦K: 9,10,13 散牌
×1

Score:
head: 16+5=21, ×1=21
mid: 21+5=26, ×1=26
tail: 30+50=80, ×5=400, ×stack=[2]→800
total=21+26+800=847, col×1=847
Δ: tail 400×2-400=+400 ✓

n_g02 T2 (尾豹子触发):
```
head: ♠2 ♥5 ♦9   → 散牌 str=99
mid:  ♣4 ♥7 ♠10  → 散牌 str=108
tail: ♥J ♠J ♦J   → 豹子J hand_type=5 ✅ ≥4 触发
```
col2=♦9♠10♦J: 9,10,11 顺子！×4 (wait, ♦J is rank 11. ♦9=9, ♠10=10, ♦J=11 → consecutive! STRAIGHT_3)

col0=♠2♣4♥J: 2,4,11 散牌×1
col1=♥5♥7♠J: 5,7,11 散牌×1
col2=♦9♠10♦J: 9,10,11 顺子×4
col_x_stack=[4]

Score:
head: 21×1=21
mid: 26×1=26  
tail: 30+100=130, ×8=1,040, ×stack=[2]→2,080
total_raw=21+26+2,080=2,127
col_x_product=4
final=2,127×4=8,508

Without n_g02:
tail: 130×8=1,040
total_raw=21+26+1,040=1,087
final=1,087×4=4,348

Δ: 1,040×4=+4,160 ✓

n_g02 T3 (尾同花❌不触发):
```
head: ♠2 ♥5 ♦9   → 散牌 str=99
mid:  ♣4 ♥7 ♠10  → 散牌 str=108
tail: ♥3 ♥6 ♥8   → 同花(3,6,8) hand_type=3 <4 → ❌不触发
```

col0=♠2♣4♥3: 2,3,4 顺子×4
col1=♥5♥7♥6: 5,6,7 ♥同花顺×16
col2=♦9♠10♥8: 8,9,10 顺子×4
col_x_stack=[4,16,4], product=256

Score:
head: 21×1=21
mid: 26×1=26
tail: 3+6+8+30=47, ×4=188
total_raw=21+26+188=235
final=235×256=60,160

With n_g02 (不触发): 60,160
Δ: 0 ✓

Perfect. Now let me write the clean final document.
