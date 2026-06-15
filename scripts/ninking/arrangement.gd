class_name Arrangement
extends RefCounted

## A single arrangement of 9 cards into 3 groups × 3 cards (影/瞬/滅).
## Produced by AutoArranger.find_best() or manually set via GameState.

var head: Array[CardData.PlayingCard]   # 影 (weakest)
var mid: Array[CardData.PlayingCard]    # 瞬
var tail: Array[CardData.PlayingCard]   # 滅 (strongest)
var head_eval: HandEvaluator3.EvalResult
var mid_eval: HandEvaluator3.EvalResult
var tail_eval: HandEvaluator3.EvalResult


func _init(h: Array, m: Array, t: Array,
		   he: HandEvaluator3.EvalResult, me: HandEvaluator3.EvalResult,
		   te: HandEvaluator3.EvalResult) -> void:
	head = _to_typed(h)
	mid = _to_typed(m)
	tail = _to_typed(t)
	head_eval = he
	mid_eval = me
	tail_eval = te


## Check if this arrangement satisfies the head ≤ mid ≤ tail constraint.
func is_legal() -> bool:
	return head_eval.strength <= mid_eval.strength and mid_eval.strength <= tail_eval.strength


static func _to_typed(arr: Array) -> Array[CardData.PlayingCard]:
	var result: Array[CardData.PlayingCard] = []
	for item in arr:
		result.append(item as CardData.PlayingCard)
	return result
