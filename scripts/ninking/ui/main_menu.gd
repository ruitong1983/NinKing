extends Control
## NinKing 主菜单 — 闪屏 → 按钮 → 牌组选择 / 继续确认面板
## Buttons defined in scene file; panels built programmatically.
## Deck panel delegated to DeckSelectPanel, ambient effects to LaunchAmbience.

const SPLASH_DURATION: float = 0.8
const BUTTON_STAGGER: float = 0.08
const BUTTON_SLIDE_DUR: float = 0.4
const BUTTON_SLIDE_OFFSET: float = 80.0

# Kenney 暖纸风纹理路径
const _BTN_PATH := "res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/"
const _BTN_BEIGE := _BTN_PATH + "buttonLong_beige.png"
const _BTN_BEIGE_PRESSED := _BTN_PATH + "buttonLong_beige_pressed.png"
const _BTN_GREY := _BTN_PATH + "buttonSquare_grey.png"
const _BTN_GREY_PRESSED := _BTN_PATH + "buttonSquare_grey_pressed.png"
const _PATCH_MARGIN: int = 8  # 9宫格边距保护四角圆边
const _FONT_COLOR_DARK := Color(0.24, 0.17, 0.10)  # 深褐

@onready var _btn_start: Button = %StartBtn
@onready var _btn_continue: Button = %ContinueBtn
@onready var _btn_settings: Button = %SettingsBtn
@onready var _btn_quit: Button = %QuitBtn
@onready var _btn_debug: Button = %DebugBtn
var _buttons: Array[Button] = []

var _overlay: ColorRect
var _continue_panel_scene: Control
var _panel_open: bool = false

# Delegates
var _ambience: LaunchAmbience
var _deck_select: DeckSelectPanel

# Assets
var _theme: Theme
var _sfx_click: AudioStream
var _sfx_hover: AudioStream


func _ready() -> void:
	_load_assets()
	MusicManager.play_menu_bgm()
	_build_ui()
	for btn in _buttons:
		btn.modulate.a = 0.0
	await get_tree().create_timer(SPLASH_DURATION).timeout
	_show_menu_buttons()
	_ambience = LaunchAmbience.new()
	_ambience.setup(self, $LaunchBg)
	_ambience.start()


func _load_assets() -> void:
	_theme = load("res://assets/themes/manga_theme.tres")
	_sfx_click = load("res://assets/audio/sound/ui/ui_click.ogg")
	_sfx_hover = load("res://assets/audio/sound/game/hover.ogg")


func _build_ui() -> void:
	_buttons = [_btn_start, _btn_continue, _btn_settings, _btn_quit]

	_btn_start.pressed.connect(_on_start_pressed)
	_btn_continue.pressed.connect(_on_continue_pressed)
	_btn_settings.pressed.connect(_on_settings_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)
	_btn_debug.pressed.connect(_on_debug_pressed)

	for btn in _buttons:
		btn.mouse_entered.connect(_on_button_hovered.bind(btn))
		btn.mouse_exited.connect(_on_button_unhovered.bind(btn))
		btn.pressed.connect(_play_click_sfx)

	_update_continue_button()

	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.modulate.a = 0.0
	_overlay.hide()
	_overlay.gui_input.connect(_on_overlay_gui_input)
	add_child(_overlay)

	_deck_select = preload("res://scenes/ninking/deck_select_panel.tscn").instantiate()
	add_child(_deck_select)
	_deck_select.setup(_theme, _on_deck_confirmed, _on_deck_cancelled, _play_click_sfx)

	_continue_panel_scene = preload("res://scenes/ninking/continue_panel.tscn").instantiate()
	add_child(_continue_panel_scene)
	_continue_panel_scene.continue_confirmed.connect(_on_continue_confirm)
	_continue_panel_scene.dismissed.connect(_hide_continue_panel)

	# Kenney 暖纸风按钮样式
	_apply_kenney_button_style_to_all()


func _apply_kenney_button_style_to_all() -> void:
	## 为 4 个主菜单按钮应用 buttonLong_beige，DebugBtn 应用 buttonSquare_grey
	var tex_beige := load(_BTN_BEIGE) as Texture2D
	var tex_beige_p := load(_BTN_BEIGE_PRESSED) as Texture2D
	var tex_grey := load(_BTN_GREY) as Texture2D
	var tex_grey_p := load(_BTN_GREY_PRESSED) as Texture2D

	for btn in _buttons:
		var s_normal := StyleBoxTexture.new()
		s_normal.texture = tex_beige
		s_normal.set("patch_margin_left", _PATCH_MARGIN)
		s_normal.set("patch_margin_top", _PATCH_MARGIN)
		s_normal.set("patch_margin_right", _PATCH_MARGIN)
		s_normal.set("patch_margin_bottom", _PATCH_MARGIN)
		btn.add_theme_stylebox_override("normal", s_normal)

		var s_pressed := StyleBoxTexture.new()
		s_pressed.texture = tex_beige_p
		s_pressed.set("patch_margin_left", _PATCH_MARGIN)
		s_pressed.set("patch_margin_top", _PATCH_MARGIN)
		s_pressed.set("patch_margin_right", _PATCH_MARGIN)
		s_pressed.set("patch_margin_bottom", _PATCH_MARGIN)
		btn.add_theme_stylebox_override("pressed", s_pressed)

		btn.add_theme_color_override("font_color", _FONT_COLOR_DARK)
		btn.add_theme_color_override("font_pressed_color", _FONT_COLOR_DARK)

	# DebugBtn 用 buttonSquare_grey
	var s_dbg_n := StyleBoxTexture.new()
	s_dbg_n.texture = tex_grey
	s_dbg_n.set("patch_margin_left", _PATCH_MARGIN)
	s_dbg_n.set("patch_margin_top", _PATCH_MARGIN)
	s_dbg_n.set("patch_margin_right", _PATCH_MARGIN)
	s_dbg_n.set("patch_margin_bottom", _PATCH_MARGIN)
	_btn_debug.add_theme_stylebox_override("normal", s_dbg_n)

	var s_dbg_p := StyleBoxTexture.new()
	s_dbg_p.texture = tex_grey_p
	s_dbg_p.set("patch_margin_left", _PATCH_MARGIN)
	s_dbg_p.set("patch_margin_top", _PATCH_MARGIN)
	s_dbg_p.set("patch_margin_right", _PATCH_MARGIN)
	s_dbg_p.set("patch_margin_bottom", _PATCH_MARGIN)
	_btn_debug.add_theme_stylebox_override("pressed", s_dbg_p)

	_btn_debug.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))  # 深灰
	_btn_debug.add_theme_color_override("font_pressed_color", Color(0.35, 0.35, 0.35))


func _update_continue_button() -> void:
	_btn_continue.disabled = not NinKingGameState.has_saved_run()


# Splash -> Menu transition

func _show_menu_buttons() -> void:
	var nodes: Array[CanvasItem] = []
	for btn in _buttons:
		nodes.append(btn)
	GlobalTweens.stagger_slide_in(nodes, BUTTON_STAGGER, BUTTON_SLIDE_DUR, BUTTON_SLIDE_OFFSET)


# Button handlers

func _on_start_pressed() -> void:
	if _panel_open:
		return
	_panel_open = true
	_overlay.show()
	GlobalTweens.fade_in(_overlay, 0.25)
	_deck_select.show_panel()


func _on_continue_pressed() -> void:
	if _panel_open:
		return
	_show_continue_panel()


func _on_settings_pressed() -> void:
	pass


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_debug_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ninking/debug_ninking_main.tscn")


# Deck panel callbacks

func _on_deck_confirmed(deck_key: String) -> void:
	_panel_open = false
	NinKingGameState.start_new_run(deck_key)
	get_tree().change_scene_to_file("res://scenes/ninking/ninking_main.tscn")


func _on_deck_cancelled() -> void:
	_panel_open = false
	_overlay.hide()
	_update_continue_button()


# Button hover effects

func _on_button_hovered(btn: Button) -> void:
	if btn.disabled:
		return
	GlobalTweens.card_hover(btn, Vector2(1.05, 1.05), -2.0)
	if _sfx_hover:
		GlobalTweens.play_sfx(_sfx_hover)


func _on_button_unhovered(btn: Button) -> void:
	if btn.disabled:
		return
	GlobalTweens.card_unhover(btn, Vector2.ONE, 0.0)


func _play_click_sfx() -> void:
	if _sfx_click:
		GlobalTweens.play_sfx(_sfx_click)


# Continue Panel

func _show_continue_panel() -> void:
	var data: Dictionary = SaveManager.load_run()
	if data.is_empty():
		ToastManager.show("没有可继续的存档")
		return
	_panel_open = true
	_continue_panel_scene.show_panel(data)
	_overlay.show()
	GlobalTweens.fade_in(_overlay, 0.25)
	_continue_panel_scene.show()
	GlobalTweens.pop_in(_continue_panel_scene, 0.25)


func _hide_continue_panel() -> void:
	_panel_open = false
	GlobalTweens.fade_out(_overlay, 0.2)
	GlobalTweens.fade_out(_continue_panel_scene, 0.2)
	await get_tree().create_timer(0.2).timeout
	_overlay.hide()
	_continue_panel_scene.hide()
	_update_continue_button()


func _on_continue_confirm() -> void:
	_panel_open = false
	NinKingGameState.continue_run()
	get_tree().change_scene_to_file("res://scenes/ninking/ninking_main.tscn")


# Overlay click -> close panels

func _on_overlay_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		if _deck_select.visible:
			_deck_select.hide_panel()
		elif _continue_panel_scene.visible:
			_hide_continue_panel()
