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
		"panel":          Color(0.96, 0.90, 0.86, 1.0),   # 淡暖白
		"accent":         Color(0.90, 0.18, 0.10, 1.0),   # 烈焰红
		"name":           "壱·火",
		"particle_color": Color(1.0, 0.45, 0.15, 1.0),    # 红橙
	},
	2: {
		"bg":             Color(0.78, 0.86, 0.92, 1.0),   # 淡蓝 — 水
		"panel":          Color(0.86, 0.93, 0.96, 1.0),   # 淡青白
		"accent":         Color(0.12, 0.45, 0.88, 1.0),   # 流水蓝
		"name":           "弐·水",
		"particle_color": Color(0.15, 0.65, 0.95, 1.0),   # 青蓝
	},
	3: {
		"bg":             Color(0.80, 0.90, 0.82, 1.0),   # 淡绿 — 風
		"panel":          Color(0.88, 0.95, 0.90, 1.0),   # 淡翠白
		"accent":         Color(0.15, 0.72, 0.38, 1.0),   # 疾风绿
		"name":           "参·風",
		"particle_color": Color(0.20, 0.85, 0.45, 1.0),   # 翠绿
	},
	4: {
		"bg":             Color(0.94, 0.90, 0.78, 1.0),   # 暖金 — 雷
		"panel":          Color(0.97, 0.95, 0.86, 1.0),   # 淡金白
		"accent":         Color(0.95, 0.72, 0.08, 1.0),   # 雷光金
		"name":           "肆·雷",
		"particle_color": Color(1.0, 0.80, 0.15, 1.0),    # 金黄
	},
	5: {
		"bg":             Color(0.88, 0.82, 0.75, 1.0),   # 暖棕 — 土
		"panel":          Color(0.94, 0.90, 0.85, 1.0),   # 淡棕白
		"accent":         Color(0.75, 0.40, 0.15, 1.0),   # 大地琥珀
		"name":           "伍·土",
		"particle_color": Color(0.85, 0.50, 0.20, 1.0),   # 橙棕
	},
	6: {
		"bg":             Color(0.92, 0.92, 0.86, 1.0),   # 象牙 — 光
		"panel":          Color(0.97, 0.97, 0.92, 1.0),   # 淡乳白
		"accent":         Color(0.90, 0.78, 0.15, 1.0),   # 光辉金
		"name":           "陸·光",
		"particle_color": Color(0.95, 0.85, 0.25, 1.0),   # 亮金
	},
	7: {
		"bg":             Color(0.72, 0.68, 0.80, 1.0),   # 暗紫 — 暗
		"panel":          Color(0.80, 0.76, 0.86, 1.0),   # 淡紫白
		"accent":         Color(0.55, 0.22, 0.78, 1.0),   # 暗夜紫
		"name":           "漆·暗",
		"particle_color": Color(0.50, 0.20, 0.70, 1.0),   # 深紫
	},
	8: {
		"bg":             Color(0.82, 0.82, 0.84, 1.0),   # 银灰 — 无
		"panel":          Color(0.90, 0.90, 0.92, 1.0),   # 淡灰白
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


static func get_name(barrier_num: int) -> String:
	return get_colors(barrier_num)["name"]


static func get_particle_color(barrier_num: int) -> Color:
	return get_colors(barrier_num)["particle_color"]
