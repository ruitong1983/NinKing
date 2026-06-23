extends Control

## Main game flow coordinator — UI operations delegated to UIManager.
## NinKing v2: 9 cards -> 3 groups x 3 cards (比鸡 + 忍者牌)
## Phase C: 同场景 immersive flow — shop as overlay, no scene switching.
## C21: Shop logic -> ShopHandler, scoring animation -> AnimationHandler.
## Phase E: No LevelComplete overlay — settlement card with 封印解除 button → shop.

## v10: Unified button entrance animation via ButtonStyles.attach_entrance_animation.
##      Replaced local attract_pulse calls.

const SB = preload("res://scripts/config/sound_bank.gd")

@onready var ui: UIManager = %UIManager

# Delegates (C21)
var shop_handler: ShopHandler
var animation_handler: AnimationHandler

# Boss reveal guard — Phase C
var _boss_revealed: bool = false

# Auto-shop: SCORING -> shop transition without click (Balatro-style)
var _auto_shop_pending: bool = false


func _ready() -> void:
	# Init delegates
	shop_handler = ShopHandler.new()
	shop_handler.setup(ui)
	animation_handler = AnimationHandler.new()
	var _mark_cb := func(): _auto_shop_pending = true
	animation_handler.setup(ui, _mark_cb)

	# Wire UI buttons
	ui.play_btn.pressed.connect(_on_play_pressed)
	ui.ai_rearrange_btn.pressed.connect(_on_ai_rearrange_pressed)
	ui.retry_button.pressed.connect(_on_retry_pressed)
	ui.back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)
	ui.victory_menu_button.pressed.connect(_on_back_to_menu_pressed)

	# Phase E: Settlement card button (await in _show_settlement_card, no direct connection)

	# Phase C: Shop overlay signals -> delegate
	ui.shop_purchase_requested.connect(shop_handler.on_purchase_requested)
	ui.shop_item_purchase_requested.connect(shop_handler.on_item_purchase_requested)
	ui.shop_reroll_requested.connect(shop_handler.on_reroll_requested)
	ui.shop_continue_requested.connect(shop_handler.on_continue_requested)

	# State signals
	NinKingGameState.state_changed.connect(_on_state_changed)
	NinKingGameState.score_updated.connect(_on_score_updated)
	NinKingGameState.plays_changed.connect(_on_plays_changed)
	NinKingGameState.gold_changed.connect(_on_gold_changed)
	NinKingGameState.hand_updated.connect(_on_hand_updated)
	NinKingGameState.hand_swapped.connect(_on_hand_swapped)
	NinKingGameState.seal_started.connect(_on_seal_started)
	NinKingGameState.xi_triggered.connect(_on_xi_triggered)

	# A3: Ink-bleed edge fade — left panel right edge blends into background
	GlobalShaders.apply_edge_fade(ui.panel_bg)
	GlobalShaders.apply_edge_fade(ui.left_panel.get_node("HandTypePanel"))
	GlobalShaders.apply_edge_fade(ui.left_panel.get_node("ScorePanel"))
	GlobalShaders.apply_edge_fade(ui.left_panel.get_node("MatchPanel"))
	GlobalShaders.apply_edge_fade(ui.left_panel.get_node("AntePanel"))

	_on_state_changed(NinKingGameState.current_state)
	ui.restore_ui_state()

	# Replay lost seal_started signal — emitted in launcher before this scene loaded
	_on_seal_started(
		NinKingGameState.barrier_num,
		NinKingGameState.seal_idx,
		float(NinKingGameState.target_score),
		NinKingGameState.current_seal_lord_name
	)

	# SEAL_INTRO -> PLAYING timer now fires from _on_state_changed on every seal entry


# ═══ State callbacks ═══

func _on_state_changed(new_state: NinKingGameState.State) -> void:
	match new_state:
		NinKingGameState.State.SEAL_INTRO:
			ui.show_view("intro")
			_intro_timer()
		NinKingGameState.State.PLAYING:
			ui.show_view("game")
			# Reset table after shop (Phase C)
			ui.game_layout.modulate = Color.WHITE
			# Restore hand area if dimmed during shop
			if ui.game_layout.has_node("CenterColumn/HandArea"):
				ui.game_layout.get_node("CenterColumn/HandArea").modulate = Color.WHITE
			GlobalTweens.play_sfx(SB.DEAL)  # C17: deal SFX
			# 按钮统一入场动效（弹跳 + 粒子 + 脉冲 + hover + 点击）
			ButtonStyles.attach_entrance_animation(ui.play_btn)
			ButtonStyles.attach_entrance_animation(ui.ai_rearrange_btn, {"mild": true})
			# hand refresh is already triggered by auto_arrange() → hand_updated signal
			ui.refresh_ninjas(NinKingGameState.owned_ninjas, NinKingGameState.max_ninja_slots)
			ui.ai_rearrange_btn.disabled = false
			_update_deck_display()
			# Phase C: Boss reveal happens in PLAYING (not during SEAL_INTRO)
			_boss_revealed = false
			if NinKingGameState.current_seal_lord_name != "":
				_trigger_boss_reveal_in_playing()
		NinKingGameState.State.SCORING:
			ui.show_view("scoring")
			animation_handler.run_scoring()
		NinKingGameState.State.SEAL_COMPLETE:
			ui.show_view("settlement")
			if _auto_shop_pending:
				_auto_shop_pending = false
				_show_settlement_card()
		NinKingGameState.State.SHOP:
			shop_handler.on_enter_shop()
		NinKingGameState.State.GAME_OVER:
			ui.show_view("gameover")
			ui.show_game_over("not enough score", NinKingGameState.barrier_num, int(NinKingGameState.current_score))
			# GameOver 按钮统一入场动效
			ButtonStyles.attach_entrance_animation(ui.retry_button, {"mild": true})
			ButtonStyles.attach_entrance_animation(ui.back_to_menu_button, {"mild": true})
		NinKingGameState.State.VICTORY:
			_auto_shop_pending = false  # Safety: clear in case finalize_play reached victory
			ui.show_view("victory")
			ui.set_victory(NinKingGameState.barrier_num, int(NinKingGameState.current_score))
			# Victory celebration VFX (V34)
			GlobalTweens.play_sfx(SB.XI_FANFARE)
			GlobalTweens.burst_particles(get_viewport_rect().size * 0.5, "manga_burst")
			GlobalTweens.do_hit_stop(0.1, 0.05)
			GlobalTweens.screen_shake(0.15, 0.1)
			MusicManager.set_game_variation(1)  # Light BGM for victory screen
			# Victory 按钮入场动效
			ButtonStyles.attach_entrance_animation(ui.victory_menu_button, {"mild": true})


func _on_score_updated(current: float, target: float) -> void:
	ui.update_score(int(current), int(target))


func _on_plays_changed(remaining: int) -> void:
	ui.update_match_info(remaining)


func _on_gold_changed(amount: int) -> void:
	ui.update_gold(amount)
	if ui.is_shop_open():
		ui.shop_panel_update_gold(amount)


func _on_hand_updated(_hand: Array) -> void:
	ui.refresh_hand(NinKingGameState.hand)
	_update_deck_display()


func _on_hand_swapped(src: int, tgt: int) -> void:
	ui.on_cards_swapped(src, tgt)
	_update_deck_display()


func _on_seal_started(barrier: int, seal_idx: int, target: float, seal_lord_name: String) -> void:
	ui.on_seal_start(barrier, seal_idx, int(target), seal_lord_name)

	# Barrier theme: apply 8-attribute bright palette (V25)
	var c: Dictionary = BarrierTheme.get_colors(barrier)
	ui.game_bg.modulate = c.bg
	ui.panel_bg.color = c.panel
	ui.progress_bar.add_theme_color_override("font_color", c.accent)
	ui.progress_bar.add_theme_color_override("font_outline_color", c.accent)

	# BGM: auto-switch variation based on barrier difficulty (B11)
	MusicManager.set_game_variation(barrier)

	# Manga-style impact buttons — ButtonStyles.apply_manga handles all font colors
	ButtonStyles.apply_manga(ui.play_btn, c.accent, "L")
	ButtonStyles.apply_manga(ui.ai_rearrange_btn, c.accent, "M")
	ButtonStyles.apply_manga(ui.deck_btn, c.accent, "S")
	ButtonStyles.apply_manga(ui.retry_button, c.accent, "S")
	ButtonStyles.apply_manga(ui.back_to_menu_button, c.accent, "S")
	ButtonStyles.apply_manga(ui.victory_menu_button, c.accent, "S")

	# Phase C: Boss reveal moved to PLAYING state (_trigger_boss_reveal_in_playing).
	# No more 1s wait here. Theme + intro watermark only.


func _on_xi_triggered(xis: Array[String]) -> void:
	if NinKingGameState.current_state == NinKingGameState.State.SCORING:
		return  # Already handled in animation Phase 3
	ui.show_xi_popup(xis)


# ═══ Button handlers ═══

func _on_play_pressed() -> void:
	if NinKingGameState.current_state != NinKingGameState.State.PLAYING:
		return
	if not NinKingGameState.is_constraint_satisfied():
		return

	# 停止讨伐按钮脉冲，进入计分流程
	GlobalTweens.kill_domain(ui.play_btn, "modulate")

	# Pre-compute scoring (no state mutation) — A7 animation flow
	var play_data: Dictionary = SealController.prepare_play(NinKingGameState)
	if play_data.is_empty():
		return

	# Capture per-dun evals for A7 sequential reveal
	var arr: Arrangement = NinKingGameState.current_arrangement
	animation_handler.current_play_data = play_data
	animation_handler.current_play_data["head_eval"] = arr.head_eval
	animation_handler.current_play_data["mid_eval"] = arr.mid_eval
	animation_handler.current_play_data["tail_eval"] = arr.tail_eval
	# Compute column evaluations for Phase 2 animation
	var col_evals: Array[HandEvaluator3.EvalResult] = []
	for i: int in range(3):
		var col_cards: Array[CardData.PlayingCard] = [arr.head[i], arr.mid[i], arr.tail[i]]
		col_evals.append(HandEvaluator3.evaluate(col_cards))
	animation_handler.current_play_data["col_evals"] = col_evals
	animation_handler.current_play_data["gold_before_settlement"] = NinKingGameState.gold
	NinKingGameState._transition_to(NinKingGameState.State.SCORING)


func _on_ai_rearrange_pressed() -> void:
	if NinKingGameState.current_state != NinKingGameState.State.PLAYING:
		return
	NinKingGameState.auto_arrange()
	# auto_arrange() emits hand_updated — UI refresh bound via signal


func _on_retry_pressed() -> void:
	NinKingGameState.start_new_run("standard")
	get_tree().change_scene_to_file("res://scenes/ninking/ninking_main.tscn")


func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ninking/ninking_launcher.tscn")


func _update_deck_display() -> void:
	var dm: DeckManager = NinKingGameState.deck_manager
	if dm != null:
		ui.update_deck_count(dm.draw_pile.size())


# ══════════════════════════════════════════
# Intro timer — SEAL_INTRO -> PLAYING
# ══════════════════════════════════════════

## Phase C: Wait 0.5 seconds for intro watermark, then transition to PLAYING.
func _intro_timer() -> void:
	await get_tree().create_timer(0.5).timeout
	if NinKingGameState.current_state == NinKingGameState.State.SEAL_INTRO:
		NinKingGameState._transition_to(NinKingGameState.State.PLAYING)


# ══════════════════════════════════════════
# Boss reveal in PLAYING (Phase C)
# ══════════════════════════════════════════

func _trigger_boss_reveal_in_playing() -> void:
	## Boss lord revealed mid-PLAYING: brief delay then punch-in portrait.
	## Player can still interact with cards during the reveal.
	await get_tree().create_timer(0.3).timeout
	if NinKingGameState.current_state != NinKingGameState.State.PLAYING or _boss_revealed:
		return
	_boss_revealed = true

	var lord_name: String = NinKingGameState.current_seal_lord_name
	if lord_name == "":
		return
	var barrier: int = NinKingGameState.barrier_num

	if barrier >= 8:
		GlobalTweens.play_sfx(SB.BOSS_FINAL_LAYER)
	else:
		GlobalTweens.play_sfx(SB.BOSS_REVEAL)

	ui.boss_portrait.visible = true
	GlobalTweens.punch_in(ui.boss_portrait, 0.4, 1.5)
	GlobalTweens.scale_pop(ui.intro_target_label, 1.2, 0.3)

	# Float for 1.5s — player can still interact
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(ui.boss_portrait):
		GlobalTweens.fade_out(ui.boss_portrait, 0.3)

# ══════════════════════════════════════════
# Phase E: Settlement card — 封印解除
# ══════════════════════════════════════════

func _show_settlement_card() -> void:
	## Show settlement card with score/gold info, then wait for button press.
	var old_gold: int = animation_handler.current_play_data.get("gold_before_settlement", -1)
	var gain: int = max(0, NinKingGameState.gold - old_gold) if old_gold >= 0 else 0
	ui.settlement_overlay.show_card({
		barrier_num = NinKingGameState.barrier_num,
		seal_idx = NinKingGameState.seal_idx,
		num = NinKingGameState.current_score,
		gold_gained = gain,
		total_gold = NinKingGameState.gold,
		seal_lord_name = NinKingGameState.current_seal_lord_name,
	})

	# Wait for button press (card manages its own lifecycle)
	await ui.settlement_overlay.unlock_pressed
	_on_settlement_unlock()


func _on_settlement_unlock() -> void:
	## Handle settlement card button — proceed to shop.
	if not is_instance_valid(ui):
		return
	if NinKingGameState.current_state != NinKingGameState.State.SEAL_COMPLETE:
		return
	shop_handler.go_shop_pressed()
