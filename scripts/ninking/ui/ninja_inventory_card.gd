class_name NinjaInventoryCard
extends Card
## Unified ninja card for both NinjaBar inventory and Shop display.
##
## Single scene (ninja_card.tscn) serving two modes:
##   - Ninja bar: drag-to-reorder (card-framework), right-click sell, hover tooltip
##   - Shop:      left-click emits card_clicked (ShopSlot handles buy), right-click detail
##
## Mode is set via setup() for ninja bar or setup_shop() for shop.
## In shop mode:
##   - NameLabel hidden
##   - Left-click emits card_clicked instead of entering HOLDING/drag
##   - Right-click opens CardDetailPopup directly
##   - API surface matches old DisplayCardBase for ShopSlot compatibility:
##       set_content_texture(), set_frame(), apply_barrier_theme(), set_detail_data()
##
## Fake3D: applies fake3d perspective shader to the ninja illustration TextureRect.
## Frame/border/hover: delegates to CardVisualComposer for consistent visual composition.
## Rarity flash materials (Foil/Holo/Polychrome): fak3d_flash shader via FLASH_MATERIAL_PATHS.
## All shader param animations go through GlobalTweens.shader_pulse / tween_shader_param.

signal card_clicked(ninja_data: Dictionary)
signal hover_started
signal hover_ended
signal sell_requested

var ninja_data: Dictionary = {}
var slot_index: int = -1

var frame_overlay: TextureRect
var _name_label: Label = null

# Shop mode
var _shop_mode: bool = false
var _detail_name: String = ""
var _detail_desc: String = ""
var _detail_effect: Dictionary = {}
var _detail_texture: Texture2D = null
var _detail_popup = null  # duck-typed CardDetailPopup

# Fake3D material (loaded at runtime to avoid compile-time .tres dependency)
var _fake3d_mat: ShaderMaterial = null
# Dissolve material for ceremonial exit effects
var _dissolve_mat: ShaderMaterial = null
# Flash material for rarity-based card surface effects (shared instance, front+frame)
var _flash_mat: ShaderMaterial = null
# Legendary / Rare flags for animation pulse control
var _is_legendary: bool = false
var _is_rare: bool = false

const NAME_FONT_SIZE: int = 12



func _init() -> void:
	card_size = Vector2(125, 175)
	custom_minimum_size = Vector2(125, 175)
	hover_scale = 1.0
	hover_distance = 12


func _ready() -> void:
	# Ensure child nodes exist: when instantiated from scene they already exist,
	# when created via .new() they are created here.
	_ensure_face_nodes()
	super._ready()
	# Re-apply card size now that front_face_texture is resolved (was null in _init())
	_update_card_size(card_size)
	# Explicitly set Control size so FrameOverlay PRESET_FULL_RECT anchors are non-zero
	size = card_size
	back_face_texture.visible = false
	show_front = true

	frame_overlay = $FrameOverlay

	_create_name_label()
	gui_input.connect(_on_right_click)
	_load_fake3d_material()
	_load_dissolve_material()
	# _apply_fake3d_material is guarded by material==null;
	# if _apply_flash_material already set a material (called from setup/setup_shop),
	# this becomes a no-op. For common rarity with no flash, it applies fake3d here.
	_apply_fake3d_material()


## Load fake3d material at runtime (avoid compile-time dependency on .tres).
func _load_fake3d_material() -> void:
	if _fake3d_mat == null:
		_fake3d_mat = load("res://resources/materials/fake3d.tres")


## Apply fake3d perspective material to the front face TextureRect.
## Guarded: only applies when front_face_texture.material is null.
## This allows _apply_flash_material (called from setup/setup_shop before _ready)
## to take precedence without being overridden.
func _apply_fake3d_material() -> void:
	if not _fake3d_mat:
		return
	if front_face_texture and front_face_texture.material == null:
		front_face_texture.material = _fake3d_mat.duplicate()


## Load dissolve2d material at runtime for ceremonial exit effects.
func _load_dissolve_material() -> void:
	if _dissolve_mat == null:
		_dissolve_mat = load("res://resources/materials/dissolve2d.tres")


## Ceremonial dissolve exit: swap to dissolve2d shader material,
## then tween dissolve_value 1.0->0.0 with burn border edge.
## Calls queue_free on completion via TweenFX.dissolve_out().
func dissolve_out(duration: float = 1.0) -> void:
	if not _dissolve_mat or not is_instance_valid(self):
		queue_free()
		return
	# Guard: already dissolving — don't double-start
	if material is ShaderMaterial and material.shader == _dissolve_mat.shader:
		return
	# Swap this Control's material to dissolve2d so frame and face share it
	material = _dissolve_mat.duplicate()
	# Manually set use_parent_material on nested TextureRects inside
	# FrontFace/BackFace — find_children("TextureRect", recursive=false)
	# inside TweenFX only hits FrameOverlay and misses these.
	for face_name: String in ["FrontFace", "BackFace"]:
		if has_node(face_name):
			var face := get_node(face_name)
			for child in face.find_children("*", "TextureRect", false, false):
				if child is TextureRect:
					child.use_parent_material = true
	# Delegate to TweenFX which handles use_parent_material + tween + queue_free
	GlobalTweens.dissolve_out(self, duration)


func _ensure_face_nodes() -> void:
	## Ensure all required child nodes exist.
	## When instantiated from ninja_card.tscn, all nodes are already present
	## and these has_node() checks become no-ops (backward-compatible).
	if not has_node("FrontFace"):
		var ff := Control.new()
		ff.name = "FrontFace"
		ff.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(ff)

		var tex_rect := TextureRect.new()
		tex_rect.name = "TextureRect"
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ff.add_child(tex_rect)

	if not has_node("BackFace"):
		var bf := Control.new()
		bf.name = "BackFace"
		bf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bf)

		var tex_rect := TextureRect.new()
		tex_rect.name = "TextureRect"
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bf.add_child(tex_rect)

	if not has_node("FrameOverlay"):
		var fo := TextureRect.new()
		fo.name = "FrameOverlay"
		fo.visible = false
		fo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		fo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(fo)

	# Resolve frame_overlay reference early (available before _ready)
	if frame_overlay == null:
		frame_overlay = $FrameOverlay if has_node("FrameOverlay") else null


# ============================================================
# Ninja bar mode
# ============================================================

func setup(ninja_name: String, data: Dictionary) -> void:
	_shop_mode = false
	ninja_data = data
	card_name = ninja_name

	# Ensure child nodes and texture rect references are resolved (safe before _ready)
	_ensure_face_nodes()
	check_and_set_textures()

	_apply_rarity_frame(data.get("rarity", "common"))
	_update_name_label(ninja_name)
	if _name_label:
		_name_label.visible = true

	var ninja_id: String = data.get("id", "")
	if ninja_id != "":
		var card_path: String = AssetRegistry.get_ninja_card_path(ninja_id)
		if ResourceLoader.exists(card_path):
			var tex: Texture2D = load(card_path)
			if tex:
				# Scale texture to card_size to avoid EXPAND_IGNORE_SIZE native-size overflow
				var img: Image = tex.get_image()
				if img and (img.get_width() != int(card_size.x) or img.get_height() != int(card_size.y)):
					img.resize(int(card_size.x), int(card_size.y), Image.INTERPOLATE_LANCZOS)
					var scaled_tex: ImageTexture = ImageTexture.create_from_image(img)
					set_faces(scaled_tex, null)
				else:
					set_faces(tex, null)


# ============================================================
# Shop mode -- API matches old DisplayCardBase
# ============================================================

func setup_shop(data: Dictionary) -> void:
	_shop_mode = true
	ninja_data = data
	_detail_name = data.get("name", "???")
	_detail_desc = data.get("effect_desc", "")
	_detail_effect = data.get("effect", {})
	_detail_texture = null

	# Ensure child nodes resolved (safe before _ready)
	_ensure_face_nodes()

	_apply_rarity_frame(data.get("rarity", "common"))
	if _name_label:
		_name_label.visible = false


func set_content_texture(texture: Texture2D) -> void:
	## Public method for ShopSlot to set the card illustration.
	## Scales texture to card_size and applies via set_faces (TextureRect path).
	_detail_texture = texture
	if texture == null:
		return
	# Ensure texture rect refs are resolved before set_faces (safe before _ready)
	check_and_set_textures()
	var img: Image = texture.get_image()
	if img and (img.get_width() != int(card_size.x) or img.get_height() != int(card_size.y)):
		img.resize(int(card_size.x), int(card_size.y), Image.INTERPOLATE_LANCZOS)
		set_faces(ImageTexture.create_from_image(img), null)
	else:
		set_faces(texture, null)


func set_frame(rarity: String) -> void:
	## Public wrapper: load and display rarity frame texture overlay + flash material.
	_apply_rarity_frame(rarity)


func apply_barrier_theme(colors: Dictionary) -> void:
	## Update panel background color (used by ShopSlot's ink-wash theme).
	if colors.has("panel") and has_theme_stylebox_override("panel"):
		var style := get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.bg_color = colors["panel"]


func set_detail_data(n_name: String, desc: String, texture: Texture2D = null, effect: Dictionary = {}) -> void:
	## Store detail popup data (called by ShopSlot after load).
	_detail_name = n_name
	_detail_desc = desc
	_detail_effect = effect
	if texture:
		_detail_texture = texture


# ============================================================
# Rarity frame
# ============================================================

## Resize a texture to card_size (125x175) via LANCZOS interpolation.
## Returns original if already correct size, or null if texture is null.
func _resize_to_card(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	var img: Image = texture.get_image()
	if img == null:
		return texture
	if img.get_width() == int(card_size.x) and img.get_height() == int(card_size.y):
		return texture
	img.resize(int(card_size.x), int(card_size.y), Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


func _apply_rarity_frame(rarity: String) -> void:
	## Load and display a rarity frame texture overlay via CardVisualComposer.
	## Falls back to StyleBoxFlat border if frame texture unavailable.
	## Also applies rarity-based flash material (Foil/Holo/Polychrome).
	var tex := AssetRegistry.load_frame_texture(rarity)
	if tex and frame_overlay:
		frame_overlay.texture = _resize_to_card(tex)
		frame_overlay.visible = true
		# Minimal background (no border - frame overlay handles it)
		add_theme_stylebox_override("panel", CardVisualComposer.create_rarity_stylebox(rarity, "bg"))
	else:
		# Fallback: rarity-colored border via StyleBoxFlat
		add_theme_stylebox_override("panel", CardVisualComposer.create_rarity_stylebox(rarity, "full"))

	# Apply flash material (all rarities now have distinct flash effects)
	_apply_flash_material(rarity)


# ============================================================
# Flash material (Foil / Holo / Polychrome)
# ============================================================

## Restore the appropriate idle looping animation based on rarity.
func _restore_idle_animation() -> void:
	if not _flash_mat:
		return
	var r: String = ninja_data.get("rarity", "common")
	match r:
		"legendary":
			GlobalTweens.shader_pulse(self, _flash_mat, "intensity", 0.1, 0.38, 0.8)
		"rare":
			GlobalTweens.shader_pulse(self, _flash_mat, "intensity", 0.2, 0.55, 0.6)
		"uncommon":
			GlobalTweens.shader_pulse(self, _flash_mat, "intensity", 0.18, 0.42, 1.2)


## Load and apply rarity-based flash shader to both front_face and frame_overlay.
## All four rarities have flash materials with distinct dynamic modes:
##   Common   -> type2 silver gradient scan (silk, static intensity 0.3)
##   Uncommon -> type2 ocean wave gradient flow + breath (0.18~0.42)
##   Rare     -> type2 fire gradient flicker + pulse (0.20~0.55)
##   Legendary-> type1 rainbow shimmer + breath (0.10~0.38)
## Uses a single ShaderMaterial instance shared by front and frame layers,
## so shader param tweens affect both simultaneously.
func _apply_flash_material(rarity: String) -> void:
	var path: String = AssetRegistry.FLASH_MATERIAL_PATHS.get(rarity, "")
	if path.is_empty():
		# No flash material -> revert to basic fake3d (shouldn't happen now)
		_flash_mat = null
		_is_legendary = false
		_is_rare = false
		if front_face_texture:
			front_face_texture.material = _fake3d_mat.duplicate() if _fake3d_mat else null
		if frame_overlay:
			frame_overlay.material = null
		return

	var loaded := load(path) as ShaderMaterial
	if loaded == null:
		return

	_flash_mat = loaded.duplicate()
	_is_legendary = rarity == "legendary"
	_is_rare = rarity == "rare"

	# Apply to front face (replaces fake3d)
	if front_face_texture:
		front_face_texture.material = _flash_mat

	# Apply to frame overlay (same instance = shared shader params)
	if frame_overlay:
		frame_overlay.material = _flash_mat

	# Apply rarity-specific flash params (one_way_loop, softness) from AssetRegistry.RARITY_FLASH_PARAMS
	if _flash_mat:
		var par: Dictionary = AssetRegistry.RARITY_FLASH_PARAMS.get(rarity, {})
		if par.has("one_way_loop"):
			_flash_mat.set_shader_parameter("one_way_loop", par["one_way_loop"])
		if par.has("softness"):
			_flash_mat.set_shader_parameter("softness", par["softness"])

	# Start rarity-specific looping animations
	if _flash_mat:
		match rarity:
			"legendary":
				GlobalTweens.shader_pulse(self, _flash_mat, "intensity", 0.1, 0.38, 0.8)
			"rare":
				GlobalTweens.shader_pulse(self, _flash_mat, "intensity", 0.2, 0.55, 0.6)
			"uncommon":
				GlobalTweens.shader_pulse(self, _flash_mat, "intensity", 0.18, 0.42, 1.2)
			# common: no looping animation (subtle scan only)


## Speed up flash material params on hover (intensity x1.5, move_speed x2).
## For legendary/rare: also accelerate the looping pulse cycle.
func _on_hover_start() -> void:
	if not _flash_mat:
		return
	var r: String = ninja_data.get("rarity", "common")
	var base: Dictionary = AssetRegistry.RARITY_FLASH_PARAMS.get(r, {})
	var target_intensity: float = base.get("intensity", 0.0) * 1.5
	var target_speed: float = maxf(base.get("move_speed", 0.0) * 2.0, 1.0)

	GlobalTweens.tween_shader_param(self, _flash_mat, "intensity", target_intensity, 0.15)
	GlobalTweens.tween_shader_param(self, _flash_mat, "move_speed", target_speed, 0.15)

	if _is_legendary:
		GlobalTweens.shader_pulse(self, _flash_mat, "intensity", 0.2, 0.55, 0.3)
	elif _is_rare:
		GlobalTweens.shader_pulse(self, _flash_mat, "intensity", 0.35, 0.75, 0.4)


## Restore flash material params on unhover and resume idle animation.
func _on_hover_end() -> void:
	if not _flash_mat:
		return
	var r: String = ninja_data.get("rarity", "common")
	var base: Dictionary = AssetRegistry.RARITY_FLASH_PARAMS.get(r, {})

	GlobalTweens.tween_shader_param(self, _flash_mat, "intensity", base.get("intensity", 0.0), 0.2)
	GlobalTweens.tween_shader_param(self, _flash_mat, "move_speed", base.get("move_speed", 0.0), 0.2)

	_restore_idle_animation()


# ============================================================
# Name label
# ============================================================

func _create_name_label() -> void:
	## Create name label if not already in scene tree.
	if has_node("NameLabel"):
		_name_label = $NameLabel
		return
	_name_label = Label.new()
	_name_label.name = "NameLabel"
	_name_label.position = Vector2(0, card_size.y + 2)
	_name_label.size = Vector2(card_size.x, 20)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	add_child(_name_label)


func _update_name_label(text: String) -> void:
	if _name_label:
		_name_label.text = text


# ============================================================
# Interaction overrides
# ============================================================

## Override: in shop mode, emit card_clicked instead of entering drag.
## In ninja bar mode, guard against null card_container.
func _handle_mouse_pressed() -> void:
	if _shop_mode:
		card_clicked.emit(ninja_data)
		return
	if card_container:
		card_container.on_card_pressed(self)
	super._handle_mouse_pressed()


## Override DraggableObject state transitions for frame-only hover glow
## and flash material acceleration. Emits hover_started/hover_ended for
## NinjaBarNode to manage tooltip timer.
func _enter_state(state: DraggableState, from_state: DraggableState) -> void:
	super._enter_state(state, from_state)
	match state:
		DraggableState.HOVERING:
			CardVisualComposer.apply_hover_glow(frame_overlay, true)
			_apply_hover_shadow(true)
			_on_hover_start()
			hover_started.emit()
		DraggableState.IDLE:
			CardVisualComposer.apply_hover_glow(frame_overlay, false)
			_apply_hover_shadow(false)
			_on_hover_end()
			if from_state == DraggableState.HOVERING:
				hover_ended.emit()


func _apply_hover_shadow(enable: bool) -> void:
	var rarity: String = ninja_data.get("rarity", "common")
	if enable:
		var border_color: Color = AssetRegistry.RARITY_BORDER_COLORS.get(rarity, Color.BLACK)
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = CardVisualComposer.CARD_BG_COLOR
		hover_style.set_corner_radius_all(6)
		hover_style.shadow_size = 10
		hover_style.shadow_color = Color(border_color, 0.35)
		add_theme_stylebox_override("panel", hover_style)
	else:
		# Restore only the stylebox, NOT _apply_rarity_frame() —
		# that would recreate flash material and break _on_hover_end() tween.
		if frame_overlay and frame_overlay.texture:
			add_theme_stylebox_override("panel", CardVisualComposer.create_rarity_stylebox(rarity, "bg"))
		else:
			add_theme_stylebox_override("panel", CardVisualComposer.create_rarity_stylebox(rarity, "full"))


func _on_right_click(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_RIGHT \
			and event.pressed:
		if current_state != DraggableObject.DraggableState.HOLDING:
			if _shop_mode:
				_show_detail_popup()
			else:
				sell_requested.emit()


# ============================================================
# Detail popup (shop mode)
# ============================================================

func _show_detail_popup() -> void:
	## Open CardDetailPopup with stored detail data.
	if _detail_popup != null:
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	var tex: Texture2D = _detail_texture
	if tex == null and front_face_texture and front_face_texture.texture:
		tex = front_face_texture.texture
	_detail_popup = CardDetailPopup.open({
		viewport = viewport,
		texture = tex,
		name = _detail_name,
		desc = _detail_desc,
		rarity = ninja_data.get("rarity", "common"),
		extra_desc = "",
		effect = _detail_effect,
	})
	_detail_popup.tree_exited.connect(func():
		_detail_popup = null
	)
