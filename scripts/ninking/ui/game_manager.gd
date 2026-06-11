extends Control

## Main game flow coordinator — UI operations delegated to UIManager.
## NinKing v2: 9 cards → 3 groups × 3 cards (比鸡 + 忍者牌)
## Phase C: 同场景 immersive flow — shop as overlay, no scene switching.
## C21: Shop logic → ShopHandler, scoring animation → AnimationHandler.

const SB = preload("res://scripts/config/sound_bank.gd")

@onready var ui: UIManager = %UIManager

# Delegates (C21)
var shop_handler: ShopHandler
var animation_handler: AnimationHandler

# Boss reveal guard — Phase C
var _boss_revealed: bool = false

# Auto-shop: SCORING → shop transition without click (Balatro-style)
var _auto_shop_pending: bool = false


func _ready() -> void:
	# Init delegates
	shop_handler = ShopHandler.new()
	shop_handler.setup(ui)
	animation_handler = AnimationHandler.new()
	animation_handler.setup(ui, func(): _auto_shop_pending = true)

	# Wire UI buttons
	ui.play_btn.pressed.connect(_on_play_pressed)
	ui.ai_rearrange_btn.pressed.connect(_on_ai_rearrange_pressed)
	ui.to_shop_button.pressed.connect(shop_handler.go_shop_pressed)
	ui.retry_button.pressed.connect(_on_retry_pressed)
	ui.back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)
	ui.victory_menu_button.pressed.connect(_on_back_to_menu_pressed)

	# Phase C: Shop overlay signals → delegate
	ui.shop_purchase_requested.connect(shop_handler.on_purchase_requested)
	ui.shop_enchant_purchase_requested.connect(shop_handler.on_enchant_purchase_requested)

	ui.shop_item_purchase_requested.connect(shop_handler.on_item_purchase_requested)
	ui.shop_reroll_requested.connect(shop_handler.on_reroll_requested)
	ui.shop_continue_requested.connect(shop_handler.on_continue_requested)

	# State signals
	NinKingGameState.state_changed.connect(_on_state_changed)
	NinKingGameState.score_updated.connect(_on_score_updated)
	NinKingGameState.plays_changed.connect(_on_plays_changed)
	NinKingGameState.gold_changed.connect(_on_gold_changed)
	NinKingGameState.hand_updated.connect(_on_hand_updated)
	NinKingGameState.arrangement_changed.connect(_on_arrangement_changed)
	NinKingGameState.seal_started.connect(_on_seal_started)
	NinKingGameState.xi_triggered.connect(_on_xi_triggered)

	# A3: Ink-bleed edge fade — left panel right edge blends into background
	var fade_shader: Shader = preload("res://scripts/ninking/ui/panel_edge_fade.gdshader")
	var make_fade := func(node: Node) -> void:
		var m := ShaderMaterial.new()
		m.shader = fade_shader
		m.set_shader_parameter("fade_start", 0.64)
		node.material = m
	make_fade.call(ui.panel_bg)
	make_fade.call(ui.score_card)
	make_fade.call(ui.left_panel.get_node("MatchPanel"))
	make_fade.call(ui.left_panel.get_node("AntePanel"))

	_on_state_changed(NinKingGameState.current_state)
	ui.restore_ui_state()

	# Replay lost seal_started signal — emitted in launcher before this scene loaded
	_on_seal_started(
		NinKingGameState.barrier_num,
		NinKingGameState.seal_idx,
		float(NinKingGameState.target_score),
		NinKingGameState.current_seal_lord_name
	)

	# SEAL_INTRO → PLAYING timer now fires from _on_state_changed on every seal entry


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
			GlobalTweens.play_sfx(SB.DEAL)  # C17: 发牌音效
			ui.refresh_hand(NinKingGameState.hand)
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
			ui.show_view("complete")
			var seal_cfg: Dictionary = BarrierConfig.get_seal(NinKingGameState.barrier_num, NinKingGameState.seal_idx)
			ui.set_level_complete(seal_cfg.get("gold", 0))

			# Auto-shop: show reward briefly then auto-enter shop (Balatro-style)
			if _auto_shop_pending:
				_auto_shop_pending = false
				await get_tree().create_timer(1.2).timeout
				if is_instance_valid(ui) and NinKingGameState.current_state == NinKingGameState.State.SEAL_COMPLETE:
					shop_handler.go_shop_pressed()
		NinKingGameState.State.SHOP:
			shop_handler.on_enter_shop()
		NinKingGameState.State.GAME_OVER:
			ui.show_view("gameover")
			ui.show_game_over("忍気不足", NinKingGameState.barrier_num, int(NinKingGameState.current_score))
		NinKingGameState.State.VICTORY:
			_auto_shop_pending = false  # Safety: clear in case finalize_play reached victory
			ui.show_view("victory")
			ui.set_victory(NinKingGameState.barrier_num, int(NinKingGameState.current_score))
			# ── Victory celebration VFX (V34) ──
			GlobalTweens.play_sfx(SB.XI_FANFARE)
			GlobalTweens.burst_particles(get_viewport_rect().size * 0.5, "manga_burst")
			GlobalTweens.do_hit_stop(0.1, 0.05)
			GlobalTweens.screen_shake(0.15, 0.1)
			MusicManager.set_game_variation(1)  # Light BGM for victory screen


func _on_score_updated(current: float, target: float) -> void:
	ui.update_score(int(current), int(target))


func _on_plays_changed(remaining: int) -> void:
	ui.update_match_info(remaining)


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
	ui.game_bg.modulate = c.bg
	ui.panel_bg.color = c.panel
	ui.progress_bar.add_theme_color_override("font_color", c.accent)
	ui.progress_bar.add_theme_color_override("font_outline_color", c.accent)

	# ── BGM: auto-switch variation based on barrier difficulty (B11) ──
	MusicManager.set_game_variation(barrier)

	# Accent font only for neutral-bg buttons
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

	# ⚠️ Phase C: Boss reveal moved to PLAYING state (_trigger_boss_reveal_in_playing).
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

	# Pre-compute scoring (no state mutation) — A7 animation flow
	var play_data: Dictionary = SealController.prepare_play(NinKingGameState)
	if play_data.is_empty():
		return

	# Capture per-dun evals for A7 sequential reveal
	var arr: AutoArranger.Arrangement = NinKingGameState.current_arrangement
	animation_handler.current_play_data = play_data
	animation_handler.current_play_data["head_eval"] = arr.head_eval
	animation_handler.current_play_data["mid_eval"] = arr.mid_eval
	animation_handler.current_play_data["tail_eval"] = arr.tail_eval
	NinKingGameState._transition_to(NinKingGameState.State.SCORING)


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
