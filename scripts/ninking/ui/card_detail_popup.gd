class_name CardDetailPopup
extends Control
## Unified Balatro-style zoom-in card detail popup.
##
## Shows a large framed card with rarity border and cropped art (KEEP_ASPECT_COVERED),
## matching the slot's DisplayCardBase visual style.
##
## Usage:
##   var popup = CardDetailPopup.open({
##       viewport = get_viewport(),
##       texture = card_texture,
##       name = "风魔小太郎",
##       desc = "效果描述/触发条件",
##       rarity = "rare",
##       extra_desc = "Lv.3",
##   })

const RARITY_COLORS: Dictionary = {
	"common": Color("#888888"),
	"uncommon": Color("#4CAF50"),
	"rare": Color("#F44336"),
	"legendary": Color("#FFD700"),
}

const COLOR_INK: Color = Color(0.102, 0.102, 0.102)  # #1A1A1A
const CARD_SIZE: Vector2 = Vector2(320, 448)
const SB = preload("res://scripts/config/sound_bank.gd")

var _is_dismissing: bool = false


static func open(config: Dictionary) -> CardDetailPopup:
	var popup := CardDetailPopup.new()
	popup._build(config)
	return popup


func _build(config: Dictionary) -> void:
	var viewport: Viewport = config.get("viewport")
	if viewport == null:
		push_error("CardDetailPopup: viewport is required")
		queue_free()
		return

	var tex: Texture2D = config.get("texture")
	var card_name: String = config.get("name", "???")
	var desc: String = config.get("desc", "")
	var rarity: String = config.get("rarity", "common")
	var extra_desc: String = config.get("extra_desc", "")

	var viewport_size: Vector2 = viewport.get_visible_rect().size

	# Setup self
	size = viewport_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 1200
	name = "CardDetailPopup"
	viewport.get_tree().current_scene.add_child(self)

	# ── Overlay ──
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.size = viewport_size
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.name = "DetailOverlay"
	overlay.gui_input.connect(_on_overlay_clicked)
	add_child(overlay)
	GlobalTweens.fade_in(overlay, 0.1)

	# ── Card frame (matching DisplayCardBase: StyleBoxFlat + KEEP_ASPECT_COVERED) ──
	var card_pos: Vector2 = viewport_size / 2 - CARD_SIZE / 2
	card_pos.y -= 60  # Shift up for text below

	# Build StyleBoxFlat
	var card_style := _build_card_style(rarity)
	var card_panel := Panel.new()
	card_panel.name = "DetailCardPanel"
	card_panel.size = CARD_SIZE
	card_panel.position = card_pos
	card_panel.add_theme_stylebox_override("panel", card_style)
	add_child(card_panel)

	# Content — draw texture KEEP_ASPECT_COVERED (same as DisplayCardBase._add_content_texture)
	if tex != null:
		var content := Control.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.draw.connect(_make_card_draw(content, tex))
		card_panel.add_child(content)

	# ── Name label (32px, rarity-colored if non-common) ──
	var name_label: Label = Label.new()
	name_label.text = card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 32)
	if rarity != "common" and RARITY_COLORS.has(rarity):
		name_label.add_theme_color_override("font_color", RARITY_COLORS[rarity])
	name_label.position = Vector2(
		viewport_size.x / 2 - 200,
		card_pos.y + CARD_SIZE.y + 12
	)
	name_label.size = Vector2(400, 40)
	add_child(name_label)

	# ── Description (22px gray) ──
	if desc != "":
		var desc_label: Label = Label.new()
		desc_label.text = desc
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.add_theme_font_size_override("font_size", 22)
		desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		desc_label.position = Vector2(
			viewport_size.x / 2 - 200,
			name_label.position.y + 44
		)
		desc_label.size = Vector2(400, 30)
		add_child(desc_label)

		# Extra desc (below description, e.g. "Lv.3" or "条件触发")
		if extra_desc != "":
			var extra_label: Label = Label.new()
			extra_label.text = extra_desc
			extra_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			extra_label.add_theme_font_size_override("font_size", 20)
			extra_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			extra_label.position = Vector2(
				viewport_size.x / 2 - 200,
				desc_label.position.y + 32
			)
			extra_label.size = Vector2(400, 28)
			add_child(extra_label)
	elif extra_desc != "":
		var extra_label: Label = Label.new()
		extra_label.text = extra_desc
		extra_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		extra_label.add_theme_font_size_override("font_size", 22)
		extra_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		extra_label.position = Vector2(
			viewport_size.x / 2 - 200,
			name_label.position.y + 44
		)
		extra_label.size = Vector2(400, 30)
		add_child(extra_label)

	# ── SFX ──
	GlobalTweens.play_sfx(SB.SELECT)

	# ── Pop-in animation ──
	card_panel.scale = Vector2(0.1, 0.1)
	var tw: Tween = get_tree().create_tween()
	tw.tween_property(card_panel, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _build_card_style(rarity: String) -> StyleBoxFlat:
	## Build StyleBoxFlat matching DisplayCardBase + NinjaSlot rarity mapping.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.18, 0.92)
	style.set_corner_radius_all(6)

	var width: int = 2
	var border_color: Color = COLOR_INK
	var shadow: int = 4
	var shadow_color: Color = Color(0, 0, 0, 0.12)

	match rarity:
		"uncommon":
			border_color = Color(0.831, 0.659, 0.263)
			shadow = 6
		"rare":
			width = 3
			border_color = Color(0.878, 0.251, 0.251)
			shadow = 10
		"legendary":
			width = 3
			border_color = Color(1.0, 0.843, 0.0)
			shadow = 14

	if shadow > 4:
		shadow_color = Color(border_color, 0.18 if rarity == "legendary" else 0.25)

	style.border_width_left = width
	style.border_width_right = width
	style.border_width_top = width
	style.border_width_bottom = width
	style.border_color = border_color
	style.shadow_size = shadow
	style.shadow_color = shadow_color
	return style


func _make_card_draw(control: Control, tex: Texture2D) -> Callable:
	## Return a callable that draws tex KEEP_ASPECT_COVERED inside control.
	return func():
		if not is_instance_valid(tex):
			return
		var draw_size: Vector2 = control.get_size()
		if draw_size.x <= 0 or draw_size.y <= 0:
			return
		var tex_size: Vector2 = tex.get_size()
		var s: float = max(draw_size.x / tex_size.x, draw_size.y / tex_size.y)
		var scaled: Vector2 = tex_size * s
		var offset: Vector2 = (draw_size - scaled) * 0.5
		control.draw_texture_rect_region(tex, Rect2(offset, scaled), Rect2(Vector2.ZERO, tex_size))


func _on_overlay_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		dismiss()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed \
			and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		dismiss()


func dismiss() -> void:
	if _is_dismissing:
		return
	_is_dismissing = true

	var tw: Tween = get_tree().create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.12)
	tw.tween_callback(queue_free)
