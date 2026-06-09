extends Panel
## Balatro-style item (consumable) card displayed in the shop.

@onready var art_icon: Label = %ArtIcon
@onready var name_label: Label = %NameLabel
@onready var effect_label: Label = %EffectLabel
@onready var desc_label: Label = %DescLabel
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton
@onready var buy_label: Label = %BuyButton

var item_data: Dictionary = {}
var is_purchased: bool = false

signal purchase_requested(item: Dictionary)
signal card_pressed(card: Panel)

const COLOR_ITEM_BORDER: Color = Color("4080D0")  # Blue
const COLOR_PRICE: Color = Color("F0D060")
const COLOR_CARD_BG: Color = Color("1A2F2A")
const COLOR_PURCHASED: Color = Color("3A3A3A")


func setup(data: Dictionary) -> void:
	item_data = data

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
	desc_label.text = data.get("desc", "")
	price_label.text = str(data.get("cost", 0))

	var icon: String = _get_item_icon(data.get("name", ""))
	art_icon.text = icon

	buy_button.pressed.connect(_on_buy_pressed)
	gui_input.connect(_on_gui_input)


func _get_item_icon(name: String) -> String:
	if "暴击" in name or "骰子" in name:
		return "🎲"
	if "药水" in name or "倍率" in name:
		return "🧪"
	if "幸运" in name:
		return "⭐"
	if "满堂" in name:
		return "🎯"
	if "王牌" in name:
		return "♠"
	if "Ace" in name:
		return "🅰"
	return "💊"


func set_purchased() -> void:
	is_purchased = true
	buy_button.disabled = true
	buy_label.text = "已购买"
	modulate = Color(0.5, 0.5, 0.5, 1.0)


func set_unavailable(reason: String) -> void:
	buy_button.disabled = true
	buy_label.text = reason


func _on_buy_pressed() -> void:
	if not is_purchased:
		purchase_requested.emit(item_data)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_pressed.emit(self)
