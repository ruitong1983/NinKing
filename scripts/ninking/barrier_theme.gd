class_name BarrierTheme
extends RefCounted

## 8 結界冷暖交替配色表
## 冷色调: 紫/青/蓝/翠 → 暖色调: 红/橙/金/粉 交替
## 每个結界含 bg / panel / accent / name 四字段
##
## 使用方式:
##   var c := BarrierTheme.get_colors(barrier_num)
##   game_bg.modulate = c.bg
##   left_panel.modulate = c.panel
##   play_btn.add_theme_color_override("font_color", c.accent)

const BARRIER_COLORS: Dictionary = {
	1: {
		"bg":     Color(0.08, 0.04, 0.16, 1.0),   # deep purple
		"panel":  Color(0.12, 0.06, 0.22, 1.0),   # dark purple
		"accent": Color(0.75, 0.45, 0.95, 1.0),   # bright purple
		"name":   "紫苑",
	},
	2: {
		"bg":     Color(0.16, 0.04, 0.04, 1.0),   # deep red
		"panel":  Color(0.22, 0.06, 0.06, 1.0),   # dark red
		"accent": Color(0.95, 0.35, 0.35, 1.0),   # bright red
		"name":   "紅蓮",
	},
	3: {
		"bg":     Color(0.04, 0.12, 0.16, 1.0),   # deep cyan
		"panel":  Color(0.06, 0.16, 0.22, 1.0),   # dark cyan
		"accent": Color(0.30, 0.85, 0.90, 1.0),   # bright cyan
		"name":   "青龍",
	},
	4: {
		"bg":     Color(0.16, 0.08, 0.04, 1.0),   # deep orange
		"panel":  Color(0.22, 0.12, 0.06, 1.0),   # dark orange
		"accent": Color(0.95, 0.55, 0.20, 1.0),   # bright orange
		"name":   "橙火",
	},
	5: {
		"bg":     Color(0.04, 0.06, 0.18, 1.0),   # deep blue
		"panel":  Color(0.06, 0.09, 0.24, 1.0),   # dark blue
		"accent": Color(0.35, 0.55, 0.95, 1.0),   # bright blue
		"name":   "藍鋼",
	},
	6: {
		"bg":     Color(0.14, 0.10, 0.04, 1.0),   # deep gold
		"panel":  Color(0.20, 0.15, 0.06, 1.0),   # dark gold
		"accent": Color(0.95, 0.75, 0.25, 1.0),   # bright gold
		"name":   "金剛",
	},
	7: {
		"bg":     Color(0.04, 0.15, 0.12, 1.0),   # deep teal
		"panel":  Color(0.06, 0.20, 0.16, 1.0),   # dark teal
		"accent": Color(0.25, 0.88, 0.70, 1.0),   # bright teal
		"name":   "翠嵐",
	},
	8: {
		"bg":     Color(0.16, 0.06, 0.12, 1.0),   # deep pink
		"panel":  Color(0.22, 0.08, 0.16, 1.0),   # dark pink
		"accent": Color(0.95, 0.45, 0.65, 1.0),   # bright pink
		"name":   "桜吹雪",
	},
}


## Get full color set for a barrier number (1-8).
## Returns Dictionary with bg/panel/accent/name, or the default (結界1 紫苑) for invalid numbers.
static func get_colors(barrier_num: int) -> Dictionary:
	if BARRIER_COLORS.has(barrier_num):
		return BARRIER_COLORS[barrier_num]
	return BARRIER_COLORS[1]  # fallback: purple (紫苑)


static func get_accent(barrier_num: int) -> Color:
	return get_colors(barrier_num)["accent"]


static func get_bg(barrier_num: int) -> Color:
	return get_colors(barrier_num)["bg"]


static func get_panel(barrier_num: int) -> Color:
	return get_colors(barrier_num)["panel"]


static func get_name(barrier_num: int) -> String:
	return get_colors(barrier_num)["name"]
