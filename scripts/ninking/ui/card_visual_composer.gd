class_name CardVisualComposer
extends RefCounted
## Static utility for composing card visuals (art + rarity frame + glow + flash).
##
## L1 — Atomic tools:
##   create_rarity_stylebox, create_frame_overlay,
##   compose_art_texture, compose_art_draw, apply_hover_glow
##
## L2 — Convenience:
##   build_card_face
## L3 — Flash shader card (TextureRect path with rarity flash material):
##   build_card_face_with_flash, _load_and_setup_flash
##
## Design: B方案（节点组合，不合并像素），支持半透明/发光/描边效果。
## 双渲染路径：TextureRect（保留 Fake3D shader 挂载点）+ _draw（KEEP_ASPECT_COVERED）。

const COLOR_INK: Color = Color(0.102, 0.102, 0.102)  # #1A1A1A
const CARD_BG_COLOR: Color = Color(0.1, 0.1, 0.18, 0.92)


# ══════════════════════════════════════════
# L1 — 原子工具
# ══════════════════════════════════════════

## Create a StyleBoxFlat for tooltip panels (dark background + colored thin border).
## Shared across Lv tooltip and Star chart tooltip to eliminate duplicate code.
static func create_tooltip_stylebox(border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.92)
	style.set_corner_radius_all(4)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.border_color.a = 0.4
	return style


## Create a StyleBoxFlat for the given rarity.
## mode="full" → complete border + shadow glow (for standalone/fallback use).
## mode="bg"   → background color only (for when frame texture overlay is active).
static func create_rarity_stylebox(rarity: String, mode: String = "full") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG_COLOR
	style.set_corner_radius_all(6)

	if mode == "bg":
		return style

	var width: int = 2
	var border_color: Color = AssetRegistry.RARITY_BORDER_COLORS.get(rarity, COLOR_INK)
	var shadow_size: int = 4
	var shadow_color: Color = Color(0, 0, 0, 0.12)

	match rarity:
		"uncommon":
			shadow_size = 6
		"rare":
			width = 3
			shadow_size = 10
		"legendary":
			width = 3
			shadow_size = 14

	if shadow_size > 4:
		shadow_color = Color(border_color, 0.18 if rarity == "legendary" else 0.25)

	style.border_width_left = width
	style.border_width_right = width
	style.border_width_top = width
	style.border_width_bottom = width
	style.border_color = border_color
	style.shadow_size = shadow_size
	style.shadow_color = shadow_color
	return style


## Create a TextureRect overlay with the rarity frame texture.
## Attached to `parent` with PRESET_FULL_RECT anchors.
## The caller is responsible for calling `parent.add_child(fo)` if needed
## (this method does NOT add it — let the caller control insertion order).
## Returns null if frame texture is unavailable.
static func create_frame_overlay(rarity: String) -> TextureRect:
	var tex := AssetRegistry.load_frame_texture(rarity)
	if tex == null:
		return null

	var fo := TextureRect.new()
	fo.texture = tex
	fo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return fo


## Compose ninja illustration as a TextureRect (supports Fake3D shader).
## Fills `parent` with texture at given size, KEEP_ASPECT_CENTERED.
## Scales texture to `size` to avoid EXPAND_IGNORE_SIZE native-size overflow.
## Returns the created TextureRect.
static func compose_art_texture(parent: Control, texture: Texture2D, size: Vector2) -> TextureRect:
	var tex_rect := TextureRect.new()
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.size = size
	parent.add_child(tex_rect)

	var img: Image = texture.get_image()
	if img and (img.get_width() != int(size.x) or img.get_height() != int(size.y)):
		img.resize(int(size.x), int(size.y), Image.INTERPOLATE_LANCZOS)
		tex_rect.texture = ImageTexture.create_from_image(img)
	else:
		tex_rect.texture = texture

	return tex_rect


## Compose illustration as a custom-drawn Control (KEEP_ASPECT_COVERED).
## Avoids TextureRect minimum_size clamping issues.
## Returns the created Control.
static func compose_art_draw(parent: Control, texture: Texture2D) -> Control:
	var ctrl := Control.new()
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ctrl.custom_minimum_size = Vector2.ZERO
	ctrl.draw.connect(_make_draw_callback(ctrl, texture))
	parent.add_child(ctrl)
	return ctrl


## Tween the frame overlay's self_modulate for hover glow.
## is_hovering=true  → brighten to Color.WHITE (0.12s, EASE_OUT_CUBIC)
## is_hovering=false → dim to Color(1,1,1,0.85) (0.15s, EASE_OUT_CUBIC)
static func apply_hover_glow(frame_node: TextureRect, is_hovering: bool) -> void:
	if not is_instance_valid(frame_node):
		return
	if frame_node.texture == null:
		return

	var target: Color = Color.WHITE if is_hovering else Color(1, 1, 1, 0.85)
	var duration: float = 0.12 if is_hovering else 0.15

	var tw: Tween = frame_node.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(frame_node, "self_modulate", target, duration)


# ══════════════════════════════════════════
# L2 — 便捷组合
# ══════════════════════════════════════════

## Build a complete card face (Panel + art + frame overlay).
## For CardDetailPopup and future preview/collection views.
##
## use_draw=true  → use compose_art_draw (KEEP_ASPECT_COVERED, no shader)
## use_draw=false → use compose_art_texture (KEEP_ASPECT_CENTERED, shader-capable)
##
## Returns the Panel node containing art + frame.
static func build_card_face(parent: Control, size: Vector2, texture: Texture2D,
		rarity: String, use_draw: bool = true) -> Panel:
	var panel := Panel.new()
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(panel)

	# Background style
	var frame_tex: Texture2D = AssetRegistry.load_frame_texture(rarity)
	if frame_tex:
		panel.add_theme_stylebox_override("panel", create_rarity_stylebox(rarity, "bg"))
	else:
		panel.add_theme_stylebox_override("panel", create_rarity_stylebox(rarity, "full"))

	# Art layer (added before frame so frame renders on top)
	if texture != null:
		if use_draw:
			compose_art_draw(panel, texture)
		else:
			compose_art_texture(panel, texture, size)

	# Frame overlay (on top of art)
	if frame_tex:
		var fo: TextureRect = create_frame_overlay(rarity)
		if fo:
			panel.add_child(fo)

	return panel


# ══════════════════════════════════════════
# L3 — 卡牌构建 + Flash 材质（卡牌弹窗/预览）
# ══════════════════════════════════════════

## Build a card face with flash shader material applied (TextureRect path).
## Used by CardDetailPopup to show rarity-based foil/holo/polychrome effects.
##
## Returns a Dictionary with keys:
##   "panel"      — Panel (parent container)
##   "art_rect"   — TextureRect (ninja art with flash material, may be null)
##   "frame_rect" — TextureRect (rarity frame overlay, may be null)
##   "flash_mat"  — ShaderMaterial (shared flash material instance, may be null)
##
## The caller should use GlobalTweens.shader_pulse() on flash_mat for looping animation.
static func build_card_face_with_flash(parent: Control, size: Vector2, texture: Texture2D,
		rarity: String) -> Dictionary:
	var panel := Panel.new()
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(panel)

	# Background style
	var frame_tex: Texture2D = AssetRegistry.load_frame_texture(rarity)
	if frame_tex:
		panel.add_theme_stylebox_override("panel", create_rarity_stylebox(rarity, "bg"))
	else:
		panel.add_theme_stylebox_override("panel", create_rarity_stylebox(rarity, "full"))

	# Art TextureRect (shader-capable, before frame so frame renders on top)
	var art_rect: TextureRect = null
	if texture != null:
		art_rect = compose_art_texture(panel, texture, size)

	# Frame overlay
	var frame_rect: TextureRect = null
	if frame_tex:
		frame_rect = create_frame_overlay(rarity)
		if frame_rect:
			panel.add_child(frame_rect)

	# Load and apply flash material to both art + frame (shared instance)
	var flash_mat: ShaderMaterial = _load_and_setup_flash(rarity)
	if flash_mat:
		if art_rect:
			art_rect.material = flash_mat
		if frame_rect:
			frame_rect.material = flash_mat

	return {
		"panel": panel,
		"art_rect": art_rect,
		"frame_rect": frame_rect,
		"flash_mat": flash_mat,
	}


## Load flash material for rarity, duplicate, set base shader params.
## Returns null if no flash material for this rarity.
static func _load_and_setup_flash(rarity: String) -> ShaderMaterial:
	var path: String = AssetRegistry.FLASH_MATERIAL_PATHS.get(rarity, "")
	if path.is_empty():
		return null
	var loaded := load(path) as ShaderMaterial
	if loaded == null:
		return null
	var mat: ShaderMaterial = loaded.duplicate()
	var par: Dictionary = AssetRegistry.RARITY_FLASH_PARAMS.get(rarity, {})
	if par.has("one_way_loop"):
		mat.set_shader_parameter("one_way_loop", par["one_way_loop"])
	if par.has("softness"):
		mat.set_shader_parameter("softness", par["softness"])
	return mat


# ══════════════════════════════════════════
# Internal helpers
# ══════════════════════════════════════════

static func _make_draw_callback(control: Control, texture: Texture2D) -> Callable:
	## Return a callable that draws texture KEEP_ASPECT_COVERED inside control.
	return func():
		if not is_instance_valid(texture):
			return
		var draw_size: Vector2 = control.get_size()
		if draw_size.x <= 0 or draw_size.y <= 0:
			return
		var tex_size: Vector2 = texture.get_size()
		var s: float = max(draw_size.x / tex_size.x, draw_size.y / tex_size.y)
		var scaled: Vector2 = tex_size * s
		var offset: Vector2 = (draw_size - scaled) * 0.5
		control.draw_texture_rect_region(
			texture,
			Rect2(offset, scaled),
			Rect2(Vector2.ZERO, tex_size)
		)
