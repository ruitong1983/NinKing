class_name NinKingCard
extends Card

## NinKing-specific Card extending card-framework's Card.
## Card face is a full SVG texture (rank + suit + background + border all in
## one image). No procedural drawing, no text labels — the SVG IS the card.
##
## FrontFace / BackFace / TextureRect nodes are defined in ninking_card.tscn.
## For cards created via NinKingCard.new() (hand_display, deck_viewer), the
## nodes are created programmatically in _ensure_face_nodes() as a fallback.
##
## Fake3D: Applies fake3d perspective shader to TextureRects for 3D tilt effect.
## Visual states (SWAP_SOURCE / REDRAW_TARGET) switch to fake3d_flash + modulate.

signal ninking_card_clicked(index: int)

enum VisualState { NORMAL, SWAP_SOURCE, REDRAW_TARGET }

const CLICK_THRESHOLD: float = 10.0

# Fake3D materials (loaded at runtime to avoid compile-time .tres dependency)
var _fake3d_mat: ShaderMaterial = null
var _flash_mat: ShaderMaterial = null

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
	_load_fake3d_materials()
	_apply_fake3d_material()


## Load fake3d materials at runtime (avoid compile-time dependency on .tres).
func _load_fake3d_materials() -> void:
	if _fake3d_mat == null:
		_fake3d_mat = load("res://resources/materials/fake3d.tres")
	if _flash_mat == null:
		_flash_mat = load("res://resources/materials/fake3d_flash.tres")


## Apply fake3d perspective material to front/back TextureRects.
func _apply_fake3d_material() -> void:
	if not _fake3d_mat:
		return
	if front_face_texture and front_face_texture.material == null:
		front_face_texture.material = _fake3d_mat.duplicate()
	if back_face_texture and back_face_texture.material == null:
		var back_mat: ShaderMaterial = _fake3d_mat.duplicate()
		back_mat.set_shader_parameter("y_rot", 0.0)
		back_face_texture.material = back_mat


## Create FrontFace/TextureRect and BackFace/TextureRect nodes if they
## don't exist. Cards instantiated via tscn already have them; cards
## created with NinKingCard.new() (hand_display, deck_viewer) do not.
func _ensure_face_nodes() -> void:
	if not has_node("FrontFace"):
		var ff := Control.new()
		ff.name = "FrontFace"
		ff.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(ff)
		var tex_rect := TextureRect.new()
		tex_rect.name = "TextureRect"
		tex_rect.size = _card_size
		tex_rect.mouse_filter = Control.MOUSE_FILTER_PASS
		ff.add_child(tex_rect)

	if not has_node("BackFace"):
		var bf := Control.new()
		bf.name = "BackFace"
		bf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bf)
		var tex_rect := TextureRect.new()
		tex_rect.name = "TextureRect"
		tex_rect.size = _card_size
		tex_rect.mouse_filter = Control.MOUSE_FILTER_PASS
		bf.add_child(tex_rect)


# ═══ SVG texture loading ═══

func _get_card_svg_path() -> String:
	if playing_card_data == null:
		return ""
	var rank_char: String = CardData.RANK_FILE_CHARS.get(playing_card_data.rank, "?")
	var suit_char: String = CardData.SUIT_FILE_CHARS.get(playing_card_data.suit, "?")
	return "%s/%s%s.svg" % [SVG_BASE_PATH, rank_char, suit_char]


func _load_card_texture() -> void:
	var path: String = _get_card_svg_path()
	if path.is_empty():
		return
	var svg_tex: Texture2D = load(path)
	if svg_tex == null:
		return

	var front_tex: Texture2D = svg_tex
	var img: Image = svg_tex.get_image()
	if img and (img.get_width() != int(card_size.x) or img.get_height() != int(card_size.y)):
		img.resize(int(card_size.x), int(card_size.y), Image.INTERPOLATE_LANCZOS)
		front_tex = ImageTexture.create_from_image(img)

	var back_tex: Texture2D = _get_card_back_tex()
	var back_img: Image = back_tex.get_image()
	if back_img and (back_img.get_width() != int(card_size.x) or back_img.get_height() != int(card_size.y)):
		back_img.resize(int(card_size.x), int(card_size.y), Image.INTERPOLATE_LANCZOS)
		back_tex = ImageTexture.create_from_image(back_img)

	set_faces(front_tex, back_tex)

	if front_face_texture:
		front_face_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		front_face_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		front_face_texture.size = card_size
	if back_face_texture:
		back_face_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		back_face_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		back_face_texture.size = card_size


# ═══ Display update ═══

func update_display() -> void:
	_load_card_texture()


# ═══ Visual state ═══

func set_visual_state(state: int) -> void:
	_visual_state = state
	match state:
		VisualState.NORMAL:
			modulate = Color.WHITE
			if _fake3d_mat and front_face_texture:
				front_face_texture.material = _fake3d_mat.duplicate()
			if _fake3d_mat and back_face_texture:
				var back_mat: ShaderMaterial = _fake3d_mat.duplicate()
				back_mat.set_shader_parameter("y_rot", 0.0)
				back_face_texture.material = back_mat

		VisualState.SWAP_SOURCE:
			modulate = Color(0.6, 0.8, 1.0, 1.0)
			_apply_flash_material(Color(0.2, 0.5, 1.0, 1.0))

		VisualState.REDRAW_TARGET:
			modulate = Color(1.0, 0.6, 0.6, 1.0)
			_apply_flash_material(Color(1.0, 0.2, 0.2, 1.0))


func _apply_flash_material(flash_color: Color) -> void:
	if not _flash_mat:
		return
	if front_face_texture:
		var mat: ShaderMaterial = _flash_mat.duplicate()
		mat.set_shader_parameter("use_flash", true)
		mat.set_shader_parameter("flash_type", 0)
		mat.set_shader_parameter("pure_flash_color", flash_color)
		mat.set_shader_parameter("intensity", 0.6)
		mat.set_shader_parameter("speed", 0.15)
		front_face_texture.material = mat
	if back_face_texture:
		var back_mat: ShaderMaterial = _flash_mat.duplicate()
		back_mat.set_shader_parameter("use_flash", true)
		back_mat.set_shader_parameter("flash_type", 0)
		back_mat.set_shader_parameter("pure_flash_color", flash_color)
		back_mat.set_shader_parameter("intensity", 0.6)
		back_mat.set_shader_parameter("speed", 0.15)
		back_mat.set_shader_parameter("y_rot", 0.0)
		back_face_texture.material = back_mat


# ═══ Click/drag detection ═══

## Override: detect click vs drag on mouse release.
## Click: emit ninking_card_clicked for swap/redraw interaction.
## Drag: let Card Framework process drop positioning via
## super._handle_mouse_released(), then our HandCardContainer.move_cards()
## override intercepts the same-container drop to perform a swap + game state
## sync via SealController.swap_cards().
func _handle_mouse_released() -> void:
	var drag_distance: float = global_position.distance_to(_press_global_position)
	var was_click: bool = drag_distance < CLICK_THRESHOLD

	# Always call super — Card Framework handles drop detection + positioning;
	# HandCardContainer.move_cards() override handles swap + game state sync.
	super._handle_mouse_released()

	if was_click:
		ninking_card_clicked.emit(card_index)


## Override: track press position for click detection.
func _handle_mouse_pressed() -> void:
	_press_global_position = global_position
	super._handle_mouse_pressed()
