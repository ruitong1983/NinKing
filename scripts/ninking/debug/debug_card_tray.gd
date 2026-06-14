extends GridContainer
## Debug 牌库网格 — 4列 × 13行，每列一个花色 (♠|♥|♦|♣)，A→K 从上到下。
## 点击牌 → 高亮 → 再点击上方 9 格空格 → 放入该牌。

signal card_selected(card_data: CardData.PlayingCard)

const CARD_H: float = 34.0

var _tray_cards: Array[CardData.PlayingCard] = []
var _highlighted_idx: int = -1
var _card_btns: Array[Button] = []


func setup(_deck: Array[CardData.PlayingCard]) -> void:
	_rebuild(_deck)


func _rebuild(source_deck: Array[CardData.PlayingCard]) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_tray_cards.clear()
	_card_btns.clear()

	columns = 4

	var SUIT_ORDER: Array[CardData.Suit] = [
		CardData.Suit.SPADES, CardData.Suit.HEARTS,
		CardData.Suit.DIAMONDS, CardData.Suit.CLUBS,
	]
	var RANK_ORDER: Array[int] = [
		CardData.Rank.ACE, CardData.Rank.TWO, CardData.Rank.THREE,
		CardData.Rank.FOUR, CardData.Rank.FIVE, CardData.Rank.SIX,
		CardData.Rank.SEVEN, CardData.Rank.EIGHT, CardData.Rank.NINE,
		CardData.Rank.TEN, CardData.Rank.JACK, CardData.Rank.QUEEN,
		CardData.Rank.KING,
	]

	# rank 外层, suit 内层 → GridContainer 左→右填充 → 每列一个花色
	for rank: int in RANK_ORDER:
		for suit: CardData.Suit in SUIT_ORDER:
			var card_data: CardData.PlayingCard = _find_in_deck(source_deck, suit, rank)
			_tray_cards.append(card_data)

			var suit_char: String = CardData.SUIT_NAMES[suit]
			var rank_char: String = CardData.RANK_NAMES[rank]
			var btn := Button.new()
			btn.text = "%s%s" % [rank_char, suit_char]
			btn.custom_minimum_size = Vector2(0, CARD_H)
			btn.add_theme_font_size_override("font_size", 14)
			var bg := StyleBoxFlat.new()
			bg.bg_color = Color.WHITE
			btn.add_theme_stylebox_override("normal", bg)
			btn.add_theme_stylebox_override("hover", bg)
			btn.add_theme_stylebox_override("pressed", bg)
			btn.add_theme_stylebox_override("focus", bg)

			match suit:
				CardData.Suit.HEARTS, CardData.Suit.DIAMONDS:
					btn.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
				_:
					btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))

			btn.tooltip_text = "%s%s" % [suit_char, rank_char]
			var idx: int = _tray_cards.size() - 1
			btn.pressed.connect(_on_card_pressed.bind(idx))
			add_child(btn)
			_card_btns.append(btn)


static func _find_in_deck(deck: Array[CardData.PlayingCard], suit: CardData.Suit, rank: int) -> CardData.PlayingCard:
	for c: CardData.PlayingCard in deck:
		if c.suit == suit and c.rank == rank:
			return c
	push_warning("DebugCardTray: card %s %s not found in source deck" % [suit, rank])
	return CardData.PlayingCard.new(suit, rank)


func _on_card_pressed(idx: int) -> void:
	_clear_highlight()
	_highlighted_idx = idx
	if idx >= 0 and idx < _card_btns.size():
		_card_btns[idx].modulate = Color(1.0, 1.0, 0.6, 1.0)
	card_selected.emit(_tray_cards[idx])


func clear_highlight() -> void:
	_clear_highlight()


func _clear_highlight() -> void:
	if _highlighted_idx >= 0 and _highlighted_idx < _card_btns.size():
		_card_btns[_highlighted_idx].modulate = Color.WHITE
	_highlighted_idx = -1
