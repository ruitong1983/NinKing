extends Panel
## Balatro-style ability (joker) card displayed in the shop.

@onready var art_rect: ColorRect = %ArtArea
@onready var art_icon: Label = %ArtIcon
@onready var rarity_badge: Panel = %RarityBadge
@onready var name_label: Label = %NameLabel
@onready var effect_label: Label = %EffectLabel
@onready var condition_label: Label = %ConditionLabel
@onready var price_badge: Panel = %PriceBadge
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton
@onready var buy_label: Label = %BuyButton

var ability_data: Dictionary = {}
var is_purchased: bool = false

signal purchase_requested(ability: Dictionary)
signal card_pressed(card: Panel)

const COLOR_ABILITY_BORDER: Color = Color("8B5CF6")  # Purple
const COLOR_RARE_BORDER: Color = Color("E04040")      # Red
const COLOR_GOLD: Color = Color("D4A843")
const COLOR_PRICE: Color = Color("F0D060")
const COLOR_TEXT_DIM: Color = Color("6A6A5A")
const COLOR_CARD_BG: Color = Color("1A2F2A")
const COLOR_NAME_PLATE: Color = Color("121A17")
const COLOR_PURCHASED: Color = Color("3A3A3A")


func setup(data: Dictionary) -> void:
	ability_data = data

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = COLOR_CARD_BG
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2

	# Rare cards have red border
	var is_rare: bool = data.get("cost", 0) >= 12
	if is_rare:
		style.border_color = COLOR_RARE_BORDER
		style.shadow_size = 8
		style.shadow_color = Color(0.878, 0.251, 0.251, 0.38)
		rarity_badge.visible = true
	else:
		style.border_color = COLOR_ABILITY_BORDER
		style.shadow_size = 4
		style.shadow_color = Color(0.545, 0.361, 0.965, 0.25)

	add_theme_stylebox_override("panel", style)

	name_label.text = data.get("name", "???")
	effect_label.text = data.get("effect_desc", "")

	var cond: String = data.get("condition_desc", "")
	if cond.is_empty():
		condition_label.text = "无条件触发"
	else:
		condition_label.text = cond + "触发"

	price_label.text = str(data.get("cost", 0))

	# Set art emoji based on card theme
	var icon: String = _get_theme_icon(data.get("name", ""), data.get("effect_desc", ""))
	art_icon.text = icon

	buy_button.pressed.connect(_on_buy_pressed)
	gui_input.connect(_on_gui_input)


func _get_theme_icon(name: String, effect: String) -> String:
	if "倍" in effect and effect.begins_with("×"):
		return "👑"
	if "筹码" in effect and "倍率" in effect:
		return "🃏"
	if "顺子" in name:
		return "🔄"
	if "同花" in name:
		return "🌸"
	if "四条" in name or "葫芦" in name:
		return "💪"
	if "皇家" in name:
		return "👑"
	if "幸运" in name or "新手" in name:
		return "🍀"
	return "🃏"


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
		purchase_requested.emit(ability_data)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_pressed.emit(self)
