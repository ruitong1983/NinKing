class_name DeckViewerController
extends RefCounted

## Manages the deck viewer popup — grid display, open/close, card sorting.
## Extracted from UIManager to keep file under 300 lines.
## 换牌系统已移除: DiscardCountLabel 已删除，discard_count 参数一并清理。

## Half of NinKingCard's default card_size (125×175) for deck overview.
## SVG textures are resized to this at load time; the 13-column GridContainer
## fits 4 rows (52 cards) without scrolling at this size.
const DECK_CARD_SIZE: Vector2 = Vector2(63, 88)

# ── Row layout: 4 rows × 13 columns, one suit per row ──
# Suit enum: CLUBS=0, DIAMONDS=1, HEARTS=2, SPADES=3
const _SUIT_ROW_ORDER: Array[int] = [3, 2, 1, 0]  # Spades → Hearts → Diamonds → Clubs
# Within each suit: Ace → King → Queen → … → Two
const _RANK_ORDER: Array[int] = [14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2]

var deck_btn: Button
var deck_viewer: Control
var deck_close_btn: Button
var deck_draw_count_label: Label
var deck_card_grid: GridContainer
var viewer_bg: ColorRect

# Guards rapid double-click from stacking competing fade tweens.
var _animating: bool = false


func setup(_btn: Button, _viewer: Control, _close_btn: Button, _draw_label: Label, _grid: GridContainer, _bg: ColorRect) -> void:
	deck_btn = _btn
	deck_viewer = _viewer
	deck_close_btn = _close_btn
	deck_draw_count_label = _draw_label
	deck_card_grid = _grid
	viewer_bg = _bg

	deck_btn.pressed.connect(_on_deck_btn_pressed)
	ButtonStyles.apply_kenney_square(deck_close_btn, "beige")
	deck_close_btn.pressed.connect(_on_close_deck_viewer)
	viewer_bg.gui_input.connect(_on_deck_bg_input)


func update_deck_count(draw_count: int) -> void:
	deck_btn.text = "牌库: %d" % draw_count


func _on_deck_btn_pressed() -> void:
	if NinKingGameState.current_state != NinKingGameState.State.PLAYING:
		return
	if deck_viewer.visible:
		_close_with_anim()
		return
	_animating = false
	_build_deck_viewer_grid()
	deck_viewer.modulate.a = 0.0
	deck_viewer.visible = true
	GlobalTweens.fade_in(deck_viewer, 0.25)


func _close_with_anim() -> void:
	if _animating:
		return
	_animating = true
	var t: Tween = GlobalTweens.fade_out(deck_viewer, 0.2)
	t.tween_callback(func():
		deck_viewer.visible = false
		_animating = false
	)


func _on_close_deck_viewer() -> void:
	_close_with_anim()


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

	# Build a quick lookup: suit*100 + rank -> PlayingCard
	var card_map: Dictionary = {}
	for card: CardData.PlayingCard in dm.draw_pile:
		card_map[card.suit * 100 + card.rank] = card

	# Pre-warm ALL 52 card textures (missing cards also need cached textures
	# for the greyed-out dimmed display).
	var all_possible: Array[CardData.PlayingCard] = []
	for suit: int in _SUIT_ROW_ORDER:
		for rank: int in _RANK_ORDER:
			all_possible.append(CardData.PlayingCard.new(suit, rank))
	NinKingCard.prewarm_face_cache(all_possible, DECK_CARD_SIZE)

	# Fixed 4x13 grid: each suit occupies one full row (13 slots).
	# Missing cards show a greyed-out face so the player can see which
	# specific cards have been drawn from the deck.
	for suit: int in _SUIT_ROW_ORDER:
		for rank: int in _RANK_ORDER:
			var key: int = suit * 100 + rank
			var pc: NinKingCard = NinKingCard.new()
			pc.card_size = DECK_CARD_SIZE
			pc.can_be_interacted_with = false
			pc.name = "DeckCard_%d_%d" % [suit, rank]

			var is_in_deck: bool = card_map.has(key)
			if is_in_deck:
				var card: CardData.PlayingCard = card_map[key] as CardData.PlayingCard
				pc.playing_card_data = card
			else:
				# Create a placeholder card to show which card is missing
				pc.playing_card_data = CardData.PlayingCard.new(suit, rank)

			deck_card_grid.add_child(pc)
			pc.update_display()

			if not is_in_deck:
				# Dim the card to visually distinguish missing slots
				pc.modulate = Color(0.35, 0.35, 0.35, 0.65)


## Note: FrontFace/BackFace structure is now created by NinKingCard._ready().
## No manual setup needed — the card self-assembles on add_child().
