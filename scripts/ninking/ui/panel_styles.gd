class_name PanelStyles
extends RefCounted

## Panel 样式工厂 — 集中管理所有 Kenney 暖纸风面板样式。
##
## 所有面板样式在此处定义，场景中不再内联 SubResource。
## 在 ui_manager.gd:_ready() 中调用应用。
##
## 使用方法:
##   node.add_theme_stylebox_override("panel", PanelStyles.beige_panel())
##   node.add_theme_stylebox_override("panel", PanelStyles.beige_light_panel())

const _TEX_BEIGE: Texture2D = preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/panel_beige.png")
const _TEX_BEIGE_LIGHT: Texture2D = preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/panel_beigeLight.png")


## 深米色面板 (panel_beige.png), 16px 四边内边距
static func beige_panel() -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = _TEX_BEIGE
	s.content_margin_left = 16.0
	s.content_margin_top = 16.0
	s.content_margin_right = 16.0
	s.content_margin_bottom = 16.0
	return s


## 浅米色面板 (panel_beigeLight.png), 16px 四边内边距
static func beige_light_panel() -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = _TEX_BEIGE_LIGHT
	s.content_margin_left = 16.0
	s.content_margin_top = 16.0
	s.content_margin_right = 16.0
	s.content_margin_bottom = 16.0
	return s


## 浅米色面板, 独特边距 (用于 DeckViewer CardPanel)
static func beige_light_panel_deck() -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = _TEX_BEIGE_LIGHT
	s.content_margin_left = 20.0
	s.content_margin_top = 15.0
	s.content_margin_right = 20.0
	s.content_margin_bottom = 15.0
	return s