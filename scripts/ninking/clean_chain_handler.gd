class_name CleanChainHandler
extends Node

## Clean mode chain resolution — visual phased elimination animation.
##
## Per-wave flow (5 phases):
##   Phase A — HIGHLIGHT (0.35s): matched cards flash REDRAW_TARGET
##   Phase B — REMOVE (instant): cards disappear, grid shows gaps
##   Phase C — GAP (0.4s): player sees empty slots
##   Phase D1 — FALL (0.3s): surviving cards "drop" to fill gaps
##   Phase D2 — DROP (0.35s): new cards from deck plummet into grid
##
## Each wave shows per-wave score popup. Chain >=2 shows combo.
## Added as child of game_manager; uses parent node's tree for timers/viewport.

const SB = preload("res://scripts/config/sound_bank.gd")

var ui: UIManager
var _scoring_vfx: CleanScoringVFX = null
var _match_display: CleanMatchDisplay = null

## Callable to set game_manager's _auto_shop_pending flag before seal completion.
var _mark_auto_shop: Callable = func(): pass


func setup(ui_ref: UIManager, mark_auto_shop_cb: Callable = func(): pass) -> void:
	ui = ui_ref
	_mark_auto_shop = mark_auto_shop_cb
	# Create clean mode scoring VFX orchestrator (add to tree for Tween support)
	_scoring_vfx = CleanScoringVFX.new()
	_scoring_vfx.setup(ui)
	add_child(_scoring_vfx)
	# Create clean mode match detail display in left panel
	_match_display = CleanMatchDisplay.new()
	var htp: Panel = ui.left_panel.get_node_or_null("HandTypePanel")
	if is_instance_valid(htp):
		_match_display.setup(htp)


## Resolve elimination chains after a clean mode swap.
func resolve_clean_chain() -> void:
	print("[MASK_DEBUG] resolve_clean_chain: START")
	var gs = NinKingGameState
	if gs.current_state != NinKingGameState.State.PLAYING:
		return

	if gs.game_mode != "clean":
		return


	# Check if swap formed any match
	var first_wave: Dictionary = CleanController.prepare_chain_wave(gs, 0)
	if first_wave.is_empty():
		# No-match anim — shake card grid + UI_ERROR sfx
		GlobalTweens.shake_node(ui.card_grid, 0.5, 0.1)
		GlobalTweens.play_sfx(SB.UI_ERROR)
		gs.swaps_remaining -= 1
		gs.emit_swaps_changed()
		if gs.swaps_remaining <= 0 and gs.current_score < gs.target_score:
			gs._transition_to(NinKingGameState.State.GAME_OVER)
		return

	# Enter SCORING state + cascading lock
	gs._transition_to(NinKingGameState.State.SCORING)
	gs.set_cascading(true)

	var chains: Array[Dictionary] = []
	var chain_level: int = 0

	# ══ Process first wave ══
	chain_level += 1
	first_wave["chain_level"] = chain_level
	chains.append(first_wave)

	# Display first wave match groups in left panel
	if _match_display != null:
		_match_display.reset_for_new_swap()
		_match_display.append_wave(first_wave)

	# Phase A — HIGHLIGHT (0.35s): matched cards flash
	GlobalTweens.play_sfx(SB.SWAP)
	GlobalTweens.screen_shake(0.1, 0.06)
	_highlight_matches(first_wave)
	await get_tree().create_timer(0.35).timeout
	if not is_instance_valid(gs) or not is_instance_valid(self):
		return

	# Reset card visuals before removal (clean slate for recycled nodes)
	_reset_card_visuals(first_wave)

	# Phase B — REMOVE (instant): cards disappear
	CleanController.remove_matches(gs, first_wave)
	# B.5 — Explicitly hide card nodes (primary hide mechanism)
	_hide_matched_cards(first_wave)
	gs.hand_updated.emit(gs.hand)
	# Mask debug
	print("[MASK_DEBUG] Wave 1 Phase B done: visible=", _count_visible_cards(), " nulls=", _count_hand_nulls(gs))

	# Phase C — GAP (0.4s): player sees empty slots
	await get_tree().create_timer(0.4).timeout
	if not is_instance_valid(gs) or not is_instance_valid(self):
		return

	# Phase D1 + D2 — FALL then DROP
	await _animate_replenishment(gs)
	if not is_instance_valid(gs) or not is_instance_valid(self):
		return

	# Per-wave scoring VFX — spawn floating popups per match group
	if _scoring_vfx != null:
		_scoring_vfx.on_wave_scored(first_wave)

	# ══ Chain loop ══
	while true:
		var wave: Dictionary = CleanController.prepare_chain_wave(gs, chain_level)
		if wave.is_empty():
			break

		chain_level += 1
		wave["chain_level"] = chain_level
		chains.append(wave)

		# Display this wave's match groups in left panel
		if _match_display != null:
			_match_display.append_wave(wave)

		# Chain VFX — stronger at higher chain levels
		GlobalTweens.play_sfx(SB.SWAP)
		if chain_level >= 3:
			GlobalTweens.screen_shake(0.2, 0.12)
			GlobalTweens.do_hit_stop(0.08, 0.04)
		else:
			GlobalTweens.screen_shake(0.15, 0.08)

		# Phase A — HIGHLIGHT
		_highlight_matches(wave)
		await get_tree().create_timer(0.35).timeout
		if not is_instance_valid(gs) or not is_instance_valid(self):
			return

		_reset_card_visuals(wave)

		# Phase B — REMOVE
		CleanController.remove_matches(gs, wave)
		# B.5 — Explicitly hide card nodes
		_hide_matched_cards(wave)
		gs.hand_updated.emit(gs.hand)
		# Mask debug
		print("[MASK_DEBUG] Wave ", chain_level, " Phase B done: visible=", _count_visible_cards(), " nulls=", _count_hand_nulls(gs))

		# Phase C — GAP
		await get_tree().create_timer(0.4).timeout
		if not is_instance_valid(gs) or not is_instance_valid(self):
			return

		# Phase D1 + D2
		await _animate_replenishment(gs)
		if not is_instance_valid(gs) or not is_instance_valid(self):
			return

		# Per-wave scoring VFX
		if _scoring_vfx != null:
			_scoring_vfx.on_wave_scored(wave)

		# Hard cap
		if chain_level >= 10:
			push_warning("CleanChainHandler: clean chain reached hard cap of 10 waves")
			break

	# ── Compute clean score with ninja integration ──
	var clean_result: Dictionary = ScoreCalculator.calculate_clean(
		gs.hand, chains, gs.owned_ninjas, gs.gold
	)
	var swap_score: int = clean_result.get("swap_score", 0)

	# Final scoring VFX — score jump + ninja flash + combo
	if _scoring_vfx != null and swap_score > 0:
		var old_score: int = gs.current_score
		_scoring_vfx.on_swap_finalized(clean_result, old_score)

	# Apply gold_on_swap
	var gold_earned: int = clean_result.get("gold_on_swap", 0)
	if gold_earned > 0:
		gs.gold += gold_earned
		gs.gold_changed.emit(gs.gold)

	# Apply extra_swaps / only_one_swap
	var extra: int = clean_result.get("extra_swaps", 0)
	if extra > 0:
		gs.swaps_remaining += extra
	if clean_result.get("only_one_swap", false):
		gs.swaps_remaining = 1

	# Mark auto-shop before transition (Phase E settlement card)
	_mark_auto_shop.call()

	# Finalize
	CleanController.finalize_swap(gs, chains, swap_score)


# ═══ Phase A — Highlight matched cards ═══

## Apply REDRAW_TARGET flash to all cards about to be removed.
func _highlight_matches(wave_data: Dictionary) -> void:
	var positions: Array[int] = wave_data.get("remove_positions", [])
	var grid: HandCardContainer = ui.card_grid
	for pos in positions:
		var nk := grid.get_card_at(pos)
		if nk == null:
			continue
		nk.set_visual_state(NinKingCard.VisualState.REDRAW_TARGET)


## Reset highlighted cards back to NORMAL visual state.
func _reset_card_visuals(wave_data: Dictionary) -> void:
	var positions: Array[int] = wave_data.get("remove_positions", [])
	var grid: HandCardContainer = ui.card_grid
	for pos in positions:
		var nk := grid.get_card_at(pos)
		if nk == null:
			continue
		if is_instance_valid(nk):
			nk.set_visual_state(NinKingCard.VisualState.NORMAL)


## Phase B.5 — Explicitly hide matched card nodes after data removal.
func _hide_matched_cards(wave_data: Dictionary) -> void:
	var positions: Array[int] = wave_data.get("remove_positions", [])
	var grid: HandCardContainer = ui.card_grid
	for pos in positions:
		var nk := grid.get_card_at(pos)
		if nk == null:
			continue
		if is_instance_valid(nk):
			nk.visible = false


# ═══ Phase D — Replenishment animation (D1 fall + D2 drop) ═══
#
## Animate card replenishment after elimination:
##   1) Snapshot hand state before gravity_and_draw
##   2) Execute gravity + draw (data layer)
##   3) Detect falling old cards vs new incoming cards
##   4) Phase D1: old cards fall with gravity acceleration + squash spring
##   5) Phase D2: new cards drop in from above (scale entry + landing flash)
func _animate_replenishment(gs) -> void:
	var pre_hand: Array = gs.hand.duplicate()

	CleanController.gravity_and_draw(gs)
	gs.hand_updated.emit(gs.hand)
	# Mask debug
	print("[MASK_DEBUG] _animate_replenishment: after update_card_faces visible=", _count_visible_cards(), " nulls=", _count_hand_nulls(gs))

	var grid: HandCardContainer = ui.card_grid
	var COLS: int = 3

	# ── Detect card movement types ──
	var falling: Array[int] = []
	var incoming: Array[int] = []

	var pre_card_refs: Array = []
	for j in 9:
		if pre_hand[j] != null:
			pre_card_refs.append(pre_hand[j])

	for col in COLS:
		for r_from in 3:
			var pre_card = pre_hand[r_from * COLS + col]
			if pre_card == null:
				continue
			for r_to in [2, 1, 0]:
				var idx = r_to * COLS + col
				if gs.hand[idx] == pre_card:
					if r_to > r_from:
						if not falling.has(idx):
							falling.append(idx)
					break

		for r in 3:
			var idx = r * COLS + col
			var card = gs.hand[idx]
			if card == null:
				continue
			if not pre_card_refs.has(card) and not falling.has(idx):
				incoming.append(idx)

	# Phase D1 — Old cards fall
	var skipped_falling: int = 0
	for idx in falling:
		var nk := grid.get_card_at(idx)
		if nk == null:
			skipped_falling += 1
			continue
		if not nk.visible:
			skipped_falling += 1
			continue
		var target_y: float = nk.position.y
		var col: int = idx % COLS
		var delay: float = 0.06 + col * 0.04

		nk.position.y = target_y - 100.0
		nk.scale = Vector2.ONE

		var tw: Tween = create_tween()
		tw.tween_property(nk, "position:y", target_y, 0.26)\
			.set_delay(delay)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(nk, "scale", Vector2(1.10, 0.86), 0.05)\
			.set_ease(Tween.EASE_OUT)
		tw.tween_property(nk, "scale", Vector2.ONE, 0.14)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

		var glow: Tween = create_tween()
		glow.tween_property(nk, "modulate", Color(1.20, 1.15, 0.7, 1.0), 0.02)\
			.set_delay(delay + 0.26)
		glow.tween_property(nk, "modulate", Color.WHITE, 0.18)\
			.set_ease(Tween.EASE_OUT)

	if skipped_falling > 0:
		print("[MASK_DEBUG] D1 skipped ", skipped_falling, "/", falling.size(), " falling cards (not visible)")

	await get_tree().create_timer(0.55).timeout

	# Phase D2 — New cards drop in
	var had_new_cards: bool = false
	for idx in incoming:
		had_new_cards = true
		var nk := grid.get_card_at(idx)
		if nk == null:
			continue
		nk.visible = true
		var target_y: float = nk.position.y
		var target_scale: Vector2 = nk.scale
		var col: int = idx % COLS
		var delay: float = col * 0.04

		nk.position.y = target_y - 130.0
		nk.scale = Vector2(0.65, 0.65)

		if idx < COLS:
			nk.set_visual_state(NinKingCard.VisualState.REDRAW_TARGET)

		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(nk, "position:y", target_y, 0.28)\
			.set_delay(delay)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tw.parallel().tween_property(nk, "scale", Vector2.ONE, 0.16)\
			.set_delay(delay + 0.04)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(nk, "scale", Vector2(1.12, 0.84), 0.05)\
			.set_ease(Tween.EASE_OUT)
		tw.tween_property(nk, "scale", target_scale, 0.16)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

		var glow: Tween = create_tween()
		glow.tween_property(nk, "modulate", Color(1.20, 1.15, 0.7, 1.0), 0.02)\
			.set_delay(delay + 0.28)
		glow.tween_property(nk, "modulate", Color.WHITE, 0.18)\
			.set_ease(Tween.EASE_OUT)

		var burst: Tween = create_tween()
		burst.tween_callback(GlobalTweens.burst_particles.bind(
				nk.global_position + Vector2(0, nk.size.y * 0.4),
				"sparkle"
			)).set_delay(delay + 0.28)

	if had_new_cards:
		GlobalTweens.play_sfx(SB.DEAL)

	await get_tree().create_timer(0.50).timeout

	for idx in incoming:
		if idx < COLS:
			var nk := grid.get_card_at(idx)
			if is_instance_valid(nk):
				nk.set_visual_state(NinKingCard.VisualState.NORMAL)


# ═══ Mask debug helpers ═══

## Count how many card nodes in the grid have visible=true.
func _count_visible_cards() -> int:
	var grid: HandCardContainer = ui.card_grid
	if not is_instance_valid(grid):
		return -1
	var count: int = 0
	for i in 9:
		var nk := grid.get_card_at(i)
		if nk != null and nk.visible:
			count += 1
	return count


## Count how many null entries exist in gs.hand (unfilled grid slots).
func _count_hand_nulls(gs) -> int:
	if gs == null or gs.hand.is_empty():
		return -1
	var count: int = 0
	for i in 9:
		if gs.hand[i] == null:
			count += 1
	return count
