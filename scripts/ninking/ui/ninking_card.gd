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
## REDRAW_TARGET switches to fake3d_flash + modulate.

enum VisualState { NORMAL, REDRAW_TARGET }

# Fake3D materials (loaded at runtime to avoid compile-time .tres dependency)
var _fake3d_mat: ShaderMaterial = null
var _flash_mat: ShaderMaterial = null

# Static back-face material — y_rot=0, shared across ALL cards.
# Each card's front face still gets a unique instance for per-card tilt.
static var _back_fake3d_mat: ShaderMaterial = null

# Per-instance material cache by VisualState (front + back).
# set_visual_state() checks this before creating duplicates.
var _material_cache: Dictionary = {}

# Card back texture (shared across all cards, loaded once at init)
static var _card_back_tex: Texture2D

# SVG texture cache — avoid re-processing the same face repeatedly.
# Key format: "svg_path_WIDTHxHEIGHT" so 63x88 deck thumbnails and
# 125x175 hand cards use separate entries, preventing wrong-sized
# texture reuse across display contexts.
static var _face_cache: Dictionary = {}

static func _face_cache_key(path: String, size: Vector2) -> String:
	return "%s_%dx%d" % [path, int(size.x), int(size.y)]

## Pre-load deck SVG textures into the shared face cache using threaded
## loading. SVG rasterization happens in background threads; the cache is
## populated with textures already resized to `target_size`. Subsequent
## _load_card_texture() calls on individual cards hit the cache instantly.
##
## Call this before instantiating cards for the deck viewer grid so the
## 52-card loop doesn't block on sequential SVG parsing + resize.
static func prewarm_face_cache(card_datas: Array[CardData.PlayingCard], target_size: Vector2) -> void:
	var paths: Array[String] = []
	for cd: CardData.PlayingCard in card_datas:
		var rank_char: String = CardData.RANK_FILE_CHARS.get(cd.rank, "?")
		var suit_char: String = CardData.SUIT_FILE_CHARS.get(cd.suit, "?")
		var path: String = "%s/%s%s.svg" % [SVG_BASE_PATH, rank_char, suit_char]
		var key: String = _face_cache_key(path, target_size)
		if not _face_cache.has(key):
			paths.append(path)
			ResourceLoader.load_threaded_request(path, "Texture2D")

	for path: String in paths:
		var tex: Texture2D = ResourceLoader.load_threaded_get(path) as Texture2D
		if tex == null:
			continue
		var img: Image = tex.get_image()
		var key: String = _face_cache_key(path, target_size)
		if img and (img.get_width() != int(target_size.x) or img.get_height() != int(target_size.y)):
			img.resize(int(target_size.x), int(target_size.y), Image.INTERPOLATE_BILINEAR)
			_face_cache[key] = ImageTexture.create_from_image(img)
		else:
			_face_cache[key] = tex

func _get_card_back_tex() -> Texture2D:
	if _card_back_tex == null:
		_card_back_tex = load("res://assets/images/cards/card_back.png")
	return _card_back_tex

# ── SVG asset path ──
const SVG_BASE_PATH: String = "res://assets/images/cards/4color_deck_by_heratexx"

# ── Instance vars ──
var playing_card_data: CardData.PlayingCard
var card_index: int = -1

var _visual_state: int = VisualState.NORMAL
var _texture_loaded: bool = false


func _ready() -> void:
	_ensure_face_nodes()
	super._ready()
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
	# Deck viewer cards (non-interactive) don't need 3D tilt;
	# skipping fake3d prevents vertex inflation and allows modulate to work.
	if not can_be_interacted_with:
		return
	if front_face_texture and front_face_texture.material == null:
		front_face_texture.material = _fake3d_mat.duplicate()
	if back_face_texture and back_face_texture.material == null:
		back_face_texture.material = _get_back_fake3d_mat()


## Returns the shared static back-face material (y_rot=0, created once).
static func _get_back_fake3d_mat() -> ShaderMaterial:
	if _back_fake3d_mat == null:
		var base := load("res://resources/materials/fake3d.tres") as ShaderMaterial
		if base:
			_back_fake3d_mat = base.duplicate()
			_back_fake3d_mat.set_shader_parameter("y_rot", 0.0)
	return _back_fake3d_mat


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
		front_face_texture = tex_rect

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
		back_face_texture = tex_rect


# ═══ SVG texture loading ═══

func _get_card_svg_path() -> String:
	if playing_card_data == null:
		return ""
	var rank_char: String = CardData.RANK_FILE_CHARS.get(playing_card_data.rank, "?")
	var suit_char: String = CardData.SUIT_FILE_CHARS.get(playing_card_data.suit, "?")
	return "%s/%s%s.svg" % [SVG_BASE_PATH, rank_char, suit_char]


func _load_card_texture() -> void:
	if _texture_loaded:
		return
	var path: String = _get_card_svg_path()
	if path.is_empty():
		return

	var cache_key: String = _face_cache_key(path, card_size)
	var front_tex: Texture2D
	if _face_cache.has(cache_key):
		front_tex = _face_cache[cache_key]
	else:
		var svg_tex: Texture2D = load(path)
		if svg_tex == null:
			return
		front_tex = svg_tex
		var img: Image = svg_tex.get_image()
		if img and (img.get_width() != int(card_size.x) or img.get_height() != int(card_size.y)):
			img.resize(int(card_size.x), int(card_size.y), Image.INTERPOLATE_LANCZOS)
			front_tex = ImageTexture.create_from_image(img)
		_face_cache[cache_key] = front_tex

	# Deck viewer (non-interactive) cards never flip — skip back texture
	# processing entirely to avoid 52x decompress+resize of a 1728x2304 PNG.
	var back_tex: Texture2D
	if can_be_interacted_with:
		back_tex = _get_card_back_tex()
		var back_img: Image = back_tex.get_image()
		if back_img and (back_img.get_width() != int(card_size.x) or back_img.get_height() != int(card_size.y)):
			back_img.resize(int(card_size.x), int(card_size.y), Image.INTERPOLATE_LANCZOS)
			back_tex = ImageTexture.create_from_image(back_img)
	else:
		back_tex = front_tex  # unused, just satisfy set_faces()

	set_faces(front_tex, back_tex)
	_texture_loaded = true

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
			_material_cache.erase(VisualState.REDRAW_TARGET)  # drop stale flash cache
			if _material_cache.has(state):
				var cached: Dictionary = _material_cache[state]
				if front_face_texture:
					front_face_texture.material = cached.get("front")
				if back_face_texture:
					back_face_texture.material = cached.get("back")
			else:
				var entry: Dictionary = {}
				if _fake3d_mat and front_face_texture:
					var front_mat: ShaderMaterial = _fake3d_mat.duplicate()
					front_face_texture.material = front_mat
					entry["front"] = front_mat
				if back_face_texture:
					back_face_texture.material = _get_back_fake3d_mat()
					entry["back"] = _get_back_fake3d_mat()
				_material_cache[state] = entry

		VisualState.REDRAW_TARGET:
			modulate = Color(1.0, 0.6, 0.6, 1.0)
			_material_cache.erase(VisualState.NORMAL)
			_apply_flash_material(Color(1.0, 0.2, 0.2, 1.0))


func _apply_flash_material(flash_color: Color) -> void:
	if not _flash_mat:
		return

	var state_key: int = VisualState.REDRAW_TARGET
	if _material_cache.has(state_key):
		var cached: Dictionary = _material_cache[state_key]
		if front_face_texture:
			front_face_texture.material = cached.get("front")
		if back_face_texture:
			back_face_texture.material = cached.get("back")
		return

	var entry: Dictionary = {}
	if front_face_texture:
		var mat: ShaderMaterial = _flash_mat.duplicate()
		mat.set_shader_parameter("use_flash", true)
		mat.set_shader_parameter("flash_type", 0)
		mat.set_shader_parameter("pure_flash_color", flash_color)
		mat.set_shader_parameter("intensity", 0.6)
		mat.set_shader_parameter("speed", 0.15)
		front_face_texture.material = mat
		entry["front"] = mat
	if back_face_texture:
		var back_mat: ShaderMaterial = _flash_mat.duplicate()
		back_mat.set_shader_parameter("use_flash", true)
		back_mat.set_shader_parameter("flash_type", 0)
		back_mat.set_shader_parameter("pure_flash_color", flash_color)
		back_mat.set_shader_parameter("intensity", 0.6)
		back_mat.set_shader_parameter("speed", 0.15)
		back_mat.set_shader_parameter("y_rot", 0.0)
		back_face_texture.material = back_mat
		entry["back"] = back_mat
	_material_cache[state_key] = entry


# ═══ Drag detection ═══

## Override: Card Framework handles drop positioning;
## HandCardContainer.move_cards() override intercepts same-container drops
## to perform swap + game state sync via SealController.swap_cards().



func _handle_mouse_released() -> void:
	super._handle_mouse_released()
