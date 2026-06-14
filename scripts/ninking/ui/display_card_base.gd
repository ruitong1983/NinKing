class_name DisplayCardBase
extends Card
## Base class for all non-poker display cards (ability, item, deck preview, collection).
##
## Pure card face at 125×175 — no text overlay, no buttons.
## All contextual UI (name, effect, price, buy button) lives in the parent container
## (e.g. ShopSlot), not on this card itself.
##
## Provides:
## - Consistent frame with shadow and rounded corners
## - Content slot for subclasses to fill (illustration, icons)
## - Uniform hover / entrance / right-click detail popup
## - Rarity border/style via set_card_border()
##
## Subclasses override:
##   setup(data)            — load content into content_slot
##   get_card_id()           — return unique identifier
##   _get_detail_config()    — provide data for detail popup


# ═══ Signals ═══
## Left-click — all display cards emit this uniformly.
signal card_clicked(card: DisplayCardBase)

# ═══ @onready references ═══
@onready var card_panel: Panel = $card_panel
@onready var content_slot: Control = $card_panel/content_slot

# ═══ Internal state ═══
var _card_style: StyleBoxFlat
var _detail_popup: CardDetailPopup = null
var _detail_name: String = ""
var _detail_desc: String = ""
var _detail_texture: Texture2D = null

const COLOR_INK: Color = Color(0.102, 0.102, 0.102)  # #1A1A1A

# ══════════════════════════════════════════
# Lifecycle
# ══════════════════════════════════════════

func _ready() -> void:
	# Satisfy Card parent's check_and_set_textures() — must exist before super()
	front_face_texture = $FrontFace/TextureRect
	back_face_texture = $BackFace/TextureRect

	super._ready()

	# Hide card-framework face nodes — DisplayCardBase uses its own layout
	front_face_texture.visible = false
	back_face_texture.visible = false

	# Must be interactable for hover to work
	can_be_interacted_with = true


# ══════════════════════════════════════════
# Public API
# ══════════════════════════════════════════

func setup(data: Dictionary) -> void:
	## Entry point. Subclasses call super(data) then load their own content.
	_init_card_style()
	_detail_name = data.get("name", "???")
	_detail_desc = data.get("effect_desc", "")


func apply_barrier_theme(colors: Dictionary) -> void:
	## Apply barrier-specific manga colors.
	if not _card_style:
		return
	_card_style.bg_color = colors.panel
	_card_style.border_color = COLOR_INK


func get_card_id() -> String:
	## Uniquely identifies this card. Subclasses must override.
	return ""


func set_content_texture(texture: Texture2D) -> void:
	## Public method for parent containers (e.g. ShopSlot) to set the illustration.
	_add_content_texture(texture)


func set_card_border(width: int, border_color: Color, shadow_size: int, shadow_color: Color) -> void:
	## Set rarity-based border style on the card frame.
	if not _card_style:
		return
	_card_style.border_width_left = width
	_card_style.border_width_right = width
	_card_style.border_width_top = width
	_card_style.border_width_bottom = width
	_card_style.shadow_size = shadow_size
	_card_style.shadow_color = shadow_color
	_card_style.border_color = border_color


func set_detail_data(n_name: String, desc: String, texture: Texture2D = null) -> void:
	## Allow parent containers to provide detail popup data.
	_detail_name = n_name
	_detail_desc = desc
	if texture:
		_detail_texture = texture


# ══════════════════════════════════════════
# Content helpers
# ══════════════════════════════════════════

func _add_content_texture(texture: Texture2D) -> Control:
	## Load an image into content_slot using a custom-drawn Control.
	## TextureRect auto-sets its minimum_size to the texture dimensions
	## (e.g. 1792×2560), which makes the Control clamp its rect size and
	## show only the top-left corner through clip_contents.
	## A custom _draw() sidesteps this entirely.
	var ctrl := Control.new()
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ctrl.custom_minimum_size = Vector2.ZERO
	ctrl.draw.connect(func():
		if not is_instance_valid(texture):
			return
		var draw_size: Vector2 = ctrl.get_size()
		if draw_size.x <= 0 or draw_size.y <= 0:
			return
		# KEEP_ASPECT_COVERED: scale to fill, center-crop
		var tex_size: Vector2 = texture.get_size()
		var s: float = max(draw_size.x / tex_size.x, draw_size.y / tex_size.y)
		var scaled: Vector2 = tex_size * s
		var offset: Vector2 = (draw_size - scaled) * 0.5
		var src_rect := Rect2(Vector2.ZERO, tex_size)
		var dst_rect := Rect2(offset, scaled)
		ctrl.draw_texture_rect_region(texture, dst_rect, src_rect)
	)
	content_slot.add_child(ctrl)
	return ctrl


# ══════════════════════════════════════════
# Style
# ══════════════════════════════════════════

func _init_card_style() -> void:
	_card_style = StyleBoxFlat.new()
	_card_style.bg_color = Color(0.1, 0.1, 0.18, 0.92)
	_card_style.set_corner_radius_all(6)
	_card_style.border_width_left = 2
	_card_style.border_width_right = 2
	_card_style.border_width_top = 2
	_card_style.border_width_bottom = 2
	_card_style.border_color = COLOR_INK
	_card_style.shadow_size = 6
	_card_style.shadow_color = Color(0, 0, 0, 0.15)
	card_panel.add_theme_stylebox_override("panel", _card_style)


# ══════════════════════════════════════════
# Interaction
# ══════════════════════════════════════════

func _on_gui_input(event: InputEvent) -> void:
	## Override DraggableObject._on_gui_input.
	## Left-click → emit signal (don't start HOLDING/drag).
	## Right-click → detail popup.
	## All other events → pass to DraggableObject for hover state management.
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				card_clicked.emit(self)
				return  # Prevent DraggableObject from entering HOLDING
			MOUSE_BUTTON_RIGHT:
				_show_detail_popup()
				return

	# Mouse move / non-button → DraggableObject handles hover state
	super._on_gui_input(event)


func _show_detail_popup() -> void:
	## Open the detail popup with data from _get_detail_config().
	if _detail_popup != null:
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	var cfg := _get_detail_config()
	cfg.viewport = viewport
	_detail_popup = CardDetailPopup.open(cfg)
	_detail_popup.tree_exited.connect(func():
		_detail_popup = null
	)


func _get_detail_config() -> Dictionary:
	## Subclasses override to provide their data for the detail popup.
	var tex: Texture2D = _detail_texture
	# Fallback: grab first child texture from content_slot
	if tex == null and content_slot.get_child_count() > 0:
		var child = content_slot.get_child(0)
		if child and "texture" in child:
			tex = child.texture
	return {
		texture = tex,
		name = _detail_name,
		desc = _detail_desc,
		rarity = "",
		extra_desc = "",
	}


# ══════════════════════════════════════════
# Hover animation — override DraggableObject
# ══════════════════════════════════════════

func _start_hover_animation() -> void:
	## Subtle scale-up for display cards.
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	hover_tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.12)


func _stop_hover_animation() -> void:
	## Return to original scale.
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	hover_tween.tween_property(self, "scale", Vector2.ONE, 0.15)


# ══════════════════════════════════════════
# Entrance animation
# ══════════════════════════════════════════

func play_entrance(delay: float = 0.0) -> void:
	## Uniform entrance animation for all display cards.
	scale = Vector2(0.8, 0.8)
	modulate.a = 0.0
	var tween: Tween = create_tween().set_delay(delay)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.2)
