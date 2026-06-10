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
	var focus_title: TextureRect = config.get("focus_title") as TextureRect
	var focus_ability: TextureRect = config.get("focus_ability") as TextureRect
	var focus_item: TextureRect = config.get("focus_item") as TextureRect
	var focus_bottom: TextureRect = config.get("focus_bottom") as TextureRect
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
		var tw := TweenFX.slide_in(panel, TweenFX.SlideDir.DOWN, 0.5)
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
