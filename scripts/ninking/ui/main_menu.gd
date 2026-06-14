extends Control
## NinKing 主菜单 — 闪屏 → 按钮 → 牌组选择 / 继续确认面板
## Buttons defined in scene file; panels built programmatically.
## Deck panel delegated to DeckSelectPanel, ambient effects to LaunchAmbience.

const SPLASH_DURATION: float = 0.8
const BUTTON_STAGGER: float = 0.08
const BUTTON_SLIDE_DUR: float = 0.4
const BUTTON_SLIDE_OFFSET: float = 80.0

@onready var _btn_start: Button = %StartBtn
@onready var _btn_continue: Button = %ContinueBtn
@onready var _btn_settings: Button = %SettingsBtn
@onready var _btn_quit: Button = %QuitBtn
@onready var _btn_debug: Button = %DebugBtn
var _buttons: Array[Button] = []

var _overlay: ColorRect
var _continue_panel: Control
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
	# Splash: hide buttons, then slide in
	for btn: Button in _buttons:
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

	# Connect signals
	_btn_start.pressed.connect(_on_start_pressed)
	_btn_continue.pressed.connect(_on_continue_pressed)
	_btn_settings.pressed.connect(_on_settings_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)
	_btn_debug.pressed.connect(_on_debug_pressed)

	for btn: Button in _buttons:
		btn.mouse_entered.connect(_on_button_hovered.bind(btn))
		btn.mouse_exited.connect(_on_button_unhovered.bind(btn))
		btn.pressed.connect(_play_click_sfx)

	_update_continue_button()

	# Full-screen overlay (hidden, behind panels)
	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.modulate.a = 0.0
	_overlay.hide()
	_overlay.gui_input.connect(_on_overlay_gui_input)
	add_child(_overlay)

	# Delegates
	_deck_select = preload("res://scenes/ninking/deck_select_panel.tscn").instantiate()
	add_child(_deck_select)
	_deck_select.setup(_theme, _on_deck_confirmed, _on_deck_cancelled, _play_click_sfx)

	# Continue panel (stays inline — 104 lines)
	_build_continue_panel(self)


func _update_continue_button() -> void:
	_btn_continue.disabled = not NinKingGameState.has_saved_run()


## Set a Control's anchors to center and place it at the screen center.
func _center_control(ctrl: Control) -> void:
	var half: Vector2 = ctrl.size * 0.5
	ctrl.anchor_left = 0.5
	ctrl.anchor_top = 0.5
	ctrl.anchor_right = 0.5
	ctrl.anchor_bottom = 0.5
	ctrl.offset_left = -half.x
	ctrl.offset_top = -half.y
	ctrl.offset_right = half.x
	ctrl.offset_bottom = half.y


# ══════════════════════════════════════════
# Splash → Menu transition
# ══════════════════════════════════════════

func _show_menu_buttons() -> void:
	var nodes: Array[CanvasItem] = []
	for btn: Button in _buttons:
		nodes.append(btn)
	GlobalTweens.stagger_slide_in(nodes, BUTTON_STAGGER, BUTTON_SLIDE_DUR, BUTTON_SLIDE_OFFSET)


# ══════════════════════════════════════════
# Button handlers
# ══════════════════════════════════════════

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
	## Launch the Debug scoring scene (independent of main game).
	get_tree().change_scene_to_file("res://scenes/ninking/debug_ninking_main.tscn")


# ══════════════════════════════════════════
# Deck panel callbacks
# ══════════════════════════════════════════

func _on_deck_confirmed(deck_key: String) -> void:
	_panel_open = false
	NinKingGameState.start_new_run(deck_key)
	get_tree().change_scene_to_file("res://scenes/ninking/ninking_main.tscn")


func _on_deck_cancelled() -> void:
	_panel_open = false
	_overlay.hide()
	_update_continue_button()


# ══════════════════════════════════════════
# Button hover effects
# ══════════════════════════════════════════

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


# ══════════════════════════════════════════
# Continue Panel
# ══════════════════════════════════════════

func _build_continue_panel(parent: Node) -> void:
	_continue_panel = Control.new()
	_continue_panel.name = "ContinuePanel"
	_continue_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_continue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_continue_panel.hide()
	parent.add_child(_continue_panel)

	var panel_bg := PanelContainer.new()
	panel_bg.name = "ContinuePanelBg"
	panel_bg.theme = _theme
	panel_bg.size = Vector2(560, 400)
	_continue_panel.add_child(panel_bg)
	_center_control(panel_bg)

	var vbox := VBoxContainer.new()
	vbox.name = "ContinueVBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	panel_bg.add_child(vbox)

	var title := Label.new()
	title.name = "ContinueTitle"
	title.text = "继续冒险"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.91, 0.77, 0.27))
	vbox.add_child(title)

	var info := Label.new()
	info.name = "ContinueInfo"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 24)
	info.add_theme_color_override("font_color", Color(0.78, 0.78, 0.82))
	vbox.add_child(info)

	var btn_row := HBoxContainer.new()
	btn_row.name = "ContinueBtnRow"
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_row)

	var go_btn := Button.new()
	go_btn.text = "继续冒险"
	go_btn.custom_minimum_size = Vector2(180, 48)
	go_btn.theme = _theme
	go_btn.add_theme_font_size_override("font_size", 24)
	go_btn.pressed.connect(_on_continue_confirm)
	btn_row.add_child(go_btn)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(160, 48)
	back_btn.theme = _theme
	back_btn.add_theme_font_size_override("font_size", 24)
	back_btn.pressed.connect(_hide_continue_panel)
	btn_row.add_child(back_btn)


func _show_continue_panel() -> void:
	var data: Dictionary = SaveManager.load_run()
	if data.is_empty():
		ToastManager.show("没有可继续的存档")
		return
	_panel_open = true

	var info: Label = _continue_panel.get_node("ContinuePanelBg/ContinueVBox/ContinueInfo")
	var barrier: int = data.get("barrier_num", 1)
	var seal_names: Array[String] = ["修羅", "明王", "夜叉"]
	var seal_idx: int = data.get("seal_idx", 0)
	var seal_name: String = seal_names[seal_idx] if seal_idx < seal_names.size() else "?"
	var gold: int = data.get("gold", 0)
	var ninja_count: int = (data.get("owned_ninjas", []) as Array).size()
	var score: int = data.get("current_score", 0)
	var target: int = data.get("target_score", 0)

	info.text = "结界 %d · %s封印\n当前忍気: %d / %d\n金币: $%d · 忍者: %d 人" % [
		barrier, seal_name, score, target, gold, ninja_count
	]

	_overlay.show()
	GlobalTweens.fade_in(_overlay, 0.25)
	_continue_panel.show()
	GlobalTweens.pop_in(_continue_panel, 0.25)


func _hide_continue_panel() -> void:
	_panel_open = false
	GlobalTweens.fade_out(_overlay, 0.2)
	GlobalTweens.fade_out(_continue_panel, 0.2)
	await get_tree().create_timer(0.2).timeout
	_overlay.hide()
	_continue_panel.hide()
	_update_continue_button()


func _on_continue_confirm() -> void:
	_panel_open = false
	NinKingGameState.continue_run()
	get_tree().change_scene_to_file("res://scenes/ninking/ninking_main.tscn")


# ══════════════════════════════════════════
# Overlay click → close panels
# ══════════════════════════════════════════

func _on_overlay_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		if _deck_select.visible:
			_deck_select.hide_panel()
		elif _continue_panel.visible:
			_hide_continue_panel()
