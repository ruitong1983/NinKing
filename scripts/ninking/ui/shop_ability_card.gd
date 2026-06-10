extends Panel
## Balatro-style ability (joker) card displayed in the shop.

@onready var art_rect: ColorRect = $ArtArea
@onready var art_icon: Label = $ArtIcon
@onready var rarity_badge: Panel = $RarityBadge
@onready var name_label: Label = $NameLabel
@onready var effect_label: Label = $EffectLabel
@onready var condition_label: Label = $ConditionLabel
@onready var price_badge: Panel = $PriceBadge
@onready var price_label: Label = $PriceBadge/PriceLabel
@onready var buy_button: Button = $BuyButton

var ability_data: Dictionary = {}
var is_purchased: bool = false
var _card_style: StyleBoxFlat = null

signal purchase_requested(ability: Dictionary)
signal card_pressed(card: Panel)

const COLOR_INK: Color = Color(0.102, 0.102, 0.102)  # #1A1A1A 漫画墨色


func _cache_nodes() -> void:
	## Ensure @onready vars are initialized — setup() may be called before enter_tree.
	if not name_label:
		art_rect = $ArtArea
		art_icon = $ArtIcon
		rarity_badge = $RarityBadge
		name_label = $NameLabel
		effect_label = $EffectLabel
		condition_label = $ConditionLabel
		price_badge = $PriceBadge
		price_label = $PriceBadge/PriceLabel
		buy_button = $BuyButton


func setup(data: Dictionary) -> void:
	_cache_nodes()
	ability_data = data

	_card_style = StyleBoxFlat.new()
	_card_style.bg_color = Color(0.1, 0.1, 0.18, 0.92)  # 默认暗底，apply_barrier_theme() 覆盖
	_card_style.corner_radius_top_left = 8
	_card_style.corner_radius_top_right = 8
	_card_style.corner_radius_bottom_left = 8
	_card_style.corner_radius_bottom_right = 8
	_card_style.border_width_left = 2
	_card_style.border_width_right = 2
	_card_style.border_width_top = 2
	_card_style.border_width_bottom = 2
	_card_style.border_color = COLOR_INK
	_card_style.shadow_size = 4
	_card_style.shadow_color = Color(0, 0, 0, 0.12)

	add_theme_stylebox_override("panel", _card_style)

	name_label.text = data.get("name", "???")
	effect_label.text = data.get("effect_desc", "")

	var cond: String = data.get("condition_desc", "")
	if cond.is_empty():
		condition_label.text = "无条件触发"
	else:
		condition_label.text = cond + "触发"

	price_label.text = str(data.get("cost", 0))

	# Set art icon based on card theme (text symbols, no emoji)
	var icon: String = _get_theme_icon(data.get("name", ""), data.get("effect_desc", ""))
	art_icon.text = icon

	buy_button.pressed.connect(_on_buy_pressed)
	gui_input.connect(_on_gui_input)


func apply_barrier_theme(colors: Dictionary) -> void:
	## Apply barrier-specific manga colors to the card.
	## colors = {bg, panel, accent, name, particle_color}
	_cache_nodes()
	if not _card_style:
		return

	# Card base = panel color + ink border
	_card_style.bg_color = colors.panel
	_card_style.border_color = COLOR_INK

	# Art area = panel darkened 15%
	art_rect.color = Color(colors.panel).darkened(0.15)
	# Name plate = panel darkened 5%
	$NamePlate.color = Color(colors.panel).darkened(0.05)
	# Price badge = panel color + ink border
	var price_style := price_badge.get_theme_stylebox("panel") as StyleBoxFlat
	if not price_style:
		price_style = StyleBoxFlat.new()
	price_style.bg_color = colors.panel
	price_style.border_color = COLOR_INK
	price_style.border_width_left = 2
	price_style.border_width_right = 2
	price_style.border_width_top = 2
	price_style.border_width_bottom = 2
	price_style.corner_radius_top_left = 6
	price_style.corner_radius_top_right = 6
	price_style.corner_radius_bottom_left = 6
	price_style.corner_radius_bottom_right = 6
	price_badge.add_theme_stylebox_override("panel", price_style)

	# Buy button = accent color + ink border (light-impact style)
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = colors.accent
	btn_normal.border_color = COLOR_INK
	btn_normal.border_width_left = 3
	btn_normal.border_width_right = 3
	btn_normal.border_width_top = 3
	btn_normal.border_width_bottom = 3
	btn_normal.corner_radius_top_left = 8
	btn_normal.corner_radius_top_right = 8
	btn_normal.corner_radius_bottom_left = 8
	btn_normal.corner_radius_bottom_right = 8
	btn_normal.content_margin_left = 16
	btn_normal.content_margin_top = 8
	btn_normal.content_margin_right = 16
	btn_normal.content_margin_bottom = 8
	buy_button.add_theme_stylebox_override("normal", btn_normal)
	buy_button.add_theme_color_override("font_color", Color.WHITE)

	# Hover: lighter accent + thicker border
	var btn_hover := btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(colors.accent).lightened(0.1)
	btn_hover.border_width_left = 4
	btn_hover.border_width_right = 4
	btn_hover.border_width_top = 4
	btn_hover.border_width_bottom = 4
	buy_button.add_theme_stylebox_override("hover", btn_hover)

	# Pressed: darker accent + content shift down
	var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color(colors.accent).darkened(0.15)
	btn_pressed.content_margin_top = 10
	btn_pressed.content_margin_bottom = 6
	buy_button.add_theme_stylebox_override("pressed", btn_pressed)


func _get_theme_icon(card_name: String, effect: String) -> String:
	if "倍" in effect and effect.begins_with("x"):
		return "[极]"
	if "筹码" in effect and "倍率" in effect:
		return "[术]"
	if "顺子" in card_name:
		return "[顺]"
	if "同花" in card_name:
		return "[花]"
	if "四条" in card_name or "葫芦" in card_name:
		return "[强]"
	if "皇家" in card_name:
		return "[极]"
	if "幸运" in card_name or "新手" in card_name:
		return "[运]"
	return "[术]"


func set_purchased() -> void:
	is_purchased = true
	buy_button.disabled = true
	buy_button.text = "入手済"
	modulate = Color(0.5, 0.5, 0.5, 1.0)


func set_unavailable(reason: String) -> void:
	buy_button.disabled = true
	buy_button.text = reason


func _on_buy_pressed() -> void:
	if not is_purchased:
		purchase_requested.emit(ability_data)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_pressed.emit(self)
