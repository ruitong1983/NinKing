extends Control
## NinKing 主菜单 — 闪屏 → 按钮 → 牌组选择 / 继续确认面板
## Buttons defined in scene file; panels built programmatically.

const DECK_NAMES: Dictionary = {
	"standard": "标准牌组",
	"night": "暗夜牌组",
	"sun": "赤阳牌组",
}

const PLAYABLE_DECKS: Array[String] = ["standard"]

const SPLASH_DURATION: float = 0.8
const BUTTON_STAGGER: float = 0.08
const BUTTON_SLIDE_DUR: float = 0.4
const BUTTON_SLIDE_OFFSET: float = 80.0

const FONT_LABEL: int = 24
const FONT_INFO: int = 20

@onready var _btn_start: Button = %StartBtn
@onready var _btn_continue: Button = %ContinueBtn
@onready var _btn_settings: Button = %SettingsBtn
@onready var _btn_quit: Button = %QuitBtn
var _buttons: Array[Button] = []

var _overlay: ColorRect
var _deck_panel: Control
var _deck_cards: Array[Control] = []
var _selected_deck: String = "standard"
var _continue_panel: Control
var _panel_open: bool = false

# Ambient effects
var _bg_breath_tween: Tween
var _ambient_timer: Timer
var _particle_layer: CanvasLayer
var _sakura_tex: ImageTexture

# Assets
var _cn_font: FontFile
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
	_start_ambient_effects()


func _load_assets() -> void:
	_cn_font = load("res://assets/fonts/vonwaon_bitmap_16px.ttf")
	_theme = load("res://assets/themes/pixel_theme.tres")
	_sfx_click = load("res://assets/audio/sound/ui/ui_click.ogg")
	_sfx_hover = load("res://assets/audio/sound/game/hover.ogg")


func _build_ui() -> void:
	_buttons = [_btn_start, _btn_continue, _btn_settings, _btn_quit]

	# Connect signals
	_btn_start.pressed.connect(_on_start_pressed)
	_btn_continue.pressed.connect(_on_continue_pressed)
	_btn_settings.pressed.connect(_on_settings_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)

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

	# Build panels (hidden)
	_build_deck_panel(self)
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
# Ambient effects
# ══════════════════════════════════════════

func _start_ambient_effects() -> void:
	# ── Background slow breathing: scale 1.0↔1.04, 14s cycle ──
	var bg: TextureRect = $LaunchBg
	bg.pivot_offset = bg.size * 0.5
	_bg_breath_tween = create_tween()
	_bg_breath_tween.set_loops()
	_bg_breath_tween.tween_property(bg, "scale", Vector2(1.04, 1.04), 7.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_bg_breath_tween.tween_property(bg, "scale", Vector2(1.0, 1.0), 7.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# ── Particle CanvasLayer (layer 128 — above everything) ──
	_particle_layer = CanvasLayer.new()
	_particle_layer.name = "ParticleLayer"
	_particle_layer.layer = 128
	add_child(_particle_layer)

	# ── Cache sakura texture once ──
	_sakura_tex = _make_sakura_tex()

	# ── Ambient sakura petals: local burst, Timer-driven ──
	_ambient_timer = Timer.new()
	_ambient_timer.name = "AmbientTimer"
	_ambient_timer.wait_time = randf_range(1.0, 2.0)
	_ambient_timer.timeout.connect(_on_ambient_tick)
	_particle_layer.add_child(_ambient_timer)
	_ambient_timer.start()


func _on_ambient_tick() -> void:
	var vp: Rect2 = get_viewport().get_visible_rect()
	var pos := Vector2(randf_range(0.0, vp.size.x), randf_range(0.0, vp.size.y * 0.4))
	_spawn_sakura_burst(pos)
	_ambient_timer.wait_time = randf_range(1.0, 2.0)


## Spawn a one-shot sakura particle burst at the given position.
func _spawn_sakura_burst(at: Vector2) -> void:
	const SAKURA_LIFETIME: float = 3.0
	const SAKURA_AMOUNT: int = 40
	const SAKURA_SPREAD: float = 120.0
	const SAKURA_COLOR := Color(1.0, 0.7, 0.8, 1.0)

	var p := CPUParticles2D.new()
	p.texture = _sakura_tex
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = SAKURA_AMOUNT
	p.lifetime = SAKURA_LIFETIME
	p.spread = SAKURA_SPREAD
	p.direction = Vector2(0, -1)
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 90.0
	p.damping_min = 2.0
	p.damping_max = 4.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 4.0
	p.modulate = SAKURA_COLOR
	p.position = at
	p.finished.connect(p.queue_free)
	_particle_layer.add_child(p)
	p.emitting = true


func _make_sakura_tex() -> ImageTexture:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in range(8):
		for x in range(8):
			var d := Vector2(float(x) - 3.5, float(y) - 3.5).length() / 3.5
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(img)


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
	pass


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
	panel_bg.size = Vector2(960, 600)
	_deck_panel.add_child(panel_bg)
	_center_control(panel_bg)

	var vbox := VBoxContainer.new()
	vbox.name = "DeckVBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 32)
	panel_bg.add_child(vbox)

	var title := Label.new()
	title.name = "DeckTitle"
	title.text = "选择牌组"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _cn_font)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.91, 0.77, 0.27))
	vbox.add_child(title)

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

	_update_deck_selection(0)

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
	title.add_theme_font_override("font", _cn_font)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.91, 0.77, 0.27))
	vbox.add_child(title)

	var info := Label.new()
	info.name = "ContinueInfo"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_override("font", _cn_font)
	info.add_theme_font_size_override("font_size", FONT_LABEL)
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
