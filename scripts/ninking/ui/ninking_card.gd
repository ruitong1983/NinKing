class_name NinKingCard
extends Card

## NinKing-specific Card extending card-framework's Card.
## Renders a realistic playing card face: white background, rounded corners,
## corner rank+suit labels (top-left upright, bottom-right 180° rotated),
## and a large centered suit symbol.

signal ninking_card_clicked(index: int)
signal ninking_card_dragged(index: int, drop_position: Vector2)

enum VisualState { NORMAL, SWAP_SOURCE, REDRAW_TARGET }

const CLICK_THRESHOLD: float = 10.0

# Card back texture (shared across all cards, loaded once at init)
static var _card_back_tex: Texture2D

func _get_card_back_tex() -> Texture2D:
	if _card_back_tex == null:
		_card_back_tex = load("res://assets/images/cards/card_back.png")
	return _card_back_tex

# ── Card face constants ──
const CORNER_RADIUS: int = 8
const BORDER_WIDTH: int = 1
const CARD_BG: Color = Color(0.98, 0.972, 0.949, 1.0)    # #FAF8F2 cream white
const BORDER_CLR: Color = Color(0.2, 0.2, 0.2, 1.0)        # #333333 dark border
const RED_CLR: Color = Color(0.8, 0.1, 0.1, 1.0)           # Red for ♥♦
const BLACK_CLR: Color = Color(0.1, 0.1, 0.1, 1.0)         # Black for ♠♣
const CORNER_FONT_SZ: int = 24
const CENTER_FONT_SZ: int = 56
const CORNER_LABEL_W: int = 36
const CORNER_LABEL_H: int = 48

# ── Figma symmetric margins: left=right=8px, top=bottom=6px
const MARGIN_XY: int = 8
const MARGIN_TOP: int = 6
const MARGIN_BOTTOM: int = 6

# ── Instance vars ──
var playing_card_data: CardData.PlayingCard
var card_index: int = -1
var _press_global_position: Vector2 = Vector2.ZERO
var _visual_state: int = VisualState.NORMAL

# Card face child labels
var _corner_top_label: Label
var _corner_bottom_label: Label
var _center_suit_label: Label


func _ready() -> void:
	_create_face_structure()
	super._ready()
	_generate_card_texture()
	_create_labels()
	_update_display_label()


## Create FrontFace/BackFace/TextureRect nodes that Card base class expects.
func _create_face_structure() -> void:
	var front_face: Control = Control.new()
	front_face.name = "FrontFace"
	front_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(front_face)

	var front_tex: TextureRect = TextureRect.new()
	front_tex.name = "TextureRect"
	front_face.add_child(front_tex)

	var back_face: Control = Control.new()
	back_face.name = "BackFace"
	back_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back_face)

	var back_tex: TextureRect = TextureRect.new()
	back_tex.name = "TextureRect"
	back_face.add_child(back_tex)


# ═══ Texture generation ═══

## Generate procedural playing card face texture with rounded corners and border.
func _generate_card_texture() -> void:
	var w: int = int(card_size.x)
	var h: int = int(card_size.y)
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)

	# Fill with card background
	img.fill(CARD_BG)

	# Pre-compute inside/outside mask for fast border detection
	var mask: PackedByteArray = _build_card_mask(w, h)

	# Apply mask: transparent outside, border at edges
	for y: int in range(h):
		for x: int in range(w):
			var idx: int = y * w + x
			if mask[idx] == 0:
				img.set_pixel(x, y, Color.TRANSPARENT)
			elif _is_mask_border(x, y, w, h, mask):
				img.set_pixel(x, y, BORDER_CLR)
			# else: stays CARD_BG (already filled)

	# Subtle drop shadow along bottom edge
	for y: int in range(h - 6, h):
		for x: int in range(w):
			if img.get_pixel(x, y).a > 0:
				var t: float = float(y - (h - 6)) / 6.0
				var shadow: Color = img.get_pixel(x, y).lerp(Color(0.0, 0.0, 0.0, 0.15), t)
				img.set_pixel(x, y, shadow)

	var tex: ImageTexture = ImageTexture.create_from_image(img)
	set_faces(tex, _get_card_back_tex())


## Build a packed byte mask: 255 = inside card shape, 0 = outside (corners).
func _build_card_mask(w: int, h: int) -> PackedByteArray:
	var mask: PackedByteArray = PackedByteArray()
	mask.resize(w * h)
	mask.fill(255)

	for y: int in range(h):
		for x: int in range(w):
			if not _is_inside_card(x, y, w, h):
				mask[y * w + x] = 0

	return mask


## Check if pixel at (x,y) is inside the rounded rectangle card shape.
func _is_inside_card(x: int, y: int, w: int, h: int) -> bool:
	var r: int = CORNER_RADIUS
	if x < r and y < r:
		return _sq_dist(x, y, r - 1, r - 1) <= r * r
	if x >= w - r and y < r:
		return _sq_dist(x, y, w - r, r - 1) <= r * r
	if x < r and y >= h - r:
		return _sq_dist(x, y, r - 1, h - r) <= r * r
	if x >= w - r and y >= h - r:
		return _sq_dist(x, y, w - r, h - r) <= r * r
	return true


## Squared distance from (x,y) to (cx,cy).
func _sq_dist(x: int, y: int, cx: int, cy: int) -> int:
	var dx: int = x - cx
	var dy: int = y - cy
	return dx * dx + dy * dy


## Check if a filled pixel has a transparent neighbor (→ border pixel).
func _is_mask_border(x: int, y: int, w: int, h: int, mask: PackedByteArray) -> bool:
	for dx: int in range(-BORDER_WIDTH, BORDER_WIDTH + 1):
		for dy: int in range(-BORDER_WIDTH, BORDER_WIDTH + 1):
			var nx: int = x + dx
			var ny: int = y + dy
			if nx < 0 or nx >= w or ny < 0 or ny >= h:
				return true
			if mask[ny * w + nx] == 0:
				return true
	return false


# ═══ Label creation ═══

## Create label nodes for card face text.
func _create_labels() -> void:
	# Top-left corner (rank + suit, stacked vertically)
	_corner_top_label = Label.new()
	_corner_top_label.name = "CornerTop"
	_corner_top_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_corner_top_label.add_theme_font_size_override("font_size", CORNER_FONT_SZ)
	_corner_top_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_corner_top_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_corner_top_label.size = Vector2(CORNER_LABEL_W, CORNER_LABEL_H)
	add_child(_corner_top_label)

	# Center suit symbol (large)
	_center_suit_label = Label.new()
	_center_suit_label.name = "CenterSuit"
	_center_suit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center_suit_label.add_theme_font_size_override("font_size", CENTER_FONT_SZ)
	_center_suit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_suit_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_center_suit_label)

	# Bottom-right corner — 180° rotated copy of top-left
	_corner_bottom_label = Label.new()
	_corner_bottom_label.name = "CornerBottom"
	_corner_bottom_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_corner_bottom_label.add_theme_font_size_override("font_size", CORNER_FONT_SZ)
	_corner_bottom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_corner_bottom_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_corner_bottom_label.size = Vector2(CORNER_LABEL_W, CORNER_LABEL_H)
	# Rotate 180° around label center for true mirror effect
	_corner_bottom_label.pivot_offset = Vector2(CORNER_LABEL_W / 2.0, CORNER_LABEL_H / 2.0)
	_corner_bottom_label.rotation = PI
	add_child(_corner_bottom_label)


# ═══ Display update ═══

## Update all labels from playing_card_data. Safe to call before _ready().
func _update_display_label() -> void:
	# Guard: labels may not exist yet if called before _ready()
	if _corner_top_label == null:
		return
	if playing_card_data == null:
		_corner_top_label.text = "?"
		_center_suit_label.text = "?"
		_corner_bottom_label.text = "?"
		return

	var rank_str: String = CardData.RANK_NAMES[playing_card_data.rank]
	var suit_str: String = CardData.SUIT_NAMES[playing_card_data.suit]
	var suit_color: Color = _get_suit_color()
	var corner_text: String = "%s\n%s" % [rank_str, suit_str]  # rank on top, suit below

	# Top-left corner — Figma: (8, 6)
	_corner_top_label.text = corner_text
	_corner_top_label.add_theme_color_override("font_color", suit_color)
	_corner_top_label.position = Vector2(MARGIN_XY, MARGIN_TOP)

	# Center suit — fills entire card for true centering
	_center_suit_label.text = suit_str
	_center_suit_label.add_theme_color_override("font_color", suit_color)
	_center_suit_label.size = card_size
	_center_suit_label.position = Vector2.ZERO

	# Bottom-right corner — same content as top-left, rotated 180° by _create_labels()
	# Position: symmetric to top-left (right=8px, bottom=6px)
	_corner_bottom_label.text = corner_text
	_corner_bottom_label.add_theme_color_override("font_color", suit_color)
	_corner_bottom_label.position = Vector2(
		card_size.x - MARGIN_XY - CORNER_LABEL_W,
		card_size.y - MARGIN_BOTTOM - CORNER_LABEL_H
	)


func _get_suit_color() -> Color:
	if playing_card_data == null:
		return BLACK_CLR
	match playing_card_data.suit:
		CardData.Suit.HEARTS, CardData.Suit.DIAMONDS:
			return RED_CLR
		_:
			return BLACK_CLR


# ═══ Visual state ═══

## Set visual state for swap/redraw highlighting via modulate.
func set_visual_state(state: int) -> void:
	_visual_state = state
	match state:
		VisualState.NORMAL:
			modulate = Color.WHITE
		VisualState.SWAP_SOURCE:
			modulate = Color(0.4, 0.6, 1.0, 1.0)
		VisualState.REDRAW_TARGET:
			modulate = Color(1.0, 0.3, 0.3, 1.0)


## Update display from playing_card_data. Safe to call before _ready().
func update_display() -> void:
	_update_display_label()


# ═══ Click detection (overrides Card) ═══

## Override: detect click vs drag on mouse release.
## Click: emit ninking_card_clicked for swap/redraw interaction.
## Drag: emit ninking_card_dragged for cross-group drag-drop swap.
func _handle_mouse_released() -> void:
	var drag_distance: float = global_position.distance_to(_press_global_position)
	var was_click: bool = drag_distance < CLICK_THRESHOLD
	super._handle_mouse_released()
	if was_click:
		ninking_card_clicked.emit(card_index)
	else:
		ninking_card_dragged.emit(card_index, get_global_mouse_position())


## Override: track press position for click detection.
func _handle_mouse_pressed() -> void:
	_press_global_position = global_position
	super._handle_mouse_pressed()
