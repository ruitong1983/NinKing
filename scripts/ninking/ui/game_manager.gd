extends Control

## Main game flow coordinator — UI operations delegated to UIManager.
## NinKing v2: 9 cards -> 3 groups x 3 cards (比鸡 + 忍者牌)
## Phase C: 同场景 immersive flow — shop as overlay, no scene switching.
## C21: Shop logic -> ShopHandler, scoring animation -> AnimationHandler.
## Phase E: No LevelComplete overlay — gold flies into left panel, then auto-shop.

const SB = preload("res://scripts/config/sound_bank.gd")
const CountUp = preload("res://scripts/tween/count_up.gd")

@onready var ui: UIManager = %UIManager

# Delegates (C21)
var shop_handler: ShopHandler
var animation_handler: AnimationHandler

# Boss reveal guard — Phase C
var _boss_revealed: bool = false

# Auto-shop: SCORING -> shop transition without click (Balatro-style)
var _auto_shop_pending: bool = false

# Phase E: skip overlay for shop transition
var _shop_skip_overlay: Control = null
var _shop_skip_requested: bool = false


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
	var fade_shader: Shader = preload("res://scripts/ninking/ui/panel_edge_fade.gdshader")
	var make_fade := func(node: Node) -> void:
		var m := ShaderMaterial.new()
		m.shader = fade_shader
		m.set_shader_parameter("fade_start", 0.64)
		node.material = m
	make_fade.call(ui.panel_bg)
	make_fade.call(ui.left_panel.get_node("HandTypePanel"))
	make_fade.call(ui.left_panel.get_node("ScorePanel"))
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
			var seal_cfg: Dictionary = BarrierConfig.get_seal(NinKingGameState.barrier_num, NinKingGameState.seal_idx)
			var gold_reward: int = seal_cfg.get("gold", 0)
			var old_gold: int = animation_handler.current_play_data.get(
				"gold_before_settlement",
				max(0, NinKingGameState.gold - gold_reward - mini(floori(NinKingGameState.gold / 5.0), 5))
			)
			_play_gold_settlement(old_gold, NinKingGameState.gold, NinKingGameState.gold - old_gold)

			# Auto-shop with skip-on-click
			if _auto_shop_pending:
				_auto_shop_pending = false
				_create_shop_skip_overlay()
		NinKingGameState.State.SHOP:
			shop_handler.on_enter_shop()
		NinKingGameState.State.GAME_OVER:
			ui.show_view("gameover")
			ui.show_game_over("not enough score", NinKingGameState.barrier_num, int(NinKingGameState.current_score))
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


func _on_score_updated(current: float, target: float) -> void:
	ui.update_score(int(current), int(target))


func _on_plays_changed(remaining: int) -> void:
	ui.update_match_info(remaining)


func _on_gold_changed(amount: int) -> void:
	ui.update_gold(amount)


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

	# Accent font only for neutral-bg buttons
	var btns: Array[Button] = [
		ui.ai_rearrange_btn,
		ui.retry_button, ui.back_to_menu_button,
		ui.victory_menu_button,
	]
	for btn: Button in btns:
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_hover_color", Color(0.9, 0.9, 0.9))
		btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7))

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
# Phase E: Gold settlement animation
# ══════════════════════════════════════════

func _play_gold_settlement(old_gold: int, new_gold: int, gain: int) -> void:
	## Animate gold count-up on GoldLabel + float text flying to MatchPanel.
	if gain <= 0:
		return

	# Count up gold label from old to new value (0.5s)
	CountUp.play(ui.gold_label, old_gold, new_gold, 0.5, "$")

	# Create float text "+X$" near score area, fly to GoldLabel
	var floater := Label.new()
	floater.text = "+%d$" % gain
	floater.add_theme_font_size_override("font_size", 36)
	floater.add_theme_color_override("font_color", Color(0.941, 0.816, 0.376))
	floater.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Position above the score label (center of left panel area)
	var start_pos: Vector2 = ui.score_label.global_position + Vector2(ui.score_label.size.x * 0.5 - 60, -40)
	floater.global_position = start_pos
	floater.size = Vector2(120, 40)
	ui.panel_bg.add_child(floater)

	# Fly to GoldLabel position
	var target_pos: Vector2 = ui.gold_label.global_position + Vector2(ui.gold_label.size.x * 0.5 - 20, 0)
	var tw := floater.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(floater, "global_position", target_pos, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(floater, "scale", Vector2(0.7, 0.7), 0.5).set_ease(Tween.EASE_IN)

	# On arrival: flash + SFX
	tw.tween_callback(func():
		if is_instance_valid(floater):
			floater.queue_free()
		if is_instance_valid(ui.gold_label):
			GlobalTweens.scale_pop(ui.gold_label, 1.15, 0.2)
		GlobalTweens.play_sfx(SB.UI_COIN)
	)


# ══════════════════════════════════════════
# Phase E: Shop skip overlay + auto-enter
# ══════════════════════════════════════════

func _create_shop_skip_overlay() -> void:
	## Create transparent fullscreen overlay to skip shop wait on click/key.
	_shop_skip_requested = false
	_shop_skip_overlay = Control.new()
	_shop_skip_overlay.name = "ShopSkipOverlay"
	_shop_skip_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_shop_skip_overlay.anchor_right = 1.0
	_shop_skip_overlay.anchor_bottom = 1.0
	_shop_skip_overlay.gui_input.connect(_on_skip_overlay_input)
	add_child(_shop_skip_overlay)

	# Wait for 0.9s dwell, then enter shop (unless already skipped)
	await get_tree().create_timer(0.9).timeout
	_do_shop_transition()


func _on_skip_overlay_input(event: InputEvent) -> void:
	if _shop_skip_requested:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
		_shop_skip_requested = true
		_do_shop_transition()


func _do_shop_transition() -> void:
	## Clean up skip overlay and enter shop (guarded against double call by shop_handler).
	if _shop_skip_overlay != null and is_instance_valid(_shop_skip_overlay):
		_shop_skip_overlay.queue_free()
		_shop_skip_overlay = null
	if is_instance_valid(ui) and NinKingGameState.current_state == NinKingGameState.State.SEAL_COMPLETE:
		shop_handler.go_shop_pressed()
