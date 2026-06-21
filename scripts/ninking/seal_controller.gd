## SealController — play execution & seal completion.
class_name SealController
extends RefCounted

const GameRunLogger = preload("res://scripts/ninking/logging/game_logger.gd")

## Play execution & seal completion logic extracted from NinKingGameState.
## All methods are static and take the game state autoload as first parameter.


# ══════════════════════════════════════════
# Play (出牌) — full flow (no animation)
# ══════════════════════════════════════════

static func execute_play(gs) -> void:
	var play_data: Dictionary = prepare_play(gs)
	if play_data.is_empty():
		return
	GameRunLogger.on_play_prepared(play_data)
	finalize_play(gs, play_data)


# ══════════════════════════════════════════
# Play — split for animation (A7)
# ══════════════════════════════════════════

## Pre-compute scoring data without mutating game state.
## Returns Dictionary with keys: score_result, xi_result, seal_effects.
## Returns empty dict if validation fails.
static func prepare_play(gs) -> Dictionary:
	if gs.current_state != NinKingGameState.State.PLAYING:
		return {}
	if gs.plays_remaining <= 0:
		return {}
	var constraint: String = gs.current_seal_lord_effects.get("constraint", "ascending")
	if not gs.current_arrangement or not gs.current_arrangement.is_legal(constraint):
		return {}

	var head_cards: Array[CardData.PlayingCard] = gs.current_arrangement.head
	var mid_cards: Array[CardData.PlayingCard] = gs.current_arrangement.mid
	var tail_cards: Array[CardData.PlayingCard] = gs.current_arrangement.tail

	var head_eval: HandEvaluator3.EvalResult = gs.current_arrangement.head_eval
	var mid_eval: HandEvaluator3.EvalResult = gs.current_arrangement.mid_eval
	var tail_eval: HandEvaluator3.EvalResult = gs.current_arrangement.tail_eval

	# Seal Lord "lowest_group_zero" (封印师)
	var seal_lord_effects: Dictionary = gs.current_seal_lord_effects.duplicate()
	if seal_lord_effects.get("lowest_group_zero", false):
		var scores: Dictionary = {
			"head": head_eval.strength,
			"mid": mid_eval.strength,
			"tail": tail_eval.strength
		}
		var lowest: String = "head"
		var lowest_val: float = scores["head"]
		for group: String in ["mid", "tail"]:
			if scores[group] < lowest_val:
				lowest_val = scores[group]
				lowest = group
		match lowest:
			"head": seal_lord_effects["skip_head"] = true
			"mid":  seal_lord_effects["skip_mid"] = true
			"tail": seal_lord_effects["skip_tail"] = true

	# Column evaluation (3 vertical columns — from arrangement, not auto-arranger)
	var col_evals: Array[HandEvaluator3.EvalResult] = []
	for i in range(3):
		var col_cards: Array[CardData.PlayingCard] = [head_cards[i], mid_cards[i], tail_cards[i]]
		col_evals.append(HandEvaluator3.evaluate(col_cards))

	# Xi detection (no signal emit — deferred to finalize_play)
	var xi_result: XiDetector.XiResult = null
	if not seal_lord_effects.get("no_xi", false):
		xi_result = XiDetector.detect(head_cards, mid_cards, tail_cards,
			head_eval, mid_eval, tail_eval)

	# Score calculation — use consolidated analyze_effects() single pass
	var summary: Dictionary = ScoreCalculator.analyze_effects(
		head_cards, mid_cards, tail_cards,
		head_eval, mid_eval, tail_eval,
		col_evals,
		gs.owned_ninjas,
		gs.gold,
		xi_result
	)
	var score_result: ScoreResult = ScoreCalculator.calculate_with_summary(
		head_cards, mid_cards, tail_cards,
		head_eval, mid_eval, tail_eval,
		col_evals,
		summary,
		gs.star_chart_levels,
		xi_result,
		seal_lord_effects,
	)

	return {
		"score_result": score_result,
		"xi_result": xi_result,
		"seal_effects": seal_lord_effects,
		"col_evals": col_evals,
		# NinKingGameState snapshot — used by AnimationHandler (Phase G refactor)
		"current_score": gs.current_score,
		"target_score": gs.target_score,
		"plays_remaining": gs.plays_remaining,
		"barrier_num": gs.barrier_num,
		"owned_ninjas": gs.owned_ninjas,
		"gold": gs.gold,
			"summary": summary,  # Phase H: pre-computed ninja effects
		"star_chart_levels": gs.star_chart_levels,
		"current_arrangement": {
			"head": gs.current_arrangement.head,
			"mid": gs.current_arrangement.mid,
			"tail": gs.current_arrangement.tail,
			"head_eval": gs.current_arrangement.head_eval,
			"mid_eval": gs.current_arrangement.mid_eval,
			"tail_eval": gs.current_arrangement.tail_eval,
		},
	}


## Apply state mutations after animation completes.
## Handles: decrement plays, add score, discard cards, emit signals,
## then win/lose/continue branching with state transitions.
static func finalize_play(gs, play_data: Dictionary) -> void:
	var score_result: ScoreResult = play_data["score_result"]
	var xi_result: XiDetector.XiResult = play_data["xi_result"]
	var summary: Dictionary = play_data.get("summary", {})

	gs.plays_remaining -= 1
	gs.emit_plays_changed()

	gs.current_score += score_result.total_score

	# Collect all 9 played cards (before discard)
	var all_cards: Array[CardData.PlayingCard] = []
	all_cards.append_array(gs.current_arrangement.head)
	all_cards.append_array(gs.current_arrangement.mid)
	all_cards.append_array(gs.current_arrangement.tail)

	# Economic gold collection (E1-E5)
	_collect_play_gold(gs, all_cards, xi_result, summary)

	# Discard all 9 played cards
	gs.deck_manager.discard(all_cards)

	gs.emit_score_updated()

	# Emit xi signal here (after animation, not during prepare)
	if xi_result and xi_result.has_any():
		gs.emit_xi_triggered(xi_result.triggered)

	# B10: Apply scaling ninja growth after each play
	var arr = gs.current_arrangement
	NinjaScaling.process_scaling(gs.owned_ninjas, "on_play", {
		"head_type": arr.head_eval.hand_type,
		"mid_type": arr.mid_eval.hand_type,
		"tail_type": arr.tail_eval.hand_type,
		"triggered_xis": xi_result.triggered if xi_result and xi_result.has_any() else [],
	})

	# Log play result before branching (win/lose/continue)
	GameRunLogger.on_play_executed(score_result.total_score, gs.plays_remaining, gs.hand)

	# Check win/lose
	if gs.current_score >= gs.target_score:
		_complete_seal(gs)
	elif gs.plays_remaining <= 0:
		gs._transition_to(NinKingGameState.State.GAME_OVER)
	else:
		# Draw 9 new cards and auto-arrange
		gs.hand = gs.deck_manager.draw(9)
		gs.auto_arrange()
		gs._transition_to(NinKingGameState.State.PLAYING)


## Collect gold from economic ninja effects + card enhancements/seals after a play.
## TODO: Replace int() casts with CardData.Enhancement.GOLD / CardData.Seal.GOLD
## once Godot "hides global script class" cache bug is resolved.
static func _collect_play_gold(gs, all_cards: Array[CardData.PlayingCard], xi_result, summary: Dictionary = {}) -> void:
	var gold_earned: int = 0

	# Phase H: use pre-computed gold_on_play from summary
	gold_earned += summary.get("gold_on_play", 0)

	# Legacy fallback: iterate only if summary didn't provide gold_on_play
	if summary.get("gold_on_play", 0) == 0:
		for ninja: Dictionary in gs.owned_ninjas:
			var eff: Dictionary = ninja.get("effect", {})

			# E1: 福神 — gold per xi triggered
			if eff.get("gold_per_xi", 0) > 0:
				if xi_result and xi_result.has_any():
					gold_earned += xi_result.triggered.size() * eff["gold_per_xi"]

	# E4: 镀金 — +$3 per card with GOLD enhancement (Enhancement.GOLD = 1)
	# E5: 金封印 — +$3 per card with GOLD seal (Seal.GOLD = 2)
	for card: CardData.PlayingCard in all_cards:
		if int(card.enhancement) == 1:
			gold_earned += 3
		if int(card.seal) == 2:
			gold_earned += card.get_seal_gold()

	if gold_earned > 0:
		gs.gold += gold_earned
		gs.gold_changed.emit(gs.gold)


# ══════════════════════════════════════════
# Card Swap (两张牌交换位置 — 入れ替え)
# ══════════════════════════════════════════

static func swap_cards(gs: NinKingGameState, idx1: int, idx2: int) -> void:
	if gs.current_state != NinKingGameState.State.PLAYING:
		return
	if idx1 < 0 or idx1 >= gs.hand.size() or idx2 < 0 or idx2 >= gs.hand.size():
		return
	var temp: CardData.PlayingCard = gs.hand[idx1]
	gs.hand[idx1] = gs.hand[idx2]
	gs.hand[idx2] = temp
	gs.re_evaluate_arrangement()
	GameRunLogger.on_card_swapped(idx1, idx2, gs.hand)
	gs.hand_swapped.emit(idx1, idx2)


# ══════════════════════════════════════════
# Seal completion → 萬屋 flow
# ══════════════════════════════════════════

static func _complete_seal(gs, summary: Dictionary = {}) -> void:
	# Gold reward
	var extra_interest: int = summary.get("interest_cap_bonus", 0)
	var seal_cfg: Dictionary = BarrierConfig.get_seal(gs.barrier_num, gs.seal_idx)
	gs.gold += seal_cfg.get("gold", 0)
	gs.gold_changed.emit(gs.gold)

	# Interest (every $5 = $1, cap $5)
	var interest_cap: int = ConfigManager.interest_cap + extra_interest
	# Legacy fallback when summary not provided
	if not summary.has("interest_cap_bonus"):
		for ninja: Dictionary in gs.owned_ninjas:
			var eff: Dictionary = ninja.get("effect", {})
			if eff.get("interest_cap_bonus", 0) > 0:
				interest_cap += eff["interest_cap_bonus"]

	var interest: int = mini(floori(float(gs.gold) / float(ConfigManager.interest_divisor)), interest_cap)
	gs.gold += interest
	gs.gold_changed.emit(gs.gold)

	GameRunLogger.on_seal_completed(gs.current_score, seal_cfg.get("gold", 0), interest)

	if not _advance_seal(gs):
		return

	gs._transition_to(NinKingGameState.State.SEAL_COMPLETE)


static func go_to_shop(gs) -> void:
	GameRunLogger.on_shop_entered(gs.gold, gs.barrier_num, gs.seal_idx)
	gs._transition_to(NinKingGameState.State.SHOP)


static func continue_from_shop(gs) -> void:
	gs._start_seal()


# ══════════════════════════════════════════
# Skip tag
# ══════════════════════════════════════════

static func skip_seal(gs: NinKingGameState, tag_reward: Dictionary) -> void:
	## Apply tag reward and skip current seal
	if tag_reward.has("gold"):
		gs.gold += tag_reward["gold"]
		gs.gold_changed.emit(gs.gold)

	if not _advance_seal(gs):
		return

	go_to_shop(gs)


# ══════════════════════════════════════════
# Internal
# ══════════════════════════════════════════

## Advance seal_idx / barrier_num. Returns true if game continues, false if victory.
static func _advance_seal(gs) -> bool:
	gs.seal_idx += 1
	if gs.seal_idx >= BarrierConfig.get_seals_per_barrier():
		gs.seal_idx = 0
		gs.barrier_num += 1

	if gs.barrier_num > BarrierConfig.get_total_barriers():
		gs._transition_to(NinKingGameState.State.VICTORY)
		return false

	return true
