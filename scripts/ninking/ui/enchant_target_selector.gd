class_name EnchantTargetSelector
extends Control

## Hand card target selector for 附魔卡 usage.
## Created on top of the shop panel when player buys a 符術 card.
## Shows all 9 hand cards as clickable SVG thumbnails.
##
## Usage:
##   var selector := EnchantTargetSelector.new()
##   add_child(selector)
##   selector.open(hand_array, func(idx): _apply_effect(idx))

const SVG_BASE_PATH: String = "res://assets/images/cards/4color_deck_by_heratexx"
const CARD_W: float = 130.0
const CARD_H: float = 181.0
const GAP: int = 12

var _callback: Callable


func open(hand: Array[CardData.PlayingCard], callback: Callable) -> void:
	## Display the card selection overlay.
	## `callback` receives (card_index: int) when a card is clicked.
	_callback = callback

	# ── Full-screen dark overlay (blocks shop interaction) ──
	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.size = get_viewport_rect().size
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # block clicks through
	add_child(overlay)

	# ── Instruction label ──
	var label := Label.new()
	label.text = "选择目标牌"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.94, 0.93, 0.89, 1))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1, 1))
	label.add_theme_constant_override("outline_size", 3)
	label.position = Vector2(0, 60)
	label.size = Vector2(get_viewport_rect().size.x, 40)
	add_child(label)

	# ── Card row ──
	var card_row := HBoxContainer.new()
	card_row.name = "CardRow"
	card_row.size = Vector2(
		hand.size() * CARD_W + (hand.size() - 1) * GAP,
		CARD_H
	)
	# Center the row
	card_row.position = Vector2(
		(get_viewport_rect().size.x - card_row.size.x) * 0.5,
		(get_viewport_rect().size.y - CARD_H) * 0.5
	)
	card_row.add_theme_constant_override("separation", GAP)
	add_child(card_row)

	for i: int in hand.size():
		var card_data: CardData.PlayingCard = hand[i]

		# ── Clickable card button ──
		var btn := Button.new()
		btn.name = "Card_%d" % i
		btn.custom_minimum_size = Vector2(CARD_W, CARD_H)
		btn.size = Vector2(CARD_W, CARD_H)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(_on_card_clicked.bind(i))

		# Make button invisible (no stylebox)
		var empty_style := StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", empty_style)
		btn.add_theme_stylebox_override("hover", empty_style)
		btn.add_theme_stylebox_override("pressed", empty_style)
		btn.add_theme_stylebox_override("disabled", empty_style)

		# ── Card face (SVG texture) ──
		var svg_path: String = _get_card_svg_path(card_data)
		var tex_rect := TextureRect.new()
		tex_rect.name = "Face"
		tex_rect.texture = load(svg_path) if not svg_path.is_empty() else null
		tex_rect.size = Vector2(CARD_W, CARD_H)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tex_rect)

		# ── Hover scale effect ──
		btn.mouse_entered.connect(_on_card_hover.bind(btn))
		btn.mouse_exited.connect(_on_card_unhover.bind(btn))

		card_row.add_child(btn)

	# Bring to front so it renders above everything
	move_to_front()


func _get_card_svg_path(card: CardData.PlayingCard) -> String:
	if card == null:
		return ""
	var rank_char: String = CardData.RANK_FILE_CHARS.get(card.rank, "?")
	var suit_char: String = CardData.SUIT_FILE_CHARS.get(card.suit, "?")
	return "%s/%s%s.svg" % [SVG_BASE_PATH, rank_char, suit_char]


func _on_card_clicked(card_index: int) -> void:
	if _callback.is_null():
		return
	# Callback before cleanup so handler can read current card state
	_callback.call(card_index)
	# Clean up self
	queue_free()


func _on_card_hover(btn: Button) -> void:
	if not is_instance_valid(btn) or btn.get_child_count() == 0:
		return
	var face := btn.get_child(0) as TextureRect
	if face:
		face.size = Vector2(CARD_W * 1.08, CARD_H * 1.08)
		face.position = Vector2(
			-(CARD_W * 0.08) * 0.5,
			-(CARD_H * 0.08) * 0.5
		)

func _on_card_unhover(btn: Button) -> void:
	if not is_instance_valid(btn) or btn.get_child_count() == 0:
		return
	var face := btn.get_child(0) as TextureRect
	if face:
		face.size = Vector2(CARD_W, CARD_H)
		face.position = Vector2.ZERO
