extends Control
## NinKing 主菜单 — 闪屏 → 按钮 → 牌组选择 / 继续确认面板
## Buttons defined in scene file; panels built programmatically.
## Deck panel delegated to DeckSelectPanel, ambient effects to LaunchAmbience.
##
## v10: Button entrance/hover/click unified via ButtonStyles.attach_entrance_animation.
##      Removed local _PULSE_CFG, _start_pulse, _stop_pulse, custom hover logic.
##      ButtonStyles manages modulate pulse, hover scale, click feedback.
##
## Godot 4.6.2 gl_compatibility MODULATE uniform bug:
##   modulate RGB 不生效，按钮呼吸用 StyleBoxTexture.modulate_color 回退。
##   hover 时先 scale=ONE → card_hover 保存正确基线 → unhover 后重启呼吸。

const SPLASH_DURATION: float = 0.8
const BUTTON_STAGGER: float = 0.08
const BUTTON_SLIDE_DUR: float = 0.4
const BUTTON_SLIDE_OFFSET: float = 80.0

@onready var _btn_start: Button = %StartBtn
@onready var _btn_continue: Button = %ContinueBtn
@onready var _btn_settings: Button = %SettingsBtn
@onready var _btn_quit: Button = %QuitBtn
@onready var _btn_debug: Button = %DebugBtn
@onready var _btn_clean: Button = %CleanBtn
var _buttons: Array[Button] = []

var _overlay: ColorRect
var _continue_panel_scene: Control
var _panel_open: bool = false
var _pending_mode: String = "bi_ji"  # "bi_ji"=笔记模式, "clean"=消除模式

# Delegates
var _ambience: LaunchAmbience
var _deck_select: DeckSelectPanel

# Assets
var _theme: Theme
var _sfx_hover: AudioStream


func _ready() -> void:
	_load_assets()
	MusicManager.play_menu_bgm()
	_build_ui()
	for btn in _buttons:
		btn.modulate.a = 0.0
	await get_tree().create_timer(SPLASH_DURATION).timeout
	_show_menu_buttons()
	var stagger_end: float = BUTTON_STAGGER * (_buttons.size() - 1) + BUTTON_SLIDE_DUR
	await get_tree().create_timer(stagger_end).timeout
	# entrance done -> ButtonStyles hover + click
	# StartBtn keeps pulse, others skip (cleaner)
	for btn in _buttons:
		var cfg: Dictionary = {"mild": true}
		if btn != _btn_start:
			cfg["pulse"] = false
		ButtonStyles.attach_entrance_animation(btn, cfg)
	ButtonStyles.attach_entrance_animation(_btn_debug, {"mild": true, "pulse": false})
	_ambience = LaunchAmbience.new()
	_ambience.setup(self, $LaunchBg)
	_ambience.start()


func _load_assets() -> void:
	_theme = load("res://assets/themes/manga_theme.tres")
	_sfx_hover = load("res://assets/audio/sound/game/hover.ogg")


# ─── UI 构建 ───

func _build_ui() -> void:
	_buttons = [_btn_start, _btn_clean, _btn_continue, _btn_settings, _btn_quit]

	_btn_start.pressed.connect(_on_start_pressed)
	_btn_clean.pressed.connect(_on_clean_pressed)
	_btn_continue.pressed.connect(_on_continue_pressed)
	_btn_settings.pressed.connect(_on_settings_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)
	_btn_debug.pressed.connect(_on_debug_pressed)

	for btn in _buttons:
		btn.mouse_entered.connect(_on_button_hovered.bind(btn))
		btn.mouse_exited.connect(_on_button_unhovered.bind(btn))

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
	_deck_select.setup(_theme, _on_deck_confirmed, _on_deck_cancelled)

	_continue_panel_scene = preload("res://scenes/ninking/continue_panel.tscn").instantiate()
	add_child(_continue_panel_scene)
	_continue_panel_scene.continue_confirmed.connect(_on_continue_confirm)
	_continue_panel_scene.dismissed.connect(_hide_continue_panel)

	# Kenney 暖纸风按钮样式
	for btn in _buttons:
		ButtonStyles.apply_kenney_long(btn, "beige")
	ButtonStyles.apply_kenney_long(_btn_clean, "brown")
	ButtonStyles.apply_kenney_long(_btn_debug, "grey")


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
	_pending_mode = "bi_ji"
	_panel_open = true
	_overlay.show()
	GlobalTweens.fade_in(_overlay, 0.25)
	_deck_select.show_panel()


func _on_clean_pressed() -> void:
	if _panel_open:
		return
	_pending_mode = "clean"
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
	var target_scene: String
	if _pending_mode == "clean":
		NinKingGameState.start_new_run(deck_key, "clean")
		target_scene = "res://scenes/ninking/ninking_clean_main.tscn"
	else:
		NinKingGameState.start_new_run(deck_key)
		target_scene = "res://scenes/ninking/ninking_main.tscn"
	get_tree().change_scene_to_file(target_scene)


func _on_deck_cancelled() -> void:
	_panel_open = false
	_overlay.hide()
	_update_continue_button()


# Button hover effects — SFX only (scale handled by ButtonStyles)

func _on_button_hovered(btn: Button) -> void:
	if btn.disabled:
		return
	if _sfx_hover:
		GlobalTweens.play_sfx(_sfx_hover)


func _on_button_unhovered(_btn: Button) -> void:
	pass  # handled by ButtonStyles


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
