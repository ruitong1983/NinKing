class_name DunHighlighter
extends RefCounted

## Constraint visualization for 影/瞬/滅 labels (V21).
## Manages highlight colors, state tracking, and card flash effects.
## v2: Single HandCardContainer replaces 3 Hand nodes.

# ── Highlight colors ──
const HIGHLIGHT_FONT_COLOR := Color(1.0, 0.9, 0.5, 1.0)
const HIGHLIGHT_OUTLINE_COLOR := Color(1.0, 0.85, 0.3, 0.8)
const DEFAULT_FONT_COLOR := Color(0.831, 0.659, 0.263, 1.0)
const DEFAULT_HEAD_OUTLINE := Color(0.0, 0.0, 0.0, 0.3)
const DEFAULT_MID_OUTLINE := Color(0.0, 0.0, 0.0, 0.6)
const DEFAULT_TAIL_OUTLINE := Color(0.0, 0.0, 0.0, 1.0)


# ── Node refs ──
var _head_label: Label
var _middle_label: Label
var _tail_label: Label
var _status_label: Label
var _card_grid: HandCardContainer

# ── State tracking ──
var _head_was_highlighted: bool = false
var _middle_was_highlighted: bool = false
var _tail_was_highlighted: bool = false


func setup(
	head_label: Label,
	middle_label: Label,
	tail_label: Label,
	status_label: Label,
	card_grid: HandCardContainer,
) -> void:
	_head_label = head_label
	_middle_label = middle_label
	_tail_label = tail_label
	_status_label = status_label
	_card_grid = card_grid


# ══════════════════════════════════════════
# Constraint highlight (V21)
# ══════════════════════════════════════════

func update(arrangement: Arrangement) -> void:

	if arrangement == null:
		reset()
		return

	var pair1_ok: bool = arrangement.head_eval.strength <= arrangement.mid_eval.strength
	var pair2_ok: bool = arrangement.mid_eval.strength <= arrangement.tail_eval.strength

	_apply_label_highlight(_head_label, pair1_ok, DEFAULT_HEAD_OUTLINE)
	_apply_label_highlight(_middle_label, pair1_ok or pair2_ok, DEFAULT_MID_OUTLINE)
	_apply_label_highlight(_tail_label, pair2_ok, DEFAULT_TAIL_OUTLINE)

	if pair1_ok and not _head_was_highlighted:
		GlobalTweens.color_flash(_head_label, Color.WHITE, 0.1)
	if (pair1_ok or pair2_ok) and not _middle_was_highlighted:
		GlobalTweens.color_flash(_middle_label, Color.WHITE, 0.1)
	if pair2_ok and not _tail_was_highlighted:
		GlobalTweens.color_flash(_tail_label, Color.WHITE, 0.1)

	_head_was_highlighted = pair1_ok
	_middle_was_highlighted = pair1_ok or pair2_ok
	_tail_was_highlighted = pair2_ok

	if pair1_ok and pair2_ok:
		_status_label.remove_theme_color_override("font_color")
		_status_label.text = ""
	else:
		const ERROR_FONT_COLOR := Color(0.95, 0.3, 0.3, 1.0)
		_status_label.add_theme_color_override("font_color", ERROR_FONT_COLOR)
		if not pair1_ok and pair2_ok:
			_status_label.text = "影勢過強 — 影 > 瞬！调整手牌顺序"
		elif pair1_ok and not pair2_ok:
			_status_label.text = "滅力不足 — 瞬 > 滅！调整手牌顺序"
		else:
			_status_label.text = "重排三道 — 调整手牌顺序"


func reset() -> void:
	_apply_label_highlight(_head_label, false, DEFAULT_HEAD_OUTLINE)
	_apply_label_highlight(_middle_label, false, DEFAULT_MID_OUTLINE)
	_apply_label_highlight(_tail_label, false, DEFAULT_TAIL_OUTLINE)
	_head_was_highlighted = false
	_middle_was_highlighted = false
	_tail_was_highlighted = false
	_status_label.text = ""


# ══════════════════════════════════════════
# Card flash — A7 group reveal
# ══════════════════════════════════════════

func flash_all_hands() -> void:
	for card: Card in _card_grid._held_cards:
		if card is CanvasItem:
			GlobalTweens.color_flash(card, Color(1.0, 0.843, 0.0, 1.0), 0.1)


func flash_row(row: int) -> void:
	for card: Card in _card_grid.get_row_cards(row):
		if card is CanvasItem:
			GlobalTweens.color_flash(card, Color(1.0, 0.843, 0.0, 1.0), 0.1)


# ══════════════════════════════════════════
# Internal helpers
# ══════════════════════════════════════════

func _apply_label_highlight(label: Label, highlight: bool, default_outline: Color) -> void:
	if highlight:
		label.add_theme_color_override("font_color", HIGHLIGHT_FONT_COLOR)
		label.add_theme_color_override("font_outline_color", HIGHLIGHT_OUTLINE_COLOR)
	else:
		label.add_theme_color_override("font_color", DEFAULT_FONT_COLOR)
		label.add_theme_color_override("font_outline_color", default_outline)
