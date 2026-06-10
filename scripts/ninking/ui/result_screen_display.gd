class_name ResultScreenDisplay
extends RefCounted

## Displays end-of-action result screens: scoring overlay, seal complete,
## victory, game over, and xi popup.
## Extracted from UIManager.

var _reward_label: Label
var _complete_label: Label
var _victory_label: Label
var _victory_stats_summary: Label
var _game_over_label: Label
var _score_summary: Label
var _hand_name_label: Label
var _score_value_label: Label
var _score_breakdown: Label


func setup(
	reward_label: Label,
	complete_label: Label,
	victory_label: Label,
	victory_stats_summary: Label,
	game_over_label: Label,
	score_summary: Label,
	hand_name_label: Label,
	score_value_label: Label,
	score_breakdown: Label,
) -> void:
	_reward_label = reward_label
	_complete_label = complete_label
	_victory_label = victory_label
	_victory_stats_summary = victory_stats_summary
	_game_over_label = game_over_label
	_score_summary = score_summary
	_hand_name_label = hand_name_label
	_score_value_label = score_value_label
	_score_breakdown = score_breakdown


# ══════════════════════════════════════════
# Seal complete
# ══════════════════════════════════════════

func set_level_complete(gold_reward: int) -> void:
	_reward_label.text = "+%d 金币" % gold_reward
	_complete_label.text = "过关!"


# ══════════════════════════════════════════
# Victory
# ══════════════════════════════════════════

func set_victory(barrier: int, score: int) -> void:
	_victory_label.text = "忍道制霸!"
	_victory_stats_summary.text = "通关! 全%d 结界制霸 · 忍気 %d" % [barrier, score]


# ══════════════════════════════════════════
# Game over
# ══════════════════════════════════════════

func show_game_over(reason: String, barrier: int, score: int) -> void:
	_game_over_label.text = reason
	_score_summary.text = "战绩: 结界 %d · 忍気 %d" % [barrier, score]


# ══════════════════════════════════════════
# Xi popup
# ══════════════════════════════════════════

func show_xi_popup(xis: Array[String]) -> void:
	var text: String = "喜触发: " + ", ".join(xis)
	_score_breakdown.text = text


# ══════════════════════════════════════════
# Scoring result
# ══════════════════════════════════════════

func show_scoring_result(head_eval: HandEvaluator3.EvalResult, mid_eval: HandEvaluator3.EvalResult, tail_eval: HandEvaluator3.EvalResult, total_score: int) -> void:
	var text: String = "影: %s | 瞬: %s | 滅: %s" % [
		CardData.get_hand_type3_name(head_eval.hand_type),
		CardData.get_hand_type3_name(mid_eval.hand_type),
		CardData.get_hand_type3_name(tail_eval.hand_type)
	]
	_hand_name_label.text = text
	_score_value_label.text = "+ %d" % total_score
	_score_breakdown.text = ""
