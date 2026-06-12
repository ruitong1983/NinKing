class_name AnimationHandler
extends RefCounted

## Handles scoring animation sequence (Phase 1-4) for NinKing.
## Created by game_manager.gd as a delegate for scoring and VFX animation logic.

const BounceScore = preload("res://scripts/tween/bounce_score.gd")
const FX = preload("res://scripts/tween/tween_fx.gd")
const SB = preload("res://scripts/config/sound_bank.gd")

var _ui: UIManager

## Set by game_manager before each scoring round (includes head/mid/tail eval).
var current_play_data: Dictionary = {}

## Callable to set game_manager's _auto_shop_pending flag before finalize_play.
var _mark_auto_shop: Callable = func(): pass

## Active toast label — freed before showing next to avoid overlap.
var _active_toast: Label = null


func setup(ui: UIManager, mark_auto_shop_cb: Callable) -> void:
	_ui = ui
	_mark_auto_shop = mark_auto_shop_cb


func run_scoring() -> void:
	await _run_scoring_animation()


func _run_scoring_animation() -> void:
	var play_data: Dictionary = current_play_data
	var score_result: ScoreCalculator.ScoreResult = play_data["score_result"]
	var xi_result: XiDetector.XiResult = play_data["xi_result"]

	var gs: NinKingGameState = NinKingGameState
	var old_score: int = int(gs.current_score)
	var new_score: int = old_score + int(score_result.total_score)
	var gain: int = new_score - old_score

	# Determine outcome before finalize
	var is_pass: bool = new_score >= int(gs.target_score)
	var is_fail: bool = (gs.plays_remaining <= 1) and not is_pass
	var barrier_color: Color = BarrierTheme.get_colors(NinKingGameState.barrier_num).accent

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
	var dun_hands: Array[Hand] = [_ui.head_cards, _ui.middle_cards, _ui.tail_cards]
	var dun_score_labels: Array[Label] = [_ui.shadow_score_label, _ui.flash_score_label, _ui.destroy_score_label]
	var dun_lv_labels: Array[Label] = [_ui.shadow_lv_label, _ui.flash_lv_label, _ui.destroy_lv_label]
	var dun_chips_vals: Array[int] = [score_result.head_chips, score_result.mid_chips, score_result.tail_chips]
	var dun_mult_vals: Array[int] = [score_result.head_mult, score_result.mid_mult, score_result.tail_mult]

	var _original_texts: Array[String] = []
	for lbl: Label in dun_type_labels:
		_original_texts.append(lbl.text)

	for i: int in range(3):
		var eval: HandEvaluator3.EvalResult = dun_evals[i]
		if eval != null:
			var type_label: Label = dun_type_labels[i]
			var hand_name: String = CardData.get_hand_type3_name(eval.hand_type)
			var hand: Hand = dun_hands[i]

			# -- Per-card stagger flash (tiered: head=fast, mid=med, tail=slow) --
			var card_stagger: float = [0.06, 0.09, 0.12][i]
			var cards_node: Node = hand.get_node_or_null("Cards")
			if cards_node != null:
				for ci: int in cards_node.get_child_count():
					var card_node: Node = cards_node.get_child(ci)
					if card_node is CanvasItem:
						GlobalTweens.color_flash(card_node, Color.GOLD, card_stagger)
					GlobalTweens.play_sfx(SB.COUNT_TICK)
					await _ui.get_tree().create_timer(card_stagger * 0.7).timeout

			# -- Type label reveal (crescendo across 3 duns) --
			type_label.text = hand_name
			GlobalTweens.play_sfx(SB.GROUP_REVEAL)
			GlobalTweens.color_flash(type_label, dun_flash_colors[i], 0.25)

			match i:
				0:  # Head — light scale_pop
					GlobalTweens.scale_pop(type_label, 1.2, 0.25)
				1:  # Middle — stronger pop + micro-shake
					GlobalTweens.scale_pop(type_label, 1.4, 0.3)
					GlobalTweens.screen_shake(0.03, 0.02)
				2:  # Tail — smooth spring pop up + settle
					var spring_tw: Tween = type_label.create_tween()
					spring_tw.tween_property(type_label, "scale", Vector2(1.5, 1.5), 0.12) \
						.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
					spring_tw.tween_property(type_label, "scale", Vector2.ONE, 0.35) \
						.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
					GlobalTweens.burst_particles(
						hand.global_position + hand.size * 0.5,
						"manga_burst"
					)
					GlobalTweens.screen_shake(0.06, 0.04)

			# -- Per-dun score label: update to full chipsxmult + flash --
			var sl: Label = dun_score_labels[i]
			var dc: int = dun_chips_vals[i]
			var dm: int = dun_mult_vals[i]
			if dc > 0 and dm > 0:
				sl.text = "%d×%d" % [dc, dm]
				GlobalTweens.color_flash(sl, Color.GOLD, 0.2)
				# Flash Lv badge alongside score
				var ll: Label = dun_lv_labels[i]
				if is_instance_valid(ll) and ll.visible:
					GlobalTweens.color_flash(ll, Color.GOLD, 0.2)
		await _ui.get_tree().create_timer([0.40, 0.55, 0.65][i]).timeout

	# ═══ Phase 2: Score bounce in left panel + "+N" float + breakdown ═══
	if NinKingGameState.owned_ninjas.size() > 0:
		GlobalTweens.play_sfx(SB.NINJA_ACTIVATE)
	BounceScore.play(
		_ui.score_label, _ui.progress_bar, _ui.col_xi_label,
		_ui.panel_bg, old_score, new_score, barrier_color, SB.COUNT_TICK
	)

	if gain > 0:
		_float_score_gain(_ui.score_label, gain, barrier_color)

	# Breakdown toast near score area (v4.0 per-group format)
	var breakdown_text: String = "影:%d  瞬:%d  滅:%d" % [
		int(score_result.head_score),
		int(score_result.mid_score),
		int(score_result.tail_score)
	]
	var col_stack: Array = score_result.col_x_stack
	if col_stack.size() > 0:
		var col_str: String = ""
		for x: int in col_stack:
			col_str += "×%d" % x
		breakdown_text += "\n列:" + col_str
	var xi_stack: Array = score_result.global_xi_x_stack
	if xi_stack.size() > 0:
		var xi_str: String = ""
		for x: int in xi_stack:
			xi_str += "×%d" % x
		breakdown_text += "\n喜:" + xi_str
	_show_breakdown_toast(breakdown_text, barrier_color)

	# ═══ Column VFX celebration ═══
	var col_evals: Array = play_data.get("col_evals", [])
	if col_evals.size() == 3:
		for i: int in range(3):
			var ct: CardData.HandType3 = col_evals[i].hand_type
			if int(ct) >= int(CardData.HandType3.FLUSH_3):
				var col_labels: Array[Label] = [_ui.col0_label, _ui.col1_label, _ui.col2_label]
				GlobalTweens.burst_particles(
					col_labels[i].global_position + col_labels[i].size * 0.5,
					"shuriken"
				)
				GlobalTweens.color_flash(col_labels[i], Color(0.831, 0.659, 0.263, 1.0), 0.15)

	# ═══ Phase 2.5: Score appreciation pulse ═══
	await _ui.get_tree().create_timer(2.0).timeout
	var pulse_tw: Tween = _ui.score_label.create_tween()
	pulse_tw.set_ignore_time_scale(true)
	pulse_tw.tween_property(_ui.score_label, "scale", Vector2(1.06, 1.06), 0.6) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	pulse_tw.tween_property(_ui.score_label, "scale", Vector2.ONE, 0.6) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	if is_instance_valid(_ui.panel_bg):
		FX.color_flash(_ui.panel_bg, barrier_color, 1.2)
	await pulse_tw.finished

	# ═══ Phase 3: Xi effects ═══
	if xi_result and xi_result.has_any():
		GlobalTweens.play_sfx(SB.XI_TRIGGER)
		GlobalTweens.burst_particles(_ui.get_viewport_rect().size * 0.5, "shuriken")
		GlobalTweens.do_hit_stop(0.06, 0.05)
		GlobalTweens.screen_shake(0.12, 0.08)
		var xi_names: Array[String] = []
		for xi_name: String in xi_result.triggered:
			xi_names.append(xi_name)
		_show_breakdown_toast("喜: " + ", ".join(xi_names), Color.GOLD)
		await _ui.get_tree().create_timer(0.5).timeout
		GlobalTweens.play_sfx(SB.XI_FANFARE)

	# Restore dun type labels
	for i: int in range(3):
		if i < _original_texts.size():
			dun_type_labels[i].text = _original_texts[i]

	# ═══ Phase 4: Outcome + finalize ═══
	if is_pass:
		GlobalTweens.play_sfx(SB.SEAL_CLEAR)
		GlobalTweens.burst_particles(_ui.get_viewport_rect().size * 0.5, "sakura")
		GlobalTweens.do_hit_stop(0.08, 0.05)
		GlobalTweens.punch_in(_ui.score_label, 0.4, 1.5)
		await _ui.get_tree().create_timer(0.6).timeout
		_mark_auto_shop.call()
		play_data["gold_before_settlement"] = gs.gold
		SealController.finalize_play(gs, play_data)
		current_play_data.clear()
		return
	elif is_fail:
		GlobalTweens.play_sfx(SB.SEAL_FAIL)
		GlobalTweens.screen_shake(0.2, 0.12)
		GlobalTweens.color_flash(_ui.game_bg, Color(0.6, 0.1, 0.1, 1.0), 0.3)
		await _ui.get_tree().create_timer(0.6).timeout
		SealController.finalize_play(gs, play_data)
	else:
		await _ui.get_tree().create_timer(0.3).timeout
		SealController.finalize_play(gs, play_data)

	current_play_data.clear()


# ══════════════════════════════════════════
# Score animation helpers
# ══════════════════════════════════════════

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
