class_name DeckSelectPanel
extends Control
## Deck selection panel — 960×600 centered card on dimmed overlay.
##
## Static structure in deck_select_panel.tscn; deck cards built dynamically.
## Usage:
##   var panel = preload("res://scenes/ninking/deck_select_panel.tscn").instantiate()
##   panel.setup(theme, on_confirmed, on_cancelled)
##   add_child(panel)

const DECK_NAMES: Dictionary = {
	"standard": "标准牌组",
	"night": "暗夜牌组",
	"sun": "赤阳牌组",
}

const PLAYABLE_DECKS: Array[String] = ["standard"]

const FONT_LABEL: int = 24
const FONT_INFO: int = 20

@onready var _panel_bg: PanelContainer = $PanelBg
@onready var _cards_row: HBoxContainer = %CardsRow
@onready var _confirm_btn: Button = %ConfirmBtn
@onready var _back_btn: Button = %BackBtn

var _deck_cards: Array[Control] = []
var _selected_deck: String = "standard"

var _on_confirmed: Callable
var _on_cancelled: Callable


func setup(btn_theme: Theme, on_confirmed: Callable, on_cancelled: Callable) -> void:
	_on_confirmed = on_confirmed
	_on_cancelled = on_cancelled

	_panel_bg.theme = btn_theme

	_confirm_btn.theme = btn_theme
	_confirm_btn.add_theme_font_size_override("font_size", FONT_LABEL)
	ButtonStyles.apply_kenney_long(_confirm_btn, "beige")
	_confirm_btn.pressed.connect(_on_confirm_pressed)

	_back_btn.theme = btn_theme
	_back_btn.add_theme_font_size_override("font_size", FONT_LABEL)
	ButtonStyles.apply_kenney_long(_back_btn, "beige")
	_back_btn.pressed.connect(hide_panel)

	_build_deck_cards()


func _build_deck_cards() -> void:
	var progress: Dictionary = SaveManager.load_progress()
	var bests: Dictionary = progress.get("deck_best_barriers", {})

	for deck_key: String in DECK_NAMES:
		var card := _make_deck_card(deck_key, DECK_NAMES[deck_key], bests.get(deck_key, 0))
		_cards_row.add_child(card)
		_deck_cards.append(card)

	_update_deck_selection(0)


func _make_deck_card(deck_key: String, deck_name: String, best_barrier: int) -> Control:
	var card := Control.new()
	card.name = "DeckCard_" + deck_key
	card.custom_minimum_size = Vector2(220, 300)

	var bg := PanelContainer.new()
	bg.name = "CardBg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	name_label.add_theme_color_override("font_color", Color(0.24, 0.17, 0.10))
	vbox.add_child(name_label)

	var best_label := Label.new()
	best_label.name = "BestBarrier"
	if best_barrier > 0:
		best_label.text = "最佳: 结界 %d" % best_barrier
	else:
		best_label.text = "暂无记录"
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_font_size_override("font_size", FONT_INFO)
	best_label.add_theme_color_override("font_color", Color(0.48, 0.42, 0.35))
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
	# SFX handled by ButtonStyles


func _update_deck_selection(idx: int) -> void:
	for i: int in range(_deck_cards.size()):
		var card: Control = _deck_cards[i]
		var bg: PanelContainer = card.get_node("CardBg")
		if i == idx:
			var selected_style := StyleBoxFlat.new()
			selected_style.bg_color = Color(0.94, 0.92, 0.86, 1.0)
			selected_style.border_width_left = 2
			selected_style.border_width_top = 2
			selected_style.border_width_right = 2
			selected_style.border_width_bottom = 2
			selected_style.border_color = Color(0.55, 0.43, 0.25, 1.0)
			selected_style.corner_radius_top_left = 8
			selected_style.corner_radius_top_right = 8
			selected_style.corner_radius_bottom_right = 8
			selected_style.corner_radius_bottom_left = 8
			selected_style.shadow_color = Color(0.55, 0.43, 0.25, 0.2)
			selected_style.shadow_size = 6
			bg.add_theme_stylebox_override("panel", selected_style)
		else:
			bg.remove_theme_stylebox_override("panel")


func show_panel() -> void:
	visible = true
	GlobalTweens.pop_in(self, 0.25)
	# 牌组面板弹入完成后，挂载 ConfirmBtn 完整入场动效
	await get_tree().create_timer(0.3).timeout
	if visible and is_inside_tree() and is_instance_valid(_confirm_btn):
		ButtonStyles.attach_entrance_animation(_confirm_btn)


func hide_panel() -> void:
	GlobalTweens.fade_out(self, 0.2)
	await get_tree().create_timer(0.2).timeout
	visible = false
	if _on_cancelled.is_valid():
		_on_cancelled.call()


func _on_confirm_pressed() -> void:
	if _on_confirmed.is_valid():
		_on_confirmed.call(_selected_deck)
