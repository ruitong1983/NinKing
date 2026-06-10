class_name ShopItemCard
extends Panel

@onready var art_icon: Label = $ArtIcon
@onready var name_label: Label = $NameLabel
@onready var effect_label: Label = $EffectLabel
@onready var desc_label: Label = $DescLabel
@onready var price_label: Label = $PriceBadge/PriceLabel
@onready var buy_button: Button = $BuyButton

var is_purchased: bool = false
var item_data: Dictionary = {}
var _card_style: StyleBoxFlat = null

signal purchase_requested(item: Dictionary)

const COLOR_INK: Color = Color(0.102, 0.102, 0.102)  # #1A1A1A 漫画墨色


func _cache_nodes() -> void:
	## Ensure @onready vars are initialized — setup() may be called before enter_tree.
	if not name_label:
		art_icon = $ArtIcon
		name_label = $NameLabel
		effect_label = $EffectLabel
		desc_label = $DescLabel
		price_label = $PriceBadge/PriceLabel
		buy_button = $BuyButton


func setup(data: Dictionary) -> void:
	_cache_nodes()
	item_data = data
	is_purchased = false

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.2, 0.92)  # 默认暗底，apply_barrier_theme() 覆盖
	style.set_corner_radius_all(8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = COLOR_INK
	style.shadow_size = 4
	style.shadow_color = Color(0, 0, 0, 0.12)
	_card_style = style
	add_theme_stylebox_override("panel", style)

	name_label.text = data.get("name", "???")
	effect_label.text = data.get("effect_desc", "")

	var cost: int = data.get("cost", 1)
	price_label.text = "$%d" % cost

	var icon: String = _get_item_icon(data.get("name", ""))
	art_icon.text = icon

	buy_button.pressed.connect(_on_buy_pressed)


func apply_barrier_theme(colors: Dictionary) -> void:
	## Apply barrier-specific manga colors to the item card.
	## colors = {bg, panel, accent, name, particle_color}
	_cache_nodes()
	if not _card_style:
		return

	# Card base = panel color + ink border
	_card_style.bg_color = colors.panel
	_card_style.border_color = COLOR_INK

	# Art area = panel darkened 15%
	$ArtArea.color = Color(colors.panel).darkened(0.15)
	# Name plate = panel darkened 5%
	$NamePlate.color = Color(colors.panel).darkened(0.05)
	# Price badge = panel color + ink border
	var price_style := price_label.get_parent().get_theme_stylebox("panel") as StyleBoxFlat
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
	price_label.get_parent().add_theme_stylebox_override("panel", price_style)

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

	# Hover
	var btn_hover := btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(colors.accent).lightened(0.1)
	btn_hover.border_width_left = 4
	btn_hover.border_width_right = 4
	btn_hover.border_width_top = 4
	btn_hover.border_width_bottom = 4
	buy_button.add_theme_stylebox_override("hover", btn_hover)

	# Pressed
	var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color(colors.accent).darkened(0.15)
	btn_pressed.content_margin_top = 10
	btn_pressed.content_margin_bottom = 6
	buy_button.add_theme_stylebox_override("pressed", btn_pressed)


func _on_buy_pressed() -> void:
	if not is_purchased:
		purchase_requested.emit(item_data)


func _get_item_icon(item_name: String) -> String:
	if "暴击" in item_name or "骰子" in item_name:
		return "[赛]"
	if "药水" in item_name or "倍率" in item_name:
		return "[药]"
	if "幸运" in item_name:
		return "[运]"
	if "满堂" in item_name:
		return "[满]"
	if "王牌" in item_name:
		return "[王]"
	if "Ace" in item_name:
		return "[A]"
	return "[物]"


func set_purchased() -> void:
	is_purchased = true
	buy_button.disabled = true
	buy_button.text = "入手済"
	modulate.a = 0.5
