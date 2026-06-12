class_name CardDetailPopup
extends Control
## Unified Balatro-style zoom-in card detail popup.
##
## Used by NinjaBar (left-click), ShopAbilityCard (right-click),
## and ShopItemCard (right-click) for consistent card info display everywhere.
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
##   popup.tree_exited.connect(func(): _detail_popup = null)  # optional guard

const RARITY_COLORS: Dictionary = {
	"common": Color("#888888"),
	"uncommon": Color("#4CAF50"),
	"rare": Color("#F44336"),
	"legendary": Color("#FFD700"),
}

const SB = preload("res://scripts/config/sound_bank.gd")

var _is_dismissing: bool = false


static func open(config: Dictionary) -> CardDetailPopup:
	## Build and display a zoom-in detail popup.
	## Config fields: viewport, texture, name, desc, rarity, extra_desc
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
	z_index = 100
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

	# ── Card art (520x680, ~4x slot size) ──
	var card_art: TextureRect = TextureRect.new()
	card_art.name = "DetailCardArt"
	card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if tex != null:
		card_art.texture = tex
	card_art.size = Vector2(520, 680)
	card_art.position = viewport_size / 2 - card_art.size / 2
	card_art.position.y -= 40  # Shift up to leave room for text below
	add_child(card_art)

	# ── Rarity border ──
	if rarity != "common" and RARITY_COLORS.has(rarity):
		var border: ColorRect = ColorRect.new()
		border.color = RARITY_COLORS[rarity]
		border.size = card_art.size + Vector2(8, 8)
		border.position = card_art.position - Vector2(4, 4)
		border.z_index = -1
		add_child(border)

	# ── Name label (32px, rarity-colored if non-common) ──
	var name_label: Label = Label.new()
	name_label.text = card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 32)
	if rarity != "common" and RARITY_COLORS.has(rarity):
		name_label.add_theme_color_override("font_color", RARITY_COLORS[rarity])
	name_label.position = Vector2(
		viewport_size.x / 2 - 200,
		card_art.position.y + card_art.size.y + 12
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
		# No desc, show extra_desc in desc position (e.g. items with level only)
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
	card_art.scale = Vector2(0.1, 0.1)
	var tw: Tween = get_tree().create_tween()
	tw.tween_property(card_art, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_overlay_clicked(event: InputEvent) -> void:
	## Click anywhere on the overlay → dismiss.
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		dismiss()


func _unhandled_input(event: InputEvent) -> void:
	## ESC key → dismiss.
	if event is InputEventKey and event.pressed \
			and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		dismiss()


func dismiss() -> void:
	## Animate out and remove the popup.
	if _is_dismissing:
		return
	_is_dismissing = true

	var tw: Tween = get_tree().create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.12)
	tw.tween_callback(queue_free)
