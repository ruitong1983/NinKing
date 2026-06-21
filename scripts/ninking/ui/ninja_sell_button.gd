class_name NinjaSellButton
extends Button
## Red sell button for ninja bar cards, appears to the right of a card on right-click.
##
## All visual properties (colors, fonts, sizes) are set in ninja_sell_button.tscn
## for editor adjustability. Position offset from card is read from this node's
## initial position in the .tscn.

signal sell_confirmed(ninja_data: Dictionary)

const SB = preload("res://scripts/config/sound_bank.gd")

var _ninja_data: Dictionary = {}
var _sell_price: int = 0
var _button_offset: Vector2


func _ready() -> void:
	_button_offset = position
	pressed.connect(_on_pressed)
	hide()


func show_for(card: NinjaInventoryCard, price: int) -> void:
	_ninja_data = card.ninja_data
	_sell_price = price

	text = "售卖 $%d" % price

	# Position to the right of card: card's right-center + offset
	global_position = card.global_position + Vector2(card.card_size.x, 0) + _button_offset

	show()
	GlobalTweens.pop_in(self, 0.2, Vector2(0.5, 0.5))


func dismiss() -> void:
	hide()


func _on_pressed() -> void:
	if _ninja_data.is_empty():
		return
	GlobalTweens.play_sfx(SB.UI_COIN)
	sell_confirmed.emit(_ninja_data)
	dismiss()
