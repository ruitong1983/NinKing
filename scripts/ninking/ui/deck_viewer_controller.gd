class_name DeckViewerController
extends RefCounted

## Manages the deck viewer popup — grid display, open/close, card sorting.
## Extracted from UIManager to keep file under 300 lines.

var deck_btn: Button
var deck_viewer: Control
var deck_close_btn: Button
var deck_draw_count_label: Label
var deck_discard_count_label: Label
var deck_card_grid: GridContainer
var viewer_bg: ColorRect


func setup(
		_btn: Button,
		_viewer: Control,
		_close_btn: Button,
		_draw_label: Label,
		_discard_label: Label,
		_grid: GridContainer,
		_bg: ColorRect) -> void:
	deck_btn = _btn
	deck_viewer = _viewer
	deck_close_btn = _close_btn
	deck_draw_count_label = _draw_label
	deck_discard_count_label = _discard_label
	deck_card_grid = _grid
	viewer_bg = _bg

	deck_btn.pressed.connect(_on_deck_btn_pressed)
	deck_close_btn.pressed.connect(_on_close_deck_viewer)
	viewer_bg.gui_input.connect(_on_deck_bg_input)


func update_deck_count(draw_count: int, _discard_count: int) -> void:
	deck_btn.text = "🎴 牌库: %d" % draw_count


func _on_deck_btn_pressed() -> void:
	_build_deck_viewer_grid()
	deck_viewer.modulate.a = 0.0
	deck_viewer.visible = true
	GlobalTweens.fade_in(deck_viewer, 0.25)


func _on_close_deck_viewer() -> void:
	var t: Tween = GlobalTweens.fade_out(deck_viewer, 0.2)
	t.tween_callback(func(): deck_viewer.visible = false)


func _on_deck_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_close_deck_viewer()


func _build_deck_viewer_grid() -> void:
	for child: Node in deck_card_grid.get_children():
		child.queue_free()

	var dm: DeckManager = NinKingGameState.deck_manager
	if dm == null:
		return

	deck_draw_count_label.text = "牌堆: %d 张" % dm.draw_pile.size()
	deck_discard_count_label.text = "手替札: %d 张" % dm.discard_pile.size()

	var sorted_cards: Array[CardData.PlayingCard] = dm.draw_pile.duplicate()
	sorted_cards.sort_custom(_compare_cards)

	for card: CardData.PlayingCard in sorted_cards:
		var pc: NinKingCard = NinKingCard.new()
		pc.card_size = Vector2(120, 160)
		pc.playing_card_data = card
		pc.can_be_interacted_with = false
		pc.name = "DeckCard_%d_%d" % [card.suit, card.rank]
		pc.update_display()
		deck_card_grid.add_child(pc)


func _compare_cards(a: CardData.PlayingCard, b: CardData.PlayingCard) -> bool:
	if a.suit != b.suit:
		return a.suit > b.suit
	return a.rank > b.rank


## Note: FrontFace/BackFace structure is now created by NinKingCard._ready().
## No manual setup needed — the card self-assembles on add_child().
