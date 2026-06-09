class_name SealController
extends RefCounted

## Play execution & seal completion logic extracted from NinKingGameState.
## All methods are static and take the game state autoload as first parameter.


# ══════════════════════════════════════════
# Play (出牌) — full flow (no animation)
# ══════════════════════════════════════════

static func execute_play(gs) -> void:
	var play_data: Dictionary = prepare_play(gs)
	if play_data.is_empty():
		return
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
	if not gs.current_arrangement or not gs.current_arrangement.is_legal():
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

	# Xi detection (no signal emit — deferred to finalize_play)
	var xi_result: XiDetector.XiResult = null
	if not seal_lord_effects.get("no_xi", false):
		xi_result = XiDetector.detect(head_cards, mid_cards, tail_cards,
			head_eval, mid_eval, tail_eval)

	# Score calculation
	var score_result: ScoreCalculator.ScoreResult = ScoreCalculator.calculate(
		head_cards, mid_cards, tail_cards,
		head_eval, mid_eval, tail_eval,
		gs.owned_ninjas,
		gs.star_chart_levels,
		xi_result,
		seal_lord_effects,
		gs.gold
	)

	return {
		"score_result": score_result,
		"xi_result": xi_result,
		"seal_effects": seal_lord_effects,
	}


## Apply state mutations after animation completes.
## Handles: decrement plays, add score, discard cards, emit signals,
## then win/lose/continue branching with state transitions.
static func finalize_play(gs, play_data: Dictionary) -> void:
	var score_result: ScoreCalculator.ScoreResult = play_data["score_result"]
	var xi_result: XiDetector.XiResult = play_data["xi_result"]

	gs.plays_remaining -= 1
	gs.emit_plays_changed()

	gs.current_score += score_result.total_score

	# Collect all 9 played cards (before discard)
	var all_cards: Array[CardData.PlayingCard] = []
	all_cards.append_array(gs.current_arrangement.head)
	all_cards.append_array(gs.current_arrangement.mid)
	all_cards.append_array(gs.current_arrangement.tail)

	# Economic gold collection (E1-E5)
	_collect_play_gold(gs, all_cards, xi_result)

	# Discard all 9 played cards
	gs.deck_manager.discard(all_cards)

	gs.emit_score_updated()

	# Emit xi signal here (after animation, not during prepare)
	if xi_result and xi_result.has_any():
		gs.emit_xi_triggered(xi_result.triggered)

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
static func _collect_play_gold(gs, all_cards: Array[CardData.PlayingCard], xi_result) -> void:
	var gold_earned: int = 0

	for ninja: Dictionary in gs.owned_ninjas:
		var eff: Dictionary = ninja.get("effect", {})

		# E1: 福神 — gold per xi triggered
		if eff.get("gold_per_xi", 0) > 0:
			if xi_result and xi_result.has_any():
				gold_earned += xi_result.triggered.size() * eff["gold_per_xi"]

		# E2: 金尾 — gold per GOLD enhancement card in tail (Enhancement.GOLD = 1)
		if eff.get("gold_per_gold_card_in_tail", 0) > 0:
			for card: CardData.PlayingCard in gs.current_arrangement.tail:
				if int(card.enhancement) == 1:
					gold_earned += eff["gold_per_gold_card_in_tail"]

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
	gs.auto_arrange()


# ══════════════════════════════════════════
# Redraw (手替え — 弃掉选中牌并抽新牌)
# ══════════════════════════════════════════

static func execute_redraw(gs: NinKingGameState, indices: Array[int]) -> void:
	if gs.current_state != NinKingGameState.State.PLAYING:
		return
	if gs.redraws_remaining <= 0:
		return
	if indices.is_empty() or indices.size() > 5:
		return

	gs.redraws_remaining -= 1
	gs.emit_redraws_changed()

	# Collect discarded cards
	var discarded: Array[CardData.PlayingCard] = []
	for idx: int in indices:
		if idx >= 0 and idx < gs.hand.size():
			discarded.append(gs.hand[idx])

	gs.deck_manager.discard(discarded)

	# Remove from hand (reverse order to avoid index shift)
	indices.sort()
	for i: int in range(indices.size() - 1, -1, -1):
		gs.hand.remove_at(indices[i])

	# Draw replacements
	var new_cards: Array[CardData.PlayingCard] = gs.deck_manager.draw(discarded.size())
	gs.hand.append_array(new_cards)

	# Re-arrange
	gs.auto_arrange()

	# E3: 俭约 — gold if redraw ≤ 2 cards
	for ninja: Dictionary in gs.owned_ninjas:
		var eff: Dictionary = ninja.get("effect", {})
		if eff.get("gold_per_small_redraw", 0) > 0 and indices.size() <= 2:
			gs.gold += eff["gold_per_small_redraw"]
			gs.gold_changed.emit(gs.gold)
			break


# ══════════════════════════════════════════
# Seal completion → 萬屋 flow
# ══════════════════════════════════════════

static func _complete_seal(gs) -> void:
	# Gold reward
	var seal_cfg: Dictionary = BarrierConfig.get_seal(gs.barrier_num, gs.seal_idx)
	gs.gold += seal_cfg.get("gold", 0)
	gs.gold_changed.emit(gs.gold)

	# Interest (every $5 = $1, cap $5)
	var interest_cap: int = 5
	# Check for economy ninja that raises cap
	for ninja: Dictionary in gs.owned_ninjas:
		var eff: Dictionary = ninja.get("effect", {})
		if eff.get("interest_cap_bonus", 0) > 0:
			interest_cap += eff["interest_cap_bonus"]

	var interest: int = mini(floori(float(gs.gold) / 5.0), interest_cap)
	gs.gold += interest
	gs.gold_changed.emit(gs.gold)

	if not _advance_seal(gs):
		return

	gs._transition_to(NinKingGameState.State.SEAL_COMPLETE)


static func go_to_shop(gs) -> void:
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
