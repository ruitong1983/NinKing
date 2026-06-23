class_name ButtonStyles
extends RefCounted
## Centralized button style library — all button styling goes through here.
##
## Usage:
##   ButtonStyles.apply_kenney_long(reroll_btn, "brown")
##   ButtonStyles.apply_kenney_square(small_btn, "grey")
##   ButtonStyles.apply_manga(play_btn, c.accent, "L")
##   ButtonStyles.attach_entrance_animation(play_btn, {"mild": false})
##
## Migration: remove scattered _apply_* methods, call ButtonStyles instead.

const _KENNEY_PATH := "res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/"
const _PATCH_MARGIN: int = 8


# ════════════════════════════════════════════════════════════════
# Kenney 暖纸风 — 长按钮 (buttonLong_{variant})
# ════════════════════════════════════════════════════════════════

## Apply Kenney long button texture (buttonLong_{variant}.png) with 9-slice patch.
## variant: "brown" | "beige" | "grey" | "blue"
static func apply_kenney_long(btn: Button, variant: String = "brown") -> void:
	var tex_n: Texture2D = load(_KENNEY_PATH + "buttonLong_" + variant + ".png")
	var tex_p: Texture2D = load(_KENNEY_PATH + "buttonLong_" + variant + "_pressed.png")
	_apply_kenney_stylebox(btn, tex_n, tex_p)
	_apply_kenney_font_colors(btn, variant)


# ════════════════════════════════════════════════════════════════
# Kenney 暖纸风 — 方按钮 (buttonSquare_{variant})
# ════════════════════════════════════════════════════════════════

## Apply Kenney square button texture (buttonSquare_{variant}.png) with 9-slice patch.
## variant: "brown" | "beige" | "grey" | "blue"
static func apply_kenney_square(btn: Button, variant: String = "brown") -> void:
	var tex_n: Texture2D = load(_KENNEY_PATH + "buttonSquare_" + variant + ".png")
	var tex_p: Texture2D = load(_KENNEY_PATH + "buttonSquare_" + variant + "_pressed.png")
	_apply_kenney_stylebox(btn, tex_n, tex_p)
	_apply_kenney_font_colors(btn, variant)


# ════════════════════════════════════════════════════════════════
# 漫画风按钮 (StyleBoxFlat, 结界属性动态配色)
# ════════════════════════════════════════════════════════════════

## Apply manga-style impact button styles (normal/hover/pressed/disabled) to a Button.
## Size tiers: "L" (primary, 4px border), "M" (secondary, 3px), "S" (utility, 2px).
## Creates 4 StyleBoxFlat states with the given accent color and ink border.
static func apply_manga(btn: Button, accent: Color, size_tier: String = "M", ink_color: Color = Color(0.102, 0.102, 0.102)) -> void:
	var border_w: int
	var margin_h: int
	var margin_v: int
	match size_tier:
		"L":
			border_w = 4; margin_h = 20; margin_v = 10
		"M":
			border_w = 3; margin_h = 16; margin_v = 8
		"S":
			border_w = 2; margin_h = 12; margin_v = 6
		_:
			border_w = 3; margin_h = 16; margin_v = 8

	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = accent
	s_normal.border_color = ink_color
	s_normal.border_width_left = border_w
	s_normal.border_width_top = border_w
	s_normal.border_width_right = border_w
	s_normal.border_width_bottom = border_w
	s_normal.corner_radius_top_left = 8
	s_normal.corner_radius_top_right = 8
	s_normal.corner_radius_bottom_left = 8
	s_normal.corner_radius_bottom_right = 8
	s_normal.content_margin_left = margin_h
	s_normal.content_margin_top = margin_v
	s_normal.content_margin_right = margin_h
	s_normal.content_margin_bottom = margin_v
	btn.add_theme_stylebox_override("normal", s_normal)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(accent).darkened(0.3))
	btn.add_theme_color_override("font_disabled_color", Color.WHITE)

	var s_hover := s_normal.duplicate() as StyleBoxFlat
	s_hover.bg_color = Color(accent).lightened(0.1)
	s_hover.border_width_left = border_w + 1
	s_hover.border_width_right = border_w + 1
	s_hover.border_width_top = border_w + 1
	s_hover.border_width_bottom = border_w + 1
	btn.add_theme_stylebox_override("hover", s_hover)

	var s_pressed := s_normal.duplicate() as StyleBoxFlat
	s_pressed.bg_color = Color(accent).darkened(0.15)
	s_pressed.content_margin_top = margin_v + 2
	s_pressed.content_margin_bottom = margin_v - 2
	btn.add_theme_stylebox_override("pressed", s_pressed)

	var s_disabled := s_normal.duplicate() as StyleBoxFlat
	# 保持与 normal 一致——此处 disabled 仅用于阻止交互，非视觉态
	s_disabled.bg_color = accent
	s_disabled.border_color = ink_color
	s_disabled.border_width_left = border_w
	s_disabled.border_width_right = border_w
	s_disabled.border_width_top = border_w
	s_disabled.border_width_bottom = border_w

	btn.add_theme_stylebox_override("disabled", s_disabled)
# ════════════════════════════════════════════════════════════════
# Private helpers
# ════════════════════════════════════════════════════════════════

static func _apply_kenney_stylebox(btn: Button, tex_normal: Texture2D, tex_pressed: Texture2D) -> void:
	var s_n := StyleBoxTexture.new()
	s_n.texture = tex_normal
	s_n.set("patch_margin_left", _PATCH_MARGIN)
	s_n.set("patch_margin_top", _PATCH_MARGIN)
	s_n.set("patch_margin_right", _PATCH_MARGIN)
	s_n.set("patch_margin_bottom", _PATCH_MARGIN)
	btn.add_theme_stylebox_override("normal", s_n)

	# Disabled: 完全等同于 normal，禁止后视觉不变（仅禁交互）
	var s_d := StyleBoxTexture.new()
	s_d.texture = tex_normal
	s_d.set("patch_margin_left", _PATCH_MARGIN)
	s_d.set("patch_margin_top", _PATCH_MARGIN)
	s_d.set("patch_margin_right", _PATCH_MARGIN)
	s_d.set("patch_margin_bottom", _PATCH_MARGIN)
	btn.add_theme_stylebox_override("disabled", s_d)

	var s_h := StyleBoxTexture.new()
	s_h.texture = tex_normal
	s_h.modulate_color = Color(1.05, 1.03, 1.0)
	s_h.set("patch_margin_left", _PATCH_MARGIN)
	s_h.set("patch_margin_top", _PATCH_MARGIN)
	s_h.set("patch_margin_right", _PATCH_MARGIN)
	s_h.set("patch_margin_bottom", _PATCH_MARGIN)
	btn.add_theme_stylebox_override("hover", s_h)

	var s_p := StyleBoxTexture.new()
	s_p.texture = tex_pressed
	s_p.set("patch_margin_left", _PATCH_MARGIN)
	s_p.set("patch_margin_top", _PATCH_MARGIN)
	s_p.set("patch_margin_right", _PATCH_MARGIN)
	s_p.set("patch_margin_bottom", _PATCH_MARGIN)
	btn.add_theme_stylebox_override("pressed", s_p)


static func _apply_kenney_font_colors(btn: Button, variant: String) -> void:
	match variant:
		"brown", "blue":
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_color_override("font_hover_color", Color(0.95, 0.95, 0.98))
			btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.95, 0.98))
			btn.add_theme_color_override("font_disabled_color", Color.WHITE)
		"beige":
			var dark := Color(0.24, 0.17, 0.10)
			btn.add_theme_color_override("font_color", dark)
			btn.add_theme_color_override("font_hover_color", Color(0.30, 0.22, 0.14))
			btn.add_theme_color_override("font_pressed_color", dark)
			btn.add_theme_color_override("font_disabled_color", dark)
		"grey":
			var grey := Color(0.35, 0.35, 0.35)
			btn.add_theme_color_override("font_color", grey)
			btn.add_theme_color_override("font_hover_color", grey)
			btn.add_theme_color_override("font_pressed_color", grey)
			btn.add_theme_color_override("font_disabled_color", grey)
		_:
			push_warning("ButtonStyles: unknown variant '%s', using default font colors." % variant)
			btn.add_theme_color_override("font_color", Color.WHITE)


# ════════════════════════════════════════════════════════════════
# 按钮入口动效 — 统一管理
# ════════════════════════════════════════════════════════════════

const _SFX_CLICK := preload("res://assets/audio/sound/ui/ui_click.ogg")

## 为按钮挂载入口动效：弹跳入场 + 金色粒子 + 稳定后呼吸脉冲 + 悬停放大 + 点击 squash 反馈。
##
## 生命周期:
##   1. btn.disabled = true（防入场误触）
##   2. 弹跳入场 (entrance_bounce, 0.4s)
##   3. 弹跳中点 → 金色粒子爆发 (sparkle)
##   4. 入场完成 → btn.disabled = false
##   5. 启动 modulate 呼吸脉冲 (attract_pulse, scale_pulse=false)
##   6. 悬停: 停脉冲 → 放大(1.05) | 移开: 归位 → 重启脉冲
##   7. 点击: squash(0.92) → spring 回弹 + 音效
##
## config:
##   "delay"     — 入场延迟秒 (default 0)
##   "mild"      — 轻度: 不做弹跳/粒子, 只加脉冲+悬停+点击 (default false)
##   "click_sfx" — 自定义点击音效 (default null → 内置 ui_click.ogg)
	##   "pulse"     - breathing pulse switch, false = hover+click only (default true)
static func attach_entrance_animation(btn: Button, config: Dictionary = {}) -> void:
	if not is_instance_valid(btn) or btn.has_meta("_fx_entrance_attached"):
		return
	btn.set_meta("_fx_entrance_attached", true)

	var mild: bool = config.get("mild", false)
	var click_sfx: AudioStream = config.get("click_sfx", _SFX_CLICK)
	var enable_pulse: bool = config.get("pulse", true)
	btn.set_meta("_fx_pulse_enabled", enable_pulse)

	if mild:
		btn.set_meta("_fx_mild", true)
		_wire_pulse(btn)
		_wire_hover(btn)
		_wire_click(btn, click_sfx)
		return

	# 完整模式 — 弹跳入场
	var was_disabled: bool = btn.disabled
	btn.disabled = true

	var tw = GlobalTweens.entrance_bounce(btn, 0.4)
	if tw == null or not tw.is_valid():
		btn.disabled = was_disabled
		return


	# 入场完成 → 恢复交互 + 脉冲 + hover + click
	tw.finished.connect(_on_entrance_done.bind(btn, was_disabled, click_sfx), CONNECT_ONE_SHOT)


# ─── Callback helpers ───


static func _on_entrance_done(btn: Button, was_disabled: bool, click_sfx: AudioStream) -> void:
	if not is_instance_valid(btn):
		return
	btn.disabled = was_disabled
	_wire_pulse(btn)
	_wire_hover(btn)
	_wire_click(btn, click_sfx)


# ─── 底层工具 ───

static func _wire_pulse(btn: Button) -> void:
	if not is_instance_valid(btn) or btn.disabled:
		return
	# Check if pulse is enabled for this button
	if btn.has_meta("_fx_pulse_enabled") and not btn.get_meta("_fx_pulse_enabled"):
		return
	# Kill any existing pulse tween
	if btn.has_meta("_fx_pulse_tw"):
		var _old: Tween = btn.get_meta("_fx_pulse_tw")
		if is_instance_valid(_old) and _old.is_valid():
			_old.kill()
		btn.remove_meta("_fx_pulse_tw")
	GlobalTweens.kill_domain(btn, "modulate")
	# Direct breathing pulse: scale 1.0 <-> 1.05, smooth sine
	var _tw := btn.create_tween()
	_tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_tw.set_loops()
	_tw.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.8)
	_tw.tween_property(btn, "scale", Vector2.ONE, 0.8)
	btn.set_meta("_fx_pulse_tw", _tw)


static func _stop_pulse(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	if btn.has_meta("_fx_pulse_tw"):
		var _tw: Tween = btn.get_meta("_fx_pulse_tw")
		if is_instance_valid(_tw) and _tw.is_valid():
			_tw.kill()
		btn.remove_meta("_fx_pulse_tw")
	GlobalTweens.kill_domain(btn, "modulate")
	btn.scale = Vector2.ONE
static func _wire_hover(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	# Guard: already wired
	if btn.has_meta("_fx_hover_wired"):
		return
	btn.set_meta("_fx_hover_wired", true)

	# mouse_entered
	btn.mouse_entered.connect(_on_btn_hovered.bind(btn))
	# mouse_exited
	btn.mouse_exited.connect(_on_btn_unhovered.bind(btn))


static func _on_btn_hovered(btn: Button) -> void:
	if btn.disabled:
		return
	_stop_pulse(btn)
	btn.scale = Vector2.ONE
	GlobalTweens.card_hover(btn, Vector2(1.05, 1.05), -2.0)


static func _on_btn_unhovered(btn: Button) -> void:
	if btn.disabled:
		return
	GlobalTweens.card_unhover(btn, Vector2.ONE, 0.0)
	_wire_pulse(btn)


static func _wire_click(btn: Button, sfx: AudioStream) -> void:
	if not is_instance_valid(btn):
		return
	if btn.has_meta("_fx_click_wired"):
		return
	btn.set_meta("_fx_click_wired", true)
	btn.pressed.connect(_on_btn_pressed.bind(btn, sfx))


static func _on_btn_pressed(btn: Button, sfx: AudioStream) -> void:
	if btn.disabled:
		return
	GlobalTweens.button_click_feedback(btn)
	if sfx != null:
		GlobalTweens.play_sfx(sfx)
