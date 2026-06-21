class_name ShopSlot
extends Control
## Shop card container — ink-wash (水墨) card + seal button.
##
## DisplayCard (card art + embedded name/desc) + buy button showing "$N".
## Single unified scene for both ability and item cards.
## Ink-wash palette: paper-white card, cinnabar seal buy button.

# ═══ Signals ═══
signal purchase_requested(data: Dictionary)

# ═══ Ink-wash palette ═══
const COLOR_SUMI       := Color(0.169, 0.118, 0.063)  # 焦墨 #2B1E10

const COLOR_PAPER      := Color(0.961, 0.941, 0.910)  # 和纸白 #F5F0E8
const COLOR_CINNABAR   := Color(0.722, 0.227, 0.165)  # 朱砂 #B83A2A
const COLOR_BLUE_ZAN   := Color(0.180, 0.361, 0.541)  # 蓝锖 #2E5C8A
const COLOR_GOLD_MUD   := Color(0.769, 0.639, 0.353)  # 金泥 #C4A35A
const COLOR_CARD_SHADOW := Color(0, 0, 0, 0.08)  # 纸片投影

# ═══ @onready references ═══
@onready var ninja_card: NinjaInventoryCard = $NinjaCard
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
	ninja_card.setup_shop(data)

	# 2. Load illustration into the card
	_load_illustration(data)

	# 3. Buy button shows price directly
	var cost: int = data.get("cost", 0)
	buy_button.text = "$%d" % cost
	if buy_button.pressed.is_connected(_on_buy_pressed):
		buy_button.pressed.disconnect(_on_buy_pressed)
	buy_button.pressed.connect(_on_buy_pressed)

	# 4. Clicking card face also triggers purchase
	if ninja_card.card_clicked.is_connected(_on_buy_pressed):
		ninja_card.card_clicked.disconnect(_on_buy_pressed)
	ninja_card.card_clicked.connect(_on_buy_pressed)

	# Reset purchased state on fresh setup
	is_purchased = false
	visible = true


func apply_barrier_theme(_colors: Dictionary) -> void:
	## Backwards-compatible entry point.
	## Delegates to ink-wash theme — ignores `colors` since shop uses its own palette.
	apply_ink_wash_theme()


func apply_ink_wash_theme() -> void:
	## Apply ink-wash (水墨) styling: paper card + sumi text + cinnabar seal button.

	# ── Card frame: paper white + ink border + soft shadow ──
	# Override the card's internal bg to paper white via its existing method
	if ninja_card.has_method("apply_barrier_theme"):
		# Hijack: pass paper as "panel" color — works because method sets bg_color = panel
		ninja_card.apply_barrier_theme({"panel": COLOR_PAPER, "accent": COLOR_SUMI})

	# ── Buy button: cinnabar seal (朱砂印章) ──
	_apply_seal_button_style(buy_button, COLOR_CINNABAR)

	# ── Rarity border for ability cards ──
	if not _is_item:
		var r: String = _data.get("rarity", "common")
		ninja_card.set_frame(r)


func set_purchased() -> void:
	## Purchased -> hide entire slot.
	is_purchased = true
	visible = false


func get_card_id() -> String:
	return _data.get("id", "")


# ══════════════════════════════════════════
# Seal button style
# ══════════════════════════════════════════

func _apply_seal_button_style(btn: Button, seal_color: Color) -> void:
	## Seal (印章) button: solid mineral-pigment bg + ink border + white text.
	var bg := seal_color

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = COLOR_SUMI
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 8
	normal.content_margin_top = 2
	normal.content_margin_right = 8
	normal.content_margin_bottom = 2
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 14)

	var hovered := normal.duplicate() as StyleBoxFlat
	hovered.bg_color = Color(bg).lightened(0.10)
	hovered.border_width_left = 3
	hovered.border_width_right = 3
	hovered.border_width_top = 3
	hovered.border_width_bottom = 3
	btn.add_theme_stylebox_override("hover", hovered)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(bg).darkened(0.15)
	pressed.content_margin_top = 4
	pressed.content_margin_bottom = 0
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0.85))


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
		ninja_card.set_content_texture(tex)
		ninja_card.set_detail_data(
			data.get("name", "???"),
			data.get("desc", ""),
			tex,
			data.get("effect", {})
		)


static func _load_texture_safe(path: String) -> Texture2D:
	return load(path) as Texture2D


# ══════════════════════════════════════════
# Purchase
# ══════════════════════════════════════════

func _on_buy_pressed() -> void:
	if not is_purchased:
		purchase_requested.emit(_data)
