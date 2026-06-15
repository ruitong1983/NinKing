class_name NinKingTween
extends RefCounted
## Project-level anime-style animation sequences.
##
## Delegates to GlobalTweens/TweenFX for individual tweens.
## Does NOT modify GlobalTweens or TweenFX.

# ─── Shared resources ───
const _sound_bank := preload("res://scripts/config/sound_bank.gd")


static func play_shop_entrance_manga(config: Dictionary) -> void:
	## 漫画格展开入场 (~0.95s total). Await-safe.
	##
	## 时序:
	##   0.00s  TopBorder scale_x: 0->1 墨线画出 + whoosh
	##   0.15s  StageBg scale_y: 0->1 背景刷出
	##   0.35s  TitleBar fade in
	##   0.45s  Cards stagger_pop_in (每张 0.06s 间隔, 0.25s dur)
	##   0.90s  impact_sfx 踩点
	##
	## config keys:
	##   top_border: ColorRect     — 顶部漫画格分割线
	##   stage_bg: ColorRect       — 舞台背景
	##   title_bar: CanvasItem      — 标题栏 (Label with background)
	##   panel: Control            — shop panel (validity anchor)
	##   all_cards: Array[Control] — 所有卡片
	##   whoosh_sfx: AudioStream   — 墨线画出音效 (optional)
	##   impact_sfx: AudioStream   — 卡片落地音效 (optional)

	var top_border: ColorRect = config.get("top_border") as ColorRect
	var stage_bg: ColorRect = config.get("stage_bg") as ColorRect
	var title_bar: CanvasItem = config.get("title_bar") as CanvasItem
	var panel: Control = config.get("panel") as Control
	var all_cards: Array = config.get("all_cards", [])
	var whoosh_sfx: AudioStream = config.get("whoosh_sfx") as AudioStream
	var impact_sfx: AudioStream = config.get("impact_sfx") as AudioStream

	# ── Phase 0: Init states ──
	if top_border and is_instance_valid(top_border):
		top_border.scale = Vector2(0, 1)
	if stage_bg and is_instance_valid(stage_bg):
		stage_bg.scale = Vector2(1, 0)
		# pivot: bottom-center (scale_y from bottom edge upward)
		# Fallback to panel height if layout not yet computed
		var bg_h: float = stage_bg.size.y if stage_bg.size.y > 0 else (panel.size.y if panel else 700.0)
		stage_bg.pivot_offset = Vector2(0, bg_h)
	if title_bar and is_instance_valid(title_bar):
		title_bar.modulate.a = 0.0

	# ── Phase 1: 墨线画出 (0.15s) + whoosh ──
	if top_border and is_instance_valid(top_border):
		if whoosh_sfx:
			GlobalTweens.play_sfx(whoosh_sfx)
		var tw := top_border.create_tween()
		tw.tween_property(top_border, "scale:x", 1.0, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		await tw.finished

	if not is_instance_valid(panel):
		return

	# ── Phase 2: 背景刷出 (0.2s) ──
	if stage_bg and is_instance_valid(stage_bg):
		var tw := stage_bg.create_tween()
		tw.tween_property(stage_bg, "scale:y", 1.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		await tw.finished

	if not is_instance_valid(panel):
		return

	# ── Phase 3: 标题栏淡入 (0.1s) ──
	if title_bar and is_instance_valid(title_bar):
		title_bar.modulate.a = 0.0  # SET BEFORE tween captures the value
		var tw := title_bar.create_tween()
		tw.tween_property(title_bar, "modulate:a", 1.0, 0.1)

	# ── Phase 4: 卡片 stagger_pop_in (0.25s each, 0.06s stagger) ──
	if not all_cards.is_empty():
		GlobalTweens.stagger_pop_in(all_cards, 0.06, 0.25)

	# ── Wait for cards to finish, then impact ──
	# Only stagger_pop_in remains; Phases 1-2 were already awaited, Phase 3 runs in parallel
	if not all_cards.is_empty():
		var stagger_end: float = (all_cards.size() - 1) * 0.06 + 0.25
		await Engine.get_main_loop().create_timer(stagger_end).timeout
	else:
		await Engine.get_main_loop().create_timer(0.001).timeout
	if not is_instance_valid(panel):
		return

	if impact_sfx:
		GlobalTweens.play_sfx(impact_sfx)


static func play_shop_exit(config: Dictionary) -> void:
	## 退场: 卡片 fade -> 舞台向下滑出
	## 每个 await 带 is_instance_valid(panel) 守卫
	##
	## config keys:
	##   panel: Control              — shop panel (validity anchor)
	##   all_cards: Array[Control]   — ability + item cards (fade out)

	var panel: Control = config.get("panel") as Control
	var all_cards: Array = config.get("all_cards", [])

	# ── Phase 1: Cards fade out (0.25s) ──
	if not all_cards.is_empty():
		for card in all_cards:
			if is_instance_valid(card):
				var tw: Tween = card.create_tween()
				tw.set_parallel()
				tw.tween_property(card, "scale", Vector2(0.1, 0.1), 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
				tw.tween_property(card, "modulate:a", 0.0, 0.2)

	if not is_instance_valid(panel):
		return
	await panel.get_tree().create_timer(0.25).timeout
	if not is_instance_valid(panel):
		return

	# ── Phase 2: Panel slide out downward (0.2s) ──
	if panel:
		GlobalTweens.play_sfx(_sound_bank.SHOP_EXIT)
		var tw: Tween = panel.create_tween()
		tw.tween_property(panel, "position:y", panel.get_viewport_rect().size.y + 100, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(panel, "modulate:a", 0.0, 0.2)
		await tw.finished


static func play_reroll_vfx(old_cards: Array, new_cards_callback: Callable) -> void:
	## Play reroll VFX: old cards blow away -> callback generates new cards -> new cards slide in.
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
	var new_cards: Variant = new_cards_callback.call()

	# ── Phase 3: New cards slide in from above (0.3s stagger) ──
	if not new_cards.is_empty():
		GlobalTweens.stagger_slide_in(new_cards, 0.08, 0.3, -60.0)


static func play_ninja_pop_in(slot_node: CanvasItem) -> void:
	## New ninja slot pop-in: scale_pop + gold flash. Fire-and-forget.
	if not is_instance_valid(slot_node):
		return
	GlobalTweens.scale_pop(slot_node, 1.3, 0.3)
	GlobalTweens.color_flash(slot_node, Color.GOLD, 0.2)
