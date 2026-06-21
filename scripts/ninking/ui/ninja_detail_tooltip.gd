class_name NinjaDetailTooltip
extends Control
## Compact hover tooltip for ninja bar cards.
##
## Shows ninja name (rarity-colored), effect summary, and short description
## below the hovered card. All visual properties (colors, fonts, sizes) are
## set in ninja_detail_tooltip.tscn for editor adjustability.
##
## Position offset from card is read from this node's initial position in the
## .tscn — the x/y values serve as the offset from the card's bottom-left.

const SB = preload("res://scripts/config/sound_bank.gd")

var _name_label: Label
var _effect_label: RichTextLabel
var _desc_label: Label

var _tooltip_offset: Vector2


func _ready() -> void:
	_name_label = find_child("NameLabel", true, false) as Label
	_effect_label = find_child("EffectLabel", true, false) as RichTextLabel
	_desc_label = find_child("DescLabel", true, false) as Label
	_tooltip_offset = position
	hide()


func show_for(card: NinjaInventoryCard) -> void:
	var ninja_data: Dictionary = card.ninja_data
	if ninja_data.is_empty():
		return

	_populate(ninja_data)

	global_position = card.global_position + Vector2(0, card.card_size.y) + _tooltip_offset

	show()
	GlobalTweens.fade_in(self, 0.12)


func dismiss() -> void:
	hide()


func _populate(data: Dictionary) -> void:
	var rarity: String = data.get("rarity", "common")

	_name_label.text = data.get("name", "???")
	if rarity != "common" and AssetRegistry.RARITY_NAME_COLORS.has(rarity):
		_name_label.add_theme_color_override("font_color", AssetRegistry.RARITY_NAME_COLORS[rarity])
	else:
		_name_label.remove_theme_color_override("font_color")

	var effect: Dictionary = data.get("effect", {})
	_effect_label.text = _format_effect(effect)
	_effect_label.visible = not _effect_label.text.is_empty()

	_desc_label.text = data.get("desc", "")
	_desc_label.visible = not _desc_label.text.is_empty()


func _format_effect(effect: Dictionary) -> String:
	var parts: Array[String] = []
	var chips: int = effect.get("add_chips", 0)
	var mult: int = effect.get("add_mult", 0)
	var xmult: float = effect.get("x_mult", 0.0)

	if chips > 0:
		parts.append("[color=#1E6BFF]+%d筹码[/color]" % chips)
	if mult > 0:
		parts.append("[color=#E53935]+%d倍率[/color]" % mult)
	if xmult > 1.0:
		parts.append("[color=#E53935]×%s[/color]" % str(xmult))

	if parts.is_empty():
		return ""

	return "[center]" + "  ".join(parts) + "[/center]"
