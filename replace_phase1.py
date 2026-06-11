#!/usr/bin/env python3
"""Replace Phase 1 scoring animation with enhanced crescendo version."""
import sys

path = sys.argv[1]

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find Phase 1 block boundaries by markers
MARKER_START = '# ═══ Phase 1: Per-dun sequential reveal'
MARKER_END = 'await get_tree().create_timer(0.55).timeout'

idx_start = content.find(MARKER_START)
if idx_start < 0:
    print("ERROR: Phase 1 start marker not found")
    sys.exit(1)

# Find preceding newline to get clean start of the line
line_start = content.rfind('\n', 0, idx_start) + 1

idx_end = content.find(MARKER_END, idx_start)
if idx_end < 0:
    print("ERROR: Phase 1 end marker not found")
    sys.exit(1)

line_end = idx_end + len(MARKER_END)

old_block = content[line_start:line_end]
print("Old block found, length:", len(old_block))

# Detect indent from the block itself
indent = ''
for c in old_block:
    if c == '\t':
        indent += c
    else:
        break
print(f"Detected indent: {len(indent)} tabs")

T = indent          # base indent (1 tab)
T2 = T + '\t'       # 2 tabs
T3 = T + '\t\t'     # 3 tabs
T4 = T + '\t\t\t'   # 4 tabs
T5 = T + '\t\t\t\t' # 5 tabs

new_block = (
    T + '# ═══ Phase 1: Per-dun sequential reveal — 渐强三幕 ═══\n'
    T + '# 影(轻) → 瞬(中) → 滅(全力). 每墩内逐卡翻牌高亮后爆牌型名.\n'
    T + '# Per-card tick → type label BANG rhythm.\n'
    T + '\n'
    T + 'var dun_evals: Array = [\n'
    T2 + 'play_data.get("head_eval"),\n'
    T2 + 'play_data.get("mid_eval"),\n'
    T2 + 'play_data.get("tail_eval"),\n'
    T + ']\n'
    T + 'var dun_names: Array[String] = ["影", "瞬", "滅"]\n'
    T + 'var dun_type_labels: Array[Label] = [ui.head_type_label, ui.middle_type_label, ui.tail_type_label]\n'
    T + 'var dun_hands: Array[Hand] = [ui.head_cards, ui.middle_cards, ui.tail_cards]\n'
    T + '\n'
    T + '# Save original label states to restore after\n'
    T + 'var _original_texts: Array[String] = []\n'
    T + 'for lbl: Label in dun_type_labels:\n'
    T2 + '_original_texts.append(lbl.text)\n'
    T + '\n'
    T + 'for i: int in range(3):\n'
    T2 + 'var eval: HandEvaluator3.EvalResult = dun_evals[i]\n'
    T2 + 'if eval != null:\n'
    T3 + 'var type_label: Label = dun_type_labels[i]\n'
    T3 + 'var hand_name: String = CardData.get_hand_type3_name(eval.hand_type)\n'
    T3 + 'var hand: Hand = dun_hands[i]\n'
    T3 + '\n'
    T3 + '# ── Per-card stagger flash (三连啼: 速度递降) ──\n'
    T3 + 'var card_stagger: float = [0.06, 0.09, 0.12][i]\n'
    T3 + 'var cards_node: Node = hand.get_node_or_null("Cards")\n'
    T3 + 'if cards_node != null:\n'
    T4 + 'for ci: int in cards_node.get_child_count():\n'
    T5 + 'var card_node: Node = cards_node.get_child(ci)\n'
    T5 + 'if card_node is CanvasItem:\n'
    T5 + '\tGlobalTweens.color_flash(card_node, Color.GOLD, card_stagger)\n'
    T5 + 'GlobalTweens.play_sfx(SB.COUNT_TICK)\n'
    T5 + 'await get_tree().create_timer(card_stagger * 0.7).timeout\n'
    T3 + '\n'
    T3 + '# ── Type label reveal (三幕递进) ──\n'
    T3 + 'type_label.text = "%s: %s" % [dun_names[i], hand_name]\n'
    T3 + 'GlobalTweens.play_sfx(SB.GROUP_REVEAL)\n'
    T3 + 'GlobalTweens.color_flash(type_label, barrier_color, 0.2)\n'
    T3 + '\n'
    T3 + 'match i:\n'
    T4 + '0:  # 影 — 轻快 scale_pop\n'
    T5 + 'GlobalTweens.scale_pop(type_label, 1.2, 0.25)\n'
    T4 + '1:  # 瞬 — 加力 scale_pop + 微震\n'
    T5 + 'GlobalTweens.scale_pop(type_label, 1.4, 0.3)\n'
    T5 + 'GlobalTweens.screen_shake(0.03, 0.02)\n'
    T4 + '2:  # 滅 — 全力 punch_in + 粒子 + 震 + hit_stop\n'
    T5 + 'GlobalTweens.punch_in(type_label, 1.5, 0.3)\n'
    T5 + 'GlobalTweens.burst_particles(\n'
    T5 + '\thand.global_position + hand.size * 0.5,\n'
    T5 + '\t"manga_burst"\n'
    T5 + ')\n'
    T5 + 'GlobalTweens.screen_shake(0.06, 0.04)\n'
    T5 + 'GlobalTweens.do_hit_stop(0.03, 0.02)\n'
    T2 + 'await get_tree().create_timer([0.40, 0.55, 0.65][i]).timeout\n'
)

content = content[:line_start] + new_block + content[line_end:]
with open(path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)
print("REPLACED OK")
