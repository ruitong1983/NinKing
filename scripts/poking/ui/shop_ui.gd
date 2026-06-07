extends Control

## Shop UI — buy jokers and items between levels.

@onready var joker_container: VBoxContainer = %JokerShopContainer
@onready var item_container: VBoxContainer = %ItemShopContainer
@onready var gold_label: Label = %ShopGoldLabel
@onready var continue_button: Button = %ContinueButton

var shop: ShopManager = null


func _ready() -> void:
	shop = ShopManager.new()
	shop.generate_stock()

	gold_label.text = "金币: %d" % PokingGameState.gold
	continue_button.pressed.connect(_on_continue_pressed)

	_render_jokers()
	_render_items()


func _render_jokers() -> void:
	for joker: Dictionary in shop.get_jokers_for_display():
		var row: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.text = "%s — %d 金币" % [joker["name"], joker["cost"]]
		row.add_child(label)

		var buy_btn: Button = Button.new()
		buy_btn.text = "购买"
		var j: Dictionary = joker
		buy_btn.pressed.connect(func(): _buy_joker(j, buy_btn))
		row.add_child(buy_btn)

		joker_container.add_child(row)


func _render_items() -> void:
	for item: Dictionary in shop.get_items_for_display():
		var row: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.text = "%s — %d 金币  [%s]" % [item["name"], item["cost"], item["desc"]]
		row.add_child(label)

		var buy_btn: Button = Button.new()
		buy_btn.text = "购买"
		var it: Dictionary = item
		buy_btn.pressed.connect(func(): _buy_item(it, buy_btn))
		row.add_child(buy_btn)

		item_container.add_child(row)


func _buy_joker(joker: Dictionary, btn: Button) -> void:
	if PokingGameState.buy_joker(joker):
		btn.disabled = true
		btn.text = "已购"
		gold_label.text = "金币: %d" % PokingGameState.gold


func _buy_item(item: Dictionary, btn: Button) -> void:
	if PokingGameState.buy_item(item):
		btn.disabled = true
		btn.text = "已购"
		gold_label.text = "金币: %d" % PokingGameState.gold


func _on_continue_pressed() -> void:
	PokingGameState.continue_from_shop()
	get_tree().change_scene_to_file("res://scenes/poking/poking_main.tscn")
