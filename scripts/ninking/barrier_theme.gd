class_name BarrierTheme
extends RefCounted

## 8 属性亮色配色表（少年漫画风）
## 属性: 火水風雷土光暗无 — 各結界绑定一个忍术属性
## 每个属性含 bg / panel / accent / name / particle_color 五字段
##
## 使用方式:
##   var c := BarrierTheme.get_colors(barrier_num)
##   game_bg.color = c.bg
##   left_panel.color = c.panel
##   play_btn.add_theme_color_override("font_color", c.accent)
##   GlobalTweens.burst_particles(pos, "manga_burst", c.particle_color)

const BARRIER_COLORS: Dictionary = {
	1: {
		"bg":             Color(0.92, 0.82, 0.78, 1.0),   # 暖米 — 火
		"panel":          Color(0.96, 0.94, 0.90, 0.2),   # 淡暖白
		"accent":         Color(0.90, 0.18, 0.10, 1.0),   # 烈焰红
		"name":           "壱·火",
		"particle_color": Color(1.0, 0.45, 0.15, 1.0),    # 红橙
	},
	2: {
		"bg":             Color(0.78, 0.86, 0.92, 1.0),   # 淡蓝 — 水
		"panel":          Color(0.92, 0.95, 0.96, 0.2),   # 淡青白
		"accent":         Color(0.12, 0.45, 0.88, 1.0),   # 流水蓝
		"name":           "弐·水",
		"particle_color": Color(0.15, 0.65, 0.95, 1.0),   # 青蓝
	},
	3: {
		"bg":             Color(0.80, 0.90, 0.82, 1.0),   # 淡绿 — 風
		"panel":          Color(0.90, 0.95, 0.92, 0.2),   # 淡翠白
		"accent":         Color(0.15, 0.72, 0.38, 1.0),   # 疾风绿
		"name":           "参·風",
		"particle_color": Color(0.20, 0.85, 0.45, 1.0),   # 翠绿
	},
	4: {
		"bg":             Color(0.94, 0.90, 0.78, 1.0),   # 暖金 — 雷
		"panel":          Color(0.96, 0.95, 0.90, 0.2),   # 淡金白
		"accent":         Color(0.95, 0.72, 0.08, 1.0),   # 雷光金
		"name":           "肆·雷",
		"particle_color": Color(1.0, 0.80, 0.15, 1.0),    # 金黄
	},
	5: {
		"bg":             Color(0.88, 0.82, 0.75, 1.0),   # 暖棕 — 土
		"panel":          Color(0.94, 0.92, 0.88, 0.2),   # 淡棕白
		"accent":         Color(0.75, 0.40, 0.15, 1.0),   # 大地琥珀
		"name":           "伍·土",
		"particle_color": Color(0.85, 0.50, 0.20, 1.0),   # 橙棕
	},
	6: {
		"bg":             Color(0.92, 0.92, 0.86, 1.0),   # 象牙 — 光
		"panel":          Color(0.97, 0.97, 0.95, 0.2),   # 淡乳白
		"accent":         Color(0.90, 0.78, 0.15, 1.0),   # 光辉金
		"name":           "陸·光",
		"particle_color": Color(0.95, 0.85, 0.25, 1.0),   # 亮金
	},
	7: {
		"bg":             Color(0.72, 0.68, 0.80, 1.0),   # 暗紫 — 暗
		"panel":          Color(0.84, 0.82, 0.88, 0.2),   # 淡紫白
		"accent":         Color(0.55, 0.22, 0.78, 1.0),   # 暗夜紫
		"name":           "漆·暗",
		"particle_color": Color(0.50, 0.20, 0.70, 1.0),   # 深紫
	},
	8: {
		"bg":             Color(0.82, 0.82, 0.84, 1.0),   # 银灰 — 无
		"panel":          Color(0.94, 0.94, 0.95, 0.2),   # 淡灰白
		"accent":         Color(0.55, 0.55, 0.58, 1.0),   # 虚无灰（提亮防不可读）
		"name":           "捌·无",
		"particle_color": Color(0.60, 0.60, 0.65, 1.0),   # 灰白
	},
}


## Get full color set for a barrier number (1-8).
## Returns Dictionary with bg/panel/accent/name/particle_color, or the default (結界1 火) for invalid numbers.
static func get_colors(barrier_num: int) -> Dictionary:
	if BARRIER_COLORS.has(barrier_num):
		return BARRIER_COLORS[barrier_num]
	return BARRIER_COLORS[1]  # fallback: fire (壱·火)


static func get_accent(barrier_num: int) -> Color:
	return get_colors(barrier_num)["accent"]


static func get_bg(barrier_num: int) -> Color:
	return get_colors(barrier_num)["bg"]


static func get_panel(barrier_num: int) -> Color:
	return get_colors(barrier_num)["panel"]


static func get_barrier_name(barrier_num: int) -> String:
	return get_colors(barrier_num)["name"]


## Apply Kenney buttonLong_brown texture to a Button (primary action buttons).
## Font: white normal, accent color on pressed.
static func apply_kenney_button_style(btn: Button, accent: Color) -> void:
	var tex: Texture2D = preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/buttonLong_brown.png")
	var tex_pressed: Texture2D = preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/buttonLong_brown_pressed.png")
	const PM: int = 8

	var s_n := StyleBoxTexture.new()
	s_n.texture = tex
	s_n.set("patch_margin_left", PM); s_n.set("patch_margin_top", PM); s_n.set("patch_margin_right", PM); s_n.set("patch_margin_bottom", PM)
	btn.add_theme_stylebox_override("normal", s_n)

	var s_h := StyleBoxTexture.new()
	s_h.texture = tex
	s_h.modulate_color = Color(1.05, 1.03, 1.0)
	s_h.set("patch_margin_left", PM); s_h.set("patch_margin_top", PM); s_h.set("patch_margin_right", PM); s_h.set("patch_margin_bottom", PM)
	btn.add_theme_stylebox_override("hover", s_h)

	var s_p := StyleBoxTexture.new()
	s_p.texture = tex_pressed
	s_p.set("patch_margin_left", PM); s_p.set("patch_margin_top", PM); s_p.set("patch_margin_right", PM); s_p.set("patch_margin_bottom", PM)
	btn.add_theme_stylebox_override("pressed", s_p)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", accent)
	btn.add_theme_color_override("font_hover_color", Color(0.95, 0.95, 0.98))


## Apply Kenney buttonSquare_brown texture (small/secondary action buttons).
static func apply_kenney_square_style(btn: Button, accent: Color) -> void:
	var tex: Texture2D = preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/buttonSquare_brown.png")
	var tex_pressed: Texture2D = preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/buttonSquare_brown_pressed.png")
	const PM: int = 8

	var s_n := StyleBoxTexture.new()
	s_n.texture = tex
	s_n.set("patch_margin_left", PM); s_n.set("patch_margin_top", PM); s_n.set("patch_margin_right", PM); s_n.set("patch_margin_bottom", PM)
	btn.add_theme_stylebox_override("normal", s_n)

	var s_h := StyleBoxTexture.new()
	s_h.texture = tex
	s_h.modulate_color = Color(1.05, 1.03, 1.0)
	s_h.set("patch_margin_left", PM); s_h.set("patch_margin_top", PM); s_h.set("patch_margin_right", PM); s_h.set("patch_margin_bottom", PM)
	btn.add_theme_stylebox_override("hover", s_h)

	var s_p := StyleBoxTexture.new()
	s_p.texture = tex_pressed
	s_p.set("patch_margin_left", PM); s_p.set("patch_margin_top", PM); s_p.set("patch_margin_right", PM); s_p.set("patch_margin_bottom", PM)
	btn.add_theme_stylebox_override("pressed", s_p)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", accent)
	btn.add_theme_color_override("font_hover_color", Color(0.95, 0.95, 0.98))


static func get_particle_color(barrier_num: int) -> Color:
	return get_colors(barrier_num)["particle_color"]


## Apply manga-style impact button styles (normal/hover/pressed/disabled) to a Button.
## Size tiers: "L" (primary, 4px border), "M" (secondary, 3px), "S" (utility, 2px).
## Creates 4 StyleBoxFlat states with the given accent color and ink #1A1A1A border.
static func apply_manga_button_style(btn: Button, accent: Color, size_tier: String = "M", ink_color: Color = Color(0.102, 0.102, 0.102)) -> void:
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
	btn.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.7, 0.6))

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
	s_disabled.bg_color = Color(0.8, 0.8, 0.8, 1)
	s_disabled.border_color = Color(0.6, 0.6, 0.6, 1)
	s_disabled.border_width_left = maxi(border_w - 1, 1)
	s_disabled.border_width_right = maxi(border_w - 1, 1)
	s_disabled.border_width_top = maxi(border_w - 1, 1)
	s_disabled.border_width_bottom = maxi(border_w - 1, 1)
	btn.add_theme_stylebox_override("disabled", s_disabled)
