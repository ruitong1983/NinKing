extends Control
## Debug 底栏卡牌托盘 — 52 张完整牌库 ♠♣♥♦ 四排显示。
## 点击牌 → 高亮 → 再点击上方 9 格空格 → 放入该牌。
## 牌序与 create_standard_deck() 不同（这里是 ♠♥♦♣ A→K），
## 因此用 _tray_cards 按按钮顺序映射，不依赖外部 _deck。
##
## 修改记录:
##   2026-06-12  Fix: 替换 _deck.find() 引用比较 bug（deck 膨胀 52→104）
##               删除未使用的 get_selected_card()

signal card_selected(card_data: CardData.PlayingCard)

const CARD_W: float = 52.0
const CARD_H: float = 38.0
const GAP: float = 2.0

## 按钮顺序的卡牌索引（与 _card_btns 一一对应）
var _tray_cards: Array[CardData.PlayingCard] = []
var _highlighted_idx: int = -1
var _card_btns: Array[Button] = []

@onready var _grid: GridContainer = %CardGrid


func setup(_deck: Array[CardData.PlayingCard]) -> void:
	## 用 source_deck 的内容按按钮顺序重建 _tray_cards
	_rebuild(_deck)


func _rebuild(source_deck: Array[CardData.PlayingCard]) -> void:
	## 清空之前的所有按钮
	for child: Node in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_tray_cards.clear()
	_card_btns.clear()

	_grid.columns = 13

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

	for suit: CardData.Suit in SUIT_ORDER:
		for rank: int in RANK_ORDER:
			# 从源牌堆按牌面值匹配（避免引用比较 bug）
			var card_data: CardData.PlayingCard = _find_in_deck(source_deck, suit, rank)
			_tray_cards.append(card_data)

			var suit_char: String = CardData.SUIT_NAMES[suit]
			var rank_char: String = CardData.RANK_NAMES[rank]
			var btn := Button.new()
			btn.text = "%s%s" % [rank_char, suit_char]
			btn.custom_minimum_size = Vector2(CARD_W, CARD_H)
			btn.size = Vector2(CARD_W, CARD_H)
			btn.add_theme_font_size_override("font_size", 12)

			match suit:
				CardData.Suit.HEARTS, CardData.Suit.DIAMONDS:
					btn.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
				_:
					btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))

			btn.tooltip_text = "%s%s" % [suit_char, rank_char]
			var idx: int = _tray_cards.size() - 1
			btn.pressed.connect(_on_card_pressed.bind(idx))
			_grid.add_child(btn)
			_card_btns.append(btn)


static func _find_in_deck(deck: Array[CardData.PlayingCard], suit: CardData.Suit, rank: int) -> CardData.PlayingCard:
	for c: CardData.PlayingCard in deck:
		if c.suit == suit and c.rank == rank:
			return c
	# 兜底：理论上不会走到这里，因为 create_standard_deck() 包含全部 52 张
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
