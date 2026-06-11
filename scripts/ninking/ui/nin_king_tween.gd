class_name NinKingTween
extends RefCounted
## Project-level anime-style animation sequences.
##
## Delegates to GlobalTweens/TweenFX for individual tweens.
## Does NOT modify GlobalTweens or TweenFX.
##
## Usage:
##   await NinKingTween.play_shop_entrance({overlay = ..., panel = ..., ...})


static func play_shop_entrance(config: Dictionary) -> void:
	## Play the full shop entrance sequence (~1.6s total). Await-safe.
	##
	## Each await is guarded with is_instance_valid(panel) —
	## if the scene is unloaded mid-animation, the sequence aborts silently.
	##
	## config keys:
	##   overlay: ColorRect          — full-screen dark overlay (fade in)
	##   panel: Control              — shop panel (slam from below, anchor for validity checks)
	##   all_cards: Array[Control]   — ability + item cards (stagger pop in)
	##   focus_title: TextureRect    — title-bar focus lines (fade in)
	##   focus_ability: TextureRect  — ability-section focus lines (fade in)
	##   focus_item: TextureRect     — item-section focus lines (fade in)
	##   focus_bottom: TextureRect   — bottom-bar focus lines (fade in)
	##   whoosh_sfx: AudioStream     — panel descent whoosh (optional)
	##   impact_sfx: AudioStream     — panel landing impact (optional)

	var overlay: ColorRect = config.get("overlay") as ColorRect
	var panel: Control = config.get("panel") as Control
	var all_cards: Array = config.get("all_cards", [])
	var focus_title: ColorRect = config.get("focus_title") as ColorRect
	var focus_ability: ColorRect = config.get("focus_ability") as ColorRect
	var focus_item: ColorRect = config.get("focus_item") as ColorRect
	var focus_bottom: ColorRect = config.get("focus_bottom") as ColorRect
	var whoosh_sfx: AudioStream = config.get("whoosh_sfx") as AudioStream
	var impact_sfx: AudioStream = config.get("impact_sfx") as AudioStream

	# ── Phase 0: Overlay fade in (0.4s) ──
	if overlay and is_instance_valid(overlay):
		overlay.modulate.a = 0.0
		GlobalTweens.fade_in(overlay, 0.4)

	# ── 溜め: brief silence (0.2s) ──
	await Engine.get_main_loop().create_timer(0.2).timeout
	if not is_instance_valid(panel):
		return

	# ── Phase 1: Panel slam from below (0.5s) ──
	if panel:
		if whoosh_sfx:
			GlobalTweens.play_sfx(whoosh_sfx)
		var tw := GlobalTweens.slide_in(panel, TweenFX.SlideDir.DOWN, 0.5)
		if tw:
			await tw.finished
	if not is_instance_valid(panel):
		return

	# ── Phase 2: Landing impact ──
	if impact_sfx:
		GlobalTweens.play_sfx(impact_sfx)
	GlobalTweens.do_hit_stop(0.08, 0.05)
	GlobalTweens.shake_node(panel, 6.0, 0.15)
	# Temporary speed-line substitute until V26 manga_speed is ready
	GlobalTweens.burst_particles(panel.global_position + panel.size * 0.5, "shuriken")

	# ── 溜め: hold the impact (0.25s) ──
	await Engine.get_main_loop().create_timer(0.25).timeout
	if not is_instance_valid(panel):
		return

	# ── Phase 3: Focus lines stagger ──
	var focus_dur: float = 0.3
	if focus_title and is_instance_valid(focus_title):
		focus_title.modulate.a = 0.0
		GlobalTweens.fade_in(focus_title, focus_dur)
	await Engine.get_main_loop().create_timer(0.15).timeout
	if not is_instance_valid(panel):
		return

	if focus_ability and is_instance_valid(focus_ability):
		focus_ability.modulate.a = 0.0
		GlobalTweens.fade_in(focus_ability, focus_dur)
	await Engine.get_main_loop().create_timer(0.15).timeout
	if not is_instance_valid(panel):
		return

	if focus_item and is_instance_valid(focus_item):
		focus_item.modulate.a = 0.0
		GlobalTweens.fade_in(focus_item, focus_dur)

	if focus_bottom and is_instance_valid(focus_bottom):
		focus_bottom.modulate.a = 0.0
		focus_bottom.visible = true
		GlobalTweens.fade_in(focus_bottom, focus_dur)

	# ── Phase 4: Cards stagger pop in ──
	if not all_cards.is_empty():
		GlobalTweens.stagger_slide_in(all_cards, 0.1, 0.3, 30.0)


static func play_shop_exit(config: Dictionary) -> void:
	## Play the shop exit sequence (Phase C): cards gather → panel slide out → overlay fade out.
	## Each await guarded with is_instance_valid(panel).
	##
	## config keys:
	##   overlay: ColorRect          — dark overlay (fade out)
	##   panel: Control              — shop panel (validity anchor + slide out)
	##   all_cards: Array[Control]   — ability + item cards (gather to center then fade)
	##   center_pos: Vector2         — gather target position (default: panel center)

	var overlay: ColorRect = config.get("overlay") as ColorRect
	var panel: Control = config.get("panel") as Control
	var all_cards: Array = config.get("all_cards", [])
	var center_pos: Vector2 = config.get("center_pos",
		panel.get_viewport_rect().size * 0.5 if panel else Vector2(960, 540))

	# ── Phase 1: Cards gather to center (0.3s) ──
	for card in all_cards:
		if is_instance_valid(card):
			var tw: Tween = card.create_tween()
			tw.set_parallel()
			tw.tween_property(card, "scale", Vector2(0.1, 0.1), 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
			tw.tween_property(card, "global_position", center_pos, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
			tw.tween_property(card, "modulate:a", 0.0, 0.25)

	if not is_instance_valid(panel):
		return
	await panel.get_tree().create_timer(0.3).timeout
	if not is_instance_valid(panel):
		return

	# ── Phase 2: Panel slide out downward (0.3s) ──
	if panel:
		GlobalTweens.play_sfx(preload("res://scripts/config/sound_bank.gd").SHOP_EXIT)
		var tw: Tween = panel.create_tween()
		tw.tween_property(panel, "position:y", panel.get_viewport_rect().size.y + 100, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		tw.parallel().tween_property(panel, "modulate:a", 0.0, 0.25)
		await tw.finished

	if not is_instance_valid(panel):
		return

	# ── Phase 3: Overlay fade out (0.2s) ──
	if overlay and is_instance_valid(overlay):
		GlobalTweens.fade_out(overlay, 0.2)


static func play_reroll_vfx(old_cards: Array, new_cards_callback: Callable) -> void:
	## Play reroll VFX: old cards blow away → callback generates new cards → new cards slide in.
	## new_cards_callback: Callable() that returns the new Array[Control] after stock refresh.
	##
	## Usage:
	##   await NinKingTween.play_reroll_vfx(ability_cards + item_cards, func(): ... )

	# ── Phase 1: Old cards blow away (0.3s) ──
	var rng := RandomNumberGenerator.new()
	for card in old_cards:
		if not is_instance_valid(card):
			continue
		var tw: Tween = card.create_tween()
		tw.set_parallel()
		var angle: float = rng.randf_range(-60.0, 60.0)
		var dist: float = rng.randf_range(300.0, 600.0)
		var fly_to: Vector2 = card.global_position + Vector2(
			cos(deg_to_rad(angle)) * dist,
			sin(deg_to_rad(angle)) * dist - 200.0  # bias upward
		)
		tw.tween_property(card, "global_position", fly_to, 0.3).set_ease(Tween.EASE_IN)
		tw.tween_property(card, "modulate:a", 0.0, 0.25)
		tw.tween_property(card, "rotation", deg_to_rad(rng.randf_range(-30.0, 30.0)), 0.3)

	await Engine.get_main_loop().create_timer(0.35).timeout

	# ── Phase 2: Generate new cards via callback ──
	var new_cards: Array = new_cards_callback.call()

	# ── Phase 3: New cards slide in from above (0.3s stagger) ──
	if not new_cards.is_empty():
		GlobalTweens.stagger_slide_in(new_cards, 0.08, 0.3, -60.0)


static func play_ninja_pop_in(slot_node: CanvasItem) -> void:
	## New ninja slot pop-in: scale_pop + gold flash. Fire-and-forget.
	if not is_instance_valid(slot_node):
		return
	GlobalTweens.scale_pop(slot_node, 1.3, 0.3)
	GlobalTweens.color_flash(slot_node, Color.GOLD, 0.2)
