
class_name XiStrikeOverlay
extends Control

## Ninja-strike overlay for Xi Strike Reveal (Phase 3 scoring animation).
##
## v4: Compact reveal in left gap (between LeftPanel and DunArea).
##     Removed full-screen center_box — overlay is a fixed 260×400 panel
##     positioned in the gap (global x=485~745, y=420~820).
##
## Layout (260x400 overlay):
##   y=0:          "+N 喜" overflow row (if triggered > MAX_ROWS)
##   y=50..188:    Row 0-3 accumulative names + xN (rowline ~46px apart)
##   y=225:        divider -----------------
##   y=260+:       stage C final xN product explosion
##
## Renders above CardGrid (z=15) in the left-gap area.
## Semi-transparent dark backdrop isolates text from table_bg texture.
## Created/destroyed per scoring round.
##
## Usage:
##   var overlay := XiStrikeOverlay.new()
##   add_child(overlay)
##   if overflow: overlay.show_overflow(N)
##   for each xi: overlay.stage_b_reveal(name, x_mult, tree)
##   overlay.stage_c_final(product, tree) # product impact
##   overlay.queue_free()

const MAX_ROWS: int = 4
const XI_FANFARE = preload("res://assets/audio/sound/game/xi_fanfare.ogg")

var _overflow_row: Label = null
var _rows: Array[Label] = []
var _divider: Label = null
var _bg: ColorRect = null

var _xi_name_color: Dictionary = {
	1: Color(0.91, 0.25, 0.25),      # Tier 1 (x2) 朱砂红
	2: Color(0.94, 0.16, 0.16),      # Tier 2 (x3) 绯红
	3: Color(1.0, 0.10, 0.10),       # Tier 3 (x4) 赤红
	4: Color(1.0, 0.04, 0.04),       # Tier 4 (x5) 血焰红
	5: Color(1.0, 0.27, 0.27),       # Tier 5 (x6) 白炽红
}

var _outline_color: Dictionary = {
	1: Color(0.29, 0.04, 0.04, 0.9),   # Tier 1 (x2) 暗红棕
	2: Color(0.35, 0.03, 0.03, 0.95),  # Tier 2 (x3) 暗红褐
	3: Color(0.42, 0.0,  0.0,  1.0),   # Tier 3 (x4) 深血红
	4: Color(0.48, 0.0,  0.0,  1.0),   # Tier 4 (x5) 黑绛红
	5: Color(0.54, 0.0,  0.0,  1.0),   # Tier 5 (x6) 黑红
}


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	# Positioned in the gap between LeftPanel (right edge x=480) and DunArea (left edge x=750).
	# Vertically centered on the DunArea card grid area (y=298~969).
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = 485.0
	offset_top = 420.0
	offset_right = 745.0
	offset_bottom = -260.0
	# Size: 260×400

	# Semi-transparent dark backdrop — isolates text from table_bg grass/path texture
	_bg = ColorRect.new()
	_bg.color = Color(0.04, 0.04, 0.08, 0.45)
	_bg.size = Vector2(260, 400)
	_bg.position = Vector2.ZERO
	_bg.mouse_filter = MOUSE_FILTER_IGNORE
	_bg.z_index = 1
	add_child(_bg)


# ═══ Overflow row — when triggered > MAX_ROWS ═══

func show_overflow(count: int) -> void:
	## Quick flash of "+N 喜" overflow line above all rows.
	## No tier effects — just a speedy 0.1s slide-in.
	var lbl := Label.new()
	lbl.text = "+%d 喜" % count
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.50, 0.31, 0.0))  # 暗金红
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_color_override("font_outline_color", Color(0.23, 0.13, 0.06, 0.6))  # 棕黑
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = MOUSE_FILTER_IGNORE
	lbl.size = Vector2(260, 28)
	lbl.position = Vector2(260, -2)
	lbl.z_index = 3
	add_child(lbl)
	_overflow_row = lbl

	var tw: Tween = create_tween().set_parallel()
	tw.tween_property(lbl, "position:x", 5.0, 0.1) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(lbl, "modulate:a", 1.0, 0.08)


# ═══ Stage B — Accumulative row reveal ═══

func stage_b_reveal(xi_name: String, x_mult: int, tree: SceneTree) -> void:
	## Add an accumulative row for one xi. Slides in from right.
	## tier effects (hit-stop/shake/particles) fire on arrival.
	var tier: int = _get_tier(x_mult)
	var row_idx: int = _rows.size()  # 0-based; controls Y slot
	var row: Label = _create_row(xi_name, x_mult, tier)
	row.position = Vector2(260, _get_row_y(row_idx))
	row.modulate.a = 0.0
	add_child(row)
	_rows.append(row)

	# Slide in from right
	var tw: Tween = create_tween().set_parallel()
	tw.tween_property(row, "position:x", 0.0, 0.35) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	tw.tween_property(row, "modulate:a", 1.0, 0.15)
	await tw.finished

	# Tier impact effects
	await _apply_tier_effects(tier, row, tree)

	# Pulse settle
	var pulse: Tween = create_tween()
	pulse.tween_property(row, "scale", Vector2(1.1, 1.1), 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	pulse.chain().tween_property(row, "scale", Vector2(1.0, 1.0), 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	await pulse.finished


func _create_row(xi_name: String, x_mult: int, tier: int) -> Label:
	## Create a single combined row Label: "{xi_name}    x{x_mult}".
	var color: Color = _xi_name_color.get(clampi(tier, 1, 5), Color(1.0, 0.84, 0.0))
	var outline: Color = _outline_color.get(clampi(tier, 1, 5), Color(0.3, 0.15, 0.0, 0.8))
	var lbl := Label.new()
	lbl.text = "%s    x%d" % [xi_name, x_mult]
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_constant_override("outline_size", clampi(tier * 2, 3, 10))
	lbl.add_theme_color_override("font_outline_color", outline)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.25))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = MOUSE_FILTER_IGNORE
	lbl.size = Vector2(260, 36)
	lbl.z_index = 3
	return lbl


func _get_row_y(row_idx: int) -> float:
	## Y position within overlay for row at given index (0-3).
	return 50.0 + row_idx * 46.0


# ═══ Stage C — product impact (with divider) ═══

func stage_c_final(product: int, tree: SceneTree) -> void:
	## Final total product explosion — three beats: charge -> strike -> burst.
	## v2: Stronger transition from accumulated rows to product.

	# -- Step 1: charge (0.4s) -- all rows brace with collective pulse --
	for row: Label in _rows:
		if is_instance_valid(row):
			var charge_tw: Tween = create_tween()
			charge_tw.tween_property(row, "scale", Vector2(1.06, 1.06), 0.15) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			charge_tw.chain().tween_property(row, "scale", Vector2(1.0, 1.0), 0.25) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	GlobalTweens.screen_shake(0.03, 0.2)  # subtle deep rumble
	await tree.create_timer(0.3).timeout

	# -- Step 2: strike (0.12s) -- divider strikes from center outward --
	_create_divider_strike()
	await tree.create_timer(0.1).timeout

	# -- Step 3: burst -- Big xN explodes --
	var final_lbl := _create_final_label(product)
	add_child(final_lbl)
	final_lbl.position.y = 260.0
	final_lbl.scale = Vector2(0.01, 0.01)

	# Explode in -- overshoot for narrow box
	var tw: Tween = create_tween().set_parallel()
	tw.tween_property(final_lbl, "scale", Vector2(1.8, 1.8), 0.25) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(final_lbl, "modulate:a", 1.0, 0.1)
	await tw.finished

	# Overshoot settle — no burst particles (user feedback: too abrupt)
	GlobalTweens.do_hit_stop(0.1, 0.04)
	GlobalTweens.screen_shake(0.2, 0.15)

	var settle: Tween = create_tween()
	settle.tween_property(final_lbl, "scale", Vector2(1.0, 1.0), 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)

	await tree.create_timer(0.2).timeout

	# Second hit for emphasis
	GlobalTweens.do_hit_stop(0.06, 0.04)
	GlobalTweens.screen_shake(0.1, 0.08)

	# Final pulse -- slow, heavy
	await tree.create_timer(0.15).timeout

	var pulse: Tween = create_tween()
	pulse.tween_property(final_lbl, "scale", Vector2(1.35, 1.35), 0.25) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	pulse.chain().tween_property(final_lbl, "scale", Vector2(1.0, 1.0), 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)

	# Gold glow hold
	await tree.create_timer(0.3).timeout
	GlobalTweens.color_flash(final_lbl, Color.GOLD, 0.6)

	await tree.create_timer(0.4).timeout


func _create_divider_strike() -> void:
	## Divider line strikes from center outward -- more dramatic than fade-in.
	var lbl := Label.new()
	lbl.text = "-----------------"
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.91, 0.31, 0.31, 1.0))  # 金属红
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color(0.35, 0.05, 0.05, 0.6))  # 暗红描边
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = MOUSE_FILTER_IGNORE
	lbl.size = Vector2(260, 18)
	lbl.pivot_offset = Vector2(130, 9)  # center pivot for scale-from-middle
	lbl.position = Vector2(0, 225)
	lbl.scale = Vector2(0.01, 1.0)       # start: invisible horizontal line
	lbl.z_index = 3
	add_child(lbl)
	_divider = lbl

	# Strike: center -> full width with hit-stop impact
	var tw: Tween = create_tween()
	tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.1) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(lbl, "modulate", Color(1.0, 0.84, 0.0, 0.7), 0.08)

	# Impact micro-shake
	GlobalTweens.do_hit_stop(0.02, 0.08)
	GlobalTweens.screen_shake(0.04, 0.03)
	GlobalTweens.play_sfx(XI_FANFARE)  # fanfare starts at strike moment


func _create_final_label(product: int) -> Label:
	var lbl := Label.new()
	lbl.text = "x%d" % product
	lbl.add_theme_font_size_override("font_size", 90)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.38, 0.25, 1.0))  # 炽白红
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.add_theme_color_override("font_outline_color", Color(0.16, 0.0, 0.0, 1.0))  # 极黑边
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = MOUSE_FILTER_IGNORE
	lbl.size = Vector2(260, 100)
	lbl.z_index = 5
	return lbl


# ═══ Tier helpers ═══

func _get_tier(x_mult: int) -> int:
	if x_mult >= 6:
		return 5
	elif x_mult >= 5:
		return 4
	elif x_mult >= 4:
		return 3
	elif x_mult >= 3:
		return 2
	return 1


func _apply_tier_effects(tier: int, _row: Label, tree: SceneTree) -> void:
	## Apply tier-dependent SFX/vfx: hit-stop, shake, flash.
	match tier:
		1:
			# x2 standard -- short hit-stop only
			GlobalTweens.do_hit_stop(0.03, 0.06)
			GlobalTweens.screen_shake(0.04, 0.03)

		2:
			# x3 -- stronger hit-stop + shake
			GlobalTweens.do_hit_stop(0.05, 0.05)
			GlobalTweens.screen_shake(0.08, 0.05)

		3:
			# x4 -- red flash + hit-stop + shake (no particles — user feedback: too abrupt)
			GlobalTweens.do_hit_stop(0.06, 0.04)
			GlobalTweens.screen_shake(0.10, 0.06)
			GlobalTweens.color_flash(_row, Color(1.0, 0.3, 0.05, 0.6), 0.15)

		4:
			# x5 -- double hit-stop + red flash + shake (no particles)
			GlobalTweens.do_hit_stop(0.06, 0.04)
			GlobalTweens.screen_shake(0.12, 0.08)
			GlobalTweens.color_flash(_row, Color(1.0, 0.1, 0.0, 0.8), 0.2)
			await tree.create_timer(0.05).timeout
			GlobalTweens.do_hit_stop(0.04, 0.04)
			GlobalTweens.screen_shake(0.06, 0.04)

		5:
			# x6 -- triple hit-stop + full red tint + massive burst
			var flash_rect := ColorRect.new()
			flash_rect.color = Color(0.6, 0.0, 0.0, 0.0)
			flash_rect.anchor_left = 0.0
			flash_rect.anchor_top = 0.0
			flash_rect.anchor_right = 1.0
			flash_rect.anchor_bottom = 1.0
			flash_rect.mouse_filter = MOUSE_FILTER_IGNORE
			flash_rect.z_index = 10
			add_child(flash_rect)
			var flash_tw: Tween = flash_rect.create_tween()
			flash_tw.tween_property(flash_rect, "color", Color(0.6, 0.0, 0.0, 0.35), 0.05)
			flash_tw.tween_property(flash_rect, "color", Color(0.6, 0.0, 0.0, 0.0), 0.2)
			flash_tw.tween_callback(flash_rect.queue_free)

			GlobalTweens.do_hit_stop(0.07, 0.03)
			GlobalTweens.screen_shake(0.15, 0.10)
			await tree.create_timer(0.06).timeout
			GlobalTweens.do_hit_stop(0.05, 0.03)
			GlobalTweens.screen_shake(0.08, 0.05)
			await tree.create_timer(0.04).timeout
			GlobalTweens.do_hit_stop(0.03, 0.05)
