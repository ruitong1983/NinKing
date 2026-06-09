extends Control

## Main game flow coordinator — UI operations delegated to UIManager.
## NinKing v2: 9 cards → 3 groups × 3 cards (比鸡 + 忍者牌)

const CountUp = preload("res://scripts/tween/count_up.gd")

@onready var ui: UIManager = %UIManager

# Cached play data during scoring animation (A7)
var _current_play_data: Dictionary = {}

# CRT scanline drift (V18-V19)
var _crt_offset: float = 0.0

# Double-click guard for scene transitions (V13)
var _transition_guard: bool = false


func _ready() -> void:
	ui.play_btn.pressed.connect(_on_play_pressed)
	ui.redraw_btn.pressed.connect(_on_redraw_pressed)
	ui.ai_rearrange_btn.pressed.connect(_on_ai_rearrange_pressed)
	ui.to_shop_button.pressed.connect(_on_go_shop_pressed)
	ui.retry_button.pressed.connect(_on_retry_pressed)

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


func _process(_delta: float) -> void:
	# CRT scanline slow downward drift (one full cycle ≈ 35 sec @ 60 fps)
	_crt_offset += 0.003
	GlobalTweens.crt.set_offset(_crt_offset)


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
		NinKingGameState.State.VICTORY:
			ui.show_view("victory")


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

	# ── Barrier theme: apply cold/warm palette (V19) ──
	var c: Dictionary = BarrierTheme.get_colors(barrier)
	ui.game_bg.color = c.bg
	ui.panel_bg.color = c.panel
	ui.progress_bar.add_theme_color_override("font_color", c.accent)
	ui.progress_bar.add_theme_color_override("font_outline_color", c.accent)

	# Button accent colors follow barrier
	var btns: Array[Button] = [ui.play_btn, ui.redraw_btn, ui.deck_btn]
	for btn: Button in btns:
		btn.add_theme_color_override("font_color", c.accent)
		btn.add_theme_color_override("font_hover_color", c.accent.lightened(0.2))
		btn.add_theme_color_override("font_pressed_color", c.accent.darkened(0.3))

	# Boss reveal: 墨字浮现 — oppressive CRT + text pop
	if seal_lord_name != "":
		GlobalTweens.crt.set_vignette(0.5)
		GlobalTweens.crt.set_aberration(0.3)
		ui.level_intro.visible = true
		GlobalTweens.scale_pop(ui.intro_target_label, 1.2, 0.3)
		await get_tree().create_timer(1.0).timeout
		GlobalTweens.crt.set_vignette(0.2)
		GlobalTweens.crt.set_aberration(0.0)


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

	_current_play_data = play_data
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
	get_tree().reload_current_scene()


func _update_deck_display() -> void:
	var dm: DeckManager = NinKingGameState.deck_manager
	if dm != null:
		ui.update_deck_count(dm.draw_pile.size(), dm.discard_pile.size())


# ══════════════════════════════════════════
# Scoring animation (A7)
# ══════════════════════════════════════════

func _run_scoring_animation() -> void:
	var play_data: Dictionary = _current_play_data
	var score_result: ScoreCalculator.ScoreResult = play_data["score_result"]
	var xi_result: XiDetector.XiResult = play_data["xi_result"]

	var gs = NinKingGameState
	var old_score: int = int(gs.current_score)
	var new_score: int = old_score + int(score_result.total_score)

	# Determine outcome before finalize
	var is_pass: bool = new_score >= int(gs.target_score)
	var is_fail: bool = (gs.plays_remaining <= 1) and not is_pass

	# ── Phase 1: Group reveal ──
	await GlobalTweens.fade_in(ui.scoring_overlay, 0.25).finished
	var type_labels: Array[Label] = [ui.head_type_label, ui.mid_type_label, ui.tail_type_label]
	for lbl: Label in type_labels:
		lbl.visible = true
	GlobalTweens.stagger_slide_in(type_labels, 0.12, 0.3)
	ui.flash_all_hand_cards()
	await get_tree().create_timer(0.7).timeout

	# ── Phase 2: Score count-up (old → new using CountUp directly for from_value) ──
	CountUp.play(ui.score_label, old_score, new_score, 0.5, "忍気 ")
	var breakdown_text: String = "筹码 %d  ×  倍率 %d" % [int(score_result.chips_sum), int(score_result.mult_sum)]
	if score_result.x_mult_product > 1.0:
		breakdown_text += "  ×%.1f" % score_result.x_mult_product
	var col_chips: int = score_result.breakdown.get("col_chips", 0)
	var col_mult: int = score_result.breakdown.get("col_mult", 0)
	if col_chips > 0 or col_mult > 0:
		breakdown_text += "\n列: +%d筹码 +%d倍率" % [col_chips, col_mult]
	ui.score_breakdown.text = breakdown_text

	# Column VFX celebration (col ≥ 同花顺 → shuriken burst + color flash)
	var col_evals: Array = play_data.get("col_evals", [])
	if col_evals.size() == 3:
		for i: int in range(3):
			var ct: CardData.HandType3 = col_evals[i].hand_type
			if int(ct) >= int(CardData.HandType3.STRAIGHT_FLUSH_3):
				var col_labels: Array[Label] = [ui.col0_label, ui.col1_label, ui.col2_label]
				GlobalTweens.burst_particles(col_labels[i].global_position + col_labels[i].size * 0.5, "shuriken")
				GlobalTweens.color_flash(col_labels[i], Color(0.831, 0.659, 0.263, 1.0), 0.15)
	await get_tree().create_timer(0.65).timeout

	# ── Phase 3: Xi effects ──
	if xi_result and xi_result.has_any():
		GlobalTweens.burst_particles(get_viewport_rect().size * 0.5, "shuriken")
		GlobalTweens.do_hit_stop(0.06, 0.05)
		GlobalTweens.screen_shake(0.12, 0.08)
		var xi_names: Array[String] = []
		for xi_name: String in xi_result.triggered:
			xi_names.append(xi_name)
		ui.score_breakdown.text += "\n喜: " + ", ".join(xi_names)
		await get_tree().create_timer(0.5).timeout

	# ── Phase 4: Outcome + finalize ──
	if is_pass:
		GlobalTweens.burst_particles(get_viewport_rect().size * 0.5, "sakura")
		GlobalTweens.do_hit_stop(0.08, 0.05)
		GlobalTweens.punch_in(ui.score_value_label, 0.4, 1.5)
		await get_tree().create_timer(0.6).timeout
		SealController.finalize_play(gs, play_data)
	elif is_fail:
		GlobalTweens.screen_shake(0.2, 0.12)
		GlobalTweens.crt.set_aberration(0.5)
		GlobalTweens.color_flash(ui.scoring_overlay, Color(0.6, 0.1, 0.1, 1.0), 0.3)
		await get_tree().create_timer(0.6).timeout
		GlobalTweens.crt.set_aberration(0.0)
		SealController.finalize_play(gs, play_data)
	else:
		await GlobalTweens.fade_out(ui.scoring_overlay, 0.25).finished
		SealController.finalize_play(gs, play_data)

	_current_play_data.clear()
