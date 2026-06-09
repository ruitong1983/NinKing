class_name ShopItemCard
extends PanelContainer

@onready var art_icon: Label = %ArtIcon
@onready var name_label: Label = %NameLabel
@onready var effect_label: Label = %EffectLabel
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton

var is_purchased: bool = false
var _data: Dictionary = {}

const COLOR_CARD_BG: Color = Color(0.1, 0.1, 0.18, 0.92)
const COLOR_ITEM_BORDER: Color = Color(0.25, 0.6, 0.9, 0.7)


func setup(data: Dictionary) -> void:
	_data = data
	is_purchased = false

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = COLOR_CARD_BG
	style.set_corner_radius_all(14)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = COLOR_ITEM_BORDER
	style.shadow_size = 4
	style.shadow_color = Color(0.251, 0.502, 0.816, 0.25)
	add_theme_stylebox_override("panel", style)

	name_label.text = data.get("name", "???")
	effect_label.text = data.get("effect_desc", "")

	var cost: int = data.get("cost", 1)
	price_label.text = "$%d" % cost

	var icon: String = _get_item_icon(data.get("name", ""))
	art_icon.text = icon


func _get_item_icon(name: String) -> String:
	if "暴击" in name or "骰子" in name:
		return "[赛]"
	if "药水" in name or "倍率" in name:
		return "[药]"
	if "幸运" in name:
		return "[运]"
	if "满堂" in name:
		return "[满]"
	if "王牌" in name:
		return "[王]"
	if "Ace" in name:
		return "[A]"
	return "[物]"


func set_purchased() -> void:
	is_purchased = true
	buy_button.disabled = true
	buy_button.text = "已购买"
	modulate.a = 0.5
