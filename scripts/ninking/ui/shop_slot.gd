class_name ShopSlot
extends Control
## Shop card container — horizontal layout.
##
## Card art (DisplayCardBase, 120x160) on the left, text info on the right.
## Name -> effect (2-line wrap) -> buy button showing price "$N".
## Single unified scene for both ability and item cards.
## Color scheme follows left panel: cream text, gray-olive desc, dark+accent buttons.

# ═══ Signals ═══
signal purchase_requested(data: Dictionary)

# ═══ Constants ═══
const COLOR_INK: Color = Color(0.102, 0.102, 0.102)  # #1A1A1A
const COLOR_CREAM: Color = Color(0.941, 0.929, 0.894)  # Left panel primary text
const COLOR_GRAY_OLIVE: Color = Color(0.478, 0.478, 0.416)  # Left panel secondary

# ═══ @onready references ═══
@onready var display_card: DisplayCardBase = $DisplayCard
@onready var name_label: Label = $name_label
@onready var effect_label: Label = $effect_label
@onready var buy_button: Button = $buy_button

# ═══ State ═══
var _data: Dictionary = {}
var _is_item: bool = false
var is_purchased: bool = false


# ══════════════════════════════════════════
# Public API
# ══════════════════════════════════════════

func setup(data: Dictionary) -> void:
	_data = data
	_is_item = data.has("hand_type") or data.get("type") == "item"

	# 1. Init DisplayCard (pure card face)
	display_card.setup(data)

	# 2. Load illustration into the card
	_load_illustration(data)

	# 3. Text labels (right of card)
	name_label.text = data.get("name", "???")

	if _is_item:
		var ht: int = data.get("hand_type", 0)
		var level: int = NinKingGameState.star_chart_levels.get(ht, 0)
		effect_label.text = data.get("desc", "") + "  Lv.%d" % level
	else:
		effect_label.text = data.get("desc", "")

	# 4. Buy button shows price directly
	var cost: int = data.get("cost", 0)
	buy_button.text = "$%d" % cost
	if buy_button.pressed.is_connected(_on_buy_pressed):
		buy_button.pressed.disconnect(_on_buy_pressed)
	buy_button.pressed.connect(_on_buy_pressed)

	# Reset purchased state on fresh setup
	is_purchased = false
	visible = true


func apply_barrier_theme(colors: Dictionary) -> void:
	## Apply barrier-specific colors to slot elements (left-panel style).

	# Card frame
	display_card.apply_barrier_theme(colors)

	# Name label — cream white (like left panel primary text)
	name_label.add_theme_color_override("font_color", COLOR_CREAM)
	name_label.add_theme_font_size_override("font_size", 16)

	# Effect label — gray olive (like left panel secondary)
	effect_label.add_theme_color_override("font_color", COLOR_GRAY_OLIVE)
	effect_label.add_theme_font_size_override("font_size", 13)

	# Buy button — dark bg + accent border (matching left panel button style)
	var bg_dark: Color = Color(colors.panel).darkened(0.50)

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = bg_dark
	btn_normal.border_color = colors.accent
	btn_normal.border_width_left = 2
	btn_normal.border_width_right = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_bottom = 2
	btn_normal.set_corner_radius_all(6)
	btn_normal.content_margin_left = 8
	btn_normal.content_margin_top = 2
	btn_normal.content_margin_right = 8
	btn_normal.content_margin_bottom = 2
	buy_button.add_theme_stylebox_override("normal", btn_normal)
	buy_button.add_theme_color_override("font_color", COLOR_CREAM)
	buy_button.add_theme_font_size_override("font_size", 14)

	var btn_hover := btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(bg_dark).lightened(0.12)
	btn_hover.border_color = Color(colors.accent).lightened(0.15)
	btn_hover.border_width_left = 3
	btn_hover.border_width_right = 3
	btn_hover.border_width_top = 3
	btn_hover.border_width_bottom = 3
	buy_button.add_theme_stylebox_override("hover", btn_hover)
	buy_button.add_theme_color_override("font_hover_color", Color.WHITE)

	var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color(bg_dark).darkened(0.15)
	btn_pressed.content_margin_top = 4
	btn_pressed.content_margin_bottom = 0
	buy_button.add_theme_stylebox_override("pressed", btn_pressed)
	buy_button.add_theme_color_override("font_pressed_color", Color(COLOR_CREAM).darkened(0.2))

	# Rarity border for ability cards
	if not _is_item:
		var r: String = _data.get("rarity", "common")
		_apply_rarity_border(r, colors)


func set_purchased() -> void:
	## Purchased -> hide entire slot.
	is_purchased = true
	visible = false


func get_card_id() -> String:
	return _data.get("id", "")


# ══════════════════════════════════════════
# Rarity — card border
# ══════════════════════════════════════════

func _apply_rarity_border(rarity: String, colors: Dictionary) -> void:
	var width: int = 2
	var border_color: Color = COLOR_INK
	var shadow_size: int = 4
	var shadow_color: Color = Color(0, 0, 0, 0.12)

	match rarity:
		"uncommon":
			border_color = colors.get("accent", Color(0.831, 0.659, 0.263))
			shadow_size = 6
			shadow_color = Color(border_color)
			shadow_color.a = 0.15
		"rare":
			width = 3
			border_color = Color(0.878, 0.251, 0.251)  # #E04040
			shadow_size = 10
			shadow_color = Color(0.878, 0.251, 0.251)
			shadow_color.a = 0.25
		"legendary":
			width = 3
			border_color = Color(1.0, 0.843, 0.0)  # #FFD700
			shadow_size = 14
			shadow_color = Color(1.0, 0.843, 0.0)
			shadow_color.a = 0.30

	display_card.set_card_border(width, border_color, shadow_size, shadow_color)


# ══════════════════════════════════════════
# Illustration loading
# ══════════════════════════════════════════

func _load_illustration(data: Dictionary) -> void:
	var path: String = ""
	var id: String = data.get("id", "")

	if _is_item:
		path = AssetRegistry.get_star_chart_card_path(id)
	else:
		path = AssetRegistry.get_ninja_card_path(id)

	if path.is_empty() or not ResourceLoader.exists(path):
		return

	var tex: Texture2D = _load_texture_safe(path)
	if tex:
		display_card.set_content_texture(tex)
		display_card.set_detail_data(
			data.get("name", "???"),
			data.get("desc", ""),
			tex
		)


static func _load_texture_safe(path: String) -> Texture2D:
	return load(path) as Texture2D


# ══════════════════════════════════════════
# Purchase
# ══════════════════════════════════════════

func _on_buy_pressed() -> void:
	if not is_purchased:
		purchase_requested.emit(_data)
