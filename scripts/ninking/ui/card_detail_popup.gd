class_name CardDetailPopup
extends Control
## Unified Balatro-style zoom-in card detail popup.
##
## Shows a large framed card with rarity border and cropped art (KEEP_ASPECT_COVERED),
## matching the slot's NinjaCard visual style (via NinjaInventoryCard).
##
## Card panel + art + frame construction delegated to CardVisualComposer.build_card_face().
## Scene structure defined in card_detail_popup.tscn.
##
## Balatro-style effect rendering:
##   - add_chips > 0  → +N 筹码  (blue bold, gray unit)
##   - add_mult > 0   → +N 倍率  (red bold, gray unit)
##   - x_mult   > 1   → ×N        (red bold)
##   - No numeric effect match → fallback to desc text (22px gray)
##
## Usage:
##   var popup = CardDetailPopup.open({
##       viewport = get_viewport(),
##       texture = card_texture,
##       name = "风魔小太郎",
##       desc = "效果描述/触发条件",
##       rarity = "rare",
##       extra_desc = "Lv.3",
##       effect = {"add_chips": 15, "add_mult": 2},
##   })

const CARD_SIZE: Vector2 = Vector2(320, 448)
const SB = preload("res://scripts/config/sound_bank.gd")

# Balatro-style effect colors
const COLOR_CHIPS_BLUE: Color = Color("#1E6BFF")
const COLOR_MULT_RED: Color = Color("#E53935")

var _is_dismissing: bool = false

# Cached node refs (set in _build, not @onready, because open() calls _build before _ready)
var _overlay: ColorRect
var _name_label: Label
var _effect_container: Control
var _desc_label: Label


static func open(config: Dictionary) -> CardDetailPopup:
	var popup: CardDetailPopup = preload("res://scenes/ninking/card_detail_popup.tscn").instantiate()
	popup._build(config)
	return popup


func _build(config: Dictionary) -> void:
	# Cache scene node refs (available immediately after instantiate)
	_overlay = %DetailOverlay
	_name_label = %NameLabel
	_effect_container = %EffectContainer
	_desc_label = %DescLabel
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
	var effect: Dictionary = config.get("effect", {})

	var viewport_size: Vector2 = viewport.get_visible_rect().size

	# Setup self
	size = viewport_size
	z_index = 1200
	name = "CardDetailPopup"
	viewport.get_tree().current_scene.add_child(self)

	# ── Position overlay ──
	_overlay.size = viewport_size
	_overlay.gui_input.connect(_on_overlay_clicked)
	GlobalTweens.fade_in(_overlay, 0.1)

	# ── Card face via CardVisualComposer (panel + background style + art + frame overlay) ──
	# build_card_face() adds the card_panel as a child of self automatically.
	var card_pos: Vector2 = viewport_size / 2 - CARD_SIZE / 2
	card_pos.y -= 60  # Shift up for text below

	var card_panel: Panel = CardVisualComposer.build_card_face(
			self, CARD_SIZE, tex, rarity, true)
	card_panel.name = "DetailCardPanel"
	card_panel.position = card_pos

	# ── Parse effect → Balatro-style rows ──
	var effect_rows: Array[Dictionary] = _parse_effect_rows(effect)

	# ── Name label (32px, rarity-colored if non-common) ──
	_name_label.text = card_name
	_name_label.add_theme_font_size_override("font_size", 32)
	if rarity != "common" and AssetRegistry.RARITY_NAME_COLORS.has(rarity):
		_name_label.add_theme_color_override("font_color", AssetRegistry.RARITY_NAME_COLORS[rarity])
	_name_label.position = Vector2(
		viewport_size.x / 2 - 200,
		card_pos.y + CARD_SIZE.y + 12
	)
	_name_label.size = Vector2(400, 40)

	# ── Effect rows (Balatro-style: chips blue / mult red / xmult red) ──
	var after_effect_y: float = _name_label.position.y + 46
	if not effect_rows.is_empty():
		var row_y: float = after_effect_y
		for row: Dictionary in effect_rows:
			_build_effect_row(row, viewport_size.x, row_y)
			row_y += 36  # 32px row height + 4px gap
		after_effect_y = row_y + 4

	# ── Description (only show if: no effect rows, OR effect has condition text) ──
	if desc != "":
		var has_condition: bool = (not effect_rows.is_empty()
				and effect.has("condition"))
		var show_desc: bool = effect_rows.is_empty() or has_condition

		if show_desc:
			_desc_label.text = desc
			if effect_rows.is_empty():
				_desc_label.add_theme_font_size_override("font_size", 22)
			else:
				_desc_label.add_theme_font_size_override("font_size", 18)
			_desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			_desc_label.position = Vector2(
				viewport_size.x / 2 - 200,
				after_effect_y
			)
			_desc_label.size = Vector2(400, 26)

			if extra_desc != "":
				var extra_label: Label = Label.new()
				extra_label.text = extra_desc
				extra_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				extra_label.add_theme_font_size_override("font_size", 18)
				extra_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
				extra_label.position = Vector2(
					viewport_size.x / 2 - 200,
					_desc_label.position.y + 28
				)
				extra_label.size = Vector2(400, 26)
				add_child(extra_label)

	elif extra_desc != "":
		# No desc but extra_desc exists (e.g. item level info)
		var extra_label: Label = Label.new()
		extra_label.text = extra_desc
		extra_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		extra_label.add_theme_font_size_override("font_size", 22)
		extra_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		extra_label.position = Vector2(
			viewport_size.x / 2 - 200,
			after_effect_y
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


## Parse effect dict into Balatro-style rows.
## Skips zero values (add_chips/add_mult = 0 is scaling cards with
## runtime growth) and x_mult  1 (no meaningful multiplier).
static func _parse_effect_rows(effect: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var chips: int = effect.get("add_chips", 0)
	var mult: int = effect.get("add_mult", 0)
	var xmult: float = effect.get("x_mult", 0.0)

	if chips > 0:
		rows.append({"type": "chips", "value": chips, "unit": "筹码"})
	if mult > 0:
		rows.append({"type": "mult", "value": mult, "unit": "倍率"})
	if xmult > 1.0:
		rows.append({"type": "xmult", "value": xmult})
	return rows


## Build one Balatro-style effect row (colored number + gray unit on one line).
## Chips: +30 筹码 (blue bold #1E6BFF, gray unit)
## Mult:  +10 倍率 (red bold #E53935, gray unit)
## xMult: ×N         (red bold #E53935)
func _build_effect_row(row: Dictionary, screen_w: float, y: float) -> void:
	var rtl: RichTextLabel = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rtl.scroll_active = false
	rtl.size = Vector2(300, 32)
	rtl.position = Vector2(screen_w / 2 - 150, y)
	rtl.add_theme_font_size_override("normal_font_size", 24)
	rtl.autowrap_mode = TextServer.AUTOWRAP_OFF

	match row.type:
		"chips":
			rtl.text = ("[center][color=#1E6BFF][b]+%d[/b][/color]"
					+ " [color=#B3B3B3]%s[/color][/center]") % [row.value, row.unit]
		"mult":
			rtl.text = ("[center][color=#E53935][b]+%d[/b][/color]"
					+ " [color=#B3B3B3]%s[/color][/center]") % [row.value, row.unit]
		"xmult":
			rtl.text = "[center][color=#E53935][b]×%s[/b][/color][/center]" % row.value

	_effect_container.add_child(rtl)


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
