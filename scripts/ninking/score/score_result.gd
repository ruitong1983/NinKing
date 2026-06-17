class_name ScoreResult
extends RefCounted

## Per-group scoring result from ScoreCalculator.calculate().
## Carries all per-group chips/mult breakdowns for UI display and animation.
##
## Formula:
##   group_score = (card_chips + hand_chips + ench_chips + ninja_chips)
##               × (hand_mult + ench_mult + ninja_mult)
##               × ∏(ninja_x_mult) × ∏(card_x_mult) × ∏(group_xi_x_mult)

var total_score: int = 0
var head_score: int = 0
var mid_score: int = 0
var tail_score: int = 0
var col_scores: Array[int] = []          # v5.0: per-column chip×mult scores (non-散牌 only)
var col_total: int = 0                   # v5.0: sum of all column scores
var global_xi_x_stack: Array[int] = []   # global xi ×mult
# Per-group chips and mult (base + ench + ninja, before ×stack)
var head_chips: int = 0
var head_mult: int = 0
var mid_chips: int = 0
var mid_mult: int = 0
var tail_chips: int = 0
var tail_mult: int = 0
var chips_sum: int = 0
var mult_sum: int = 0
var breakdown: Dictionary = {}
# ── Per-group component breakdown (for test cross-validation) ──
var head_card_chips: int = 0
var head_hand_chips: int = 0
var head_ench_chips: int = 0
var head_ninja_chips: int = 0
var head_hand_mult: int = 0
var head_ench_mult: int = 0
var head_ninja_mult: int = 0
var head_ninja_x_stack: Array = []
var mid_card_chips: int = 0
var mid_hand_chips: int = 0
var mid_ench_chips: int = 0
var mid_ninja_chips: int = 0
var mid_hand_mult: int = 0
var mid_ench_mult: int = 0
var mid_ninja_mult: int = 0
var mid_ninja_x_stack: Array = []
var tail_card_chips: int = 0
var tail_hand_chips: int = 0
var tail_ench_chips: int = 0
var tail_ninja_chips: int = 0
var tail_hand_mult: int = 0
var tail_ench_mult: int = 0
var tail_ninja_mult: int = 0
var tail_ninja_x_stack: Array = []
