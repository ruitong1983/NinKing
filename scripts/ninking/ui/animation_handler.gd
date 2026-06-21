class_name AnimationHandler
extends RefCounted

## Handles scoring animation sequence. (Phase 1-4) for NinKing.
## Created by game_manager.gd as a delegate for scoring and VFX animation logic.
##
## v5: Balatro-style multi-segment count-up via CountUp.play_score.
##     All score labels count from 0 to final values with eased animation.
## v6: Enhanced VFX — pop_in on score labels, punch_in for product reveal,
##     panel_bg glow pulse on cumulative updates (2026-06-15).
## v7: Column score inline count-up on type labels (removed hidden col_score_labels).
## v8: Removed _compute_ninja_contributions fallback (H3 — use summary.anim_contribs only).

const FX = preload("res://scripts/tween/tween_fx.gd")
const SB = preload("res://scripts/config/sound_bank.gd")

const GLOW_DUR: float = 0.45
const PROGRESS_DUR: float = 0.60

var _ui  # duck-typed — accepts UIManager or DebugUiProxy

## Set by game_manager before each scoring round (includes head/mid/tail eval).
var current_play_data: Dictionary = {}

## Callable to set game_manager's _auto_shop_pending flag before finalize_play.
var _mark_auto_shop: Callable = func(): pass

## Active toast label — freed before showing next to avoid overlap.
var _active_toast: Label = null

var _sfx_tick: Callable = func(pitch: float = 1.0): GlobalTweens.play_sfx(SB.COUNT_TICK, 0.0, pitch)


func setup(ui, mark_auto_shop_cb: Callable) -> void:  # ui: duck-typed (UIManager | DebugUiProxy)
	_ui = ui
	_mark_auto_shop = mark_auto_shop_cb


func run_scoring() -> void:
	await _run_scoring_animation()


func _run_scoring_animation() -> void:
	var play_data: Dictionary = current_play_data
	var score_result: ScoreResult = play_data["score_result"]
	var xi_result: XiDetector.XiResult = play_data["xi_result"]

	var gs: NinKingGameState = NinKingGameState
	var old_score: int = int(gs.current_score)
	var new_score: int = old_score + int(score_result.total_score)
	var gain: int = new_score - old_score

	var barrier_color: Color = BarrierTheme.get_colors(NinKingGameState.barrier_num).accent

	var tree: SceneTree = _ui.get_tree()

	# ── Initial pause: let main card animation settle ──
	_ui.progress_bar.modulate = Color.WHITE
	await tree.create_timer(1.2).timeout

	# Phase H: consume pre-computed ninja contribs from summary (single pass in ScoreCalculator)
	var _raw_summary: Dictionary = play_data.get("summary", {})
	var _raw_contribs: Array = _raw_summary.get("anim_contribs", [])
	var ninja_contribs: Array[Dictionary] = []
	for _c in _raw_contribs:
		if _c is Dictionary:
			ninja_contribs.append(_c)

	# ── Round-robin pool for cat meow SFX (彩蛋) ──
	var _unplayed_cats: Array[AudioStream] = SB.CAT_MEOWS.duplicate()

	# ═══ Phase 1: Per-dun sequential reveal ═══
	var dun_evals: Array = [
		play_data.get("head_eval"),
		play_data.get("mid_eval"),
		play_data.get("tail_eval"),
	]
	var dun_flash_colors: Array[Color] = [
		Color(0.3, 0.6, 1.0),   # 影 — cool blue
		Color(1.0, 0.84, 0.0),  # 瞬 — gold
		Color(1.0, 0.2, 0.1),   # 滅 — fiery red
	]
	var dun_type_labels: Array[Label] = [_ui.head_type_label, _ui.middle_type_label, _ui.tail_type_label]
	var dun_lv_labels: Array[Label] = [_ui.shadow_lv_label, _ui.flash_lv_label, _ui.destroy_lv_label]
	var dun_chips_vals: Array[int] = [score_result.head_chips, score_result.mid_chips, score_result.tail_chips]
	var dun_mult_vals: Array[int] = [score_result.head_mult, score_result.mid_mult, score_result.tail_mult]
	var dun_score_labels: Array[RichTextLabel] = [_ui.shadow_score_label, _ui.flash_score_label, _ui.destroy_score_label]

	var _original_texts: Array[String] = []
	for lbl: Label in dun_type_labels:
		_original_texts.append(lbl.text)

	for i: int in range(3):
		var eval: HandEvaluator3.EvalResult = dun_evals[i]
		if eval != null:
			var type_label: Label = dun_type_labels[i]
			var hand_name: String = CardData.get_hand_type3_name(eval.hand_type)
			var sl: RichTextLabel = dun_score_labels[i]
			var dc: int = dun_chips_vals[i]
			var dm: int = dun_mult_vals[i]
			var dr: int = dc * dm

			# -- Score fade-in: show "0 x 0 = 0" at low alpha --
			sl.text = "0 x 0 = 0"
			sl.modulate.a = 0.0
			sl.scale = Vector2(0.1, 0.1)
			GlobalTweens.fade_in(sl, 0.15)
			GlobalTweens.pop_in(sl, 0.25)
			await tree.create_timer(0.15).timeout

			# -- Per-card stagger flash --
			var card_stagger: float = [0.15, 0.20, 0.25][i]
			for card_node: Card in _ui.card_grid.get_row_cards(i):
				if card_node is CanvasItem:
					GlobalTweens.color_flash(card_node, Color.GOLD, card_stagger)
				await tree.create_timer(card_stagger).timeout

			# -- Stage 2: Ninja bar card trigger animations (Balatro-style impact) --
			var row_ninjas: Array = _contribs_for_row(ninja_contribs, i)
			for nc: Dictionary in row_ninjas:
				var ninja_card: NinjaInventoryCard = _find_ninja_card(nc.id)
				if ninja_card != null:
					# Bright white flash -> gold flash (hit impact)
					GlobalTweens.color_flash(ninja_card, Color.WHITE, 0.06)
					await tree.create_timer(0.04).timeout
					GlobalTweens.color_flash(ninja_card, Color.GOLD, 0.35)
					# Snappy bounce + screen shake + sparkle particles
					GlobalTweens.ninja_trigger(ninja_card)
					GlobalTweens.screen_shake(0.04, 0.02)
					GlobalTweens.burst_particles(ninja_card.global_position + ninja_card.size * 0.5, "sparkle")
					# ── Random cat meow (round-robin) ──
					if _unplayed_cats.is_empty():
						_unplayed_cats = SB.CAT_MEOWS.duplicate()
					var _cat_idx: int = randi() % _unplayed_cats.size()
					GlobalTweens.play_sfx(_unplayed_cats[_cat_idx])
					_unplayed_cats.remove_at(_cat_idx)
					await tree.create_timer(0.05).timeout
					_float_ninja_text(ninja_card, nc.chips, nc.mult)
				await tree.create_timer(0.22).timeout

			# -- Type label reveal --
			type_label.text = hand_name
			GlobalTweens.play_sfx(SB.GROUP_REVEAL)
			GlobalTweens.color_flash(type_label, dun_flash_colors[i], 0.25)

			match i:
				0:  # Head — light scale_pop
					GlobalTweens.scale_pop(type_label, 1.2, 0.35)
				1:  # Middle — stronger pop + micro-shake
					GlobalTweens.scale_pop(type_label, 1.4, 0.4)
					GlobalTweens.screen_shake(0.03, 0.02)
				2:  # Tail — smooth spring pop up + settle
					var spring_tw: Tween = type_label.create_tween()
					spring_tw.tween_property(type_label, "scale", Vector2(1.5, 1.5), 0.15) \
						.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
					spring_tw.tween_property(type_label, "scale", Vector2.ONE, 0.45) \
						.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
					GlobalTweens.burst_particles(
						_ui.card_grid.global_position + _ui.card_grid.size * 0.5,
						"manga_burst"
					)
					GlobalTweens.screen_shake(0.06, 0.04)

			# -- play_score: 3-segment rolling count-up --
			var score_tw: Tween = GlobalTweens.play_score(
				sl, dc, dm, dr, 1.2, _sfx_tick
			)

			# -- Lv badge gold flash alongside score --
			var ll: Label = dun_lv_labels[i]
			if is_instance_valid(ll) and ll.visible:
				GlobalTweens.color_flash(ll, Color.GOLD, 0.4)

			# -- Wait for score tween to finish FIRST --
			if is_instance_valid(score_tw):
				await score_tw.finished

			# -- punch_in AFTER score completes (emphasis) --
			if is_instance_valid(sl):
				GlobalTweens.punch_in(sl, 0.25, 1.5)

			# -- Cumulative total update after this row --
			var _row_cum: int = score_result.head_score
			match i:
				1: _row_cum = score_result.head_score + score_result.mid_score
				2: _row_cum = score_result.head_score + score_result.mid_score + score_result.tail_score
			await tree.create_timer(0.15).timeout
			_ui.set_score_formula(_row_cum, 0)
			GlobalTweens.punch_in(_ui.score_label, 0.35, 2.0)
			GlobalTweens.color_flash(_ui.panel_bg, barrier_color, 0.3)
			_tween_progress(_ui.progress_bar, float(old_score + _row_cum), 0.35)
			await tree.create_timer(0.3).timeout

		# -- Pause between rows --
		await tree.create_timer(0.35).timeout

	# ═══ Phase 2: Column sequential reveal ═══
	var row_total: int = score_result.head_score + score_result.mid_score + score_result.tail_score
	var col_evals: Array = play_data.get("col_evals", [])
	var col_type_labels: Array[Label] = [_ui.left_col_type, _ui.mid_col_type, _ui.right_col_type]
	var col_lv_labels: Array[Label] = [_ui.left_col_lv, _ui.mid_col_lv, _ui.right_col_lv]

	# Compute column hand names (used as prefix for inline count-up)
	var col_hand_names: Array[String] = []
	if col_evals.size() == 3 and gs.current_arrangement != null:
		for i: int in range(3):
			var ct: CardData.HandType3 = col_evals[i].hand_type
			col_hand_names.append(CardData.get_hand_type3_name(ct))

	var col_cumulative: int = row_total
	var col_scores: Array = score_result.col_scores
	if col_scores.size() > 0:
		for i: int in range(3):
			var ct: CardData.HandType3 = col_evals[i].hand_type if i < col_evals.size() else CardData.HandType3.HIGH_CARD_3
			if ct == CardData.HandType3.HIGH_CARD_3:
				continue

			var cs: int = col_scores[i] if i < col_scores.size() else 0
			if cs > 0:
				col_cumulative += cs

				# Flash column type label + start score count-up inline
				var ctl: Label = col_type_labels[i]
				ctl.text = col_hand_names[i] + "+0"
				GlobalTweens.color_flash(ctl, Color(0.627, 0.627, 0.627, 1.0), 0.35)
				var col_tw: Tween = GlobalTweens.count_up(ctl, cs, 0.75, col_hand_names[i] + "+", "", _sfx_tick)
				await tree.create_timer(0.05).timeout

				# -- Column ninja replay (global/economy ninjas only, Balatro-style) --
				var col_ninjas: Array = _contribs_for_column(ninja_contribs)
				for nc: Dictionary in col_ninjas:
					var ninja_card: NinjaInventoryCard = _find_ninja_card(nc.id)
					if ninja_card != null:
						GlobalTweens.color_flash(ninja_card, Color.WHITE, 0.05)
						await tree.create_timer(0.03).timeout
						GlobalTweens.color_flash(ninja_card, Color.GOLD, 0.3)
						GlobalTweens.ninja_trigger(ninja_card, 0.45)
						GlobalTweens.screen_shake(0.03, 0.02)
						GlobalTweens.burst_particles(ninja_card.global_position + ninja_card.size * 0.5, "sparkle")
					await tree.create_timer(0.12).timeout

				# Lv badge flash
				var cll: Label = col_lv_labels[i]
				if is_instance_valid(cll) and cll.visible:
					GlobalTweens.color_flash(cll, Color.GOLD, 0.4)

				# Wait for column score count-up to finish FIRST
				if col_tw != null:
					await col_tw.finished

				# -- Cumulative total update after this column --
				await tree.create_timer(0.1).timeout
				_ui.set_score_formula(col_cumulative, 0)
				GlobalTweens.punch_in(_ui.score_label, 0.3, 1.8)
				GlobalTweens.color_flash(_ui.panel_bg, barrier_color, 0.25)
				_tween_progress(_ui.progress_bar, float(old_score + col_cumulative), 0.25)
				await tree.create_timer(0.2).timeout

	# ── Brief pause before progress ──
	await tree.create_timer(0.35).timeout

	# ── Ninja SFX + float gain ──
	if NinKingGameState.owned_ninjas.size() > 0:
		GlobalTweens.play_sfx(SB.NINJA_ACTIVATE)

	if gain > 0:
		_float_score_gain(_ui.score_label, gain, barrier_color)

	_ui.update_xi_display(_build_xi_summary(xi_result))

	# ═══ Column VFX celebration ═══
	if col_evals.size() == 3:
		for i: int in range(3):
			var ct: CardData.HandType3 = col_evals[i].hand_type
			if int(ct) >= int(CardData.HandType3.FLUSH_3):
				var col_labels: Array[Label] = [_ui.col0_label, _ui.col1_label, _ui.col2_label]
				GlobalTweens.burst_particles(
					col_labels[i].global_position + col_labels[i].size * 0.5,
					"shuriken"
				)
				GlobalTweens.color_flash(col_labels[i], Color(0.831, 0.659, 0.263, 1.0), 0.2)

	# ═══ Phase 3: Formula reveal ═══
	var xi_product: int = 1
	for x: int in score_result.global_xi_x_stack:
		xi_product *= x

	var has_xi: bool = xi_result and xi_result.has_any()
	var has_global_xi: bool = xi_product > 1

	if has_global_xi:
		await tree.create_timer(0.5).timeout
		_ui.set_score_formula(col_cumulative, xi_product)
		GlobalTweens.scale_pop(_ui.score_label, 1.2, 0.35)
		GlobalTweens.color_flash(_ui.score_label, Color.GOLD, 0.5)
		_tween_progress(_ui.progress_bar, float(new_score), PROGRESS_DUR)
		if not has_xi:
			await tree.create_timer(0.5).timeout
	elif has_xi:
		await tree.create_timer(0.4).timeout
	else:
		await tree.create_timer(0.3).timeout

	if has_xi:
		GlobalTweens.play_sfx(SB.XI_TRIGGER)
		GlobalTweens.burst_particles(_ui.get_viewport_rect().size * 0.5, "shuriken")
		GlobalTweens.do_hit_stop(0.08, 0.06)
		GlobalTweens.screen_shake(0.15, 0.10)
		var xi_names: Array[String] = []
		for xi_name: String in xi_result.triggered:
			xi_names.append(xi_name)
		_show_breakdown_toast("喜: " + ", ".join(xi_names), Color.GOLD)
		await tree.create_timer(0.8).timeout
		GlobalTweens.play_sfx(SB.XI_FANFARE)
	else:
		await tree.create_timer(0.5).timeout

	# Restore dun type labels
	for i: int in range(3):
		if i < _original_texts.size():
			dun_type_labels[i].text = _original_texts[i]

	# ═══ Phase 4: Outcome + finalize ═══
	var is_pass: bool = new_score >= int(gs.target_score)
	var is_fail: bool = (gs.plays_remaining <= 1) and not is_pass

	if is_pass:
		GlobalTweens.play_sfx(SB.SEAL_CLEAR)
		GlobalTweens.burst_particles(_ui.get_viewport_rect().size * 0.5, "sakura")
		GlobalTweens.do_hit_stop(0.08, 0.05)
		GlobalTweens.punch_in(_ui.score_label, 0.4, 1.5)
		await tree.create_timer(0.8).timeout
		_mark_auto_shop.call()
		play_data["gold_before_settlement"] = gs.gold
		SealController.finalize_play(gs, play_data)
		current_play_data.clear()
		return
	elif is_fail:
		GlobalTweens.play_sfx(SB.SEAL_FAIL)
		GlobalTweens.screen_shake(0.2, 0.12)
		GlobalTweens.color_flash(_ui.game_bg, Color(0.6, 0.1, 0.1, 1.0), 0.3)
		await tree.create_timer(0.8).timeout
		SealController.finalize_play(gs, play_data)
	else:
		await tree.create_timer(0.4).timeout
		SealController.finalize_play(gs, play_data)

	current_play_data.clear()


func _apply_progress_color(current_value: float) -> void:
	var bar: ProgressBar = _ui.progress_bar
	var max_val: float = bar.max_value
	var pct: float = current_value / max_val if max_val > 0 else 0.0
	if pct >= 1.0:
		bar.modulate = Color(1.0, 0.15, 0.05, 0.85)   # red
	elif pct >= 0.8:
		bar.modulate = Color(1.0, 0.65, 0.1, 0.75)    # orange
	elif pct >= 0.5:
		bar.modulate = Color(1.0, 0.9, 0.4, 0.65)     # light yellow
	else:
		bar.modulate = Color.WHITE


func _tween_progress(bar: ProgressBar, target: float, duration: float) -> void:
	if not is_instance_valid(bar):
		return
	var tw: Tween = bar.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(bar, "value", target, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_apply_progress_color(target)


func _float_score_gain(anchor: Label, gain: int, color: Color) -> void:
	var floater := Label.new()
	floater.text = "+ %d" % gain
	floater.add_theme_font_size_override("font_size", 36)
	floater.add_theme_color_override("font_color", color)
	floater.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui.panel_bg.add_child(floater)
	floater.global_position = anchor.global_position + Vector2(anchor.size.x * 0.5 - 60, -20)
	floater.size = Vector2(120, 40)

	var tw := floater.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(floater, "position:y", floater.position.y - 60, 1.0).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(floater, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tw.tween_callback(floater.queue_free)


func _build_xi_summary(xi_result: XiDetector.XiResult) -> String:
	## Build xi summary for ColXiLabel (persists after scoring).
	if xi_result == null or not xi_result.has_any():
		return "喜: -"
	var parts: Array[String] = []
	for xi_name: String in xi_result.triggered:
		parts.append(xi_name)
	if parts.size() > 0:
		return "喜: " + "  ".join(parts)
	return "喜: -"


func _show_breakdown_toast(text: String, _color: Color) -> void:
	if _active_toast != null and is_instance_valid(_active_toast):
		_active_toast.queue_free()

	var toast := Label.new()
	toast.text = text
	toast.add_theme_font_size_override("font_size", 16)
	toast.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85, 1.0))
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui.panel_bg.add_child(toast)
	toast.anchor_left = 0.0
	toast.anchor_right = 1.0
	toast.offset_top = _ui.score_label.position.y + _ui.score_label.size.y + 8
	toast.offset_bottom = toast.offset_top + 50

	var tw := toast.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_interval(1.5)
	tw.tween_property(toast, "modulate:a", 0.0, 0.5)
	tw.tween_callback(toast.queue_free)

	_active_toast = toast


func _contribs_for_row(contribs: Array, row_idx: int) -> Array:
	## Filter contributions for a specific row (0=head, 1=mid, 2=tail).
	var result: Array = []
	for c: Dictionary in contribs:
		if row_idx in c.groups:
			result.append(c)
	return result


func _contribs_for_column(contribs: Array) -> Array:
	## Filter contributions for column replay — global ninjas (all 3 rows) and economy ninjas.
	var result: Array = []
	for c: Dictionary in contribs:
		if c.is_economy or c.groups.size() >= 3:
			result.append(c)
	return result


func _find_ninja_card(ninja_id: String) -> NinjaInventoryCard:
	## Find a NinjaInventoryCard in the ninja bar by ninja ID.
	if ninja_id == "" or _ui == null or _ui.ninja_bar == null:
		return null
	var bar: NinjaBarNode = _ui.ninja_bar
	for card in bar.get_held_cards():
		if card is NinjaInventoryCard and card.ninja_data.get("id", "") == ninja_id:
			return card
	return null


func _float_ninja_text(ninja_card: NinjaInventoryCard, chips: int, mult: int) -> void:
	## Create floating "+N chips  +M mult" text above a triggered ninja card.
	var text: String = ""
	if chips > 0 and mult > 0:
		text = "+%d筹码  +%d倍率" % [chips, mult]
	elif chips > 0:
		text = "+%d筹码" % chips
	elif mult > 0:
		text = "+%d倍率" % mult
	else:
		text = "触发!"

	var floater := Label.new()
	floater.text = text
	floater.add_theme_font_size_override("font_size", 14)
	floater.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	floater.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui.panel_bg.add_child(floater)
	floater.global_position = ninja_card.global_position + Vector2(ninja_card.card_size.x * 0.5 - 60, -30)
	floater.size = Vector2(120, 30)

	var tw := floater.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(floater, "position:y", floater.position.y - 40, 0.8).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(floater, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tw.tween_callback(floater.queue_free)
