extends Node
## NinKing 主菜单 — 闪屏 → 按钮 → 牌组选择 / 继续确认面板

const DECK_NAMES: Dictionary = {
	"standard": "标准牌组",
	"night": "暗夜牌组",
	"sun": "赤阳牌组",
}

## 当前仅标准牌组可玩；night/sun 在牌组系统实现前置灰
const PLAYABLE_DECKS: Array[String] = ["standard"]

const SPLASH_DURATION: float = 0.8
const BUTTON_STAGGER: float = 0.08
const BUTTON_SLIDE_DUR: float = 0.4
const BUTTON_SLIDE_OFFSET: float = 80.0

# Menu button layout (32px Chinese font)
const BTN_WIDTH: int = 300
const BTN_HEIGHT: int = 72
const BTN_SPACING: int = 24
const BTN_START_Y: float = 680.0
const BTN_X: float = 80.0

const FONT_TITLE: int = 32
const FONT_LABEL: int = 24
const FONT_INFO: int = 20

var _btn_start: Button
var _btn_continue: Button
var _btn_settings: Button
var _btn_quit: Button
var _buttons: Array[Button] = []

var _menu_container: Control
var _overlay: ColorRect
var _deck_panel: Control
var _deck_cards: Array[Control] = []
var _selected_deck: String = "standard"
var _continue_panel: Control
var _panel_open: bool = false

# Assets
var _cn_font: FontFile
var _theme: Theme
var _sfx_click: AudioStream
var _sfx_hover: AudioStream


# ══════════════════════════════════════════
# Lifecycle
# ══════════════════════════════════════════

func _ready() -> void:
	_load_assets()
	GlobalTweens.set_crt_enabled(true)
	MusicManager.play_menu_bgm()
	_build_ui()
	# 闪屏阶段 — 隐藏按钮，延迟后滑入
	_menu_container.modulate.a = 0.0
	await get_tree().create_timer(SPLASH_DURATION).timeout
	_show_menu_buttons()


func _load_assets() -> void:
	_cn_font = load("res://assets/fonts/vonwaon_bitmap_16px.ttf")
	_theme = load("res://assets/themes/pixel_theme.tres")
	_sfx_click = load("res://assets/audio/sound/ui/ui_click.ogg")
	_sfx_hover = load("res://assets/audio/sound/game/hover.ogg")


# ══════════════════════════════════════════
# UI Construction
# ══════════════════════════════════════════

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "MenuCanvas"
	canvas.layer = 1
	add_child(canvas)

	# Full-screen overlay (hidden until a panel opens)
	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.modulate.a = 0.0
	_overlay.hide()
	_overlay.gui_input.connect(_on_overlay_gui_input)
	canvas.add_child(_overlay)

	# Buttons container
	_menu_container = Control.new()
	_menu_container.name = "MenuButtons"
	_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_menu_container)

	# Build each button
	_btn_start = _make_button("开始游戏", BTN_X, BTN_START_Y)
	_btn_continue = _make_button("继续游戏", BTN_X, BTN_START_Y + BTN_HEIGHT + BTN_SPACING)
	_btn_settings = _make_button("设置", BTN_X, BTN_START_Y + (BTN_HEIGHT + BTN_SPACING) * 2)
	_btn_quit = _make_button("退出游戏", BTN_X, BTN_START_Y + (BTN_HEIGHT + BTN_SPACING) * 3)

	_btn_start.pressed.connect(_on_start_pressed)
	_btn_continue.pressed.connect(_on_continue_pressed)
	_btn_settings.pressed.connect(_on_settings_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)

	_buttons = [_btn_start, _btn_continue, _btn_settings, _btn_quit]

	# Settings button: disabled placeholder
	_btn_settings.disabled = true

	# Continue: visible only if save exists
	_update_continue_button()

	# Build panels (hidden)
	_build_deck_panel(canvas)
	_build_continue_panel(canvas)


func _make_button(text: String, x: float, y: float) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = Vector2(x, y)
	btn.size = Vector2(BTN_WIDTH, BTN_HEIGHT)
	btn.theme = _theme
	btn.add_theme_font_override("font", _cn_font)
	btn.add_theme_font_size_override("font_size", FONT_TITLE)
	btn.mouse_entered.connect(_on_button_hovered.bind(btn))
	btn.mouse_exited.connect(_on_button_unhovered.bind(btn))
	btn.pressed.connect(_play_click_sfx)
	_menu_container.add_child(btn)
	return btn


func _update_continue_button() -> void:
	_btn_continue.disabled = not NinKingGameState.has_saved_run()


# ══════════════════════════════════════════
# Splash → Menu transition
# ══════════════════════════════════════════

func _show_menu_buttons() -> void:
	# Container must be visible BEFORE stagger_slide_in sets per-button alpha=0
	_menu_container.modulate.a = 1.0
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
	_show_deck_panel()


func _on_continue_pressed() -> void:
	if _panel_open:
		return
	_show_continue_panel()


func _on_settings_pressed() -> void:
	pass  # disabled; no-op


func _on_quit_pressed() -> void:
	get_tree().quit()


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
# Deck Selection Panel
# ══════════════════════════════════════════

func _build_deck_panel(parent: Node) -> void:
	_deck_panel = Control.new()
	_deck_panel.name = "DeckPanel"
	_deck_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_deck_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deck_panel.hide()
	parent.add_child(_deck_panel)

	var panel_bg := PanelContainer.new()
	panel_bg.name = "DeckPanelBg"
	panel_bg.theme = _theme
	panel_bg.set_anchors_preset(Control.PRESET_CENTER)
	panel_bg.custom_minimum_size = Vector2(960, 600)
	panel_bg.position = Vector2(-480, -300)
	_deck_panel.add_child(panel_bg)

	var vbox := VBoxContainer.new()
	vbox.name = "DeckVBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 32)
	panel_bg.add_child(vbox)

	# Title
	var title := Label.new()
	title.name = "DeckTitle"
	title.text = "选择牌组"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _cn_font)
	title.add_theme_font_size_override("font_size", FONT_TITLE)
	title.add_theme_color_override("font_color", Color(0.91, 0.77, 0.27))
	vbox.add_child(title)

	# Deck cards row
	var cards_row := HBoxContainer.new()
	cards_row.name = "DeckCards"
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 32)
	vbox.add_child(cards_row)

	var progress: Dictionary = SaveManager.load_progress()
	var bests: Dictionary = progress.get("deck_best_barriers", {})

	for deck_key: String in DECK_NAMES:
		var card := _make_deck_card(deck_key, DECK_NAMES[deck_key], bests.get(deck_key, 0))
		cards_row.add_child(card)
		_deck_cards.append(card)

	# Default: select standard
	_update_deck_selection(0)

	# Buttons row
	var btn_row := HBoxContainer.new()
	btn_row.name = "DeckBtnRow"
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_row)

	var confirm_btn := Button.new()
	confirm_btn.text = "确认"
	confirm_btn.custom_minimum_size = Vector2(160, 48)
	confirm_btn.theme = _theme
	confirm_btn.add_theme_font_override("font", _cn_font)
	confirm_btn.add_theme_font_size_override("font_size", FONT_LABEL)
	confirm_btn.pressed.connect(_on_deck_confirm)
	btn_row.add_child(confirm_btn)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(160, 48)
	back_btn.theme = _theme
	back_btn.add_theme_font_override("font", _cn_font)
	back_btn.add_theme_font_size_override("font_size", FONT_LABEL)
	back_btn.pressed.connect(_hide_deck_panel)
	btn_row.add_child(back_btn)


func _make_deck_card(deck_key: String, deck_name: String, best_barrier: int) -> Control:
	var card := Control.new()
	card.name = "DeckCard_" + deck_key
	card.custom_minimum_size = Vector2(220, 300)

	var bg := PanelContainer.new()
	bg.name = "CardBg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.theme = _theme
	card.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.name = "CardVBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	bg.add_child(vbox)

	var name_label := Label.new()
	name_label.name = "DeckName"
	name_label.text = deck_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override("font", _cn_font)
	name_label.add_theme_font_size_override("font_size", FONT_LABEL)
	vbox.add_child(name_label)

	var best_label := Label.new()
	best_label.name = "BestBarrier"
	if best_barrier > 0:
		best_label.text = "最佳: 结界 %d" % best_barrier
	else:
		best_label.text = "暂无记录"
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_font_override("font", _cn_font)
	best_label.add_theme_font_size_override("font_size", FONT_INFO)
	vbox.add_child(best_label)

	# Grey out non-playable decks
	if not PLAYABLE_DECKS.has(deck_key):
		card.modulate = Color(0.4, 0.4, 0.4, 0.6)
	else:
		card.gui_input.connect(_on_deck_card_clicked.bind(deck_key, card))

	return card


func _on_deck_card_clicked(event: InputEvent, deck_key: String, _card: Control) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if not PLAYABLE_DECKS.has(deck_key):
		return
	_selected_deck = deck_key
	var idx: int = DECK_NAMES.keys().find(deck_key)
	_update_deck_selection(idx)
	_play_click_sfx()


func _update_deck_selection(idx: int) -> void:
	for i: int in range(_deck_cards.size()):
		var card: Control = _deck_cards[i]
		var bg: PanelContainer = card.get_node("CardBg")
		if i == idx:
			var selected_style := StyleBoxFlat.new()
			selected_style.bg_color = Color(0.12, 0.08, 0.25, 1.0)
			selected_style.border_width_left = 2
			selected_style.border_width_top = 2
			selected_style.border_width_right = 2
			selected_style.border_width_bottom = 2
			selected_style.border_color = Color(0.94, 0.75, 0.25, 1.0)
			selected_style.corner_radius_top_left = 8
			selected_style.corner_radius_top_right = 8
			selected_style.corner_radius_bottom_right = 8
			selected_style.corner_radius_bottom_left = 8
			selected_style.shadow_color = Color(0.94, 0.75, 0.25, 0.35)
			selected_style.shadow_size = 10
			bg.add_theme_stylebox_override("panel", selected_style)
		else:
			bg.remove_theme_stylebox_override("panel")


func _show_deck_panel() -> void:
	_panel_open = true
	_overlay.show()
	GlobalTweens.fade_in(_overlay, 0.25)
	_deck_panel.show()
	GlobalTweens.pop_in(_deck_panel, 0.25)


func _hide_deck_panel() -> void:
	_panel_open = false
	GlobalTweens.fade_out(_overlay, 0.2)
	GlobalTweens.fade_out(_deck_panel, 0.2)
	await get_tree().create_timer(0.2).timeout
	_overlay.hide()
	_deck_panel.hide()
	_update_continue_button()


func _on_deck_confirm() -> void:
	_panel_open = false
	NinKingGameState.start_new_run(_selected_deck)
	get_tree().change_scene_to_file("res://scenes/ninking/ninking_main.tscn")


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
	panel_bg.set_anchors_preset(Control.PRESET_CENTER)
	panel_bg.custom_minimum_size = Vector2(560, 400)
	panel_bg.position = Vector2(-280, -200)
	_continue_panel.add_child(panel_bg)

	var vbox := VBoxContainer.new()
	vbox.name = "ContinueVBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	panel_bg.add_child(vbox)

	# Title
	var title := Label.new()
	title.name = "ContinueTitle"
	title.text = "继续冒险"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _cn_font)
	title.add_theme_font_size_override("font_size", FONT_TITLE)
	title.add_theme_color_override("font_color", Color(0.91, 0.77, 0.27))
	vbox.add_child(title)

	# Save info label (populated on show)
	var info := Label.new()
	info.name = "ContinueInfo"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_override("font", _cn_font)
	info.add_theme_font_size_override("font_size", FONT_LABEL)
	info.add_theme_color_override("font_color", Color(0.78, 0.78, 0.82))
	vbox.add_child(info)

	# Button row
	var btn_row := HBoxContainer.new()
	btn_row.name = "ContinueBtnRow"
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_row)

	var go_btn := Button.new()
	go_btn.text = "继续冒险"
	go_btn.custom_minimum_size = Vector2(180, 48)
	go_btn.theme = _theme
	go_btn.add_theme_font_override("font", _cn_font)
	go_btn.add_theme_font_size_override("font_size", FONT_LABEL)
	go_btn.pressed.connect(_on_continue_confirm)
	btn_row.add_child(go_btn)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(160, 48)
	back_btn.theme = _theme
	back_btn.add_theme_font_override("font", _cn_font)
	back_btn.add_theme_font_size_override("font_size", FONT_LABEL)
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
		if _deck_panel.visible:
			_hide_deck_panel()
		elif _continue_panel.visible:
			_hide_continue_panel()
