class_name DeckSelectPanel
extends RefCounted

## Deck selection panel UI for the main menu.
## Builds the panel programmatically, manages selection state and show/hide animation.
## Extracted from main_menu.gd to keep file under 300 lines.

const DECK_NAMES: Dictionary = {
	"standard": "标准牌组",
	"night": "暗夜牌组",
	"sun": "赤阳牌组",
}

const PLAYABLE_DECKS: Array[String] = ["standard"]

const FONT_LABEL: int = 24
const FONT_INFO: int = 20

var _parent: Node
var _theme: Theme
var _overlay: ColorRect
var _panel: Control
var _deck_cards: Array[Control] = []
var _selected_deck: String = "standard"

# Callbacks
var _on_confirmed: Callable
var _on_cancelled: Callable
var _play_sfx: Callable


func setup(parent: Node, theme: Theme, overlay: ColorRect, on_confirmed: Callable, on_cancelled: Callable, play_sfx: Callable) -> void:
	_parent = parent
	_theme = theme
	_overlay = overlay
	_on_confirmed = on_confirmed
	_on_cancelled = on_cancelled
	_play_sfx = play_sfx
	_build()


func _build() -> void:
	_panel = Control.new()
	_panel.name = "DeckPanel"
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.hide()
	_parent.add_child(_panel)

	var panel_bg := PanelContainer.new()
	panel_bg.name = "DeckPanelBg"
	panel_bg.theme = _theme
	panel_bg.size = Vector2(960, 600)
	_panel.add_child(panel_bg)
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
	confirm_btn.add_theme_font_size_override("font_size", FONT_LABEL)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	btn_row.add_child(confirm_btn)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(160, 48)
	back_btn.theme = _theme
	back_btn.add_theme_font_size_override("font_size", FONT_LABEL)
	back_btn.pressed.connect(hide_panel)
	btn_row.add_child(back_btn)


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
	name_label.add_theme_font_size_override("font_size", FONT_LABEL)
	vbox.add_child(name_label)

	var best_label := Label.new()
	best_label.name = "BestBarrier"
	if best_barrier > 0:
		best_label.text = "最佳: 结界 %d" % best_barrier
	else:
		best_label.text = "暂无记录"
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	if _play_sfx.is_valid():
		_play_sfx.call()


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


func show_panel() -> void:
	_overlay.show()
	GlobalTweens.fade_in(_overlay, 0.25)
	_panel.show()
	GlobalTweens.pop_in(_panel, 0.25)


func hide_panel() -> void:
	GlobalTweens.fade_out(_overlay, 0.2)
	GlobalTweens.fade_out(_panel, 0.2)
	await _panel.get_tree().create_timer(0.2).timeout
	_overlay.hide()
	_panel.hide()
	if _on_cancelled.is_valid():
		_on_cancelled.call()


func _on_confirm_pressed() -> void:
	if _on_confirmed.is_valid():
		_on_confirmed.call(_selected_deck)


func is_visible() -> bool:
	return _panel != null and _panel.visible
