extends Control

## Main game flow coordinator — UI operations delegated to UIManager.
## NinKing v2: 9 cards → 3 groups × 3 cards (比鸡 + 忍者牌)

const BounceScore = preload("res://scripts/tween/bounce_score.gd")

@onready var ui: UIManager = %UIManager

# Cached play data during scoring animation (A7)
var _current_play_data: Dictionary = {}

# Active toast label — freed before showing next to avoid overlap (CR#3)
var _active_toast: Label = null

# Double-click guard for scene transitions (V13)
var _transition_guard: bool = false


func _ready() -> void:
	ui.play_btn.pressed.connect(_on_play_pressed)
	ui.redraw_btn.pressed.connect(_on_redraw_pressed)
	ui.ai_rearrange_btn.pressed.connect(_on_ai_rearrange_pressed)
	ui.to_shop_button.pressed.connect(_on_go_shop_pressed)
	ui.retry_button.pressed.connect(_on_retry_pressed)
	ui.back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)
	ui.victory_menu_button.pressed.connect(_on_back_to_menu_pressed)

	NinKingGameState.state_changed.connect(_on_state_changed)
	NinKingGameState.score_updated.connect(_on_score_updated)
	NinKingGameState.plays_changed.connect(_on_plays_changed)
	NinKingGameState.redraws_changed.connect(_on_redraws_changed)
	NinKingGameState.gold_changed.connect(_on_gold_changed)
	NinKingGameState.hand_updated.connect(_on_hand_updated)
	NinKingGameState.arrangement_changed.connect(_on_arrangement_changed)
	NinKingGameState.seal_started.connect(_on_seal_started)
	NinKingGameState.xi_triggered.connect(_on_xi_triggered)

	_on_state_changed(NinKingGameState.current_state)
	ui.restore_ui_state()

	# Replay lost seal_started signal — emitted in launcher before this scene loaded
	_on_seal_started(
		NinKingGameState.barrier_num,
		NinKingGameState.seal_idx,
		float(NinKingGameState.target_score),
		NinKingGameState.current_seal_lord_name
	)

	# Transition SEAL_INTRO → PLAYING after intro display.
	# Moved from game_state._begin_seal_phase() because change_scene_to_file
	# destroys the old scene tree along with any pending await timers.
	await _intro_timer()


# ═══ State callbacks ═══

func _on_state_changed(new_state: NinKingGameState.State) -> void:
	match new_state:
		NinKingGameState.State.SEAL_INTRO:
			ui.show_view("intro")
		NinKingGameState.State.PLAYING:
			ui.show_view("game")
			ui.refresh_hand(NinKingGameState.hand)
			ui.refresh_ninjas(NinKingGameState.owned_ninjas, NinKingGameState.max_ninja_slots)
			ui.ai_rearrange_btn.disabled = false
			_update_deck_display()
		NinKingGameState.State.SCORING:
			ui.show_view("scoring")
			_run_scoring_animation()
		NinKingGameState.State.SEAL_COMPLETE:
			ui.show_view("complete")
			var seal_cfg: Dictionary = BarrierConfig.get_seal(NinKingGameState.barrier_num, NinKingGameState.seal_idx)
			ui.set_level_complete(seal_cfg.get("gold", 0))
		NinKingGameState.State.GAME_OVER:
			ui.show_view("gameover")
			ui.show_game_over("忍気不足", NinKingGameState.barrier_num, int(NinKingGameState.current_score))
		NinKingGameState.State.VICTORY:
			ui.show_view("victory")
			ui.set_victory(NinKingGameState.barrier_num, int(NinKingGameState.current_score))


func _on_score_updated(current: float, target: float) -> void:
	ui.update_score(int(current), int(target))


func _on_plays_changed(remaining: int) -> void:
	ui.update_match_info(remaining, NinKingGameState.redraws_remaining)


func _on_redraws_changed(remaining: int) -> void:
	ui.update_match_info(NinKingGameState.plays_remaining, remaining)


func _on_gold_changed(amount: int) -> void:
	ui.update_gold(amount)


func _on_hand_updated(_hand: Array) -> void:
	ui.refresh_hand(NinKingGameState.hand)
	_update_deck_display()


func _on_arrangement_changed(_arr: AutoArranger.Arrangement) -> void:
	ui.refresh_groups(
		NinKingGameState.get_head_cards(),
		NinKingGameState.get_mid_cards(),
		NinKingGameState.get_tail_cards(),
		NinKingGameState.is_constraint_satisfied()
	)


func _on_seal_started(barrier: int, seal_idx: int, target: float, seal_lord_name: String) -> void:
	ui.on_seal_start(barrier, seal_idx, int(target), seal_lord_name)

	# ── Barrier theme: apply 8-attribute bright palette (V25) ──
	var c: Dictionary = BarrierTheme.get_colors(barrier)
	ui.game_bg.color = c.bg
	ui.panel_bg.color = c.panel
	ui.progress_bar.add_theme_color_override("font_color", c.accent)
	ui.progress_bar.add_theme_color_override("font_outline_color", c.accent)

	# Accent font only for neutral-bg buttons (PlayBtn/RedrawBtn/DeckBtn have own colors)
	var btns: Array[Button] = [
		ui.ai_rearrange_btn,
		ui.to_shop_button,
		ui.retry_button, ui.back_to_menu_button,
		ui.victory_menu_button,
	]
	for btn: Button in btns:
		btn.add_theme_color_override("font_color", c.accent)
		btn.add_theme_color_override("font_hover_color", c.accent.lightened(0.2))
		btn.add_theme_color_override("font_pressed_color", c.accent.darkened(0.3))

	# Boss reveal: 墨字浮现 — text pop
	if seal_lord_name != "":
		ui.level_intro.visible = true
		GlobalTweens.scale_pop(ui.intro_target_label, 1.2, 0.3)
		await get_tree().create_timer(1.0).timeout


func _on_xi_triggered(xis: Array[String]) -> void:
	if NinKingGameState.current_state == NinKingGameState.State.SCORING:
		return  # Already handled in animation Phase 3
	ui.show_xi_popup(xis)


# ═══ Button handlers ═══

func _on_play_pressed() -> void:
	if ui.redraw_mode:
		return
	if NinKingGameState.current_state != NinKingGameState.State.PLAYING:
		return
	if not NinKingGameState.is_constraint_satisfied():
		return

	# Pre-compute scoring (no state mutation) — A7 animation flow
	var play_data: Dictionary = SealController.prepare_play(NinKingGameState)
	if play_data.is_empty():
		return

	# Capture per-dun evals for A7 sequential reveal
	var arr: AutoArranger.Arrangement = NinKingGameState.current_arrangement
	_current_play_data = play_data
	_current_play_data["head_eval"] = arr.head_eval
	_current_play_data["mid_eval"] = arr.mid_eval
	_current_play_data["tail_eval"] = arr.tail_eval
	NinKingGameState._transition_to(NinKingGameState.State.SCORING)


func _on_redraw_pressed() -> void:
	if ui.redraw_mode:
		ui.confirm_redraw()
	else:
		ui.enable_redraw_mode()


func _on_go_shop_pressed() -> void:
	if _transition_guard:
		return
	_transition_guard = true
	SealController.go_to_shop(NinKingGameState)
	await GlobalTweens.fade_out(ui, 0.3).finished
	get_tree().change_scene_to_file("res://scenes/ninking/shop.tscn")


func _on_ai_rearrange_pressed() -> void:
	if NinKingGameState.current_state != NinKingGameState.State.PLAYING:
		return
	NinKingGameState.auto_arrange()
	ui.refresh_hand(NinKingGameState.hand)


func _on_retry_pressed() -> void:
	NinKingGameState.start_new_run("standard")
	get_tree().change_scene_to_file("res://scenes/ninking/ninking_main.tscn")


func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ninking/ninking_launcher.tscn")


func _update_deck_display() -> void:
	var dm: DeckManager = NinKingGameState.deck_manager
	if dm != null:
		ui.update_deck_count(dm.draw_pile.size(), dm.discard_pile.size())


# ══════════════════════════════════════════
# Intro timer — SEAL_INTRO → PLAYING
# ══════════════════════════════════════════

## Wait 2 seconds then transition from SEAL_INTRO to PLAYING.
## Extracted from game_state._begin_seal_phase() because
## change_scene_to_file destroys the old scene tree (and its timers).
func _intro_timer() -> void:
	await get_tree().create_timer(2.0).timeout
	if NinKingGameState.current_state == NinKingGameState.State.SEAL_INTRO:
		NinKingGameState._transition_to(NinKingGameState.State.PLAYING)


# ══════════════════════════════════════════
# Scoring animation (A7)
# ══════════════════════════════════════════

func _run_scoring_animation() -> void:
	var play_data: Dictionary = _current_play_data
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

	# ═══ Phase 1: Per-dun sequential reveal — inline on dun type labels ═══
	# Balatro-style: animate on HeadTypeLabel / MiddleTypeLabel / TailTypeLabel.
	# No overlay dimming — game stays fully visible, left panel BounceScore visible.

	var dun_evals: Array = [
		play_data.get("head_eval"),
		play_data.get("mid_eval"),
		play_data.get("tail_eval"),
	]
	var dun_names: Array[String] = ["影", "瞬", "滅"]
	var dun_type_labels: Array[Label] = [ui.head_type_label, ui.middle_type_label, ui.tail_type_label]
	var dun_hands: Array[Hand] = [ui.head_cards, ui.middle_cards, ui.tail_cards]

	# Save original label states to restore after
	var _original_texts: Array[String] = []
	for lbl: Label in dun_type_labels:
		_original_texts.append(lbl.text)

	for i: int in range(3):
		var eval: HandEvaluator3.EvalResult = dun_evals[i]
		if eval != null:
			var type_label: Label = dun_type_labels[i]
			var hand_name: String = CardData.get_hand_type3_name(eval.hand_type)
			type_label.text = "%s: %s" % [dun_names[i], hand_name]
			GlobalTweens.scale_pop(type_label, 1.3, 0.3)
			GlobalTweens.color_flash(type_label, barrier_color, 0.2)
			ui.flash_hand(dun_hands[i])
		await get_tree().create_timer(0.55).timeout

	# ═══ Phase 2: Score bounce in left panel + "+N" float + breakdown ═══
	BounceScore.play(ui.score_label, ui.progress_bar, ui.chips_label, ui.mult_label, ui.panel_bg, old_score, new_score, barrier_color)

	# "+ N" floats up from score_label
	if gain > 0:
		_float_score_gain(ui.score_label, gain, barrier_color)

	# Breakdown toast near score area (brief, auto-fade)
	var breakdown_text: String = "筹码 %d  ×  倍率 %d" % [int(score_result.chips_sum), int(score_result.mult_sum)]
	if score_result.x_mult_product > 1.0:
		breakdown_text += "  ×%.1f" % score_result.x_mult_product
	var col_chips: int = score_result.breakdown.get("col_chips", 0)
	var col_mult: int = score_result.breakdown.get("col_mult", 0)
	if col_chips > 0 or col_mult > 0:
		breakdown_text += "\n列: +%d筹码 +%d倍率" % [col_chips, col_mult]
	_show_breakdown_toast(breakdown_text, barrier_color)

	# ═══ Column VFX celebration ═══
	var col_evals: Array = play_data.get("col_evals", [])
	if col_evals.size() == 3:
		for i: int in range(3):
			var ct: CardData.HandType3 = col_evals[i].hand_type
			if int(ct) >= int(CardData.HandType3.STRAIGHT_FLUSH_3):
				var col_labels: Array[Label] = [ui.col0_label, ui.col1_label, ui.col2_label]
				GlobalTweens.burst_particles(col_labels[i].global_position + col_labels[i].size * 0.5, "shuriken")
				GlobalTweens.color_flash(col_labels[i], Color(0.831, 0.659, 0.263, 1.0), 0.15)
	await get_tree().create_timer(0.65).timeout

	# ═══ Phase 3: Xi effects ═══
	if xi_result and xi_result.has_any():
		GlobalTweens.burst_particles(get_viewport_rect().size * 0.5, "shuriken")
		GlobalTweens.do_hit_stop(0.06, 0.05)
		GlobalTweens.screen_shake(0.12, 0.08)
		var xi_names: Array[String] = []
		for xi_name: String in xi_result.triggered:
			xi_names.append(xi_name)
		_show_breakdown_toast("喜: " + ", ".join(xi_names), Color.GOLD)
		await get_tree().create_timer(0.5).timeout

	# Restore dun type labels
	for i: int in range(3):
		if i < _original_texts.size():
			dun_type_labels[i].text = _original_texts[i]

	# ═══ Phase 4: Outcome + finalize ═══
	if is_pass:
		GlobalTweens.burst_particles(get_viewport_rect().size * 0.5, "sakura")
		GlobalTweens.do_hit_stop(0.08, 0.05)
		GlobalTweens.punch_in(ui.score_label, 0.4, 1.5)
		await get_tree().create_timer(0.6).timeout
		SealController.finalize_play(gs, play_data)
	elif is_fail:
		GlobalTweens.screen_shake(0.2, 0.12)
		GlobalTweens.color_flash(ui.game_bg, Color(0.6, 0.1, 0.1, 1.0), 0.3)
		await get_tree().create_timer(0.6).timeout
		SealController.finalize_play(gs, play_data)
	else:
		await get_tree().create_timer(0.3).timeout
		SealController.finalize_play(gs, play_data)

	_current_play_data.clear()


# ══════════════════════════════════════════
# Score animation helpers
# ══════════════════════════════════════════

## Float "+N" text upward from score_label, then free it.
## Added to panel_bg (not anchor) because anchor is inside a VBoxContainer
## which would override the floater's position.
func _float_score_gain(anchor: Label, gain: int, color: Color) -> void:
	var floater := Label.new()
	floater.text = "+ %d" % gain
	floater.add_theme_font_size_override("font_size", 36)
	floater.add_theme_color_override("font_color", color)
	floater.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.panel_bg.add_child(floater)
	floater.global_position = anchor.global_position + Vector2(anchor.size.x * 0.5 - 60, -20)
	floater.size = Vector2(120, 40)

	var tw := floater.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(floater, "position:y", floater.position.y - 60, 1.0).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(floater, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tw.tween_callback(floater.queue_free)


## Show a brief toast-like breakdown text that fades out and self-frees.
## Frees any previous active toast before creating a new one to avoid overlap.
func _show_breakdown_toast(text: String, _color: Color) -> void:
	if _active_toast != null and is_instance_valid(_active_toast):
		_active_toast.queue_free()

	var toast := Label.new()
	toast.text = text
	toast.add_theme_font_size_override("font_size", 16)
	toast.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85, 1.0))
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.panel_bg.add_child(toast)
	toast.anchor_left = 0.0
	toast.anchor_right = 1.0
	toast.offset_top = ui.score_label.position.y + ui.score_label.size.y + 8
	toast.offset_bottom = toast.offset_top + 50

	var tw := toast.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_interval(1.5)
	tw.tween_property(toast, "modulate:a", 0.0, 0.5)
	tw.tween_callback(toast.queue_free)

	_active_toast = toast
