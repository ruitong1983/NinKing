class_name NinKingCard
extends Card

## NinKing-specific Card extending card-framework's Card.
## Card face is a full SVG texture (rank + suit + background + border all in
## one image). No procedural drawing, no text labels — the SVG IS the card.
##
## FrontFace / BackFace / TextureRect nodes are defined in ninking_card.tscn.
## For cards created via NinKingCard.new() (hand_display, deck_viewer), the
## nodes are created programmatically in _ensure_face_nodes() as a fallback.

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

# ── SVG asset path ──
const SVG_BASE_PATH: String = "res://assets/images/cards/4color_deck_by_heratexx"

# ── Instance vars ──
var playing_card_data: CardData.PlayingCard
var card_index: int = -1
var _press_global_position: Vector2 = Vector2.ZERO
var _visual_state: int = VisualState.NORMAL


func _ready() -> void:
	_ensure_face_nodes()
	super._ready()
	_load_card_texture()


## Create FrontFace/TextureRect and BackFace/TextureRect nodes if they
## don't exist. Cards instantiated via tscn already have them; cards
## created with NinKingCard.new() (hand_display, deck_viewer) do not.
## Must run BEFORE super._ready() so Card.check_and_set_textures()
## can find them via $FrontFace/TextureRect and $BackFace/TextureRect.
func _ensure_face_nodes() -> void:
	if not has_node("FrontFace"):
		var ff := Control.new()
		ff.name = "FrontFace"
		ff.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(ff)

		var tex_rect := TextureRect.new()
		tex_rect.name = "TextureRect"
		tex_rect.size = _card_size
		ff.add_child(tex_rect)

	if not has_node("BackFace"):
		var bf := Control.new()
		bf.name = "BackFace"
		bf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bf)

		var tex_rect := TextureRect.new()
		tex_rect.name = "TextureRect"
		tex_rect.size = _card_size
		bf.add_child(tex_rect)


# ═══ SVG texture loading ═══

## Build the SVG file path for this card's suit + rank.
func _get_card_svg_path() -> String:
	if playing_card_data == null:
		return ""
	var rank_char: String = CardData.RANK_FILE_CHARS.get(playing_card_data.rank, "?")
	var suit_char: String = CardData.SUIT_FILE_CHARS.get(playing_card_data.suit, "?")
	return "%s/%s%s.svg" % [SVG_BASE_PATH, rank_char, suit_char]


## Load the SVG and apply to the card face.
## SVG imports at its native viewBox size (240×334). Card base sets
## EXPAND_IGNORE_SIZE which would blow up the TextureRect → override
## with KEEP_SIZE + stretch-to-fit so the texture scales into card_size.
func _load_card_texture() -> void:
	var path: String = _get_card_svg_path()
	if path.is_empty():
		return

	var svg_tex: Texture2D = load(path)
	if svg_tex == null:
		return

	set_faces(svg_tex, _get_card_back_tex())

	# Constrain TextureRect to card_size — Card base sets EXPAND_IGNORE_SIZE
	# which ignores size and expands to the texture's native resolution.
	if front_face_texture:
		front_face_texture.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		front_face_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		front_face_texture.size = card_size
	if back_face_texture:
		back_face_texture.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		back_face_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		back_face_texture.size = card_size


# ═══ Display update ═══

## Reload SVG texture when card data changes (e.g., after redraw).
func update_display() -> void:
	_load_card_texture()


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
